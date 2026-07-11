# Replace install system with dotbot + Python (uv)

## Context

`install.sh` has grown to 252 lines orchestrating ~600 lines of bash across 6 sourced scripts, branching on OS (`$OSTYPE`) and work/personal (`detect_work_machine` = "does `atlas` exist") for 4 machine types. Problems found:

- **Two workflows conflated**: rare full provisioning vs frequent "sync my dotfile changes" — the frequent path pays the full interactive ceremony every run.
- **Duplication**: Brewfile selection in `install.sh` + `brew-install-custom.sh`; the `IFS=: read` + `eval echo` conf parser in `links.sh`, `sync.sh`, **and** `git/hooks/pre-commit` (a hidden dependent — it re-parses the conf files to self-heal links on every commit; migrating the confs breaks committing unless the hook moves in the same pass).
- **Fragility**: `eval echo` on config lines; work detection misclassifies fresh work machines; hardcoded brew prefixes; `--delete --include-files` does `rm -rf` on real files; `set -e` with no resume; orphaned scripts (`vscode-extensions.sh`, `install_nvidia_gpu.sh`); dead `.env` (`WORK_HOSTNAMES` — nothing reads it).

**Decisions (user-confirmed):** adopt dotbot for linking; Python (uv-managed) for orchestration/diff/adopt/managed-files; thin bash bootstrap; explicit saved machine profile; split fast `sync` from full `install`; full replacement in one pass. Repo reorg allowed.

## Target layout

```
dotfiles/
├── dot                       # bash shim: exec uv run --project . python -m dotfiles "$@"
│                             #   (finds uv in PATH / ~/.local/bin / brew prefixes;
│                             #    after successful `install` on a tty: exec zsh)
├── bootstrap.sh              # virgin machine: xcode|apt prereqs → homebrew → uv → exec ./dot install "$@"
├── pyproject.toml + uv.lock  # deps: dotbot (pinned); dev: pytest, ruff; requires-python >= 3.11
├── install/
│   ├── dotbot/
│   │   ├── base.yaml         # ← softlinks_config.conf (minus .git/hooks line) + hushlogin shell step
│   │   ├── macos.yaml        # ← softlinks_config_mac.conf
│   │   ├── linux.yaml        # placeholder (empty today)
│   │   ├── work.yaml         # ← softlinks_config_work.conf
│   │   └── personal.yaml     # ← softlinks_config_personal.conf
│   ├── managed.toml          # ← sync_config.conf + sync_config_work.conf
│   └── dotfiles/             # Python package
│       ├── __main__.py, cli.py        # argparse subcommands
│       ├── profile.py                 # ~/.config/dotfiles/profile.json
│       ├── linker.py                  # dotbot invocation + classify/diff/adopt/heal
│       ├── managed.py                 # pull/push of app-owned files
│       ├── packages.py                # brew bundle per profile + claude CLI install
│       ├── gitrepo.py                 # skip-worktree, strip-work-tooling filter, hooksPath
│       ├── platform_setup.py          # subprocess → osx-defaults.sh / install_debian.sh
│       └── ui.py                      # colored logging (NO_COLOR aware)
├── tests/                    # pytest: config validity, linker/managed/profile semantics on tmp_path
├── mac_config/osx-defaults.sh   # kept bash, + arg dispatch (defaults|keyboard)
├── linux/install_debian.sh      # kept bash, + arg dispatch (settings|cli-tools|apps)
├── git/hooks/pre-commit         # rewritten as 3-line shim → ./dot hook pre-commit
└── scripts/utils.sh             # trimmed to logging only (detect_work_machine deleted)
```

**Deleted:** `install.sh`, `scripts/{links.sh,sync.sh,prerequisites.sh,brew-install-custom.sh,non-homebrew-install.sh}`, all 4 `softlinks_config*.conf`, both `sync_config*.conf`, `.env`.

## CLI surface

```
./dot install [--profile NAME] [--minimal] [--adopt|--overwrite] [--skip-apps] [--dry-run]
./dot sync    [--dry-run]     # THE frequent path: links + managed push + git housekeeping, non-interactive, seconds
./dot diff                    # classify links/managed files; exit 2 on conflict (parity with --show-diffs)
./dot adopt [TARGET ...]      # copy machine versions into repo, relink
./dot pull  [--dry-run]       # managed files: system → repo
./dot profile [show | set NAME [--minimal]]
./dot apps                    # brew bundles + claude CLI only (replaces brew-install-custom standalone)
./dot defaults                # rerun OS defaults
./dot hook pre-commit         # internal: heal/adopt/pull for the git hook
```

Profiles: `personal-mac | work-mac | personal-linux | work-linux`, saved as JSON `{"profile": ..., "minimal": ...}` at `~/.config/dotfiles/profile.json`; first `install` asks or takes `--profile`; later runs read silently; error if saved OS ≠ running platform. `minimal` replaces `--terminal-only` and is persisted (property of the machine). Behavior change to document: minimal still links the work/personal context layer (old terminal-only skipped personal links); minimal skips apps/defaults only.

## Key design points

- **dotbot via PyPI dep pinned in `uv.lock`**, invoked in-process (single merged task list → one `Dispatcher(base_directory=REPO)` pass over layers base → os → context). Fallback if the semi-internal API is awkward at the pinned version: sequential `dotbot.cli.main` per layer catching `SystemExit`. No submodule.
- **Link defaults** `{create: true, relink: true, force: false}` — matches `links.sh` semantics exactly (update symlink pointing elsewhere, e.g. the work/personal `~/.gitconfig` swap at `scripts/links.sh:43`; never clobber real files).
- **`linker.py` is the single source of truth**: parses the same YAMLs to enumerate `(source, target)` pairs, classifies each (`OK | MISSING | WRONG_LINK | EXISTS_SAME | EXISTS_DIFFERS | CONFLICT`). Reproduces: `--show-diffs` conflict rule (target differs AND repo source dirty vs HEAD → exit 2, `scripts/links.sh:116-123`), `--adopt` (`links.sh:137-161`), and the pre-commit heal logic (`git/hooks/pre-commit:47-75`: same content → fix link; differs + clean repo file → adopt + `git add`; differs + dirty → abort commit).
- **Overwrite safety**: `install --overwrite` removes only targets classified `EXISTS_*`, moving them to `~/.config/dotfiles/backup/<timestamp>/` first — the blanket `rm -rf` path is gone. `sync` never touches real files.
- **`managed.py` + `managed.toml`** (stdlib `tomllib`): port of `sync.sh` — pull/push, mkdir parents, realpath-equal skip, `--dry-run`; groups `base` / `work` (Arc sidebar entry). Hook behavior preserved: managed files always pulled, never staged (`pre-commit:80-105`).
- **`gitrepo.py`**: skip-worktree on `zsh/local.zsh` (+ `git/global-config/work.gitconfig` on work), the `strip-work-tooling` clean filter (exact sed from `install.sh:219`), and `git config core.hooksPath git/hooks` (replaces the self-referential `.git/hooks/pre-commit` symlink line in the old conf). Run from both `install` and `sync` (idempotent, self-healing).
- **Platform scripts stay bash** (`osx-defaults.sh`, `install_debian.sh`) — pure `defaults write`/apt sequences; Python calls them via subprocess with new arg dispatch. `bootstrap.sh` absorbs `prerequisites.sh` (xcode / apt prereqs + linuxbrew dir → homebrew NONINTERACTIVE → uv via astral installer) then `exec ./dot install "$@"`. Add `brew "uv"` to `Brewfile.terminal` so brew maintains uv afterwards.
- No eval anywhere; expansion is `os.path.expanduser` on targets only.

## Implementation steps

1. Scaffold: `pyproject.toml`, `uv.lock`, package skeleton, `ui.py`, `profile.py`, `./dot` shim. Verify `./dot profile set/show`.
2. Write the 5 dotbot YAMLs + `managed.toml` from the 6 conf files (mechanical; watch the two-target `zsh/.zshenv`, the space in the Arc path, and drop the `.git/hooks/pre-commit` line → `gitrepo.py`).
   Parity check (throwaway scratchpad script, not committed): expand old confs via bash and diff the `(source,target)` sets against `linker.entries()` for all 4 profiles.
3. `linker.py` (entries/classify/diff/adopt/heal + dotbot dispatch) → wire `dot diff`, `dot adopt`, link half of `dot sync`.
4. `managed.py` → wire `dot pull` + push half of `sync`.
5. `gitrepo.py` + rewrite `git/hooks/pre-commit` as shim → `dot hook pre-commit`.
6. `packages.py`, `platform_setup.py`; add arg dispatch to the two platform bash scripts; trim `utils.sh`.
7. `cli.py` install flow + `bootstrap.sh`; `brew "uv"` in Brewfile.terminal.
8. Delete old files; `grep -rn 'links.sh\|sync\.sh\|sync_config\|softlinks_config\|detect_work_machine\|install\.sh'` for stragglers (zsh aliases, claude hooks, docs).
9. Docs + CI: rewrite README/CLAUDE.md around `./dot`; update `.github/workflows/lint.yml` shellcheck file list (bootstrap.sh, dot, remaining scripts, hook) and add a uv job (`uv sync --locked`, `ruff check`, `pytest`).
10. Tests: `test_configs.py` (every YAML source + managed repo path exists — standing regression guard), `test_linker.py`, `test_managed.py`, `test_profile.py` on tmp_path trees.

## Verification

On this mac (sources/targets unchanged → migration must be a no-op for link state):
1. Before deleting old files: snapshot `readlink` of every old-conf target to scratchpad.
2. `./dot diff` → all OK; `./dot sync --dry-run` → nothing destructive; `./dot sync`; re-snapshot → byte-identical.
3. Managed round-trip: touch `~/.config/htop/htoprc` → `./dot pull` picks it up; revert → `./dot sync` pushes back.
4. Idempotency: second `./dot sync` = zero changes; `git ls-files -v | grep ^S` still lists skip-worktree entries; filter config intact.
5. Hook: benign commit passes; simulated conflict (edit repo file + replace its link target) aborts with instructions.
6. Ubuntu smoke: `tests/docker-smoke.sh` — `ubuntu:24.04` container, non-root user, `bootstrap.sh --profile personal-linux --minimal --skip-apps` fast path, assert `readlink ~/.zshenv`; full brew path optional/manual.
7. Profile guard: `personal-linux` profile on the mac errors on next `dot sync`.

## Risks

- dotbot `Dispatcher` is semi-internal — pin the version; sequential-CLI fallback documented above.
- `uv run` needs one `uv sync` with network (bootstrap covers it); offline thereafter.
- Profile switch leaves stale links from the other context (same as today); note in README, future `dot prune`.

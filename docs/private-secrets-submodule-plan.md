# Private secrets via a git submodule

## Status

In progress — see repo history for the commits landing each step below.

## Context

Two files in this public dotfiles repo (`github.com/Pencilvesterr/dotfiles`, confirmed public)
hold data that shouldn't be publicly readable, but that Morgan still wants synced across
machines by the normal `./dot` flow:

- `config/claude/hooks/.env` — real ntfy.sh server/topic/token used by the Claude Code notify
  hook. Currently gitignored and **has never been committed** (verified via
  `git log --all --full-history`), so there's no history exposure — but it's also **not synced
  anywhere today**: it's not in `setup/dotbot/` or `setup/managed.toml`, so it only exists by
  hand-copying it machine to machine.
- `config/arc/StorableSidebar.json` — Arc browser sidebar/sync data (tabs, titles, URLs).
  This one **is tracked and already pushed** to the public repo (present since before the
  July 2026 `config/`+`setup/` reorg, commit `bf7abc1` carried it forward). It's wired into
  `setup/managed.toml` as a `work`+`mac`-scoped managed file, copied both directions by
  `./dot pull`/`./dot sync`.

Decisions made with Morgan:
- **Do not rewrite git history right now.** Stop tracking `StorableSidebar.json` going forward;
  document the existing exposure and the future purge steps in a separate file instead of
  acting on it now.
- **Use a private GitHub submodule** as the sync mechanism for both files. Create the new
  private repo via `gh repo create` as part of this implementation.

## Design

New private repo: `Pencilvesterr/dotfiles-private` (private visibility), added as a git
submodule at `private/` in the repo root (sibling to `config/` and `setup/`), using an HTTPS
remote URL to match the existing `origin` remote (`https://github.com/Pencilvesterr/dotfiles.git`).

Layout inside the submodule mirrors what it replaces:
```
private/
  claude/hooks/.env
  arc/StorableSidebar.json
```

### File moves
- `config/claude/hooks/.env` → `private/claude/hooks/.env` (plain move; nothing to purge from
  public history since it was never committed). Keep `config/claude/hooks/.env.sample` in the
  public repo unchanged — it's a safe placeholder.
- `config/arc/StorableSidebar.json` → `private/arc/StorableSidebar.json`. `git rm --cached` it
  from the public repo (stops future tracking, per the decision above) and remove the
  now-empty `config/arc/` directory.

### Wiring changes
- `setup/dotbot/base.yaml`: add a new link entry next to the existing
  `~/.claude/hooks/notify.sh: config/claude/hooks/notify.sh` line:
  ```yaml
  ~/.claude/hooks/.env: private/claude/hooks/.env
  ```
  `notify.sh` (`config/claude/hooks/notify.sh:10`) already does
  `source "$script_dir/.env"` where `script_dir` resolves through the symlink — this keeps
  working unmodified since both files land in `~/.claude/hooks/`. This is what makes `.env`
  actually synced across machines for the first time.
- `setup/managed.toml`: change the `StorableSidebar.json` entry's `repo` field from
  `config/arc/StorableSidebar.json` to `private/arc/StorableSidebar.json` (keep the existing
  `context = "work"` / `os = "mac"` scoping).

### Submodule initialization in the install/sync flow
There's no existing submodule handling, and two real failure modes if we don't add it:
- `linker.run_dotbot`'s skip-set (`setup/dotfiles/linker.py:174-178`) does **not** exclude the
  `SOURCE_MISSING` state, so an uninitialized submodule (e.g. cloned by someone without access
  to the private repo) makes dotbot warn-and-fail on that one directive, which surfaces as an
  **uncaught `RuntimeError`** crashing `./dot install`/`./dot sync` entirely, not a clean skip.
- `managed.py`'s `pull()` (`managed.py:59`) will happily `mkdir -p` and write into a
  not-yet-initialized submodule directory, which can conflict with `git submodule update --init`
  populating it later.

Changes:
1. Add `ensure_submodules(repo: Path)` to `setup/dotfiles/gitrepo.py` running
   `git -C <repo> submodule update --init --recursive`, treating a non-zero exit as a
   **warning, not a fatal error** (this repo is public — other people run `./bootstrap.sh`
   against it and won't have access to `dotfiles-private`; provisioning must still succeed for
   them, just skipping the two managed files).
2. Call `ensure_submodules(repo)` in `install_flow.run_install()` at the very top, before
   `linker.classified_entries(...)` (currently `install_flow.py:50-51`) — this precedes every
   consumer of submodule-backed paths (classification, dotbot linking, `managed.pull/push`).
3. Call it as the first line of `cli.cmd_sync()`, before `linker.sync_links(...)`.
4. Harden `linker.run_dotbot`'s skip-set to also exclude `State.SOURCE_MISSING`, matching how
   `EXISTS_SAME/EXISTS_DIFFERS/CONFLICT` are already excluded — turns a crash into the same
   graceful warning `diff()`/dry-run already produce for that state. Defense-in-depth alongside
   step 1 in case submodule init silently fails.

### Docs
- `README.md`: note near the clone instructions that the private submodule is owner-only and
  optional — cloning/provisioning works fine without access to it (the two managed files are
  simply skipped).
- New `docs/arc-sidebar-history-exposure.md`: record that `StorableSidebar.json` was publicly
  tracked from repo inception through commit `bf7abc1` up to the commit landing this change,
  that it contains real Arc tab/sync data with no rotatable credential, and the future remediation
  path (`git filter-repo --path ... --invert-paths` across all historical paths the file lived
  at, then force-push, then anyone with an existing clone must re-clone). Flagged as not-yet-done.

## Implementation steps

1. Write this plan to `docs/private-secrets-submodule-plan.md` and commit it before other changes.
2. `gh repo create Pencilvesterr/dotfiles-private --private --description "Private synced files for github.com/Pencilvesterr/dotfiles"`, with a minimal initial commit so it's cloneable.
3. `git submodule add https://github.com/Pencilvesterr/dotfiles-private.git private`.
4. Move `.env` and `StorableSidebar.json` into the submodule (mkdir the two subdirs, `git mv`/move, commit inside the submodule), then in the main repo: `git rm --cached config/arc/StorableSidebar.json`, remove the empty `config/arc/` dir, stage the new submodule gitlink.
5. Update `setup/managed.toml` (repo path) and `setup/dotbot/base.yaml` (new `.env` link entry).
6. Implement `ensure_submodules()` in `gitrepo.py`; wire it into `install_flow.run_install()` and `cli.cmd_sync()`.
7. Harden `linker.run_dotbot`'s skip-set to exclude `SOURCE_MISSING`.
8. Update `README.md` clone-instructions note.
9. Write `docs/arc-sidebar-history-exposure.md`.
10. Run `uv run pytest` and `uv run ruff check`.

## Verification

- `git submodule status` shows `private/` initialized and clean.
- `./dot diff` and `./dot sync --dry-run` show no CONFLICT/unexpected states.
- `./dot sync` on this machine (real run, not a test — this is Morgan's actual dev machine):
  confirm `~/.claude/hooks/.env` is now a symlink into `private/claude/hooks/.env`, `notify.sh`
  still fires a notification correctly, and (on the work Mac) Arc's `StorableSidebar.json`
  still round-trips via `./dot pull`.
- Simulate the "public consumer, no submodule access" path: in a scratch clone without running
  `git submodule update --init`, run `./dot install --dry-run` / `./dot sync --dry-run` and
  confirm it warns and continues rather than crashing (exercises the `SOURCE_MISSING` hardening
  and the non-fatal `ensure_submodules` behavior).
- `uv run pytest` passes (per repo convention, using temp HOME, never the real one, for any test
  that exercises `./dot`).

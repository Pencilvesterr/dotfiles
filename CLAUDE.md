# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Linux development environment configuration. Config files are **symlinked** into place by a Python CLI (`./dot`, run via uv) that uses [dotbot](https://github.com/anishathalye/dotbot) for the linking layer. Machine differences are handled by a **saved profile** (`personal-mac`, `work-mac`, `personal-linux`, `work-linux`) stored in `~/.config/dotfiles/profile.json`.

## Key Commands

```bash
# New machine: prerequisites (Xcode CLT/apt, Homebrew, uv) then full provisioning
./bootstrap.sh --profile personal-mac

# Full provisioning on an existing machine (apps, OS defaults, links, git housekeeping)
./dot install [--profile NAME] [--terminal-apps-only] [--adopt|--overwrite] [--skip-brew-install] [--dry-run]

# Frequent path: fast non-interactive sync of links + managed files (seconds)
./dot sync [--dry-run]

# Inspection / maintenance
./dot diff              # targets differing from repo; exit 2 = conflict
./dot adopt [TARGET..]  # copy machine versions into the repo, relink
./dot pull              # app-managed files: system -> repo
./dot apps              # brew bundles + non-brew tools for this profile
./dot defaults          # re-apply macOS defaults / Linux settings
./dot profile show|set NAME [--terminal-apps-only]

# Python dev (package lives in setup/dotfiles/)
uv run pytest
uv run ruff check
```

## Architecture

The repo has two top-level buckets: **`config/`** holds the app/tool config
*payload* (nvim, zsh, git, wezterm, …) that gets symlinked/copied onto a machine,
and **`setup/`** holds the *provisioning machinery* (the `dot` CLI package, dotbot
YAML layers, Brewfiles, and platform scripts) that installs and syncs it.

### The `dot` CLI

- `./dot` is a bash shim that runs `uv run python -m dotfiles` (package at `setup/dotfiles/`).
- `cli.py` — argparse subcommands. `install_flow.py` — full provisioning. `linker.py` — link
  enumeration/classification (OK, MISSING, WRONG_LINK, EXISTS_SAME, EXISTS_DIFFERS, CONFLICT),
  diff/adopt/heal, and the in-process dotbot dispatch. `managed.py` — copy-based sync for files
  apps overwrite. `gitrepo.py` — skip-worktree flags, `strip-work-tooling` filter,
  `core.hooksPath`. `packages.py` / `platform_setup.py` — brew bundles and the platform bash
  scripts. `hook.py` — pre-commit self-heal logic.
- A CONFLICT means a target differs from the repo AND the repo source has uncommitted changes;
  commands exit 2 and never auto-resolve it.

### Link definitions (dotbot YAML layers)

`setup/dotbot/` holds one YAML per layer, applied in order (later layers win for the same target):

- `base.yaml` — every machine
- `macos.yaml` / `linux.yaml` — by OS
- `work.yaml` / `personal.yaml` — by context (both map `~/.gitconfig`, to work/personal gitconfig respectively)

Format: `~/target/path: repo/relative/source` under a `link:` task. These YAMLs are the single
source of truth — dotbot creates the links, and `linker.py` reads the same files for
diff/adopt/heal and the pre-commit hook.

Files that third-party apps overwrite (htoprc, Arc sidebar) can't be symlinks; they're listed in
`setup/managed.toml` and copied by `managed.py` (optionally scoped by `context`/`os` keys).

### Work vs Personal / Mac vs Linux

Both axes come from the saved profile — there is no runtime detection. `--terminal-apps-only`
(persisted in the profile) marks servers: skips GUI apps and OS defaults, still links everything.

### Platform scripts (bash, called by the CLI)

- `setup/mac/osx-defaults.sh [all|keyboard|defaults|capslock]` — macOS `defaults write` calls
- `setup/linux/install_debian.sh [settings|cli-tools|apps]` — apt/Docker/zsh/fonts setup
- `bootstrap.sh` — virgin-machine prerequisites, then `exec ./dot install`

### Git hook

`config/git/hooks/` is the repo's `core.hooksPath`. `pre-commit` shims to `./dot hook pre-commit`,
which fixes broken links, adopts changed machine files (staged), pulls managed files (unstaged),
and aborts the commit on conflicts. It skips (never blocks) if no profile or uv is present.

## Adding New Dotfiles

1. Place the config file in the appropriate subdirectory under `config/`
2. Add `~/target/path: config/relative/source` to the right layer in `setup/dotbot/`
3. Run `./dot sync`

## Adding New Software

1. Add the package to the appropriate Brewfile:
   - `setup/homebrew/Brewfile.terminal` - CLI tools, all machines (including Linux via linuxbrew)
   - `setup/homebrew/Brewfile.mac` - macOS apps, all Macs
   - `setup/homebrew/Brewfile.mac_personal` - Personal Macs only
   - `setup/homebrew/Brewfile.mac_work` - Work Macs only
2. Install with: `./dot apps`

## Important Notes

- The `cd` command is aliased to use **zoxide** (use `/bin/cd` for the original command)
- Nord color palette is used throughout all themes; theme switching via env vars in `.zshenv`
- NeoVim config is based on LazyVim
- `config/zsh/local.zsh` is marked skip-worktree (machine-local, never committed)
- On work machines `config/git/global-config/work.gitconfig` is skip-worktree because work tooling
  appends sections to it; the `strip-work-tooling` clean filter is a safety net
- Never test `./dot` against the real `$HOME` — use a temp `HOME` (see `tests/`)

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Linux development environment configuration. Dotfiles are managed with **[chezmoi](https://www.chezmoi.io/)**, which deploys config files from this repo to their system locations and can pull changes back from the system into the repo.

## Key Commands

### Dotfile Management (chezmoi)

```bash
# Deploy repo → system (run after pulling changes)
chezmoi apply

# Pull system → repo (run before committing, e.g. after htop changes settings)
chezmoi re-add

# See what's out of sync
chezmoi status
chezmoi diff

# Full installation on a new machine
./install.sh
```

### Package Management

```bash
# Install packages from Brewfile
brew bundle install --file=homebrew/Brewfile
brew bundle install --file=homebrew/Brewfile.work
brew bundle install --file=homebrew/Brewfile.personal

# Check if Brewfile dependencies are satisfied
brew bundle check --file=homebrew/Brewfile
```

### Aerospace Window Management

```bash
# Move applications to designated workspaces
./aerospace/move-apps-to-workspace.sh
```

## Architecture

### chezmoi System

Dotfiles are deployed via chezmoi. The source directory IS this git repo (`~/dev/personal/dotfiles`). chezmoi is configured via `~/.config/chezmoi/chezmoi.toml`.

**Source file naming conventions:**
- Files/dirs starting with `.` → prefixed with `dot_` in source (e.g. `dot_zshrc` → `~/.zshrc`)
- Files needing execute permission → prefixed with `executable_`
- Files with restricted permissions → prefixed with `private_` (chezmoi adds this automatically on `re-add`)
- Templates (work/personal differences) → suffixed with `.tmpl`

**Key chezmoi files:**
- `.chezmoi.toml.tmpl` — generates `~/.config/chezmoi/chezmoi.toml` on `chezmoi init`; encodes work machine detection by hostname
- `.chezmoiroot` — tells chezmoi to use the `home/` subdirectory as its source root, keeping dotfiles separate from repo utilities
- `home/.chezmoiignore` — excludes work-only files on personal machines
- `home/.chezmoiscripts/run_once_install-git-hooks.sh` — installs the pre-commit hook on first `chezmoi apply`

**Pre-commit hook:** Automatically runs `chezmoi re-add` before every commit, so changes made by apps (like htop rewriting its config) are captured before committing.

### Directory Structure

```
├── .chezmoi.toml.tmpl         # Work detection template (repo root, not in home/)
├── .chezmoiroot               # Contains "home" — tells chezmoi to use home/ as source root
│
├── home/                      # chezmoi source root (all managed dotfiles live here)
│   ├── .chezmoiignore
│   ├── .chezmoiscripts/
│   ├── dot_zshenv             # → ~/.zshenv
│   ├── dot_vimrc              # → ~/.vimrc
│   ├── dot_ideavimrc          # → ~/.ideavimrc
│   ├── dot_gitconfig.tmpl     # → ~/.gitconfig (templated: work vs personal email)
│   ├── dot_config/
│   │   ├── zsh/               # Zsh config (modular files)
│   │   │   ├── dot_zshrc      # → ~/.config/zsh/.zshrc
│   │   │   ├── dot_zprofile.tmpl  # → ~/.config/zsh/.zprofile (templated)
│   │   │   ├── work.zsh       # → ~/.config/zsh/work.zsh (work machines only)
│   │   │   └── ...
│   │   ├── nvim/              # NeoVim config (LazyVim-based)
│   │   ├── wezterm/           # WezTerm terminal config
│   │   ├── starship/          # Starship prompt config
│   │   ├── aerospace/         # Aerospace window manager config
│   │   ├── ranger/            # Ranger file manager config
│   │   ├── htop/              # htop config
│   │   ├── difftastic/        # Git diff tool config
│   │   └── lazygit/           # LazyGit config
│   ├── dot_claude/            # Claude Code settings
│   └── Library/
│       └── Application Support/  # macOS app configs (VS Code, Arc)
│
├── homebrew/                  # Brewfiles (NOT chezmoi-managed)
│   ├── Brewfile               # Shared packages
│   ├── Brewfile.personal      # Personal-only packages
│   └── Brewfile.work          # Work-only packages
├── scripts/                   # Utility scripts (NOT chezmoi-managed)
├── aerospace/                 # Workspace setup script (NOT chezmoi-managed)
└── linux/                     # Linux-specific install scripts
```

### Work vs Personal Configuration

Work machine detection is **hostname-based**, configured in `.chezmoi.toml.tmpl`. The `isWork` template variable controls:

- **`.gitconfig`** — work email (`mcrouch@atlassian.com`) vs personal
- **`.zprofile`** — JetBrains Toolbox PATH, brew shellenv, Python PATH (work only)
- **`work.zsh`** — Atlassian tools, NVM, jenv lazy-loading (excluded on personal via `.chezmoiignore`)
- **Arc sidebar** — work browser config (excluded on personal via `.chezmoiignore`)

To add a new work machine: update `$workHostnames` in `.chezmoi.toml.tmpl` AND `WORK_HOSTNAMES` in `install.sh`.

### Zsh Configuration Structure

Zsh config is split into modular files sourced from `.zshrc`:

- `dot_zshrc` — main entry point
- `dot_zshenv` — environment variables (must live at `~/.zshenv`, sets `ZDOTDIR`)
- `dot_zprofile.tmpl` — login shell setup (templated for work/personal)
- `custom.zsh` — core config (Homebrew, antidote plugins, vi mode)
- `plugin_settings.zsh` — fzf, fzf-tab settings
- `functions.zsh` — custom functions
- `aliases.zsh` — aliases and git functions
- `work.zsh` — work-specific PATH, NVM, jenv (work machines only)
- `dot_zsh_plugins.txt` — antidote plugin list

## Adding New Dotfiles

1. Place the config file in the appropriate `home/dot_config/` subdirectory (following chezmoi naming conventions)
2. Run `chezmoi add ~/.config/tool/file` to register it, or name it manually:
   - Dotfiles: prefix with `dot_` (`.zshrc` → `dot_zshrc`)
   - Executables: prefix with `executable_`
   - Private (0600): prefix with `private_` (chezmoi adds this automatically on `re-add`)
3. If work-only, add an exclusion to `home/.chezmoiignore` under the `{{ if not .isWork }}` block
4. Run `chezmoi apply` to deploy

## Adding New Software

1. Add the package to the appropriate Brewfile:
   - `homebrew/Brewfile` — shared across all machines
   - `homebrew/Brewfile.personal` — personal machines only
   - `homebrew/Brewfile.work` — work machines only

2. Install with: `brew bundle install --file=homebrew/Brewfile`

## Important Notes

- The `cd` command is aliased to use **zoxide** (use `/bin/cd` for the original command)
- Nord color palette is used throughout all themes
- Theme switching via environment variables in `dot_zshenv`
- NeoVim config is based on LazyVim
- Git config is templated — personal email by default, work email on work machines

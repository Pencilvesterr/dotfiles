# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Linux development environment configuration. The repository uses **hardlinks** (not symlinks) to install configuration files to their target locations, managed through configuration files.

## Key Commands

### Installation and Setup

```bash
# Full installation (prompts for options)
./install.sh

# Create hardlinks from dotfiles to system locations
./scripts/links.sh --create

# Create work-specific hardlinks
./scripts/links.sh --create --work-conf

# Delete hardlinks
./scripts/links.sh --delete

# Delete hardlinks including files (use when overwriting)
./scripts/links.sh --delete --include-files

# Delete work-specific hardlinks
./scripts/links.sh --delete --include-files --work-conf
```

### Package Management

```bash
# Install packages from Brewfile
./scripts/brew-install-custom.sh

# Or install a specific Brewfile
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

### Hardlink System

The core installation mechanism uses **hardlinks** and **softlinks** (symlinks) via `scripts/links.sh`:

- Configuration:
  - `hardlinks_config.conf` - for file hardlinks (main config)
  - `softlinks_config.conf` - for symlinks (supports directories)
  - `hardlinks_config_work.conf` - work-specific hardlinks
- Format: `source_path:target_path` (one per line, comments start with `#`)
- The script expands variables like `$(pwd)` and `$HOME`
- Creates parent directories if needed
- Detects existing hardlinks by checking if files share the same inode
- Softlinks can be used for directories (hardlinks cannot)

### Directory Structure

```
├── zsh/               # Zsh configuration (split into modular files)
├── nvim/              # NeoVim configuration (LazyVim-based)
├── vim/               # Fallback Vim configuration
├── wezterm/           # WezTerm terminal configuration
├── starship/          # Starship prompt configuration
├── aerospace/         # Aerospace window manager configuration
├── git/               # Git configurations (difftastic, delta, lazygit)
│   └── global-config/ # Contains personal.gitconfig (default) and work.gitconfig
├── ranger/            # Ranger file manager configuration
├── vscode/            # VS Code settings
├── idea/              # IntelliJ IDEA vim plugin configuration
├── homebrew/          # Homebrew package definitions
│   ├── Brewfile           # Shared packages
│   ├── Brewfile.personal  # Personal-only packages
│   ├── Brewfile.work      # Work-only packages
│   ├── custom-casks/      # Custom version casks
│   └── custom-formulae/   # Custom version formulae
├── scripts/           # Installation and utility scripts
└── linux/             # Linux-specific installation scripts
```

### Work vs Personal Configuration

The repository supports dual configurations:

- **Default**: Personal configuration (e.g., `git/global-config/personal.gitconfig`)
- **Work Override**: Activated by answering "y" to "Work machine?" during `./install.sh`
  - Uses `hardlinks_config_work.conf` to override specific files
  - Example: `zsh/work.zsh` contains machine-specific PATH configurations for Atlassian tools, nvm, jenv

### Zsh Configuration Structure

Zsh config is split into modular files for maintainability:

- `.zshrc` - Main entry point
- `.zshenv` - Environment variables
- `custom.zsh` - Custom configurations
- `plugin_settings.zsh` - Plugin-specific settings
- `functions.zsh` - Custom functions
- `aliases.zsh` - Command aliases
- `work.zsh` - Work-specific settings (PATH, lazy-loaded pyenv/nvm/jenv)
- `.zsh_plugins.txt` - Plugin list (likely for antidote or similar)

## Adding New Dotfiles

1. Place the config file in the appropriate subdirectory
2. Add an entry to the appropriate config file:
   - For files: use `hardlinks_config.conf`
   - For directories: use `softlinks_config.conf`
   - For work-specific: use `hardlinks_config_work.conf`

   Format:
   ```
   $(pwd)/path/to/source:$HOME/path/to/target
   ```
3. Run `./scripts/links.sh --create`

## Adding New Software

1. Add the package to the appropriate Brewfile:
   - `homebrew/Brewfile` - Shared across personal and work
   - `homebrew/Brewfile.personal` - Personal machines only
   - `homebrew/Brewfile.work` - Work machines only

2. Install with: `./scripts/brew-install-custom.sh` or `brew bundle install --file=homebrew/Brewfile`

3. For specific package versions:
   - Find the Ruby formula/cask in Homebrew's commit history
   - Place in `homebrew/custom-casks/` or `homebrew/custom-formulae/`

## Important Notes

- The repository uses **hardlinks**, not symlinks
- The `cd` command is aliased to use **zoxide** (use `/bin/cd` for the original command)
- Nord color palette is used throughout all themes
- Theme switching via environment variables in `.zshenv`
- NeoVim config is based on LazyVim
- Git config defaults to `personal.gitconfig` unless overridden by work hardlinks

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for macOS and Linux development environment configuration. The repository uses **symlinks** to install configuration files to their target locations, managed through configuration files.

## Key Commands

### Installation and Setup

```bash
# Full installation (prompts for options)
./install.sh

# Create symlinks from a config file
./scripts/links.sh --create softlinks_config.conf

# Create work-specific symlinks
./scripts/links.sh --create softlinks_config_work.conf

# Delete symlinks
./scripts/links.sh --delete softlinks_config.conf

# Delete symlinks including target files (use when overwriting)
./scripts/links.sh --delete --include-files softlinks_config.conf
```

### Package Management

```bash
# Install packages from Brewfile
./scripts/brew-install-custom.sh

# Or install a specific Brewfile
brew bundle install --file=homebrew/Brewfile.terminal
brew bundle install --file=homebrew/Brewfile.mac_work
brew bundle install --file=homebrew/Brewfile.mac_personal

# Check if Brewfile dependencies are satisfied
brew bundle check --file=homebrew/Brewfile.terminal
```

### Aerospace Window Management

```bash
# Move applications to designated workspaces
./aerospace/move-apps-to-workspace.sh
```

## Architecture

### Symlink System

The core installation mechanism uses **symlinks** via `scripts/links.sh`:

- Configuration:
  - `softlinks_config.conf` - main symlink config (cross-platform)
  - `softlinks_config_mac.conf` - macOS-only symlinks (VS Code, Aerospace)
  - `softlinks_config_work.conf` - work-specific symlinks
- Format: `source_path:target_path` (one per line, comments start with `#`)
- The script expands variables like `$(pwd)` and `$HOME`
- Creates parent directories if needed
- Existing symlinks pointing elsewhere are automatically updated

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
│   ├── Brewfile.terminal  # CLI tools
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
  - Uses `softlinks_config_work.conf` to override specific files
  - Example: `zsh/work.zsh` contains machine-specific PATH configurations for Atlassian tools, nvm, jenv

### Zsh Configuration Structure

Zsh config is split into modular files for maintainability:

- `.zshrc` - Main entry point
- `.zshenv` - Environment variables
- `custom.zsh` - Custom configurations
- `plugin_settings.zsh` - Plugin-specific settings
- `aliases.zsh` - Command aliases
- `work.zsh` - Work-specific settings (PATH, lazy-loaded pyenv/nvm/jenv)
- `.zsh_plugins.txt` - Plugin list (likely for antidote or similar)

## Adding New Dotfiles

1. Place the config file in the appropriate subdirectory
2. Add an entry to the appropriate config file:
   - `softlinks_config.conf` - shared across personal and work (cross-platform)
   - `softlinks_config_mac.conf` - macOS-only configs
   - `softlinks_config_work.conf` - work-specific overrides

   Format:
   ```
   $(pwd)/path/to/source:$HOME/path/to/target
   ```
3. Run `./scripts/links.sh --create softlinks_config.conf`

## Adding New Software

1. Add the package to the appropriate Brewfile:
   - `homebrew/Brewfile.terminal` - Shared across personal and work
   - `homebrew/Brewfile.personal` - Personal machines only
   - `homebrew/Brewfile.work` - Work machines only

2. Install with: `./scripts/brew-install-custom.sh` or `brew bundle install --file=homebrew/Brewfile.terminal`

3. For specific package versions:
   - Find the Ruby formula/cask in Homebrew's commit history
   - Place in `homebrew/custom-casks/` or `homebrew/custom-formulae/`

## Important Notes

- The repository uses **symlinks** to link config files
- The `cd` command is aliased to use **zoxide** (use `/bin/cd` for the original command)
- Nord color palette is used throughout all themes
- Theme switching via environment variables in `.zshenv`
- NeoVim config is based on LazyVim
- Git config defaults to `personal.gitconfig` unless overridden by `softlinks_config_work.conf`

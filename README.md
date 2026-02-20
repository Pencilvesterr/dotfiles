# Dotfiles

This repository contains my dotfiles, which are the config files and scripts I use to customize my development environment. These files help me maintain a consistent setup across different machines and save time when setting up new environments.

![screenshot](img/nvim-demo.png)

## Essential Tools

- **Editor**: [NeoVim](https://neovim.io/). As a fallback, I have a basic standard [Vim](https://www.vim.org/) config that provides 80% of the functionality of my NeoVim setup with minimal dependencies for maximum portability and stability.
- **Main Terminal**: [WezTerm](https://wezfurlong.org/wezterm/index.html)
- **Shell Prompt**: [Starship](https://starship.rs/)
- **Color Theme**: All themes are based on the [Nord color palette](https://www.nordtheme.com/docs/colors-and-palettes). Themes can be easily switched via environment variables set in `.zshenv`.
- **Window Management**: [Aerospace](https://github.com/nikitabobko/AeroSpace) for windows tiling manager.
- **File Manager**: [Ranger](https://github.com/ranger/ranger)

## Custom Window Management

I'm not a fan of the default window management solutions that macOS provides, like repeatedly pressing Cmd+Tab to switch apps or using the mouse to click and drag. To streamline my workflow, I created a custom window management solution using [Aerospace](https://github.com/nikitabobko/AeroSpace). I can efficiently manage my windows and switch apps with minimal mental overhead and maximum speed, using only my keyboard. Checkout `dot_config/aerospace/aerospace.toml`.

## Setup

Dotfiles are managed with [chezmoi](https://www.chezmoi.io/). To set up on a new machine:

```bash
# Clone the repo
git clone https://github.com/mcrouch/dotfiles ~/dev/personal/dotfiles

# Run the installer
cd ~/dev/personal/dotfiles && ./install.sh
```

Then follow the on-screen prompts. The installer handles Homebrew, apps, macOS defaults, and applies all dotfiles via chezmoi.

## Daily Workflow

```bash
# After an app modifies its config (e.g. htop, Arc)
chezmoi re-add

# After pulling changes from another machine
chezmoi apply

# See what's out of sync between repo and system
chezmoi status
chezmoi diff
```

The pre-commit hook automatically runs `chezmoi re-add` before every commit, so changes made by apps are always captured.

## Adding New Dotfiles

1. Place the config file in the appropriate subdirectory (e.g. `dot_config/htop/`)
2. Run `chezmoi add ~/.config/htop/htoprc` to register it with chezmoi, or manually name it following chezmoi conventions:
   - Files starting with `.` → prefix with `dot_` (e.g. `.zshrc` → `dot_zshrc`)
   - Files needing execute permission → prefix with `executable_`
   - Files with restricted permissions → prefix with `private_`
   - Directories follow the same rules
3. Add an entry to `.chezmoiignore` if the file should be excluded on certain machines (e.g. work-only)
4. Run `chezmoi apply` to deploy

## Work vs Personal Machines

Work machine detection is hostname-based, configured in `.chezmoi.toml.tmpl`. Work machines get:
- Work email in `.gitconfig`
- Work-specific `.zprofile` (JetBrains Toolbox, Python PATH)
- `work.zsh` (Atlassian tools, NVM, jenv lazy-loading)
- Work Arc browser sidebar

To add a new work machine hostname, update the `$workHostnames` list in `.chezmoi.toml.tmpl` and the `WORK_HOSTNAMES` array in `install.sh`.

## Adding New Software

Software is installed via Homebrew. Add a formula or cask to the appropriate Brewfile:

- `homebrew/Brewfile` — shared across all machines
- `homebrew/Brewfile.personal` — personal machines only
- `homebrew/Brewfile.work` — work machines only

Then install with:

```bash
brew bundle install --file=homebrew/Brewfile
```

# TODO:
- Export current vs code settings and then update sysmlinks_config.confg to install it
- Setup NeoVim as my default editor
- Copy relevant info from .vimrc_original_repo to my own .vimrc
- thefuck has been deprecated. Look into (pay-respects)[https://github.com/iffse/pay-respects/] as a replacement 
- Import the extensions and key bindings used in cursor to my VSCODE director

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

I'm not a fan of the default window management solutions that macOS provides, like repeatedly pressing Cmd+Tab to switch apps or using the mouse to click and drag. To streamline my workflow, I created a custom window management solution using [Aerospace](https://github.com/nikitabobko/AeroSpace). I can efficiently manage my windows and switch apps with minimal mental overhead and maximum speed, using only my keyboard. Checkout `aerospace.toml`. It's close to the deault settings with some minor variations. 

## Setup

To set up these dotfiles on your system, run:

```bash
./install.sh
```

Then follow the on-screen prompts.

## Uninstalling

If you ever want to remove the symlinks created by the installation script, you can use the provided symlinks removal script:

To delete all symlinks created by the installation script, run:

```bash
./scripts/symlinks.sh --delete
```

This will remove the symlinks but will not delete the actual configuration files, allowing you to easily revert to your previous configuration if needed.

## Adding New Dotfiles and Software

### Dotfiles

When adding new dotfiles to this repository, follow these steps:

1. Place your dotfile in the appropriate location within the repository.
2. Update the `symlinks_config.conf` file to include the symlink creation for your new dotfile.
3. If necessary, update the `install.sh` script to set up the software.

### Software Installation

Software is installed using Homebrew. To add a formula or cask, update the `homebrew/Brewfile` and run `./scripts/brew_install_custom.sh`. If you need to install a specific version of a package, find its Ruby script in the commit history of an official Homebrew GitHub repository and place it in the `homebrew/custom-casks/` or `homebrew/custom-formulae/` directory, depending on whether it's a cask or formula.

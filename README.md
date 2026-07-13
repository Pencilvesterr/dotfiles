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

### New machine

```bash
# macOS (running `git clone` prompts to install the Xcode CLI tools first)
git clone https://github.com/Pencilvesterr/dotfiles.git && cd dotfiles
./bootstrap.sh --profile personal-mac        # or work-mac

# Ubuntu
sudo apt install -y git
git clone https://github.com/Pencilvesterr/dotfiles.git && cd dotfiles
./bootstrap.sh --profile personal-linux --terminal-apps-only   # servers: --terminal-apps-only skips GUI apps / OS defaults
```

`bootstrap.sh` installs the prerequisites (Xcode CLT or apt packages, Homebrew, uv) and hands
off to `./dot install`, which does the actual provisioning. Without `--profile` it asks
interactively; the answer is saved to `~/.config/dotfiles/profile.json` and reused from then on.

Sensitive and app-owned files stay local. Agent notification credentials live at
`~/.config/agent-notify/.env` (see `config/agent-notify/.env.sample`), and Arc owns its live
sidebar data. Neither file is linked to or synchronized with this repository.

### Day-to-day: syncing config changes

This is the frequent path — after pulling dotfile changes (or editing them locally), run:

```bash
./dot sync
```

Non-interactive and takes seconds: pulls changed app-managed files into the repo for review,
repairs/creates all symlinks, and refreshes the repo's git housekeeping. It never deletes real
files. If both copies of a managed file changed, sync stops without changing anything; after
reviewing, use `./dot pull` to keep the machine version or
`./dot sync --overwrite-managed-with-repo-version` to keep the repo version.

### Other commands

```bash
./dot diff              # show targets that differ from the repo (exit 2 on conflict)
./dot adopt [TARGET..]  # copy machine versions of differing files into the repo, then relink
./dot pull              # copy app-managed files (htoprc, Arc sidebar) system -> repo
./dot sync --overwrite-managed-with-repo-version
                        # explicitly replace managed machine files from the repo
./dot apps              # (re)install Homebrew bundles + non-brew tools for this profile
./dot defaults          # re-apply macOS defaults / Linux settings
./dot profile show|set  # inspect or change this machine's profile
./dot install --help    # full provisioning flags (--adopt/--overwrite/--skip-brew-install/--dry-run)
```

`./dot install --overwrite` never deletes files outright — anything replaced is backed up to
`~/.config/dotfiles/backup/<timestamp>/` first.

## Uninstalling

The symlinks all point into this repo; remove any you no longer want and put a real file in
place (`./dot diff` will tell you what differs). There is no bulk-delete command — deleting the
repo leaves broken symlinks you can remove as you encounter them.

## Adding New Dotfiles and Software

### Dotfiles

1. Place your dotfile in the appropriate location under `config/`.
2. Add a `target: source` line to the right layer in `setup/dotbot/`:
   - `base.yaml` — every machine
   - `macos.yaml` / `linux.yaml` — OS-specific
   - `work.yaml` / `personal.yaml` — context-specific
3. Run `./dot sync`.

Files that third-party apps overwrite (so they can't be symlinks) go in `setup/managed.toml`
instead. `./dot sync` pulls machine changes into the repo; use
`./dot sync --overwrite-managed-with-repo-version` when the repo version should win.

### Software Installation

Software is installed using Homebrew. To add a formula or cask, update the appropriate Brewfile in `setup/homebrew/` (`Brewfile.terminal` for CLI tools on all machines, `Brewfile.mac` for macOS apps, `Brewfile.mac_personal` / `Brewfile.mac_work` for machine-specific apps) and run `./dot apps`.

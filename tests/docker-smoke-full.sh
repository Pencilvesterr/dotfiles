#!/bin/bash
# Smoke test: exercises the FULL Linux install path, including Homebrew
# itself and all Linux-specific apps (Docker, Wezterm, Nerd Fonts, ...) in a
# clean Ubuntu container. Runs in CI (.github/workflows/linux-smoke-full.yml)
# on pushes/PRs that touch Linux-install-relevant paths; also runnable
# manually anytime.
#
# This is the slow, thorough sibling of docker-smoke.sh: that one passes
# --terminal-apps-only --skip-brew-install to stay fast and only checks links/hooks/managed files.
# This one runs ./bootstrap.sh with no flags stripped, so it actually installs
# Homebrew, runs `brew bundle install` against Brewfile.terminal, and installs
# the Linux CLI tools/apps. Expect 15-35 minutes depending on bottle
# availability and network speed.
#
# The working tree (including uncommitted changes) is copied inside the container,
# so nothing touches your working copy.
#
# Two container-only incompatibilities are neutralized with no-op shims, since
# they're unrelated to whether Homebrew/apt installation works:
#   - `systemctl enable docker/containerd` needs a real systemd PID 1.
#   - `dconf write` (caps/esc swap) needs a D-Bus session.
#
# Usage: ./tests/docker-smoke-full.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker run --rm -v "$REPO_DIR:/src:ro" ubuntu:24.04 bash -euo pipefail -c '
    export DEBIAN_FRONTEND=noninteractive
    export USER=root
    export NO_COLOR=1

    apt-get update -q >/dev/null
    apt-get install -yq git curl ca-certificates rsync sudo build-essential procps file wget unzip fontconfig gnupg >/dev/null
    mkdir -p /etc/apt/keyrings

    rsync -a --exclude .venv /src/ /dotfiles/
    cd /dotfiles
    git config --global --add safe.directory /dotfiles

    echo "==> Stubbing systemctl/dconf (no systemd or D-Bus in this container)..."
    printf "#!/bin/sh\nexit 0\n" > /usr/local/sbin/systemctl
    printf "#!/bin/sh\nexit 0\n" > /usr/local/sbin/dconf
    chmod +x /usr/local/sbin/systemctl /usr/local/sbin/dconf

    echo "==> Running bootstrap.sh (installs Homebrew + full dot install)..."
    ./bootstrap.sh --profile personal-linux --adopt

    BREW=/home/linuxbrew/.linuxbrew/bin/brew
    eval "$("$BREW" shellenv)"
    export PATH="$HOME/.local/bin:$PATH"

    echo "==> Asserting results..."
    [ "$(readlink "$HOME/.zshenv")" = "/dotfiles/config/zsh/.zshenv" ]
    [ "$(readlink "$HOME/.gitconfig")" = "/dotfiles/config/git/global-config/personal.gitconfig" ]
    [ -f "$HOME/.hushlogin" ]
    [ -f "$HOME/.config/htop/htoprc" ]
    [ "$(git config core.hooksPath)" = "/dotfiles/config/git/hooks" ]
    git ls-files -v | grep -q "^S config/zsh/local.zsh"

    echo "==> Asserting brew packages installed..."
    [ -x "$BREW" ]
    command -v bat
    command -v eza
    command -v starship
    command -v fzf

    echo "==> Asserting Linux apps installed..."
    command -v claude
    command -v docker
    command -v wezterm
    [ -n "$(ls -A "$HOME/.local/share/fonts/JetBrainsMonoNerd")" ]

    echo "==> Second sync must be a clean no-op..."
    ./dot sync
    ./dot diff

    echo "==> Pre-commit hook must pass..."
    ./dot hook pre-commit

    echo "SMOKE TEST PASSED"
'

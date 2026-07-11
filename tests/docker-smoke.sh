#!/bin/bash
# Manual smoke test: exercises the Linux install path (uv -> dot install -> links,
# hooks, managed files) in a clean Ubuntu container. Not run in CI.
#
# The working tree (including uncommitted changes) is copied inside the container,
# so nothing touches your working copy.
# The Homebrew half of bootstrap.sh is skipped (slow); this validates the Python path.
#
# Usage: ./tests/docker-smoke.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker run --rm -v "$REPO_DIR:/src:ro" ubuntu:24.04 bash -euo pipefail -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -q >/dev/null
    apt-get install -yq git curl ca-certificates rsync >/dev/null

    rsync -a --exclude .venv /src/ /dotfiles/
    cd /dotfiles
    git config --global --add safe.directory /dotfiles

    echo "==> Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1
    export PATH="$HOME/.local/bin:$PATH"

    echo "==> Running dot install (minimal, no apps)..."
    ./dot install --profile personal-linux --minimal --skip-apps --adopt

    echo "==> Asserting results..."
    [ "$(readlink "$HOME/.zshenv")" = "/dotfiles/zsh/.zshenv" ]
    [ "$(readlink "$HOME/.gitconfig")" = "/dotfiles/git/global-config/personal.gitconfig" ]
    [ -f "$HOME/.hushlogin" ]
    [ -f "$HOME/.config/htop/htoprc" ]
    [ "$(git config core.hooksPath)" = "/dotfiles/git/hooks" ]
    git ls-files -v | grep -q "^S zsh/local.zsh"

    echo "==> Second sync must be a clean no-op..."
    ./dot sync
    ./dot diff

    echo "==> Pre-commit hook must pass..."
    ./dot hook pre-commit

    echo "SMOKE TEST PASSED"
'

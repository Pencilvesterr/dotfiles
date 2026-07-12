#!/bin/bash
# Bootstrap a brand-new machine: installs the prerequisites (Xcode CLT / apt
# packages, Homebrew, uv) and then hands off to `./dot install`.
#
# Usage: ./bootstrap.sh [install flags, e.g. --profile personal-linux --terminal-apps-only]
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf '\033[34m==> %s\033[0m\n' "$1"; }

if [[ "$OSTYPE" == "darwin"* ]]; then
    info "Checking Apple's CLI tools (prerequisite for Git and Homebrew)..."
    if ! xcode-select -p >/dev/null 2>&1; then
        xcode-select --install
        info "Waiting for Xcode CLI tools installation to finish..."
        until xcode-select -p >/dev/null 2>&1; do sleep 5; done
        sudo xcodebuild -license accept
    fi
else
    info "Installing Linux prerequisites for Homebrew..."
    sudo apt-get update
    sudo apt-get install -y build-essential procps curl file git
    info "Pre-creating Homebrew prefix so the installer doesn't need sudo..."
    sudo mkdir -p /home/linuxbrew/.linuxbrew
    sudo chown -R "$USER:$(id -gn)" /home/linuxbrew
fi

if ! command -v brew >/dev/null 2>&1; then
    info "Installing Homebrew..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo --validate
    fi
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for this session (Apple Silicon, Intel mac, or linuxbrew)
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [ -x "$brew_bin" ]; then
        eval "$("$brew_bin" shellenv)"
        break
    fi
done

if ! command -v uv >/dev/null 2>&1; then
    info "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

info "Prerequisites ready. Handing off to ./dot install..."
exec "$REPO_DIR/dot" install "$@"

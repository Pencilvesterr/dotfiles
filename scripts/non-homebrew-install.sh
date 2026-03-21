#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR"/utils.sh

install_non_homebrew() {
    info "Installing non-Homebrew tools..."
    if command -v claude &>/dev/null; then
        warning "Claude CLI already installed"
    else
        info "Installing Claude CLI..."
        curl -fsSL https://claude.ai/install.sh | bash
    fi
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    install_non_homebrew
fi
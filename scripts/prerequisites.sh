#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR"/utils.sh

install_xcode() {
    info "Installing Apple's CLI tools (prerequisites for Git and Homebrew)..."
    if xcode-select -p >/dev/null; then
        warning "xcode is already installed"
    else
        xcode-select --install
        sudo xcodebuild -license accept
    fi
}

install_linux_prerequisites() {
    info "Installing Linux prerequisites for Homebrew..."
    sudo apt-get update
    sudo apt-get install -y build-essential procps curl file git
}

install_homebrew() {
    info "Installing Homebrew..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export HOMEBREW_CASK_OPTS="--appdir=/Applications"
    fi
    if hash brew &>/dev/null; then
        warning "Homebrew already installed"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sudo --validate
        fi
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # Ensure brew is on PATH for the rest of this script session
    if [[ "$OSTYPE" == "darwin"* ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
}

if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    install_xcode
    install_homebrew
fi

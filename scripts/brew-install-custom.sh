#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR"/utils.sh

install_brewfile() {
    local brewfile="${1}"
    if [ -f "$brewfile" ]; then
        info "Checking Brewfile dependencies..."

        # brew bundle check returns exit code 0 if satisfied, non-zero if not
        if brew bundle check --file="$brewfile"; then
            warning "The Brewfile's dependencies are already satisfied."
        else
            info "Satisfying missing dependencies with 'brew bundle install'..."
            brew bundle install --file="$brewfile"
            info "Finished installing brew bundle."
        fi
    else
        error "Brewfile not found"
        return 1
    fi
}

# When run directly (not sourced by install.sh), install the given Brewfiles,
# or the platform-appropriate defaults if none are given.
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    if [ $# -gt 0 ]; then
        for brewfile in "$@"; do
            install_brewfile "$brewfile"
        done
    else
        REPO_DIR="$(dirname "$SCRIPT_DIR")"
        install_brewfile "$REPO_DIR/homebrew/Brewfile.terminal"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_brewfile "$REPO_DIR/homebrew/Brewfile.mac"
            if detect_work_machine; then
                install_brewfile "$REPO_DIR/homebrew/Brewfile.mac_work"
            else
                install_brewfile "$REPO_DIR/homebrew/Brewfile.mac_personal"
            fi
        fi
    fi
fi
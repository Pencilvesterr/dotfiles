#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR"/utils.sh

install_brewfile() {
    local brewfile="${1:-$SCRIPT_DIR/../homebrew/Brewfile}"
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
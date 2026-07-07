#!/bin/bash

if [[ -z "${NO_COLOR:-}" ]]; then
    default_color=$(tput sgr 0)
    red="$(tput setaf 1)"
    yellow="$(tput setaf 3)"
    green="$(tput setaf 2)"
    blue="$(tput setaf 4)"
else
    default_color="" red="" yellow="" green="" blue=""
fi

info() {
    printf "%s==> %s%s\n" "$blue" "$1" "$default_color"
}

success() {
    printf "%s==> %s%s\n" "$green" "$1" "$default_color"
}

error() {
    printf "%s==> %s%s\n" "$red" "$1" "$default_color"
}

warning() {
    printf "%s==> %s%s\n" "$yellow" "$1" "$default_color"
}

# Detect if the current machine is a work machine.
# Returns 0 if the 'atlas' CLI (work tooling) is installed, 1 otherwise.
# Usage: if detect_work_machine; then ...; fi
detect_work_machine() {
    if command -v atlas &> /dev/null; then
        info "Work machine detected"
        return 0
    fi
    return 1
}

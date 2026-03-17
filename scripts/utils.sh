#!/bin/bash

default_color=$(tput sgr 0)
red="$(tput setaf 1)"
yellow="$(tput setaf 3)"
green="$(tput setaf 2)"
blue="$(tput setaf 4)"

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
# Reads WORK_HOSTNAMES from REPO_DIR/.env (space-separated list).
# Returns 0 if work machine, 1 if not. Exits 1 if WORK_HOSTNAMES is unset.
# Usage: if detect_work_machine; then ...; fi
detect_work_machine() {
    local repo_dir="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    if [ -f "$repo_dir/.env" ]; then
        . "$repo_dir/.env"
    fi
    if [ -z "${WORK_HOSTNAMES:-}" ]; then
        error "WORK_HOSTNAMES is not set. Define it as a space-separated list in $repo_dir/.env"
        exit 1
    fi
    local _wh
    read -ra _work_hostnames <<< "$WORK_HOSTNAMES"
    for _wh in "${_work_hostnames[@]}"; do
        if [ "$(hostname -s)" == "$_wh" ]; then
            info "Work machine detected: $(hostname -s)"
            return 0
        fi
    done
    return 1
}

#!/bin/bash
# Syncs files managed by third-party apps that overwrite symlinks.
#
# Usage:
#   ./scripts/sync.sh pull [config_file...]   # app -> repo
#   ./scripts/sync.sh push [config_file...]   # repo -> app
#
# Config format (same as softlinks_config.conf):
#   $(pwd)/repo/path:$HOME/system/path
#
# Entries can be files or directories. Lines starting with # are ignored.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

. "$SCRIPT_DIR/utils.sh"

info "Starting sync script..."
# cd to repo root so $(pwd) in config files resolves correctly
cd "$REPO_DIR" || exit 1

# Detect work machine using the same mechanism as install.sh
if [ -f "$REPO_DIR/.env" ]; then
    . "$REPO_DIR/.env"
fi
read -ra WORK_HOSTNAMES <<< "${WORK_HOSTNAMES:-}"
is_work_machine="n"
for wh in "${WORK_HOSTNAMES[@]}"; do
    if [ "$(hostname -s)" == "$wh" ]; then
        is_work_machine="y"
        info "Work machine detected: $(hostname -s)"
        break
    fi
done

DEFAULT_CONFIGS=("$REPO_DIR/sync_config.conf")
if [ "$is_work_machine" == "y" ]; then
    DEFAULT_CONFIGS+=("$REPO_DIR/sync_config_work.conf")
fi

usage() {
    echo "Usage: $(basename "$0") [pull|push] [config_file...]"
    echo ""
    echo "  pull    Copy files from their system locations into the repo"
    echo "  push    Copy files from the repo to their system locations"
    echo ""
    echo "  config_file   One or more config files (default: sync_config.conf,"
    echo "                plus sync_config_work.conf on work machines via .env)"
    echo "                Config format: \$(pwd)/repo/path:\$HOME/system/path"
}

sync_config() {
    local direction="$1"
    local config_file="$2"

    if [ ! -f "$config_file" ]; then
        warning "Config file not found: $config_file (skipping)"
        return
    fi

    info "Syncing from $(basename "$config_file") ($direction)..."

    while IFS=: read -r source target || [ -n "$source" ]; do
        [[ -z "$source" || -z "$target" || "$source" == \#* ]] && continue

        source=$(eval echo "$source")
        target=$(eval echo "$target")

        if [ "$direction" == "pull" ]; then
            from="$target"
            to="$source"
        else
            from="$source"
            to="$target"
        fi

        if [ ! -e "$from" ]; then
            error "Not found: $from"
            continue
        fi

        to_dir=$(dirname "$to")
        if [ ! -d "$to_dir" ]; then
            mkdir -p "$to_dir"
            info "Created directory: $to_dir"
        fi

        cp -r "$from" "$to"
        success "$direction: $from -> $to"

    done < "$config_file"
}

direction="${1:-}"
shift || true

case "$direction" in
    pull|push) ;;
    --help|-h) usage; exit 0 ;;
    *) usage; exit 1 ;;
esac

if [ "$#" -gt 0 ]; then
    configs=("$@")
else
    configs=("${DEFAULT_CONFIGS[@]}")
fi

for config in "${configs[@]}"; do
    sync_config "$direction" "$config"
done

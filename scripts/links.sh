#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/utils.sh"

check_config_exists() {
    local config_file="$1"
    if [ ! -f "$config_file" ]; then
        warning "Configuration file not found: $config_file (skipping)"
        return 1
    fi
    return 0
}

create_links() {
    local config_file="$1"
    check_config_exists "$config_file" || return

    info "Creating links from $(basename "$config_file")..."

    while IFS=: read -r source target || [ -n "$source" ]; do

        # Skip empty or invalid lines in the config file
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi

        # Evaluate variables
        source=$(eval echo "$source")
        target=$(eval echo "$target")

        # Check if the source exists (can be file or directory)
        if [ ! -e "$source" ]; then
            error "Error: Source '$source' not found. Skipping link creation for '$target'."
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ -L "$target" ] && [ "$(readlink "$target")" == "$source" ]; then
                # Already correctly linked — nothing to do
                warning "Link already exists: $target -> $source"
            elif [ -L "$target" ]; then
                # Symlink exists but points somewhere else (e.g. personal.gitconfig was linked
                # first, now work config is overriding it with work.gitconfig) — update it.
                ln -sf "$source" "$target"
                success "Updated link: $target -> $source"
            else
                # Regular file or directory — leave it alone to avoid data loss
                warning "File/directory already exists: $target"
            fi
        else
            target_dir=$(dirname "$target")
            if [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir"
                info "Created directory: $target_dir"
            fi

            ln -s "$source" "$target"
            success "Created link: $target -> $source"
        fi
    done <"$config_file"
}

delete_links() {
    local config_file="$1"
    check_config_exists "$config_file" || return

    info "Deleting links from $(basename "$config_file")..."
    while IFS=: read -r _ target || [ -n "$target" ]; do

        # Skip empty and invalid lines
        if [[ -z "$target" ]]; then
            continue
        fi

        # Evaluate variables
        target=$(eval echo "$target")

        # Check if the target exists (could be file, directory, or broken symlink)
        if [ -e "$target" ] || [ -L "$target" ]; then
            rm -rf "$target"
            success "Deleted: $target"
        else
            warning "Not found: $target"
        fi
    done <"$config_file"
}

show_diffs() {
    local config_files=("$@")
    local any_diffs=false

    for config_file in "${config_files[@]}"; do
        [ -f "$config_file" ] || continue
        while IFS=: read -r source target || [ -n "$source" ]; do
            [[ -z "$source" || -z "$target" || "$source" == \#* ]] && continue
            source=$(eval echo "$source")
            target=$(eval echo "$target")

            [ -e "$target" ] || [ -L "$target" ] || continue

            if [ -L "$target" ] && [ "$(readlink "$target")" == "$source" ]; then
                continue
            fi

            if [ -f "$source" ] && [ -f "$target" ]; then
                if ! diff -q "$source" "$target" > /dev/null 2>&1; then
                    warning "Different content: $target"
                    # If the source also has uncommitted repo changes, this is a conflict
                    if ! git -C "$SCRIPT_DIR" diff --quiet HEAD -- "$source" 2>/dev/null; then
                        error "Conflict: '$source' has uncommitted changes in the repo and '$target' on this machine also differs. Resolve before proceeding."
                        exit 2
                    fi
                else
                    warning "Exists (not linked): $target"
                fi
            else
                warning "Exists (not linked): $target"
            fi
            any_diffs=true
        done < "$config_file"
    done

    $any_diffs
}

adopt_existing_files() {
    local config_files=("$@")

    for config_file in "${config_files[@]}"; do
        [ -f "$config_file" ] || continue
        while IFS=: read -r source target || [ -n "$source" ]; do
            [[ -z "$source" || -z "$target" || "$source" == \#* ]] && continue
            source=$(eval echo "$source")
            target=$(eval echo "$target")

            [ -e "$target" ] || [ -L "$target" ] || continue

            if [ -L "$target" ] && [ "$(readlink "$target")" == "$source" ]; then
                continue
            fi

            if [ -f "$target" ]; then
                cp "$target" "$source"
                rm "$target"
                ln -s "$source" "$target"
                success "Adopted: $target -> $source"
            fi
        done < "$config_file"
    done
}

# Parse arguments
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    case "$1" in
    "--create")
        create_links "$2"
        ;;
    "--delete")
        shift
        include_files=false
        conf_file=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                "--include-files") include_files=true ;;
                *) conf_file="$1" ;;
            esac
            shift
        done
        delete_links "$conf_file"
        ;;
    "--show-diffs")
        shift
        show_diffs "$@"
        ;;
    "--adopt")
        shift
        adopt_existing_files "$@"
        ;;
    "--help")
        echo "Usage: $0 [--create <conf_file> | --delete [--include-files] <conf_file> | --show-diffs <conf_files...> | --adopt <conf_files...> | --help]"
        echo ""
        echo "Options:"
        echo "  --create <conf_file>  Create symlinks from the specified config file"
        echo "  --delete <conf_file>  Delete links from the specified config file"
        echo "  --delete --include-files <conf_file>"
        echo "                        Delete links including target files"
        echo "  --show-diffs <conf_files...>"
        echo "                        Show target files that differ from source"
        echo "  --adopt <conf_files...>"
        echo "                        Copy existing target files into repo, then replace with symlinks"
        echo "  --help                Display this help message"
        ;;
    *)
        error "Error: Unknown argument '$1'"
        error "Usage: $0 [--create <conf_file> | --delete [--include-files] <conf_file> | --show-diffs <conf_files...> | --adopt <conf_files...> | --help]"
        exit 1
        ;;
    esac
fi

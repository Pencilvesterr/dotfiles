#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $SCRIPT_DIR/utils.sh

check_config_exists() {
    local config_file="$1"
    # Check if configuration file exists
    if [ ! -f "$config_file" ]; then
        warning "Configuration file not found: $config_file (skipping)"
        return 1
    fi
    return 0
}

create_hardlinks() {
    local config_file="$1"
    check_config_exists "$config_file" || return

    info "Creating hard links from $(basename "$config_file")..."

    # Read dotfile links from the config file
    while IFS=: read -r source target || [ -n "$source" ]; do

        # Skip empty or invalid lines in the config file
        if [[ -z "$source" || -z "$target" || "$source" == \#* ]]; then
            continue
        fi

        # Evaluate variables
        source=$(eval echo "$source")
        target=$(eval echo "$target")

        # Check if the source file exists
        if [ ! -e "$source" ]; then
            error "Error: Source file '$source' not found. Skipping link creation for '$target'."
            continue
        fi

        # Check if source is a directory (hard links don't work for directories)
        if [ -d "$source" ]; then
            error "Error: Cannot create hard link for directory '$source'. Skipping."
            continue
        fi

        # Check if the hard link already exists
        if [ -f "$target" ]; then
            # Check if it's already the same inode (already hard linked)
            if [ "$source" -ef "$target" ]; then
                warning "Hard link already exists: $target"
            else
                warning "File already exists: $target"
            fi
        else
            # Extract the directory portion of the target path
            target_dir=$(dirname "$target")

            # Check if the target directory exists, and if not, create it
            if [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir"
                info "Created directory: $target_dir"
            fi

            # Create the hard link
            ln "$source" "$target"
            success "Created hard link: $target"
        fi
    done <"$config_file"
}

create_softlinks() {
    local config_file="$1"
    check_config_exists "$config_file" || return

    info "Creating soft links from $(basename "$config_file")..."

    # Read dotfile links from the config file
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

        # Check if the soft link already exists
        if [ -e "$target" ] || [ -L "$target" ]; then
            # Check if it's already a symlink pointing to the right place
            if [ -L "$target" ] && [ "$(readlink "$target")" == "$source" ]; then
                warning "Soft link already exists: $target -> $source"
            else
                warning "File/directory already exists: $target"
            fi
        else
            # Extract the directory portion of the target path
            target_dir=$(dirname "$target")

            # Check if the target directory exists, and if not, create it
            if [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir"
                info "Created directory: $target_dir"
            fi

            # Create the soft link
            ln -s "$source" "$target"
            success "Created soft link: $target -> $source"
        fi
    done <"$config_file"
}

delete_hardlink_files() {
    local config_file="$1"
    check_config_exists "$config_file" || return

    info "Deleting hard links from $(basename "$config_file")..."
    while IFS=: read -r _ target || [ -n "$target" ]; do

        # Skip empty and invalid lines
        if [[ -z "$target" ]]; then
            continue
        fi

        # Evaluate variables
        target=$(eval echo "$target")

        # Check if the file exists
        if [ -f "$target" ] || { [ "$include_files" == true ] && [ -f "$target" ]; }; then
            # Remove the file
            rm -rf "$target"
            success "Deleted: $target"
        else
            warning "Not found: $target"
        fi
    done <"$config_file"
}

delete_softlink_files() {
    local config_file="$1"
    check_config_exists "$config_file" || return

    info "Deleting soft links from $(basename "$config_file")..."
    while IFS=: read -r _ target || [ -n "$target" ]; do

        # Skip empty and invalid lines
        if [[ -z "$target" ]]; then
            continue
        fi

        # Evaluate variables
        target=$(eval echo "$target")

        # Check if the target exists (could be file, directory, or broken symlink)
        if [ -e "$target" ] || [ -L "$target" ]; then
            # Remove the symlink or directory
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

adopt_existing_files_and_soft_link() {
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
        create_softlinks "$2"
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
        delete_softlink_files "$conf_file"
        ;;
    "--show-diffs")
        shift
        show_diffs "$@"
        ;;
    "--adopt")
        shift
        adopt_existing_files_and_soft_link "$@"
        ;;
    "--help")
        echo "Usage: $0 [--create [conf_file] | --delete [--include-files] [conf_file] | --show-diffs [conf_files...] | --adopt [conf_files...] | --help]"
        echo ""
        echo "Options:"
        echo "  --create              Create hard links from hardlinks_config.conf"
        echo "                        and soft links from softlinks_config.conf"
        echo "  --create <conf_file>  Create soft links from the specified conf file only"
        echo "  --delete              Delete links from both config files"
        echo "  --delete --include-files"
        echo "                        Delete links including files"
        echo "  --delete <conf_file>  Delete links from the specified conf file only"
        echo "  --show-diffs [conf_files...]"
        echo "                        Show target files that differ from source"
        echo "  --adopt [conf_files...]"
        echo "                        Copy existing target files into repo, then replace with links"
        echo "  --help                Display this help message"
        ;;
    *)
        error "Error: Unknown argument '$1'"
        error "Usage: $0 [--create [conf_file] | --delete [--include-files] [conf_file] | --show-diffs [conf_files...] | --adopt [conf_files...] | --help]"
        exit 1
        ;;
    esac
fi

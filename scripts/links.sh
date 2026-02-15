#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $SCRIPT_DIR/utils.sh

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HARDLINKS_CONFIG="$SCRIPT_DIR/../hardlinks_config.conf"
SOFTLINKS_CONFIG="$SCRIPT_DIR/../softlinks_config.conf"

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

delete_hardlinks() {
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

delete_softlinks() {
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

# Parse arguments
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    case "$1" in
    "--create")
        if [ "$2" == "--work-conf" ]; then
            create_hardlinks "$SCRIPT_DIR/../hardlinks_config_work.conf"
        else
            create_hardlinks "$HARDLINKS_CONFIG"
            create_softlinks "$SOFTLINKS_CONFIG"

            # Automatically create work config links if user is mcrouch
            if [ "$(whoami)" == "mcrouch" ]; then
                info "Detected user 'mcrouch' - creating work config links..."
                create_hardlinks "$SCRIPT_DIR/../hardlinks_config_work.conf"
            fi
        fi
        ;;
    "--delete")
        if [ "$2" == "--include-files" ]; then
            include_files=true
        fi
        if [ "$2" == "--work-conf" ] || [ "$3" == "--work-conf" ]; then
            delete_hardlinks "$SCRIPT_DIR/../hardlinks_config_work.conf"
        else
            delete_hardlinks "$HARDLINKS_CONFIG"
            delete_softlinks "$SOFTLINKS_CONFIG"

            # Automatically delete work config links if user is mcrouch
            if [ "$(whoami)" == "mcrouch" ]; then
                info "Detected user 'mcrouch' - deleting work config links..."
                delete_hardlinks "$SCRIPT_DIR/../hardlinks_config_work.conf"
            fi
        fi
        ;;
    "--help")
        # Display usage/help message
        echo "Usage: $0 [--create | --delete [--include-files] [--work-conf] | --help]"
        echo ""
        echo "Options:"
        echo "  --create              Create hard links from hardlinks_config.conf"
        echo "                        and soft links from softlinks_config.conf"
        echo "  --create --work-conf  Create hard links from hardlinks_config_work.conf"
        echo "  --delete              Delete links from both config files"
        echo "  --delete --include-files"
        echo "                        Delete links including files"
        echo "  --delete --work-conf  Delete links from work config"
        echo "  --help                Display this help message"
        ;;
    *)
        # Display an error message for unknown arguments
        error "Error: Unknown argument '$1'"
        error "Usage: $0 [--create | --delete [--include-files] [--work-conf] | --help]"
        exit 1
        ;;
    esac
fi

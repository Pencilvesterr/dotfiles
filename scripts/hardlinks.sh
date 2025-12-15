#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $SCRIPT_DIR/utils.sh

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CONFIG_FILE="$SCRIPT_DIR/../hardlinks_config.conf"

. $SCRIPT_DIR/utils.sh

check_config_exists() {
    # Check if configuration file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
}

create_hardlinks() {
    check_config_exists
    info "Creating hard links..."

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
    done <"$CONFIG_FILE"
}

delete_hardlinks() {
    check_config_exists
    info "Deleting hard links..."
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
    done <"$CONFIG_FILE"
}

# Parse arguments
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    case "$1" in
    "--create")
        if [ "$2" == "--work-conf" ]; then
            CONFIG_FILE="$SCRIPT_DIR/../hardlinks_config_work.conf"
        fi
        create_hardlinks
        ;;
    "--delete")
        if [ "$2" == "--include-files" ]; then
            include_files=true
        fi
        if [ "$3" == "--work-conf" ]; then
            CONFIG_FILE="$SCRIPT_DIR/../hardlinks_config_work.conf"
        fi
        delete_hardlinks
        ;;
    "--help")
        # Display usage/help message
        echo "Usage: $0 [--create | --delete [--include-files] | --help]"
        ;;
    *)
        # Display an error message for unknown arguments
        error "Error: Unknown argument '$1'"
        error "Usage: $0 [--create | --delete [--include-files] | --help]"
        exit 1
        ;;
    esac
fi

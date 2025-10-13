#!/bin/bash
set -e

# Log file for debugging AeroSpace execution

# Aerospace workspace app movement script
# Automatically moves specific apps to the current workspace when switching

# Configuration: Get apps for workspace using case statement
# Note,ordering  matters. Last one will be on top
get_apps_for_workspace() {
    case "$1" in
    *"Slack"*)
        echo "Slack"
        ;;
    *"Zoom+Postman"*)
        echo "Postman|zoom.us"
        ;;
    *"Zoom"*)
        echo "zoom.us"
        ;;
    *"Chrome"*)
        echo "Google Chrome"
        ;;
    *"Code"*)
        echo "Code|Cursor|IntelliJ IDEA"
        ;;
    *"Terminal"*)
        echo "WezTerm"
        ;;
    *)
        echo ""
        ;;
    esac
}

# Function to check if app exists and move it to current workspace
move_app_to_workspace() {
    local app_identifier="$1"
    local current_workspace="$2"

    echo "$(date): Checking app: $app_identifier for workspace: $current_workspace"

    # Check if app exists globally
    if ! aerospace list-windows --all | grep -q "$app_identifier"; then
        echo "$(date): $app_identifier not running, skipping"
        return 0 # App not running, skip silently
    fi

    # Note: We'll move all windows of this app, even if some are already in the workspace

    echo "$(date): Moving $app_identifier to $current_workspace"
    echo "Moving $app_identifier to $current_workspace"

    # Move all windows of this app to current workspace
    echo "$(date): Searching for all windows of: $app_identifier"

    # First, get all matching window IDs into an array
    local window_ids=()
    while IFS= read -r window_line; do
        # Check if this window line contains our app identifier
        if echo "$window_line" | grep -q "$app_identifier"; then
            local window_id
            window_id=$(echo "$window_line" | awk '{print $1}')
            window_ids+=("$window_id")
            echo "$(date): Found window $window_id for $app_identifier"
        fi
    done < <(aerospace list-windows --all)

    # Now move all found windows
    for window_id in "${window_ids[@]}"; do
        echo "$(date): Moving window $window_id of $app_identifier to $current_workspace"
        aerospace move-node-to-workspace "$current_workspace" --window-id "$window_id" 2>/dev/null || true
    done

    echo "$(date): Moved ${#window_ids[@]} windows for $app_identifier"
}

# Main execution
main() {
    # Log that the script was called
    echo "$(date): Script called by AeroSpace"

    local current_workspace
    current_workspace=$(aerospace list-workspaces --focused)

    echo "$(date): Current workspace: $current_workspace"
    echo "DEBUG: Current workspace: $current_workspace"

    # Test associative array access with error handling
    echo "$(date): Testing associative array access"

    # Get apps for this workspace using function instead of associative array
    local apps
    apps=$(get_apps_for_workspace "$current_workspace")
    echo "$(date): get_apps_for_workspace returned: '$apps'"

    echo "$(date): Apps configured: '$apps'"
    echo "DEBUG: Apps configured for this workspace: '$apps'"

    if [[ -z "$apps" ]]; then
        echo "$(date): No apps configured, exiting"
        echo "DEBUG: No apps configured, exiting"
        exit 0 # No apps configured for this workspace
    fi

    # Move each configured app (pipe-separated for multiple apps)
    IFS='|' read -ra app_list <<<"$apps"
    for app in "${app_list[@]}"; do
        echo "$(date): Processing app: '$app'"
        echo "DEBUG: Processing app: '$app'"
        if [[ -n "$app" ]]; then
            move_app_to_workspace "$app" "$current_workspace"
            echo "$(date): Finished processing $app"
        fi
    done

    echo "$(date): Script completed"
}

main "$@"


#!/bin/bash
set -e

# Aerospace workspace app movement script
# Automatically moves specific apps to the current workspace when switching into a workspace
# Used for apps that are used in other workspaces frequently, but should be moved to the current workspace when switching into it

# Configuration: Get apps for workspace using case statement
# Note,ordering  matters. Last one will be on top
get_apps_for_workspace() {
    case "$1" in
    *"Slack"*)
        echo "Slack"
        ;;
    *"WhatsApp"*)
        echo "WhatsApp"
        ;;
    *"Zoom+Postman"*)
        echo "zoom.us"
        ;;
    *"Postman"*)
        echo "Postman"
        ;;
    *"Zoom"*)
        echo "zoom.us"
        ;;
    *"Bitwarden"*)
        echo "Bitwarden"
        ;;
    *"Browser"*)
        echo "Arc:skip_if_present+new_window"
        ;;
    *"Mail"*)
        echo "Mail"
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
    local flags="${3:-}"
    local skip_if_present="false"
    local new_window="false"
    [[ "$flags" == *"skip_if_present"* ]] && skip_if_present="true"
    [[ "$flags" == *"new_window"* ]] && new_window="true"

    echo "$(date): Checking app: $app_identifier for workspace: $current_workspace"

    if [[ "$skip_if_present" == "true" ]]; then
        if aerospace list-windows --workspace "$current_workspace" 2>/dev/null | awk -F'|' '{print $2}' | grep -q "$app_identifier"; then
            echo "$(date): $app_identifier already in $current_workspace, skipping"
            return 0
        fi
    fi

    if [[ "$new_window" == "true" ]]; then
        echo "$(date): Opening new window for $app_identifier"
        osascript -e "tell application \"$app_identifier\" to make new window" 2>/dev/null ||
            open -a "$app_identifier"
        return 0
    fi

    # Check if app exists globally
    if ! aerospace list-windows --all | awk -F'|' '{print $2}' | grep -q "$app_identifier"; then
        echo "$(date): $app_identifier not running, skipping"
        return 0 # App not running, skip silently
    fi

    echo "$(date): Moving $app_identifier to $current_workspace"

    # First, get all matching window IDs into an array
    local window_ids=()
    while IFS= read -r window_line; do
        if echo "$window_line" | awk -F'|' '{print $2}' | grep -q "$app_identifier"; then
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
    for app_entry in "${app_list[@]}"; do
        app="${app_entry%%:*}"
        flags="${app_entry#*:}"
        [[ "$flags" == "$app" ]] && flags="" # no colon present

        echo "$(date): Processing app: '$app'"
        echo "DEBUG: Processing app: '$app'"
        if [[ -n "$app" ]]; then
            move_app_to_workspace "$app" "$current_workspace" "$flags"
            echo "$(date): Finished processing $app"
        fi
    done

    echo "$(date): Script completed"
}

main "$@"

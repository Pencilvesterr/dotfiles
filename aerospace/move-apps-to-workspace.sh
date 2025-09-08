#!/bin/bash
set -e

# Log file for debugging AeroSpace execution

# Aerospace workspace app movement script
# Automatically moves specific apps to the current workspace when switching

# Configuration: Get apps for workspace using case statement
get_apps_for_workspace() {
    case "$1" in
        "5->Slack"|"0->Slack")
            echo "Slack"
            ;;
        "9->Zoom")
            echo "zoom.us"
            ;;
        "4->Zoom+Postman")
            echo "zoom.us|Postman"
            ;;
        "6->Chrome")
            echo "Google Chrome"
            ;;
        "3->Terminal"|"8->Terminal")
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
        return 0  # App not running, skip silently
    fi
    
    # Check if app is already in current workspace
    if aerospace list-windows --workspace "$current_workspace" | grep -q "$app_identifier"; then
        echo "$(date): $app_identifier already in $current_workspace, skipping" 
        return 0  # App already in workspace, skip
    fi
    
    echo "$(date): Moving $app_identifier to $current_workspace" 
    echo "Moving $app_identifier to $current_workspace"
    
    # Move all windows of this app to current workspace
    aerospace list-windows --all | grep "$app_identifier" | while IFS= read -r window_line; do
        local window_id
        window_id=$(echo "$window_line" | awk '{print $1}')
        aerospace move-node-to-workspace "$current_workspace" --window-id "$window_id" 2>/dev/null || true
    done
}

# Main execution
main() {
    # Log that the script was called
    echo "$(date): Script called by AeroSpace"  
    
    local current_workspace
    current_workspace=$(aerospace list-workspaces --focused )
    
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
        exit 0  # No apps configured for this workspace
    fi
    
    # Move each configured app (pipe-separated for multiple apps)
    IFS='|' read -ra app_list <<< "$apps"
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
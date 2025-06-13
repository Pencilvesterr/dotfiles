#!/bin/bash
set -e
set -x

# Define app mappings: app_name -> window_identifier
declare -A APP_MAPPINGS=(
    ["Slack"]="Slack"
    ["Zoom"]="zoom.us"
    # Add more apps as needed
    # ["Discord"]="Discord"
    # ["Teams"]="Microsoft Teams"
)

# Function to move app windows to current workspace
move_app_to_workspace() {
    local app_name="$1"
    local window_identifier="$2"
    local workspace="$3"
    
    echo "Looking for $app_name windows with identifier: $window_identifier"
    
    # Find all windows for this app (get full window info)
    app_windows=$(aerospace list-windows --all | grep "$window_identifier" || true)
    echo "Found windows: $app_windows"
    
    # Check if there are any windows for this app
    if [ -n "$app_windows" ]; then
        # Check if any windows are already in the current workspace
        app_in_current_workspace=$(aerospace list-windows --workspace "$workspace" | grep "$window_identifier" || true)
        echo "Windows already in workspace '$workspace': $app_in_current_workspace"
        
        # If no windows are in the current workspace, move the first one found
        if [ -z "$app_in_current_workspace" ]; then
            # Get the window ID of the first window (first column)
            window_id=$(echo "$app_windows" | head -n1 | awk '{print $1}')
            echo "Moving window ID: $window_id to workspace: $workspace"
            
            # Move the window to the current workspace
            aerospace move-node-to-workspace --window-id "$window_id" "$workspace"
            echo "Moved $app_name window to workspace: $workspace"
        else
            echo "$app_name window already in workspace: $workspace"
        fi
    else
        echo "No $app_name windows found"
    fi
}

# Check each app to see if the current workspace name contains it
for app_name in "${!APP_MAPPINGS[@]}"; do
    echo "Checking if workspace '$AEROSPACE_FOCUSED_WORKSPACE' contains '$app_name'"
    if [[ "$AEROSPACE_FOCUSED_WORKSPACE" == *"$app_name"* ]]; then
        echo "Match found! Processing $app_name"
        window_identifier="${APP_MAPPINGS[$app_name]}"
        move_app_to_workspace "$app_name" "$window_identifier" "$AEROSPACE_FOCUSED_WORKSPACE"
        break  # Only handle one app per workspace switch
    fi
done 
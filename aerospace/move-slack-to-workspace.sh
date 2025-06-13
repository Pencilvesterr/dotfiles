#!/bin/bash

# Check if we switched to a workspace that contains "Slack" in its name
if [[ "$AEROSPACE_FOCUSED_WORKSPACE" == *"Slack"* ]]; then
    # Find all Slack windows and their current workspaces
    # Look for windows with app-id 'com.tinyspeck.slackmacgap'
    slack_windows=$(aerospace list-windows --all | grep "\| Slack")
    
    # Check if there are any Slack windows
    if [ -n "$slack_windows" ]; then
        # Check if any Slack windows are already in the current workspace
        slack_in_current_workspace=$(aerospace list-windows --workspace "$AEROSPACE_FOCUSED_WORKSPACE" | grep "\| Slack")
        
        # If no Slack windows are in the current workspace, move the first one found
        if [ -z "$slack_in_current_workspace" ]; then
            # Get the window ID of the first Slack window
            window_id=$(echo "$slack_windows" | head -n1 | awk '{print $1}')
            
            # Move the Slack window to the current workspace
            aerospace move-node-to-workspace --window-id "$window_id" "$AEROSPACE_FOCUSED_WORKSPACE"
        fi
    fi
fi

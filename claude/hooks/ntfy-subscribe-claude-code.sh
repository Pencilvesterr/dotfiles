#!/bin/bash
# Subscribes to the claude-code ntfy topic and shows a macOS notification for
# each incoming message. Publishing side: claude/hooks/notify.sh (non-macOS
# machines push here so this Mac can surface the notification).

exec /opt/homebrew/bin/ntfy subscribe \
  --token=tk_szmpvbxak9mg9qn4owf1tpdtpy423 \
  ntfy.ketaflix.com/claude-code \
  "$HOME/.claude/hooks/ntfy-notify-remote.sh"

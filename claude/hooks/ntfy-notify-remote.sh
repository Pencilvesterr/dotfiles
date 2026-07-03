#!/bin/bash
# Shows a macOS notification for an incoming ntfy message.
# Invoked by ntfy-subscribe-claude-code.sh (via `ntfy subscribe`), which
# sets $NTFY_MESSAGE for each message received on the claude-code topic.

osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Claude Code (remote)" sound name "Glass"' -e 'end run' "$NTFY_MESSAGE"

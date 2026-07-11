#!/bin/bash
# Subscribes to the claude-code ntfy topic and shows a macOS notification for
# each incoming message. Publishing side: claude/hooks/notify.sh (non-macOS
# machines push here so this Mac can surface the notification).

script_source="${BASH_SOURCE[0]}"
[ -h "$script_source" ] && script_source="$(readlink "$script_source")"
script_dir="$(cd "$(dirname "$script_source")" && pwd)"
[ -f "$script_dir/.env" ] && source "$script_dir/.env"

if [ -z "$NTFY_SERVER" ] || [ -z "$NTFY_TOPIC" ] || [ -z "$NTFY_TOKEN" ]; then
  echo "ntfy-subscribe-claude-code.sh: NTFY_SERVER, NTFY_TOPIC, NTFY_TOKEN must be set in $script_dir/.env" >&2
  exit 1
fi

exec /opt/homebrew/bin/ntfy subscribe \
  --token="$NTFY_TOKEN" \
  "$NTFY_SERVER/$NTFY_TOPIC" \
  "$HOME/.claude/hooks/ntfy-notify-remote.sh"

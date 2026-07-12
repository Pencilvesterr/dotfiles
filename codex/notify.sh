#!/usr/bin/env bash

# Codex passes the hook payload as JSON on stdin. Keep the alert concise so it
# does not expose prompts or agent output in a toast.
payload=$(cat)

message="Codex has finished a turn and is ready for your input."
if printf '%s\n' "$payload" | /usr/bin/grep -qE '"hook_event_name"[[:space:]]*:[[:space:]]*"PermissionRequest"'; then
  message="Codex needs your approval to continue."
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  /usr/bin/osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title "Codex" sound name "Glass"' \
    -e 'end run' \
    "$message" >/dev/null 2>&1 || true
elif command -v notify-send >/dev/null 2>&1; then
  notify-send "Codex" "$message" >/dev/null 2>&1 || true
fi

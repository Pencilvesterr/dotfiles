#!/bin/bash
# macOS: always show a notification.
# Other platforms: push a notification via ntfy.
# Usage: notify.sh "<message template>" — a %s in the template is replaced
# with the name of the app running Claude Code (macOS) or the hostname (ntfy).

script_source="${BASH_SOURCE[0]}"
[ -h "$script_source" ] && script_source="$(readlink "$script_source")"
script_dir="$(cd "$(dirname "$script_source")" && pwd)"
[ -f "$script_dir/.env" ] && source "$script_dir/.env"

if [ "$(uname)" != "Darwin" ]; then
  if [ -z "$NTFY_SERVER" ] || [ -z "$NTFY_TOPIC" ] || [ -z "$NTFY_TOKEN" ]; then
    echo "notify.sh: NTFY_SERVER, NTFY_TOPIC, NTFY_TOKEN must be set in $script_dir/.env" >&2
    exit 1
  fi
  msg=$(printf -- "$1" "$(hostname -s)")
  curl -fsS -H "Authorization: Bearer $NTFY_TOKEN" -d "$msg" "https://$NTFY_SERVER/$NTFY_TOPIC" >/dev/null
  exit 0
fi

case "$TERM_PROGRAM" in
  WezTerm) runningApp="WezTerm" ;;
  iTerm.app) runningApp="iTerm2" ;;
  Apple_Terminal) runningApp="Terminal" ;;
  vscode) runningApp="VS Code" ;;
  ""|JetBrains-JediTerm) runningApp="IntelliJ IDEA" ;;
  *) runningApp="$TERM_PROGRAM" ;;
esac

msg=$(printf -- "$1" "$runningApp")
osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Claude Code" sound name "Glass"' -e 'end run' "$msg"

exit 0

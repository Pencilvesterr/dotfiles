#!/bin/bash
# macOS: always show a notification.
# Other platforms: push a notification via ntfy.
# Usage: notify.sh "<message template>" — a %s in the template is replaced
# with the name of the app running Claude Code (macOS) or the hostname (ntfy).

NTFY_URL="https://ntfy.ketaflix.com/claude-code"
NTFY_TOKEN="tk_szmpvbxak9mg9qn4owf1tpdtpy423"

if [ "$(uname)" != "Darwin" ]; then
  msg=$(printf -- "$1" "$(hostname -s)")
  curl -fsS -H "Authorization: Bearer $NTFY_TOKEN" -d "$msg" "$NTFY_URL" >/dev/null
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

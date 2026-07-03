#!/bin/bash
# macOS: show a notification unless the app running Claude Code is frontmost.
# Other platforms: push a notification via ntfy (no frontmost-app concept).
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
  WezTerm) sysEventsName="wezterm-gui"; runningApp="WezTerm" ;;
  iTerm.app) sysEventsName="iTerm2"; runningApp="iTerm2" ;;
  Apple_Terminal) sysEventsName="Terminal"; runningApp="Terminal" ;;
  vscode) sysEventsName="Code"; runningApp="VS Code" ;;
  ""|JetBrains-JediTerm) sysEventsName="idea"; runningApp="IntelliJ IDEA" ;;
  *) sysEventsName="$TERM_PROGRAM"; runningApp="$TERM_PROGRAM" ;;
esac

frontApp=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true')

if [ "$frontApp" != "$sysEventsName" ]; then
  msg=$(printf -- "$1" "$runningApp")
  osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "Claude Code" sound name "Glass"' -e 'end run' "$msg"
fi

exit 0

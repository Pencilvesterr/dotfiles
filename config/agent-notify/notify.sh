#!/usr/bin/env bash

# Send a completion or approval notification for an interactive coding agent.
# Usage: notify.sh <codex|claude> <complete|approval>

agent="${1:-}"
event="${2:-}"

case "$agent" in
  codex)
    title="Codex"
    ;;
  claude)
    title="Claude Code"
    ;;
  *)
    echo "notify.sh: agent must be 'codex' or 'claude'" >&2
    exit 2
    ;;
esac

case "$agent:$event" in
  codex:complete)
    local_message="Codex has finished a turn and is ready for your input."
    remote_message="Codex finished on %s and is ready for your input."
    ;;
  codex:approval)
    local_message="Codex needs your approval to continue."
    remote_message="Codex on %s needs your approval to continue."
    ;;
  claude:complete)
    local_message="Done in %s — ready for your next message"
    remote_message="Claude Code finished on %s — ready for your next message"
    ;;
  *)
    echo "notify.sh: unsupported event '$event' for $agent" >&2
    exit 2
    ;;
esac

if [ "$(uname -s)" = "Darwin" ]; then
  case "${TERM_PROGRAM:-}" in
    WezTerm) running_app="WezTerm" ;;
    iTerm.app) running_app="iTerm2" ;;
    Apple_Terminal) running_app="Terminal" ;;
    vscode) running_app="VS Code" ;;
    ""|JetBrains-JediTerm) running_app="IntelliJ IDEA" ;;
    *) running_app="$TERM_PROGRAM" ;;
  esac

  if [ "$agent" = "claude" ]; then
    message=$(printf -- "$local_message" "$running_app")
  else
    message="$local_message"
  fi

  osascript \
    -e 'on run argv' \
    -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name "Glass"' \
    -e 'end run' \
    "$message" "$title" >/dev/null
  exit 0
fi

env_file="${AGENT_NOTIFY_ENV_FILE:-$HOME/.config/agent-notify/.env}"
if [ -f "$env_file" ]; then
  # shellcheck disable=SC1090
  source "$env_file"
fi

if [ -z "${NTFY_SERVER:-}" ] || [ -z "${NTFY_TOPIC:-}" ]; then
  echo "notify.sh: NTFY_SERVER, NTFY_TOPIC must be set in $env_file" >&2
  exit 1
fi

curl_args=(-H "X-Title: $title")
if [ -n "${NTFY_TOKEN:-}" ]; then
  curl_args+=(-H "Authorization: Bearer $NTFY_TOKEN")
fi

message=$(printf -- "$remote_message" "$(hostname -s)")
curl -fsS \
  "${curl_args[@]}" \
  -d "$message" \
  "https://$NTFY_SERVER/$NTFY_TOPIC" >/dev/null

#!/usr/bin/env bash
# Subscribe to remote agent notifications and surface them on this Mac.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
env_file="$script_dir/.env"
if [ -f "$env_file" ]; then
  # shellcheck disable=SC1090
  source "$env_file"
fi

if [ -z "${NTFY_SERVER:-}" ] || [ -z "${NTFY_TOPIC:-}" ]; then
  echo "ntfy-subscribe.sh: NTFY_SERVER, NTFY_TOPIC must be set in $env_file" >&2
  exit 1
fi

ntfy_args=()
if [ -n "${NTFY_TOKEN:-}" ]; then
  ntfy_args+=(--token="$NTFY_TOKEN")
fi

exec /opt/homebrew/bin/ntfy subscribe \
  "${ntfy_args[@]}" \
  "$NTFY_SERVER/$NTFY_TOPIC" \
  "$script_dir/ntfy-display.sh"

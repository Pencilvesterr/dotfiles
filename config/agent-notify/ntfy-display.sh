#!/usr/bin/env bash
# Display one notification received by `ntfy subscribe`.

title="${NTFY_TITLE:-Agent} (remote)"
osascript \
  -e 'on run argv' \
  -e 'display notification (item 1 of argv) with title (item 2 of argv) sound name "Glass"' \
  -e 'end run' \
  "${NTFY_MESSAGE:-}" "$title"

#!/bin/bash
set -euo pipefail

# JankyBorders applies one style globally. Keep it conspicuous while the
# focused window uses AeroSpace fullscreen, and restore the normal style
# whenever focus returns to a regular window or an empty workspace.
normal_options=(
    active_color=0xffe1e3e4
    inactive_color=0xff494d64
    width=10.0
)
fullscreen_options=(
    active_color=0xffff9500
    inactive_color=0xff494d64
    width=24.0
)

is_fullscreen="false"
if is_fullscreen=$(aerospace list-windows --focused --format '%{window-is-fullscreen}' 2>/dev/null); then
    :
fi

if [[ "$is_fullscreen" == "true" ]]; then
    borders "${fullscreen_options[@]}"
else
    borders "${normal_options[@]}"
fi

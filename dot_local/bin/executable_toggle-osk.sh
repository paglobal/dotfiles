#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

app="wvkbd-mobintl"

if pgrep -x "$app" > /dev/null; then
    pkill -x "$app"
else
    nohup $app -L 250 --text "ffffff" > /dev/null 2>&1 &
fi

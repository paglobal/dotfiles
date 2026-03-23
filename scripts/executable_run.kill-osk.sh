#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

app="wvkbd-mobintl"

pkill -x "$app"

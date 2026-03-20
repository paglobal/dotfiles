#!/bin/bash

# 1. Grab raw JSON and exit if canceled
raw_json=$(niri msg --json pick-color)
[[ -z "$raw_json" ]] && exit 0

# 2. Extract to a space-separated string, then read into a safe array
ints=$(echo "$raw_json" | jq -r '.rgb | map(. * 255 + 0.5 | floor) | join(" ")')
read -r -a int_array <<< "$ints"

# 3. Create strings using the array for printf safety
hex=$(printf "#%02x%02x%02x" "${int_array[@]}")
rgb="rgb(${ints// /, })"

# 4. Pick, exit if canceled, then copy
selected=$(printf "%s\n%s\n" "$hex" "$rgb" | fzf --prompt="Copy: ")
[[ -z "$selected" ]] && exit 0

echo -n "$selected" | wl-copy


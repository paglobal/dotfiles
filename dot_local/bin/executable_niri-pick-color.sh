#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

color_json=$(niri msg --json pick-color)
[[ -z "$color_json" ]] && exit 0

color_ints=$(echo "$color_json" | jq -r '.rgb | map(. * 255 + 0.5 | floor) | join(" ")')
IFS=$' \n\t'
read -r -a color_int_array <<< "$color_ints"
IFS=$'\n\t'

export HEX=$(printf "#%02x%02x%02x" "${color_int_array[@]}")
export RGB="rgb(${color_ints// /, })"

export SELECTED_COLOR_T=$(mk_t)
PICK_COLOR() {
    printf "%s\n%s\n" "$HEX" "$RGB" | fzf --prompt="Select format: " > "$SELECTED_COLOR_T"
}
export -f PICK_COLOR

# 4. Pick, exit if canceled, then copy
term.sh PICK_COLOR
selected_color=$(rd_t "$SELECTED_COLOR_T")
[[ -z "$selected_color" ]] && exit 0
echo -n "$selected_color" | wl-copy


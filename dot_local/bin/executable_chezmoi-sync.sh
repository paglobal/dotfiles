#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

yay -Qqe > ~/assets/txts/pkglist.txt

success_message="Done! Run 'chezmoi cd' to inspect, and don't forget to commit your changes!"

path=${1:-}
# Process a single target if an argument is provided
if [[ -n "$path" ]]; then
    if [[ ! -e "$path" ]]; then
        echo "Error: '$path' does not exist."
        exit 1
    fi
    echo "Processing single target: $path"
    chezmoi forget --force "$path"
    chezmoi add "$path"
    echo "$success_message"
    exit 0
fi

config_list="$HOME/assets/txts/chezmoi-dirs.txt"
[[ ! -f "$config_list" ]] && echo "File $config_list not found" && exit 1

chezmoi managed -p absolute | xargs -d '\n' chezmoi forget --force

while read -r entry || [[ -n "$entry" ]]; do
  [[ -z "$entry" ]] && continue
  echo "Processing: $entry"
  chezmoi add "$entry"
done < "$config_list"

echo "$success_message"

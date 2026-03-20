#!/bin/bash

yay -Qqe > ~/assets/txts/pkglist.txt

SUCCESS_MESSAGE="Done! Run 'chezmoi cd' to inspect, and don't forget to commit your changes!"

# Process a single target if an argument is provided
if [[ -n "$1" ]]; then
    if [[ ! -e "$1" ]]; then
        echo "Error: '$1' does not exist."
        exit 1
    fi
    echo "Processing single target: $1"
    chezmoi forget --force "$1"
    chezmoi add "$1"
    echo "$SUCCESS_MESSAGE"
    exit 0
fi

CONFIG_LIST="$HOME/assets/txts/chezmoi-dirs.txt"
[[ ! -f "$CONFIG_LIST" ]] && echo "File $CONFIG_LIST not found" && exit 1

chezmoi managed -p absolute | xargs -d '\n' chezmoi forget --force

while read -r entry || [[ -n "$entry" ]]; do
  [[ -z "$entry" ]] && continue
  echo "Processing: $entry"
  chezmoi add "$entry"
done < "$CONFIG_LIST"

echo "$SUCCESS_MESSAGE"

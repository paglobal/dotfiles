#!/bin/bash

BATTERY_PATH="/org/freedesktop/UPower/devices/battery_BAT0"

PERCENT=$(upower -i "$BATTERY_PATH" | awk '/percentage:/ {gsub("%",""); print $2}')
STATUS=$(upower -i "$BATTERY_PATH" | awk '/state:/ {print $2}')
DATE=$(date +"%H:%M %a %b %d")
CATEGORY="no-history"

case "$STATUS" in
charging)
  ICON="🔌"
  ;;
discharging)
  ICON="🔋"
  ;;
fully-charged)
  ICON="✅"
  ;;
*)
  ICON="❓"
  ;;
esac

case $PERCENT in
    [0-9]|1[0-9]|2[0-9]|3[0-9]|4[0-9])   URGENCY="critical" ;;  # 0–49%
    5[0-9]|6[0-9]|7[0-4]) URGENCY="normal" ;; # 50–70%
    *)              URGENCY="low" ;;       # 71%+
esac

if [[ "$STATUS" == "charging" ]]; then
  URGENCY="low"
fi

notify-send -u "$URGENCY" -c "$CATEGORY" "${ICON} Battery Status - ${DATE}" "Battery at ${PERCENT}%, ${STATUS}"

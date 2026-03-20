#!/bin/bash

APP="wvkbd-mobintl"

if pgrep -x "$APP" > /dev/null; then
    pkill -x "$APP"
else
    nohup $APP -L 250 --text "ffffff" > /dev/null 2>&1 &
fi

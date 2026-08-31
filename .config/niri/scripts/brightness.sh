#!/usr/bin/env bash
# Brightness control via systemd-logind D-Bus
DEVICE=$(ls /sys/class/backlight 2>/dev/null | head -n 1)
if [ -z "$DEVICE" ]; then
    exit 1
fi

MAX=$(cat "/sys/class/backlight/$DEVICE/max_brightness")
CUR=$(cat "/sys/class/backlight/$DEVICE/brightness")
STEP=$(( MAX / 20 )) # 5% step

case "$1" in
    up|+)
        NEW=$(( CUR + STEP ))
        if [ "$NEW" -gt "$MAX" ]; then
            NEW=$MAX
        fi
        ;;
    down|-)
        NEW=$(( CUR - STEP ))
        MIN=$(( MAX / 20 )) # minimum 5%
        if [ "$NEW" -lt "$MIN" ]; then
            NEW=$MIN
        fi
        ;;
    *)
        exit 1
        ;;
esac

busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetBrightness ssu "backlight" "$DEVICE" "$NEW" >/dev/null 2>&1

PCT=$(( NEW * 100 / MAX ))
notify-send -a "Brightness" -h string:x-canonical-private-synchronous:brightness -h int:value:"$PCT" -t 1200 "Brightness" "${PCT}%"

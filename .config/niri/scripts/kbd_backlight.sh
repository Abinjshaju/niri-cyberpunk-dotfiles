#!/usr/bin/env bash
DEV="tpacpi::kbd_backlight"
if [ ! -d "/sys/class/leds/$DEV" ]; then
    exit 0
fi

MAX=$(cat "/sys/class/leds/$DEV/max_brightness")
CUR=$(cat "/sys/class/leds/$DEV/brightness")

case "$1" in
    up|+)
        NEW=$(( CUR + 1 ))
        [ "$NEW" -gt "$MAX" ] && NEW=$MAX
        ;;
    down|-)
        NEW=$(( CUR - 1 ))
        [ "$NEW" -lt 0 ] && NEW=0
        ;;
    toggle)
        NEW=$(( (CUR + 1) % (MAX + 1) ))
        ;;
    *)
        exit 1
        ;;
esac

busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetBrightness ssu "leds" "$DEV" "$NEW" >/dev/null 2>&1
notify-send -a "Keyboard Backlight" -h string:x-canonical-private-synchronous:kbd -t 1200 "Keyboard Backlight" "Level: $NEW / $MAX"

#!/usr/bin/env bash

case "$1" in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    mic-mute)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o "\[MUTED\]")
        if [ -n "$MUTED" ]; then
            notify-send -a "Volume" -h string:x-canonical-private-synchronous:mic -t 1200 "Microphone" "Muted"
        else
            notify-send -a "Volume" -h string:x-canonical-private-synchronous:mic -t 1200 "Microphone" "Unmuted"
        fi
        exit 0
        ;;
    *)
        exit 1
        ;;
esac

VOL_INFO=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
MUTED=$(echo "$VOL_INFO" | grep -o "\[MUTED\]")
VOL_RAW=$(echo "$VOL_INFO" | awk '{print $2}')
VOL_PCT=$(python3 -c "print(int(round(float('$VOL_RAW') * 100)))" 2>/dev/null || echo "50")

if [ -n "$MUTED" ]; then
    notify-send -a "Volume" -h string:x-canonical-private-synchronous:volume -h int:value:0 -t 1200 "Volume" "Muted ($VOL_PCT%)"
else
    notify-send -a "Volume" -h string:x-canonical-private-synchronous:volume -h int:value:"$VOL_PCT" -t 1200 "Volume" "${VOL_PCT}%"
fi

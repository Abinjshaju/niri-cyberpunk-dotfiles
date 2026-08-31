#!/usr/bin/env bash

NAME="bluetooth_menu"
PIDFILE="/tmp/rofi_${NAME}.pid"

# Switch / Toggle Behavior:
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    pkill -x rofi
    rm -f "$PIDFILE"
    exit 0
fi

pkill -x rofi 2>/dev/null
sleep 0.02

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

POWERED=$(bluetoothctl show 2>/dev/null | grep -i "Powered:" | awk '{print $2}')
if [ "$POWERED" = "yes" ]; then
    POWER_TOGGLE="󰂲  Turn Bluetooth Off"
else
    POWER_TOGGLE="󰂯  Turn Bluetooth On"
fi

PAIRED_RAW=$(bluetoothctl devices Paired 2>/dev/null)
PAIRED_LIST=""
while read -r _ mac name; do
    [ -z "$mac" ] && continue
    IS_CONN=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Connected:" | awk '{print $2}')
    if [ "$IS_CONN" = "yes" ]; then
        ICON="󰂱"
        STATUS="[Connected]"
    else
        ICON="󰂯"
        STATUS="[Disconnected]"
    fi
    LINE=$(printf "%s  %-30s %s (%s)" "$ICON" "$name" "$STATUS" "$mac")
    PAIRED_LIST="${PAIRED_LIST}${LINE}\n"
done <<< "$PAIRED_RAW"

MENU=$(printf "%s\n%b" "$POWER_TOGGLE" "$PAIRED_LIST")

CHOSEN=$(printf "%b\n" "$MENU" | rofi -dmenu -theme $HOME/.config/niri/rofi/battery-popup.rasi -p "  BLUETOOTH ")

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if echo "$CHOSEN" | grep -iq "Turn Bluetooth Off"; then
    bluetoothctl power off
elif echo "$CHOSEN" | grep -iq "Turn Bluetooth On"; then
    bluetoothctl power on
elif echo "$CHOSEN" | grep -o -E '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}'; then
    MAC=$(echo "$CHOSEN" | grep -o -E '([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}')
    if [ -n "$MAC" ]; then
        IS_CONNECTED=$(bluetoothctl info "$MAC" 2>/dev/null | grep -i "Connected:" | awk '{print $2}')
        if [ "$IS_CONNECTED" = "yes" ]; then
            bluetoothctl disconnect "$MAC"
        else
            bluetoothctl connect "$MAC"
        fi
    fi
fi

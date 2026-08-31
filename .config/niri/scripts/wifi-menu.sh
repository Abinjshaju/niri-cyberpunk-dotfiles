#!/usr/bin/env bash

NAME="wifi_menu"
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

nmcli device wifi rescan >/dev/null 2>&1

RAW_LIST=$(nmcli -t -f "IN-USE,SSID,BARS,SECURITY" dev wifi list 2>/dev/null)

FORMATTED_LIST=""
while IFS=: read -r in_use ssid bars security; do
    [ -z "$ssid" ] && continue
    if [ "$in_use" = "*" ]; then
        ICON="󰄵"
    else
        ICON="󰤨"
    fi
    SEC=""
    [ -n "$security" ] && SEC="[$security]"
    LINE=$(printf "%s  %-25s %s %s" "$ICON" "$ssid" "$bars" "$SEC")
    if ! echo "$FORMATTED_LIST" | grep -Fq "  $ssid "; then
        FORMATTED_LIST="${FORMATTED_LIST}${LINE}\n"
    fi
done <<< "$RAW_LIST"

TOGGLE="󰤮  Toggle Wi-Fi (On/Off)"
MENU=$(printf "%s\n%b" "$TOGGLE" "$FORMATTED_LIST")

CHOSEN=$(printf "%b\n" "$MENU" | rofi -dmenu -theme $HOME/.config/niri/rofi/battery-popup.rasi -p "  WI-FI ")

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if echo "$CHOSEN" | grep -iq "Toggle Wi-Fi"; then
    WIFI_STATUS=$(nmcli -fields WIFI g)
    if echo "$WIFI_STATUS" | grep -q "enabled"; then
        nmcli radio wifi off
    else
        nmcli radio wifi on
    fi
    exit 0
fi

SELECTED_SSID=$(echo "$CHOSEN" | sed -E 's/^[^ ]+[ ]+//' | sed -E 's/[ ]+[ ▂▄▆█_]+.*//' | xargs)

if [ -n "$SELECTED_SSID" ]; then
    if nmcli connection show "$SELECTED_SSID" >/dev/null 2>&1; then
        nmcli connection up "$SELECTED_SSID"
    else
        PASS=$(rofi -dmenu -password -theme $HOME/.config/niri/rofi/battery-popup.rasi -p "  PASSWORD FOR $SELECTED_SSID ")
        if [ -n "$PASS" ]; then
            nmcli device wifi connect "$SELECTED_SSID" password "$PASS"
        fi
    fi
fi

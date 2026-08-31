#!/usr/bin/env bash

NAME="control_center"
PIDFILE="/tmp/rofi_${NAME}.pid"

# Switch / Toggle Behavior:
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    pkill -x rofi
    rm -f "$PIDFILE"
    exit 0
fi

# Close any other active menu
pkill -x rofi 2>/dev/null
sleep 0.02

echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT

set_brightness() {
    local pct=$1
    local max_val
    max_val=$(cat /sys/class/backlight/amdgpu_bl1/max_brightness 2>/dev/null || echo "255")
    local target=$(( pct * max_val / 100 ))
    busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session SetBrightness ssu "backlight" "amdgpu_bl1" "$target" 2>/dev/null
}

show_control_center() {
    WIFI_NAME=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
    if [ -z "$WIFI_NAME" ]; then
        WIFI_STATUS="󰤭  Wi-Fi: Disconnected"
    else
        WIFI_STATUS="󰤨  Wi-Fi: $WIFI_NAME"
    fi

    BT_POWER=$(bluetoothctl show 2>/dev/null | grep -i "Powered:" | awk '{print $2}')
    if [ "$BT_POWER" = "yes" ]; then
        BT_DEV=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | cut -d' ' -f3-)
        if [ -n "$BT_DEV" ]; then
            BT_STATUS="󰂱  Bluetooth: $BT_DEV"
        else
            BT_STATUS="󰂯  Bluetooth: On"
        fi
    else
        BT_STATUS="󰂲  Bluetooth: Off"
    fi

    VOL_NUM=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}')
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED" && echo "yes" || echo "no")
    if [ "$MUTED" = "yes" ]; then
        AUDIO_STATUS="󰝟  Sound: Muted"
    else
        AUDIO_STATUS="󰕾  Sound: ${VOL_NUM}%"
    fi

    BRIGHT_CUR=$(cat /sys/class/backlight/amdgpu_bl1/brightness 2>/dev/null || echo "128")
    BRIGHT_MAX=$(cat /sys/class/backlight/amdgpu_bl1/max_brightness 2>/dev/null || echo "255")
    BRIGHT_PCT=$(( BRIGHT_CUR * 100 / BRIGHT_MAX ))
    DISP_STATUS="󰃠  Display: ${BRIGHT_PCT}%"

    CURRENT_PROF=$(powerprofilesctl get 2>/dev/null || echo "balanced")
    POWER_STATUS="󰓅  Power Mode: ${CURRENT_PROF^}"

    BAT_PCT=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "0")
    BAT_STAT=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo "Discharging")
    BAT_STATUS="󰁹  Battery: ${BAT_PCT}% (${BAT_STAT})"

    DND_STATUS="󰂚  Do Not Disturb: Off"
    if makoctl mode 2>/dev/null | grep -q "dnd"; then
        DND_STATUS="󰂛  Do Not Disturb: On"
    fi

    MENU="--- CONNECTIVITY ---
${WIFI_STATUS}
${BT_STATUS}
--- DISPLAY & SOUND ---
${DISP_STATUS}
${AUDIO_STATUS}
--- POWER & BATTERY ---
${BAT_STATUS}
${POWER_STATUS}
--- FOCUS & SYSTEM ---
${DND_STATUS}
  Lock Screen
󰤄  Sleep (Suspend)
󰗽  Log Out
  Shut Down..."

    SELECTED=$(printf "%b\n" "$MENU" | rofi -dmenu -theme $HOME/.config/niri/rofi/control-center.rasi -p "  CONTROL CENTER ")

    if [ -z "$SELECTED" ]; then
        exit 0
    fi

    case "$SELECTED" in
        *"Wi-Fi:"*)
            $HOME/.config/niri/scripts/wifi-menu.sh
            ;;
        *"Bluetooth:"*)
            $HOME/.config/niri/scripts/bluetooth-menu.sh
            ;;
        *"Display:"*)
            DISP_MENU="󰃠  25%  (Dim)
󰃠  50%  (Medium)
󰃠  75%  (Bright)
󰃠  100% (Maximum)"
            CHOSEN_BRIGHT=$(printf "%b\n" "$DISP_MENU" | rofi -dmenu -theme $HOME/.config/niri/rofi/control-center.rasi -p "  SET BRIGHTNESS ")
            case "$CHOSEN_BRIGHT" in
                *"25%"*)  set_brightness 25 ;;
                *"50%"*)  set_brightness 50 ;;
                *"75%"*)  set_brightness 75 ;;
                *"100%"*) set_brightness 100 ;;
            esac
            show_control_center
            ;;
        *"Sound:"*)
            AUDIO_MENU="󰝟  Toggle Mute
󰕾  Volume 25%
󰕾  Volume 50%
󰕾  Volume 75%
󰕾  Volume 100%"
            CHOSEN_VOL=$(printf "%b\n" "$AUDIO_MENU" | rofi -dmenu -theme $HOME/.config/niri/rofi/control-center.rasi -p "  SET VOLUME ")
            case "$CHOSEN_VOL" in
                *"Toggle Mute"*) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
                *"25%"*) wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null; wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.25 ;;
                *"50%"*) wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null; wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.50 ;;
                *"75%"*) wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null; wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.75 ;;
                *"100%"*) wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null; wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.00 ;;
            esac
            show_control_center
            ;;
        *"Battery:"*)
            $HOME/.config/niri/scripts/battery-popup.sh
            ;;
        *"Power Mode:"*)
            if [ "$CURRENT_PROF" = "power-saver" ]; then
                powerprofilesctl set balanced 2>/dev/null || true
            else
                powerprofilesctl set power-saver 2>/dev/null || true
            fi
            show_control_center
            ;;
        *"Do Not Disturb:"*)
            makoctl mode -t dnd
            show_control_center
            ;;
        *"Lock Screen"*)
            swaylock 2>/dev/null || loginctl lock-session
            ;;
        *"Sleep"*)
            systemctl suspend
            ;;
        *"Log Out"*)
            niri msg action quit --skip-confirmation 2>/dev/null || loginctl terminate-session self
            ;;
        *"Shut Down"*)
            systemctl poweroff
            ;;
    esac
}

show_control_center

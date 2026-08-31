#!/usr/bin/env bash

NAME="battery_popup"
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

BAT_PATH="/sys/class/power_supply/BAT0"
AC_PATH="/sys/class/power_supply/AC"

show_menu() {
    PERCENTAGE=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "0")
    FILLED=$(( (PERCENTAGE + 5) / 10 ))
    EMPTY=$(( 10 - FILLED ))
    BAR=""
    for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
    for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

    STATUS=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")
    AC_ONLINE=$(cat "$AC_PATH/online" 2>/dev/null || echo "0")
    if [ "$AC_ONLINE" -eq 1 ]; then
        POWER_SRC="AC Power"
    else
        POWER_SRC="Battery Power"
    fi

    if [ "$STATUS" = "Charging" ]; then
        STATE_ICON="⚡"
        STATE_TEXT="Charging"
    elif [ "$STATUS" = "Discharging" ]; then
        STATE_ICON="󰁹"
        STATE_TEXT="Discharging"
    elif [ "$STATUS" = "Full" ]; then
        STATE_ICON="󰁹"
        STATE_TEXT="Fully Charged"
    else
        STATE_ICON="󰚥"
        STATE_TEXT="$STATUS"
    fi

    UPOWER_DEV=$(upower -e 2>/dev/null | grep -i 'battery' | head -n1)
    TIME_STR=""
    if [ -n "$UPOWER_DEV" ]; then
        TIME_EMPTY=$(upower -i "$UPOWER_DEV" | grep -E "time to empty" | awk -F: '{print $2}' | xargs)
        TIME_FULL=$(upower -i "$UPOWER_DEV" | grep -E "time to full" | awk -F: '{print $2}' | xargs)
        if [ -n "$TIME_FULL" ]; then
            TIME_STR="$TIME_FULL until full"
        elif [ -n "$TIME_EMPTY" ]; then
            TIME_STR="$TIME_EMPTY remaining"
        elif [ "$STATUS" = "Full" ]; then
            TIME_STR="Battery is fully charged"
        fi
    fi
    [ -z "$TIME_STR" ] && TIME_STR="Estimating..."

    CURRENT_PROFILE=$(powerprofilesctl get 2>/dev/null || echo "balanced")
    case "$CURRENT_PROFILE" in
        "balanced")    ACTIVE_PROF="● Balanced" ;;
        "performance") ACTIVE_PROF="● Performance" ;;
        "power-saver") ACTIVE_PROF="● Power Saver" ;;
        *)             ACTIVE_PROF="● $CURRENT_PROFILE" ;;
    esac

    EFULL=$(cat "$BAT_PATH/energy_full" 2>/dev/null || echo "0")
    EDESIGN=$(cat "$BAT_PATH/energy_full_design" 2>/dev/null || echo "0")
    if [ "$EDESIGN" -gt 0 ]; then
        HEALTH=$(( (EFULL * 100) / EDESIGN ))
        EFULL_WH=$(awk -v e="$EFULL" 'BEGIN { printf "%.1f", e / 1000000 }')
        EDESIGN_WH=$(awk -v e="$EDESIGN" 'BEGIN { printf "%.1f", e / 1000000 }')
        HEALTH_STR="${HEALTH}% (${EFULL_WH} / ${EDESIGN_WH} Wh)"
    else
        HEALTH_STR="N/A"
    fi

    CYCLES=$(cat "$BAT_PATH/cycle_count" 2>/dev/null || echo "N/A")

    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo "0")
    if [ "$TEMP_RAW" -gt 0 ]; then
        TEMP=$(( TEMP_RAW / 1000 ))
        TEMP_STR="${TEMP}°C"
    else
        TEMP_STR="N/A"
    fi

    POWER_NOW=$(cat "$BAT_PATH/power_now" 2>/dev/null || echo "0")
    if [ "$POWER_NOW" -gt 0 ]; then
        WATTAGE=$(awk -v p="$POWER_NOW" 'BEGIN { printf "%.1f W", p / 1000000 }')
    else
        WATTAGE="N/A"
    fi

    CHG_LIMIT=$(cat "$BAT_PATH/charge_control_end_threshold" 2>/dev/null || cat "$BAT_PATH/charge_stop_threshold" 2>/dev/null || echo "100")

    PROF_LINES="   ├─ Switch to Balanced Mode\n   └─ Switch to Power Saver Mode"
    if powerprofilesctl list 2>/dev/null | grep -q "performance"; then
        PROF_LINES="   ├─ Switch to Performance Mode\n   ├─ Switch to Balanced Mode\n   └─ Switch to Power Saver Mode"
    fi

    MENU_OPTIONS="󰁹  Battery Level: ${PERCENTAGE}%  [${BAR}]
${STATE_ICON}  State: ${STATE_TEXT} (${POWER_SRC})
  Estimate: ${TIME_STR}
󰓅  Active Profile: ${ACTIVE_PROF}
$(printf "%b" "$PROF_LINES")
  Battery Health: ${HEALTH_STR}
󰑐  Cycle Count: ${CYCLES}
  Temperature: ${TEMP_STR}
  Power Consumption: ${WATTAGE}
󰢝  Charge Limit: ${CHG_LIMIT}%"

    SELECTED=$(printf "%s\n" "$MENU_OPTIONS" | rofi -dmenu -theme $HOME/.config/niri/rofi/battery-popup.rasi -p "  BATTERY ")

    if [ -z "$SELECTED" ]; then
        exit 0
    fi

    if echo "$SELECTED" | grep -iq "Performance"; then
        powerprofilesctl set performance 2>/dev/null || true
        show_menu
    elif echo "$SELECTED" | grep -iq "Balanced"; then
        powerprofilesctl set balanced 2>/dev/null || true
        show_menu
    elif echo "$SELECTED" | grep -iq "Power Saver"; then
        powerprofilesctl set power-saver 2>/dev/null || true
        show_menu
    fi
}

show_menu

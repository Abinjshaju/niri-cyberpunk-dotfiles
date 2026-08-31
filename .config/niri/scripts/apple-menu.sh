#!/usr/bin/env bash

NAME="apple_menu"
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

UPTIME=$(uptime -p | sed 's/up //')
KERNEL=$(uname -r)
ARCH_INFO="󰣇  About This System (${KERNEL}, up ${UPTIME})"

OPTIONS="${ARCH_INFO}
󰀻  App Launcher (Spotlight)
  Open Terminal (Ghostty)
───────────────────────────────
  Lock Screen
󰤄  Sleep (Suspend)
󰗽  Log Out
󰜉  Restart...
  Shut Down..."

CHOSEN=$(printf "%b\n" "$OPTIONS" | rofi -dmenu -theme $HOME/.config/niri/rofi/battery-popup.rasi -p "  SYSTEM ")

case "$CHOSEN" in
    *"About This System"*)
        notify-send -t 6000 "System Info" "OS: Arch Linux\nKernel: $(uname -r)\nHost: $(hostname)\nUptime: $(uptime -p)"
        ;;
    *"App Launcher"*)
        rofi -show drun -show-icons
        ;;
    *"Open Terminal"*)
        ghostty &
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
    *"Restart"*)
        systemctl reboot
        ;;
    *"Shut Down"*)
        systemctl poweroff
        ;;
esac

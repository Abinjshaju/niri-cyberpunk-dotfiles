#!/usr/bin/env bash

OPTIONS="  Lock Screen
󰤄  Suspend
󰗽  Log Out
󰜉  Reboot
  Power Off"

CHOSEN=$(printf "%s\n" "$OPTIONS" | rofi -dmenu -theme $HOME/.config/niri/rofi/battery-popup.rasi -p "  SESSION ")

case "$CHOSEN" in
    *"Lock Screen"*)
        swaylock 2>/dev/null || loginctl lock-session
        ;;
    *"Suspend"*)
        systemctl suspend
        ;;
    *"Log Out"*)
        niri msg action quit --skip-confirmation 2>/dev/null || loginctl terminate-session self
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Power Off"*)
        systemctl poweroff
        ;;
esac

#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
INTERVAL=900 # 15 minutes (900 seconds)

# Ensure wallpaper directory exists
mkdir -p "$WALLPAPER_DIR"

set_wallpaper() {
    local img="$1"
    [ -f "$img" ] || return 1

    # Keep track of old swaybg PIDs
    local old_pids
    old_pids=$(pgrep -x swaybg || true)

    # Spawn new swaybg instance
    swaybg -i "$img" -m fill &
    local new_pid=$!

    # Wait for the new swaybg to render before killing the old one to avoid flicker
    sleep 0.8

    # Kill previous swaybg instances
    if [ -n "$old_pids" ]; then
        for pid in $old_pids; do
            if [ "$pid" != "$new_pid" ]; then
                kill "$pid" 2>/dev/null || true
            fi
        done
    fi

    # Update cache copy for persistence / reference
    cp "$img" "$HOME/.config/niri/wallpaper.jpg" 2>/dev/null || true
}

# If run with a single manual execution argument (e.g. next wallpaper)
if [ "$1" = "next" ] || [ "$1" = "once" ]; then
    mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.avif" \) | sort)
    if [ ${#WALLPAPERS[@]} -gt 0 ]; then
        RANDOM_IMG="${WALLPAPERS[RANDOM % ${#WALLPAPERS[@]}]}"
        set_wallpaper "$RANDOM_IMG"
    fi
    exit 0
fi

# Ensure only one instance of the cycling daemon runs
PIDFILE="/run/user/$(id -u)/wallpaper-cycle.pid"
if [ -f "$PIDFILE" ]; then
    OTHER_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OTHER_PID" ] && kill -0 "$OTHER_PID" 2>/dev/null && [ "$OTHER_PID" != "$$" ]; then
        kill "$OTHER_PID" 2>/dev/null || true
    fi
fi
echo "$$" > "$PIDFILE"

# Main cycling loop
while true; do
    mapfile -t WALLPAPERS < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.avif" \) | sort)
    
    if [ ${#WALLPAPERS[@]} -eq 0 ]; then
        if [ -f "$HOME/.config/niri/wallpaper.jpg" ]; then
            set_wallpaper "$HOME/.config/niri/wallpaper.jpg"
        fi
        sleep 60
        continue
    fi

    for wp in "${WALLPAPERS[@]}"; do
        set_wallpaper "$wp"
        sleep "$INTERVAL"
    done
done

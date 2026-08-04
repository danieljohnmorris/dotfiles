#!/bin/bash
# Apply a random wallpaper and retheme the system

WALLDIR="$HOME/Pictures/Wallpapers"
WALLPAPER=$(find "$WALLDIR" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) | shuf -n1)

[ -z "$WALLPAPER" ] && exit 1

awww img "$WALLPAPER" \
    --transition-type center \
    --transition-duration 1 \
    --transition-fps 60

matugen --prefer saturation image "$WALLPAPER"

hyprctl reload
pkill -SIGUSR2 waybar
pkill -SIGUSR1 kitty

notify-send "Theme Applied" "$(basename "$WALLPAPER")" -i "$WALLPAPER"

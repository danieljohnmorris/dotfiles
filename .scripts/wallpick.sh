#!/bin/bash
# Wallpaper picker — select a wallpaper via rofi, apply with swww, retheme with matugen

WALLDIR="$HOME/Pictures/Wallpapers"
mkdir -p "$WALLDIR"

# List images and let user pick via rofi
PICK=$(find "$WALLDIR" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' -o -name '*.gif' \) | sort | while read -r img; do
    echo -en "$(basename "$img")\0icon\x1f$img\n"
done | rofi -dmenu -i -p "Wallpaper" -theme-str 'listview { columns: 1; lines: 6; } element-icon { size: 120px; }')

[ -z "$PICK" ] && exit 0

WALLPAPER="$WALLDIR/$PICK"
[ ! -f "$WALLPAPER" ] && exit 1

# Apply wallpaper with awww transition
awww img "$WALLPAPER" \
    --transition-type center \
    --transition-duration 1 \
    --transition-fps 60

# Generate colors with matugen
matugen image "$WALLPAPER"

# Reload configs
hyprctl reload
pkill -SIGUSR2 waybar
pkill -SIGUSR1 kitty

notify-send "Theme Applied" "$(basename "$WALLPAPER")" -i "$WALLPAPER"

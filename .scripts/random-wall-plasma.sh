#!/bin/bash
# Apply a random wallpaper in Plasma and retint via matugen

WALLDIR="$HOME/Pictures/Wallpapers"
WALLPAPER=$(find "$WALLDIR" -maxdepth 1 -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) | shuf -n1)

[ -z "$WALLPAPER" ] && exit 1

plasma-apply-wallpaperimage "$WALLPAPER"
matugen --prefer saturation image "$WALLPAPER"

notify-send "Wallpaper" "$(basename "$WALLPAPER")" -i "$WALLPAPER" 2>/dev/null || true

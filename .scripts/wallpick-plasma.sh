#!/bin/bash
# Plasma wallpaper picker via kdialog; applies wallpaper + retints theme

WALLDIR="$HOME/Pictures/Wallpapers"
WALLPAPER=$(kdialog --title "Wallpaper" --getopenfilename "$WALLDIR" "*.png *.jpg *.jpeg *.webp *.gif")
[ -z "$WALLPAPER" ] && exit 0

plasma-apply-wallpaperimage "$WALLPAPER"
matugen --prefer saturation image "$WALLPAPER"

notify-send "Wallpaper" "$(basename "$WALLPAPER")" -i "$WALLPAPER"

#!/bin/bash
# Install this rice on a fresh Arch system.
# Backs up existing configs, deploys these, then generates colours from a wallpaper.

set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

PKGS=(
    hyprland hypridle hyprlock waybar kitty rofi mako swaync cava
    fastfetch starship btop swww
    wl-clipboard grim slurp brightnessctl playerctl pamixer
    polkit-gnome
    ttf-jetbrains-mono-nerd ttf-cascadia-mono-nerd
)
AUR_PKGS=(matugen-bin)

echo "==> Installing packages"
sudo pacman -S --needed --noconfirm "${PKGS[@]}"

if command -v yay >/dev/null; then
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
elif command -v paru >/dev/null; then
    paru -S --needed --noconfirm "${AUR_PKGS[@]}"
else
    echo "!! No AUR helper found. Install matugen manually: https://github.com/InioX/matugen"
fi

echo "==> Backing up existing configs to $BACKUP"
mkdir -p "$BACKUP"
for cfg in "$DOTDIR"/.config/*; do
    name="$(basename "$cfg")"
    [ -e "$HOME/.config/$name" ] && cp -r "$HOME/.config/$name" "$BACKUP/"
done

echo "==> Deploying configs"
"$DOTDIR/sync.sh" pull

echo "==> Setting up wallpapers"
mkdir -p "$HOME/Pictures/Wallpapers"
if [ -d "$DOTDIR/Wallpapers" ] && [ -n "$(ls -A "$DOTDIR/Wallpapers" 2>/dev/null)" ]; then
    cp -n "$DOTDIR/Wallpapers/"* "$HOME/Pictures/Wallpapers/"
fi

WALL="$(find "$HOME/Pictures/Wallpapers" -maxdepth 1 -type f \
    \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) | head -1)"

if [ -n "$WALL" ] && command -v matugen >/dev/null; then
    echo "==> Generating colours from $WALL"
    matugen image "$WALL"
else
    echo "!! No wallpaper found. Drop images in ~/Pictures/Wallpapers, then run:"
    echo "   matugen image ~/Pictures/Wallpapers/your-image.png"
fi

cat <<'EOF'

Done.

Next:
  1. Edit ~/.config/hypr/monitors.conf for your display (hyprctl monitors)
  2. Log out and pick Hyprland at your display manager, or run `Hyprland` from a TTY
  3. SUPER+SPACE for the launcher, ~/.scripts/wallpick.sh to change the theme
EOF

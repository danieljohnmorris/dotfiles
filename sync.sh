#!/bin/bash
# Sync dotfiles repo <-> system configs
# Usage: ./sync.sh pull  — copy from repo to system (deploy)
#        ./sync.sh push  — copy from system to repo (backup)

set -e

DOTDIR="$(cd "$(dirname "$0")" && pwd)"

CONFIGS=(
    ".config/hypr"
    ".config/waybar"
    ".config/kitty"
    ".config/rofi"
    ".config/cava"
    ".config/matugen"
    ".config/mako"
    ".config/swaync"
    ".config/fastfetch"
    ".config/elephant"
    ".config/walker"
)

# Single files, not directories
FILES=(
    ".config/chromium-flags.conf"
    ".config/kwalletrc"
)

SCRIPTS=".scripts"

case "${1:-pull}" in
    pull)
        echo "Deploying dotfiles to system..."
        for cfg in "${CONFIGS[@]}"; do
            mkdir -p "$HOME/$cfg"
            rsync -av "$DOTDIR/$cfg/" "$HOME/$cfg/"
        done
        for f in "${FILES[@]}"; do
            mkdir -p "$(dirname "$HOME/$f")"
            rsync -av "$DOTDIR/$f" "$HOME/$f"
        done
        mkdir -p "$HOME/.scripts"
        rsync -av "$DOTDIR/$SCRIPTS/" "$HOME/.scripts/"
        chmod +x "$HOME/.scripts/"*.sh
        echo "Done. Run 'hyprctl reload' and restart waybar to apply."
        ;;
    push)
        echo "Backing up system configs to repo..."
        for cfg in "${CONFIGS[@]}"; do
            mkdir -p "$DOTDIR/$cfg"
            rsync -av "$HOME/$cfg/" "$DOTDIR/$cfg/"
        done
        for f in "${FILES[@]}"; do
            mkdir -p "$(dirname "$DOTDIR/$f")"
            rsync -av "$HOME/$f" "$DOTDIR/$f"
        done
        mkdir -p "$DOTDIR/$SCRIPTS"
        rsync -av "$HOME/.scripts/" "$DOTDIR/$SCRIPTS/"
        echo "Done. Commit and push to save."
        ;;
    *)
        echo "Usage: $0 [pull|push]"
        exit 1
        ;;
esac

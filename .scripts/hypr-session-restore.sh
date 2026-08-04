#!/bin/bash
# Relaunch apps recorded by hypr-session-save.sh on the workspaces they were on.
# Uses a class -> exec lookup table. Add entries here for apps you use.

SESSION="$HOME/.cache/hypr-session.json"
[ -f "$SESSION" ] || exit 0

declare -A EXEC=(
    [kitty]="kitty"
    [org.wezfurlong.wezterm]="wezterm"
    [ghostty]="ghostty"
    [Alacritty]="alacritty"
    [firefox]="firefox"
    [Firefox]="firefox"
    [chromium]="chromium"
    [Chromium]="chromium"
    [google-chrome]="google-chrome-stable"
    [Google-chrome]="google-chrome-stable"
    [code]="code"
    [Code]="code"
    [obsidian]="obsidian"
    [obs]="obs"
    [thunderbird]="thunderbird"
    [org.telegram.desktop]="telegram-desktop"
    [Slack]="slack"
    [discord]="discord"
    [spotify]="spotify"
    [org.kde.dolphin]="dolphin"
)

jq -c '.[]' "$SESSION" | while read -r entry; do
    class=$(jq -r '.class' <<<"$entry")
    ws=$(jq -r '.workspace' <<<"$entry")
    cmd="${EXEC[$class]}"
    [ -z "$cmd" ] && { echo "skip: no exec for class '$class'"; continue; }
    hyprctl dispatch exec "[workspace $ws silent] $cmd" >/dev/null
    sleep 0.3
done

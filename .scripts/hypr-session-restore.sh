#!/bin/bash
# Relaunch apps recorded by hypr-session-save.sh on the workspaces they were on.
# Uses a class -> exec lookup table. Add entries here for apps you use.
# Terminals are reopened in their old cwd, and if a resumable program was
# running inside (claude, nvim, ...) it is started again.

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

# Terminals that accept `-e <command>`.
declare -A IS_TERM=(
    [kitty]=1 [ghostty]=1 [Alacritty]=1 [org.wezfurlong.wezterm]=1
)

# Turn a saved command line into the one to resume with.
resume_cmd() {
    local cmd=$1
    case "$cmd" in
        claude*)
            # reattach to the previous conversation instead of starting fresh
            [[ "$cmd" == *--continue* || "$cmd" == *" -c"* ]] || cmd="$cmd --continue"
            ;;
    esac
    printf '%s' "$cmd"
}

jq -c '.[]' "$SESSION" | while read -r entry; do
    class=$(jq -r '.class' <<<"$entry")
    ws=$(jq -r '.workspace' <<<"$entry")
    cwd=$(jq -r '.cwd // ""' <<<"$entry")
    inner=$(jq -r '.cmd // ""' <<<"$entry")
    exe="${EXEC[$class]}"
    [ -z "$exe" ] && { echo "skip: no exec for class '$class'"; continue; }

    launch="$exe"
    if [ -n "${IS_TERM[$class]}" ]; then
        [ -d "$cwd" ] || cwd="$HOME"
        if [ -n "$inner" ]; then
            inner=$(resume_cmd "$inner")
            # keep the shell alive after the program exits so the window stays
            launch="$exe -e bash -lc $(printf '%q' "cd $(printf '%q' "$cwd") && $inner; exec bash")"
        else
            launch="$exe -e bash -lc $(printf '%q' "cd $(printf '%q' "$cwd") && exec bash")"
        fi
    fi

    hyprctl dispatch exec "[workspace $ws silent] $launch" >/dev/null
    sleep 0.3
done

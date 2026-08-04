#!/bin/bash
# Snapshot open Hyprland windows to ~/.cache/hypr-session.json
mkdir -p "$HOME/.cache"
hyprctl clients -j | jq '[.[] | {class, title, workspace: .workspace.name, pid, at, size}]' \
    > "$HOME/.cache/hypr-session.json"

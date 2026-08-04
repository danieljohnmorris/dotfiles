#!/bin/bash
# Save session and log out to the SDDM session picker.
# Works in both Hyprland and Plasma.

if pgrep -x Hyprland >/dev/null; then
    ~/.scripts/hypr-session-save.sh
    hyprctl dispatch exit
elif pgrep -x plasmashell >/dev/null; then
    # Plasma auto-saves session via loginMode=restorePreviousLogout.
    qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null \
        || loginctl terminate-session "$XDG_SESSION_ID"
else
    loginctl terminate-session "$XDG_SESSION_ID"
fi

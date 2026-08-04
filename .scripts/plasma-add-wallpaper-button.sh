#!/bin/bash
# Add the Wallpaper Picker launcher to Plasma's main panel (idempotent).
# Run inside a Plasma session. Safe to re-run.

MARKER="$HOME/.config/plasma-wallpaper-btn.installed"
[ -f "$MARKER" ] && exit 0
command -v qdbus6 >/dev/null || exit 0
pgrep -x plasmashell >/dev/null || exit 0

DESKTOP="$HOME/.local/share/applications/wallpaper-picker.desktop"
[ -f "$DESKTOP" ] || exit 1

qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
var panel = panels()[0];
if (panel) {
    var w = panel.addWidget('org.kde.plasma.quicklaunch');
    w.currentConfigGroup = ['General'];
    w.writeConfig('launcherUrls', ['file://$DESKTOP']);
    w.reloadConfig();
}
" && touch "$MARKER"

#!/bin/bash
# Apply system-level login config. Run with sudo.
# See system/README.md for what this does and why.

set -euo pipefail

[ "$EUID" -eq 0 ] || { echo "Run me with sudo."; exit 1; }

DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP="/root/system-config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

echo "==> Backing up to $BACKUP"
cp /etc/pam.d/sddm "$BACKUP/" 2>/dev/null || true
cp /usr/share/wayland-sessions/*.desktop "$BACKUP/" 2>/dev/null || true
cp /etc/pacman.conf "$BACKUP/" 2>/dev/null || true

echo "==> Session entries (hide the duplicate, rename the real one)"
install -m644 "$DIR/usr/share/wayland-sessions/hyprland.desktop" \
    /usr/share/wayland-sessions/hyprland.desktop
install -m644 "$DIR/usr/share/wayland-sessions/hyprland-uwsm.desktop" \
    /usr/share/wayland-sessions/hyprland-uwsm.desktop

echo "==> Keep the duplicate hidden across package upgrades"
if ! grep -q 'wayland-sessions/hyprland-uwsm.desktop' /etc/pacman.conf; then
    sed -i '/^\[options\]/a NoExtract = usr/share/wayland-sessions/hyprland-uwsm.desktop' /etc/pacman.conf
fi

echo "==> Disable autologin (it raced the greeter and started a second session)"
if [ -f /etc/sddm.conf.d/autologin.conf ]; then
    mv /etc/sddm.conf.d/autologin.conf /etc/sddm.conf.d/autologin.conf.disabled
fi

echo "==> Passwordless login for the nopasswdlogin group"
groupadd -f nopasswdlogin
[ -n "${SUDO_USER:-}" ] && gpasswd -a "$SUDO_USER" nopasswdlogin >/dev/null
install -m644 "$DIR/etc/pam.d/sddm" /etc/pam.d/sddm

echo "==> Passwordless Raspberry Pi Imager"
install -d -m755 /etc/polkit-1/rules.d
install -m644 "$DIR/etc/polkit-1/rules.d/49-rpi-imager.rules" \
    /etc/polkit-1/rules.d/49-rpi-imager.rules

echo "==> Preselect Hyprland at the login screen"
install -m644 -o sddm -g sddm "$DIR/sddm-state.conf" /var/lib/sddm/state.conf

cat <<'EOF'

Done. Reboot to get a login screen with two options and no password:
  Hyprland  |  Plasma (Wayland)

If the login screen misbehaves, switch to a TTY (Ctrl+Alt+F2) and restore
the backup printed above.
EOF

# System-level config

These live outside `$HOME`, so `sync.sh` doesn't touch them. Apply with
`sudo ./system/apply.sh`, or copy by hand.

## What this fixes

**Duplicate login sessions.** SDDM shipped two near-identical Hyprland session
entries (`hyprland.desktop` and `hyprland-uwsm.desktop`). With autologin
enabled for one and SDDM's saved last-session pointing at the other, boot
started *two* Hyprland compositors on different VTs — which fought over the GPU
and froze the machine.

The fix hides the plain entry, disables autologin, and pins the saved session.

## Files

| File | Purpose |
| ---- | ------- |
| `usr/share/wayland-sessions/hyprland.desktop` | `Hidden=true` — removes the duplicate entry |
| `usr/share/wayland-sessions/hyprland-uwsm.desktop` | The session actually used, renamed to just "Hyprland" |
| `etc/pam.d/sddm` | Passwordless login for members of the `nopasswdlogin` group |
| `sddm-state.conf` | Goes to `/var/lib/sddm/state.conf`; preselects Hyprland |

`NoExtract = usr/share/wayland-sessions/hyprland.desktop` is also added to
`/etc/pacman.conf` so the duplicate doesn't come back on a Hyprland upgrade.

## Login screen

Two options, no password:

- **Hyprland** — the rice
- **Plasma (Wayland)** — traditional desktop, draggable windows, desktop icons

## Security note

`etc/pam.d/sddm` grants passwordless login to anyone in the `nopasswdlogin`
group. Convenient on a personal machine; anyone with physical access can log
in as you. To undo, drop the `pam_succeed_if.so` line and remove yourself from
the group.

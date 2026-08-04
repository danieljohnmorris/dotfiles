# System-level config

These live outside `$HOME`, so `sync.sh` doesn't touch them. Apply with
`sudo ./system/apply.sh`, or copy by hand.

## What this fixes

**Duplicate login sessions.** SDDM shipped two near-identical Hyprland session
entries (`hyprland.desktop` and `hyprland-uwsm.desktop`). With autologin
enabled for one and SDDM's saved last-session pointing at the other, boot
started *two* Hyprland compositors on different VTs — which fought over the GPU
and froze the machine.

The first attempt at a fix hid the *plain* entry and kept the uwsm one. That
made things worse: `uwsm` refuses to launch a Desktop Entry marked
`Hidden=true`, so `uwsm start -e -D Hyprland hyprland.desktop` aborted with
`Entry /usr/share/wayland-sessions/hyprland.desktop is hidden` and exited 1
about six seconds in. The only visible Hyprland option was guaranteed to die on
selection. (SDDM honours `Hidden`; uwsm honours it too, but as a refusal.)

The fix now goes the other way: keep the plain entry (`/usr/bin/start-hyprland`,
which works), hide the uwsm wrapper, disable autologin, and pin the saved
session.

## Files

| File | Purpose |
| ---- | ------- |
| `usr/share/wayland-sessions/hyprland.desktop` | The session actually used — plain `start-hyprland`, no uwsm |
| `usr/share/wayland-sessions/hyprland-uwsm.desktop` | `Hidden=true` — removes the duplicate entry |
| `etc/pam.d/sddm` | Passwordless login for members of the `nopasswdlogin` group |
| `sddm-state.conf` | Goes to `/var/lib/sddm/state.conf`; preselects Hyprland |
| `etc/polkit-1/rules.d/49-rpi-imager.rules` | Passwordless Raspberry Pi Imager (ships as `auth_admin_keep`) |

`NoExtract = usr/share/wayland-sessions/hyprland-uwsm.desktop` is also added to
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

## Boot: TPM2 auto-unlock of the root volume

The LUKS2 root (`/dev/nvme0n1p2`) auto-unlocks from the TPM, so there is no
passphrase prompt at boot. The passphrase remains enrolled in keyslot 0 as a
fallback. Reproduce with:

```sh
# 1. enroll a TPM2 keyslot, sealed to PCR 0 (firmware) + 7 (secure boot state)
sudo systemd-cryptenroll /dev/nvme0n1p2 --tpm2-device=auto --tpm2-pcrs=0+7

# 2. the old `encrypt` hook cannot use TPM tokens - switch to the systemd stack
#    /etc/mkinitcpio.conf.d/omarchy_hooks.conf
HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms \
       sd-vconsole block sd-encrypt filesystems fsck btrfs-overlayfs)

# 3. swap the cmdline in /etc/default/limine: cryptdevice=... becomes
#    rd.luks.uuid=<UUID> rd.luks.name=<UUID>=root rd.luks.options=tpm2-device=auto

# 4. rebuild
sudo limine-mkinitcpio && sudo limine-update

# verify without rebooting (exit 0 means the TPM released the key):
sudo cryptsetup open --test-passphrase --token-only /dev/nvme0n1p2
```

A firmware update changes PCR 0 and invalidates the seal — you fall back to the
passphrase, then re-enroll with `--wipe-slot=tpm2`.

Secure Boot is currently **disabled**, which limits how much PCR 7 is worth.
Combined with passwordless login above, a cold machine is effectively
unauthenticated to anyone holding it.

## Login keyring

Autologin/passwordless login means PAM never sees your password, so
`gnome-keyring` cannot unlock `~/.local/share/keyrings/login.keyring` and you
get an "unlock keyring" dialog on the first app that wants a secret. Both
keyrings have been given an empty password so they unlock automatically; the
secrets are then protected only by the LUKS volume.

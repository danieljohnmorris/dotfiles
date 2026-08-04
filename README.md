# dotfiles

Hyprland rice on Arch Linux. Wallpaper-driven theming — pick an image, and Hyprland
borders, Waybar, Kitty, Rofi and SwayNC all re-colour to match via
[matugen](https://github.com/InioX/matugen) (Material You colour extraction).

![screenshot](screenshots/desktop.png)

## What's in here

| Component      | Package        | Config                  |
| -------------- | -------------- | ----------------------- |
| Compositor     | `hyprland`     | `.config/hypr/`         |
| Bar            | `waybar`       | `.config/waybar/`       |
| Terminal       | `kitty`        | `.config/kitty/`        |
| Launcher       | `rofi`         | `.config/rofi/`         |
| Notifications  | `mako`         | `.config/mako/`         |
| Notif. centre  | `swaync`       | `.config/swaync/`       |
| Audio viz      | `cava`         | `.config/cava/`         |
| Colour engine  | `matugen`      | `.config/matugen/`      |
| Fetch          | `fastfetch`    | `.config/fastfetch/`    |
| Lock / idle    | `hyprlock`, `hypridle` | `.config/hypr/` |

Fonts: `ttf-jetbrains-mono-nerd`, `ttf-cascadia-mono-nerd`.

## Install

```sh
git clone https://github.com/danieljohnmorris/dotfiles ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` installs the packages, backs up any existing configs to
`~/.config-backup-<timestamp>/`, copies these in, and generates the colour
files from a wallpaper.

Prefer to do it by hand? `./sync.sh pull` just deploys the configs.

System-level login config (session picker, passwordless SDDM) lives separately
in [`system/`](system/) — see its README, then `sudo ./system/apply.sh`.

## Day-to-day

| Command             | What it does                                            |
| ------------------- | ------------------------------------------------------- |
| `~/.scripts/wallpick.sh`   | Rofi wallpaper picker; re-themes everything      |
| `~/.scripts/random-wall.sh`| Random wallpaper from `~/Pictures/Wallpapers`   |
| `./sync.sh push`    | Copy your live configs back into this repo (then commit) |
| `./sync.sh pull`    | Deploy repo configs onto the system                      |

## Keybinds

A few of the ones you'll want first — all 110 are in
[`.config/hypr/bindings.conf`](.config/hypr/bindings.conf), each with a
description (`bindd`), so `hyprctl binds` prints them readably.

| Key                | Action              |
| ------------------ | ------------------- |
| `SUPER+Return`     | Terminal            |
| `SUPER+Space`      | Launcher            |
| `SUPER+W`          | Close window        |
| `SUPER+1..9`       | Switch workspace    |
| `SUPER+SHIFT+Space`| Toggle Waybar       |

## Notes

- Colour files (`.config/hypr/configs/colors.conf`, `.config/waybar/theme.css`,
  `.config/kitty/theme.conf`, `.config/rofi/colors.rasi`) are **generated** by
  matugen from your wallpaper — they're not tracked. `install.sh` creates them;
  the templates that produce them live in `.config/matugen/templates/`.
- `.config/hypr/monitors.conf` is machine-specific. Edit it for your display —
  run `hyprctl monitors` to see what you've got.
- Wallpapers go in `~/Pictures/Wallpapers`.

## Credit

Take whatever's useful. Colour scheme derives from whatever wallpaper you feed it.

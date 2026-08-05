# Plasma wallpaper + colour theming

**Date:** 2026-08-05
**Project:** dotfiles (KDE Plasma 6 / Wayland side of the rice)
**Type:** bugfix

## Summary

Plasma fell back to default Breeze colours on every boot, and the wallpaper on
screen could disagree with the palette derived from it. Four independent causes,
all fixed. This doc also records how the Plasma theming pipeline is *meant* to
fit together, since the README only covers the Hyprland side.

## The pipeline

One wallpaper writer, one colour watcher. Anything else is a race.

```
login
  └─ .config/autostart/rotate-wallpaper.desktop
       └─ ~/.local/bin/rotate-wallpaper      (boot-once guard via /proc/sys/kernel/random/boot_id)
            ├─ applies the wallpaper staged last boot, via set-wallpaper
            │    └─ matugen → MatugenDynamic.colors → post_hook → plasma-apply-colorscheme
            └─ stages the next wallpaper + syncs it to the SDDM greeter

any later wallpaper change (picker, Plasma settings, script)
  └─ plasma-wallpaper-watch.path  (watches plasma-org.kde.plasma.desktop-appletsrc)
       └─ plasma-watch-wallpaper  → matugen → re-applies the colour scheme
```

The `.path` unit is the self-correcting half: whatever ends up as the wallpaper,
the palette is re-derived from *that* image. It makes the colours converge even
if something sets the wallpaper outside the normal path.

## Root causes

**1. Every colour silently failed to parse.**
`.config/matugen/templates/kde-colorscheme.colors` uses `{{colors.*.default.rgb}}`,
which matugen renders as CSS `rgb(18, 19, 24)`. KConfig only accepts bare
`18,19,24`, so all 102 values failed conversion and Plasma used Breeze defaults:

```
plasma-apply-colorscheme[35323]: "BackgroundNormal" - conversion from "rgb(18, 19, 24)" to QColor failed  (integer conversion failed)
```

matugen offers no comma-separated RGB format and its template engine has no
reliable `replace` filter, so the fix normalises downstream — a `sed` in the
`templates.kde` `post_hook`, which runs before `plasma-apply-colorscheme`.

**2. Three autostart entries raced to set the wallpaper.**
`rotate-wallpaper`, `random-wallpaper` and `plasma-apply-matugen` all fired at
login, each picking a *different* image (staged / random / DankMaterialShell
state) and each re-running matugen. Last writer won, which is why the wallpaper
and the palette could come from different images. Kept `rotate-wallpaper` — it
is the deliberate one, with the boot-once guard and SDDM sync — and dropped the
other two.

**3. `plasma-wallpaper-watch.path` never ran.**
It used `ConditionEnvironment=XDG_CURRENT_DESKTOP=KDE`, but the systemd *user*
manager evaluates conditions before Plasma imports that variable into its
environment, so the unit was skipped on every boot:

```
Watch Plasma wallpaper for changes skipped, unmet condition check ConditionEnvironment=XDG_CURRENT_DESKTOP=KDE
```

Replaced with `WantedBy=plasma-workspace.target` + `PartOf=graphical-session.target`,
which scopes it to a Plasma session without depending on environment import order.

**4. `plasma-matugen.path` was dead from the same bug — left disabled, not revived.**
It triggers `plasma-apply-matugen`, which *also* sets the wallpaper (from
DankMaterialShell's `session.json`). Paired with the watcher in (3) that closes a
feedback loop: wallpaper change → matugen → `.colors` change → apply-matugen sets
a possibly different wallpaper → wallpaper change → … flip-flopping indefinitely.
`plasma-watch-wallpaper` already applies the scheme itself, so the unit is
redundant. **If you ever want it back, first strip the wallpaper-setting half out
of `plasma-apply-matugen` so it only applies colours.**

## Repo gaps closed

The fix would have been undone by `./sync.sh pull`:

- `sync.sh push` rsynced **without `--delete`**, so files removed from the system
  stayed in the repo — the two disabled autostart entries would have been
  redeployed. Added `--delete` to the push path.
- `.local/bin` and `.config/systemd/user` were **not tracked at all**, despite
  `rotate-wallpaper`, `set-wallpaper` and both watchers living there. Added to
  `CONFIGS`.
- `.local/bin/ilo` is an 8MB compiled ELF binary; gitignored so the newly added
  `.local/bin` tracking doesn't drag it in.

## Verification

Full boot path re-run with the boot-once guard cleared:

```sh
rm -f ~/.local/state/rotate-wallpaper.boot_id && ~/.local/bin/rotate-wallpaper
```

Wallpaper applied, matugen regenerated, scheme applied, `0` QColor errors in
`journalctl --user`. `plasma-wallpaper-watch.path` now reports `enabled / active`.

## Related files

- `.config/matugen/config.toml` — `rgb()` normalisation in the kde `post_hook`
- `.config/matugen/templates/kde-colorscheme.colors` — source of the `rgb()` output
- `.config/autostart/rotate-wallpaper.desktop` — the one surviving wallpaper writer
- `.config/systemd/user/plasma-wallpaper-watch.path` — target binding fix
- `.config/systemd/user/plasma-matugen.path` — present but disabled, see (4)
- `.local/bin/rotate-wallpaper`, `set-wallpaper`, `plasma-watch-wallpaper`
- `.local/share/color-schemes/MatugenDynamic.colors` — generated, now valid
- `sync.sh`, `.gitignore`

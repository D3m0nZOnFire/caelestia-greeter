# caelestia-greeter

A [greetd](https://sr.ht/~kennylevinsen/greetd/) login screen that looks like the
[Caelestia](https://github.com/caelestia-dots/shell) lock screen: clock, date, avatar and
password field on your blurred wallpaper, in your current colour scheme.

It runs Quickshell inside a minimal Hyprland session. The greeter reuses Caelestia's own
lock-screen widgets from the installed `caelestia-shell` package, swapping PAM for greetd.

## Requirements

- Arch Linux with `caelestia-shell`, `quickshell` and Hyprland (Lua config, `start-hyprland`)
- `greetd` (installed by the installer)

## Install

```sh
sudo ./install.sh
systemctl --user enable --now caelestia-greeter-sync.path
systemctl --user start caelestia-greeter-sync.service
sudo systemctl disable sddm && sudo systemctl enable greetd   # or whatever DM you use
```

Reboot. Re-run `sudo ./install.sh` after a `caelestia-shell` update to pick up upstream changes.

### Going back

From a TTY (Ctrl+Alt+F2): `sudo systemctl disable greetd && sudo systemctl enable sddm`.

## How it works

| File | Purpose |
| --- | --- |
| `shell.qml`, `modules/greeter/` | Greeter UI. `GreetAuth.qml` mimics Caelestia's `Pam.qml` so the lock widgets work unchanged; without greetd it falls back to a PAM check so you can preview it. |
| `hyprland.lua` | Minimal Hyprland config for the greeter session (monitors, no animations). Exits the compositor when the greeter quits. |
| `sync.sh`, `systemd/` | User path unit that mirrors your scheme, wallpaper, Caelestia config and `~/.face` to `/var/lib/caelestia-greeter-sync`, which the greeter uses as `HOME`. |
| `greetd/config.toml` | greetd config. Gives Hyprland writable cache/state dirs, since the `greeter` user's home is `/`. |
| `install.sh` | Builds `/etc/caelestia-greeter` from the installed Caelestia shell plus this overlay; installs greetd config and PAM (with gnome-keyring unlock). |

## Configuration

Set in `hyprland.lua`:

- Monitors: copy your `hl.monitor` blocks (kept by hand, not synced).
- `CAELESTIA_GREETER_MONITOR`: monitor that shows the login card (others show the wallpaper).
- `CAELESTIA_GREETER_USER`: user to log in (default `ivo`).
- `CAELESTIA_GREETER_SESSION`: session command (default `start-hyprland`).

## Preview without logging out

```sh
CAELESTIA_GREETER_HOME=/var/lib/caelestia-greeter-sync CAELESTIA_GREETER_CACHE=/tmp/cg-cache \
    start-hyprland -- --config /etc/caelestia-greeter/hyprland.lua
```

Opens the installed greeter in a nested Hyprland window. Without greetd the password is
checked against your own account and the session launch is only logged.

## Limitations

- Single user, no session picker.
- No fingerprint / face unlock.

## License

GPL-3.0, as it is derived from Caelestia's shell.

#!/bin/sh
# Mirror the user's Caelestia colours, wallpaper, config and avatar to a place the
# greetd `greeter` user can read. The greeter runs with HOME pointed at $dst.
set -eu

dst=${1:-/var/lib/caelestia-greeter-sync}
state=${XDG_STATE_HOME:-$HOME/.local/state}/caelestia
config=${XDG_CONFIG_HOME:-$HOME/.config}/caelestia

dstate=$dst/.local/state/caelestia
dconfig=$dst/.config/caelestia
mkdir -p "$dstate/wallpaper" "$dconfig"

[ -f "$state/scheme.json" ] && cp -f "$state/scheme.json" "$dstate/scheme.json"

wall=$(cat "$state/wallpaper/path.txt" 2>/dev/null || true)
if [ -n "$wall" ] && [ -f "$wall" ]; then
    out=$dstate/wallpaper/current.${wall##*.}
    rm -f "$dstate"/wallpaper/current.*
    cp -fL "$wall" "$out"
    printf '%s\n' "$out" > "$dstate/wallpaper/path.txt"
fi

[ -f "$config/shell.json" ] && cp -f "$config/shell.json" "$dconfig/shell.json"
if [ -d "$config/monitors" ]; then
    rm -rf "$dconfig/monitors"
    cp -r "$config/monitors" "$dconfig/monitors"
fi

if [ -f "$HOME/.face" ]; then
    cp -fL "$HOME/.face" "$dst/.face"
else
    rm -f "$dst/.face"
fi

chmod -R a+rX "$dst"

#!/bin/sh
# Install the Caelestia greetd greeter. Run with sudo from this directory.
# Does NOT switch display managers; that is done separately (see end of output).
set -eu

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
src=$(cd "$(dirname "$0")" && pwd)
owner=${SUDO_USER:?run via sudo so the sync dir can be owned by your user}

pacman -S --needed --noconfirm greetd

# Greeter files: the installed Caelestia shell, minus its entry point, plus our overlay.
# Re-run after a caelestia-shell update to pick up upstream changes.
base=/etc/xdg/quickshell/caelestia
[ -d "$base" ] || { echo "caelestia-shell not found at $base" >&2; exit 1; }
dst=/etc/caelestia-greeter
rm -rf "$dst"
cp -r "$base" "$dst"
rm -f "$dst/shell.qml"
# The lock widgets type their pam property as Pam; GreetAuth is a duck-typed stand-in
sed -i 's/property Pam pam/property var pam/' "$dst"/modules/lock/*.qml "$dst"/modules/lock/center/*.qml
cp -r "$src/modules/greeter" "$dst/modules/"
install -m 644 "$src/shell.qml" "$src/hyprland.lua" "$dst/"
install -m 755 "$src/sync.sh" "$dst/"
chmod -R a+rX "$dst"

# Theme sync units (enable per user: systemctl --user enable --now caelestia-greeter-sync.path)
install -m 644 "$src"/systemd/caelestia-greeter-sync.* /etc/systemd/user/

# Synced theme (written by the user, read by greeter) and greeter cache
install -d -o "$owner" -g "$owner" -m 755 /var/lib/caelestia-greeter-sync
install -d -o greeter -g greeter -m 755 /var/cache/caelestia-greeter
usermod -aG video,input greeter

# greetd config + PAM (same keyring unlock as SDDM had)
[ -f /etc/greetd/config.toml ] && cp -n /etc/greetd/config.toml /etc/greetd/config.toml.orig
install -m 644 "$src/greetd/config.toml" /etc/greetd/config.toml
[ -f /etc/pam.d/greetd ] && cp -n /etc/pam.d/greetd /etc/pam.d/greetd.orig
cat > /etc/pam.d/greetd <<'EOF'
#%PAM-1.0

auth        include     system-login
-auth       optional    pam_gnome_keyring.so

account     include     system-login

password    include     system-login
-password   optional    pam_gnome_keyring.so    use_authtok

session     optional    pam_keyinit.so          force revoke
session     include     system-login
-session    optional    pam_gnome_keyring.so    auto_start
EOF

echo
echo "Enable the theme sync as your user (once):"
echo "  systemctl --user enable --now caelestia-greeter-sync.path && systemctl --user start caelestia-greeter-sync.service"
echo "Installed. To switch from SDDM to greetd (takes effect on reboot):"
echo "  sudo systemctl disable sddm && sudo systemctl enable greetd"
echo "To go back from a TTY (Ctrl+Alt+F2):"
echo "  sudo systemctl disable greetd && sudo systemctl enable sddm"

#!/bin/bash
# Hard reset all keyboard/XKB settings (system and user)
# WARNING: This will remove all custom layouts and keyboard configs!
set -e

echo "[1/5] Restoring /usr/share/X11/xkb/ to package defaults..."
sudo pacman -S --noconfirm xkeyboard-config

echo "[2/5] Removing system keyboard config files..."
sudo rm -f /etc/default/keyboard
sudo rm -f /etc/X11/xorg.conf.d/00-keyboard.conf

echo "[3/5] Removing user and KDE keyboard configs..."
rm -rf ~/.config/kxkbrc
rm -rf ~/.config/plasma* ~/.config/kglobalshortcutsrc

# GNOME/Cinnamon remnants (safe to run even if not present)
echo "[4/5] Resetting dconf keyboard settings..."
dconf reset -f /org/gnome/desktop/input-sources/ || true
dconf reset -f /org/cinnamon/desktop/input-sources/ || true

echo "[5/5] Done. Please reboot your system now."

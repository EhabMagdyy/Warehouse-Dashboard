#!/usr/bin/env bash
# Linux only: registers the app icon with the desktop (needed on Wayland / GNOME,
# where the taskbar icon comes from a .desktop file, not from the program).
# Usage: scripts/install-linux-icon.sh /path/to/appWarehouseDashboard
set -e
EXE="$(realpath "${1:?usage: $0 /path/to/appWarehouseDashboard}")"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor/256x256/apps"

mkdir -p "$APPS" "$ICONS"
cp "$HERE/assets/icons/app.png" "$ICONS/WarehouseDashboard.png"

cat > "$APPS/WarehouseDashboard.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Warehouse Dashboard
Exec=$EXE
Icon=WarehouseDashboard
Terminal=false
Categories=Office;
StartupWMClass=appWarehouseDashboard
DESKTOP

update-desktop-database "$APPS" 2>/dev/null || true
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
echo "Done. Restart the app (log out/in if the icon still doesn't show)."

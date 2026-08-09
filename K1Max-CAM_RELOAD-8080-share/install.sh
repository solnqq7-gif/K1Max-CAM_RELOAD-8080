#!/bin/sh

set -u
umask 022

PACKAGE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_DIR=/usr/data/printer_data/config
STATE_DIR=/usr/data/camera-reload-backups
STAMP=$(date '+%Y%m%d-%H%M%S')
BACKUP_DIR="$STATE_DIR/$STAMP"
ENABLE_AUTOSTART=0

if [ "${1:-}" = "--autostart" ]; then
  ENABLE_AUTOSTART=1
elif [ "$#" -gt 0 ]; then
  echo "Usage: sh install.sh [--autostart]" >&2
  exit 2
fi

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[ "$(id -u)" = "0" ] || die "Run this installer as root."
[ -f "$PACKAGE_DIR/cam_reload.sh" ] || die "cam_reload.sh is missing."
[ -f "$PACKAGE_DIR/camera_reload.cfg" ] || die "camera_reload.cfg is missing."
[ -d "$CONFIG_DIR" ] || die "$CONFIG_DIR was not found."
[ -f "$CONFIG_DIR/printer.cfg" ] || die "printer.cfg was not found."
[ -f /usr/share/klipper/klippy/extras/gcode_shell_command.py ] || \
  die "gcode_shell_command is not installed. Install the K1 Helper Script component first."
[ -x /usr/bin/mjpg_streamer ] || die "/usr/bin/mjpg_streamer was not found."
[ -f /usr/lib/mjpg-streamer/input_memfd.so ] || die "Factory input_memfd.so was not found."

if command -v wget >/dev/null 2>&1; then
  PRINT_INFO=$(wget -q -T 3 -O - 'http://127.0.0.1:7125/printer/objects/query?print_stats' 2>/dev/null || true)
  case "$PRINT_INFO" in
    *'"state":"printing"'*|*'"state": "printing"'*|*'"state":"paused"'*|*'"state": "paused"'*)
      die "The printer is printing or paused. Finish or cancel the job before installing."
      ;;
  esac
fi

mkdir -p "$BACKUP_DIR" || die "Could not create $BACKUP_DIR."
for file in /usr/data/cam_reload.sh "$CONFIG_DIR/camera_reload.cfg" "$CONFIG_DIR/camera_reload_autostart.cfg" "$CONFIG_DIR/printer.cfg"; do
  if [ -e "$file" ]; then
    cp -a "$file" "$BACKUP_DIR/" || die "Could not back up $file."
  fi
done

cp "$PACKAGE_DIR/cam_reload.sh" /usr/data/cam_reload.sh || die "Could not install cam_reload.sh."
chmod 0755 /usr/data/cam_reload.sh || die "Could not make cam_reload.sh executable."
cp "$PACKAGE_DIR/camera_reload.cfg" "$CONFIG_DIR/camera_reload.cfg" || die "Could not install camera_reload.cfg."

if ! grep -Eq '^\[include[[:space:]]+camera_reload\.cfg\][[:space:]]*$' "$CONFIG_DIR/printer.cfg"; then
  printf '\n[include camera_reload.cfg]\n' >> "$CONFIG_DIR/printer.cfg" || die "Could not update printer.cfg."
fi

if [ "$ENABLE_AUTOSTART" -eq 1 ]; then
  cp "$PACKAGE_DIR/camera_reload_autostart.cfg" "$CONFIG_DIR/camera_reload_autostart.cfg" || \
    die "Could not install the optional autostart config."
  if ! grep -Eq '^\[include[[:space:]]+camera_reload_autostart\.cfg\][[:space:]]*$' "$CONFIG_DIR/printer.cfg"; then
    printf '[include camera_reload_autostart.cfg]\n' >> "$CONFIG_DIR/printer.cfg" || die "Could not enable autostart."
  fi
fi

echo "Installation files are ready."
echo "Backup: $BACKUP_DIR"
echo "In Mainsail, run FIRMWARE_RESTART, then run CAM_RELOAD."
if [ "$ENABLE_AUTOSTART" -eq 1 ]; then
  echo "Automatic camera restart is enabled with a 20-second boot delay."
else
  echo "Automatic camera restart is not enabled."
fi

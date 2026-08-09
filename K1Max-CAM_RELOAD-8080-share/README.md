# K1 Max Factory Camera MJPEG Port 8080 Reload Tool

This package restores the factory-camera MJPEG stream on a rooted Creality K1 Max. It has been tested with firmware `1.3.5.22`.

It only manages the factory camera on port `8080`. It does not stop or modify an additional USB camera using port `8081`.

For Traditional Chinese instructions, see [`繁中README.md`](繁中README.md).

## Package contents

- `cam_reload.sh`: Starts `cam_app`, recreates the MJPEG stream on port `8080`, and verifies a snapshot.
- `camera_reload.cfg`: Adds the `CAM_RELOAD` command to Klipper and Mainsail.
- `camera_reload_autostart.cfg`: Optional configuration that runs `CAM_RELOAD` 20 seconds after Klipper starts.
- `install.sh`: Checks the required components, backs up existing files, and installs the package.

## Requirements

- A Creality K1 Max with root and SSH access enabled.
- The `gcode_shell_command` Klipper extension, normally installed through the K1 Helper Script.
- The factory `/usr/bin/cam_app`, `/usr/bin/mjpg_streamer`, and `input_memfd.so` files must still be present.
- Do not install while the printer is printing or paused.

## Upload and installation

Replace `PRINTER_IP` with the printer's IP address. Current Windows OpenSSH versions require `scp -O` because some K1 firmware versions do not provide an SFTP server.

```powershell
scp -O -r K1Max-CAM_RELOAD-8080-share root@PRINTER_IP:/usr/data/
ssh root@PRINTER_IP
```

Install the manual `CAM_RELOAD` command only:

```sh
cd /usr/data/K1Max-CAM_RELOAD-8080-share
sh install.sh
```

Install it and automatically restore the camera after each boot:

```sh
cd /usr/data/K1Max-CAM_RELOAD-8080-share
sh install.sh --autostart
```

After installation, run these commands in Mainsail:

```gcode
FIRMWARE_RESTART
CAM_RELOAD
```

## Testing

Snapshot URL:

```text
http://PRINTER_IP:8080/?action=snapshot
```

MJPEG stream URL:

```text
http://PRINTER_IP:8080/?action=stream
```

Test from an SSH session:

```sh
wget -O /tmp/camera-test.jpg 'http://127.0.0.1:8080/?action=snapshot'
ls -lh /tmp/camera-test.jpg
```

## Logs and troubleshooting

```sh
cat /tmp/cam_reload_single.log
tail -40 /tmp/factory_mjpg.log
netstat -ltn | grep ':8080'
ps | grep -E 'cam_app|mjpg_streamer' | grep -v grep
```

If Klipper reports that `CAM_RELOAD` is unknown, confirm that:

1. `printer.cfg` contains `[include camera_reload.cfg]`.
2. `gcode_shell_command.py` is installed.
3. You ran `FIRMWARE_RESTART` after changing the configuration.

The installer stores copies of replaced files under:

```text
/usr/data/camera-reload-backups/date-and-time/
```

## Before sharing

This package does not contain printer passwords, IP addresses, SSH host keys, serial numbers, or personal configuration. Share the complete folder or ZIP file and remind users to back up their own `printer.cfg` before installing.

# K1 Max Factory Camera Port 8080 Reload Tool

## Installation, Operation, and Verification Guide

This tool restores the factory-camera MJPEG stream on port `8080` of a rooted Creality K1 Max. It has been tested with firmware `1.3.5.22`.

> The tool only manages the factory camera on port `8080`. It does not stop or modify an additional USB camera using port `8081`.

## 1. Requirements and Safety Checks

Before starting, confirm all of the following:

- The printer is a Creality K1 Max with root and SSH access enabled.
- You know the printer's root password.
- The computer and printer are connected to the same local network.
- The `gcode_shell_command` Klipper extension has been installed, normally through the K1 Helper Script.
- The printer is idle. Do not install or reload the camera while a print is running or paused.
- The factory camera components have not been removed.

The installer creates a backup before modifying the Klipper configuration.

## 2. Download and Extract the Package

1. Open the project page:
   <https://github.com/solnqq7-gif/K1Max-CAM_RELOAD-8080>
2. Select **Code** and then **Download ZIP**.
3. Extract the ZIP file.
4. Rename the extracted folder to:

   ```text
   K1Max-CAM_RELOAD-8080-share
   ```

5. Open the folder and confirm that it contains at least:

   ```text
   install.sh
   cam_reload.sh
   camera_reload.cfg
   camera_reload_autostart.cfg
   ```

## 3. Find the Printer IP Address

Find the IP address in the K1 Max network settings or in the router's connected-device list.

This guide uses `192.168.1.50` as an example. Replace it with the actual printer IP address in every command.

## 4. Connect and Upload with MobaXterm

### 4.1 Create the SSH Session

1. Open MobaXterm.
2. Select **Session** and then **SSH**.
3. Enter the K1 Max IP address under **Remote host**.
4. Enable **Specify username** and enter `root`.
5. Keep the port set to `22`.
6. In the advanced SSH session settings, set **SSH-browser type** to **SCP (normal speed)**.
7. Select **OK** to connect.
8. Accept the SSH host key when prompted.
9. Enter the K1 Max root password.

Some K1 firmware versions do not provide an SFTP server. Selecting the legacy-compatible **SCP (normal speed)** mode prevents the graphical SSH browser from depending on SFTP.

### 4.2 Check the SSH Login and Required Components

Run:

```sh
id -u
```

Expected result:

```text
0
```

Then check the required files:

```sh
ls -l /usr/bin/cam_app
ls -l /usr/bin/mjpg_streamer
ls -l /usr/lib/mjpg-streamer/input_memfd.so
ls -l /usr/share/klipper/klippy/extras/gcode_shell_command.py
```

Each command should display a file. If any command reports `No such file or directory`, stop and restore or install that required component before continuing.

### 4.3 Upload the Folder

1. In the MobaXterm SSH browser on the left, open:

   ```text
   /usr/data
   ```

2. From Windows File Explorer, drag the inner `K1Max-CAM_RELOAD-8080-share` folder into `/usr/data`.
3. Wait until the transfer is complete.

### 4.4 Verify the Upload

Run in the MobaXterm terminal:

```sh
ls -l /usr/data/K1Max-CAM_RELOAD-8080-share
```

Confirm that `install.sh`, `cam_reload.sh`, `camera_reload.cfg`, and `camera_reload_autostart.cfg` are listed.

## 5. PowerShell Upload Alternative

Skip this section if the package was uploaded with MobaXterm.

Open PowerShell in the parent folder containing `K1Max-CAM_RELOAD-8080-share`, and run:

```powershell
scp -O -r ".\K1Max-CAM_RELOAD-8080-share" root@192.168.1.50:/usr/data/
ssh root@192.168.1.50
```

The `-O` option is an uppercase letter O. It forces the legacy SCP protocol required by some K1 firmware versions that do not provide an SFTP server.

After logging in, verify the upload:

```sh
ls -l /usr/data/K1Max-CAM_RELOAD-8080-share
```

## 6. Install the Tool

Choose one installation mode.

### Option A: Manual Camera Reload Only

Use this mode if the camera should only be restarted when `CAM_RELOAD` is entered manually:

```sh
cd /usr/data/K1Max-CAM_RELOAD-8080-share
sh install.sh
```

### Option B: Automatic Reload After Startup

This is the recommended mode when the factory-camera stream often fails after startup. Klipper waits 20 seconds and then runs `CAM_RELOAD` automatically:

```sh
cd /usr/data/K1Max-CAM_RELOAD-8080-share
sh install.sh --autostart
```

Expected successful output includes:

```text
Installation files are ready.
Backup: /usr/data/camera-reload-backups/date-and-time
```

The backup directory contains copies of the configuration files that existed before installation.

## 7. Verify the Installed Files and Configuration

Run:

```sh
ls -l /usr/data/cam_reload.sh
ls -l /usr/data/printer_data/config/camera_reload.cfg
grep -n 'camera_reload' /usr/data/printer_data/config/printer.cfg
```

The last command should show:

```ini
[include camera_reload.cfg]
```

If automatic startup was selected, also run:

```sh
ls -l /usr/data/printer_data/config/camera_reload_autostart.cfg
grep -n 'camera_reload_autostart' /usr/data/printer_data/config/printer.cfg
```

The second command should show:

```ini
[include camera_reload_autostart.cfg]
```

## 8. Activate and Run the Tool

1. Open the K1 Max Mainsail interface.
2. Open **Console**.
3. Run:

   ```gcode
   FIRMWARE_RESTART
   ```

4. Wait until Klipper reconnects.
5. Run:

   ```gcode
   CAM_RELOAD
   ```

6. Allow approximately 10 seconds for the camera service and MJPEG stream to restart.

## 9. Verify the Camera Reload

### 9.1 Check the Reload Log

In SSH, run:

```sh
cat /tmp/cam_reload_single.log
```

A successful run ends with a line similar to:

```text
Snapshot OK: 123456 bytes
```

The byte count will vary. Any non-zero value indicates that a snapshot was created.

### 9.2 Check Port 8080

Run:

```sh
netstat -ltn | grep ':8080'
```

Expected result: a listening TCP entry for port `8080`.

### 9.3 Check the Camera Processes

Run:

```sh
ps | grep -E 'cam_app|mjpg_streamer' | grep -v grep
```

Expected result: both `cam_app` and the port-`8080` `mjpg_streamer` process are listed.

### 9.4 Test a Snapshot from the Printer

Run:

```sh
wget -O /tmp/camera-test.jpg 'http://127.0.0.1:8080/?action=snapshot'
ls -lh /tmp/camera-test.jpg
```

Expected result: `/tmp/camera-test.jpg` exists and its size is greater than `0` bytes.

### 9.5 Test from a Web Browser

Replace the example IP address with the printer IP.

Snapshot:

```text
http://192.168.1.50:8080/?action=snapshot
```

MJPEG stream:

```text
http://192.168.1.50:8080/?action=stream
```

If an image or live stream appears, the installation and camera reload are working.

## 10. Verify Automatic Startup

Perform this check only if the tool was installed with `--autostart`.

1. Restart Klipper or reboot the printer while it is idle.
2. Wait at least 30 seconds after Klipper starts.
3. Check the reload log:

   ```sh
   cat /tmp/cam_reload_single.log
   ```

4. Confirm that the log header contains the current startup time and that the final result is `Snapshot OK`.
5. Open the browser stream URL again and confirm that the image is available without manually entering `CAM_RELOAD`.

## 11. Normal Daily Operation

If the factory camera becomes unavailable or the port-`8080` stream shows a black screen:

1. Confirm that the printer is not printing or paused.
2. Open the Mainsail **Console**.
3. Run:

   ```gcode
   CAM_RELOAD
   ```

4. Wait approximately 10 seconds.
5. Refresh the camera page and confirm the result with the snapshot URL if necessary.

## 12. Troubleshooting

### `Unknown command: CAM_RELOAD`

Run `FIRMWARE_RESTART` in Mainsail. If the command is still unavailable, check:

```sh
grep -n 'camera_reload' /usr/data/printer_data/config/printer.cfg
ls -l /usr/data/printer_data/config/camera_reload.cfg
ls -l /usr/share/klipper/klippy/extras/gcode_shell_command.py
```

### No Image After `CAM_RELOAD`

Collect the following information:

```sh
cat /tmp/cam_reload_single.log
tail -40 /tmp/factory_mjpg.log
netstat -ltn | grep ':8080'
ps | grep -E 'cam_app|mjpg_streamer' | grep -v grep
```

Look for an error in the logs, a missing process, or no listening entry on port `8080`.

### MobaXterm SSH Browser Does Not Open

Edit the saved SSH session and confirm that **SSH-browser type** is set to **SCP (normal speed)** instead of SFTP. Reconnect after saving the setting.

### Installer Reports That the Printer Is Printing or Paused

Finish or cancel the current job. Confirm that the printer is idle, then run the installer again.

## 13. Disable Automatic Camera Reload

In the Mainsail configuration editor, open `printer.cfg` and remove:

```ini
[include camera_reload_autostart.cfg]
```

Save the file and run:

```gcode
FIRMWARE_RESTART
```

This disables automatic startup only. The manual `CAM_RELOAD` command remains available.

## Important Notes

- Do not install or reload the camera while the printer is printing or paused.
- Port `8081`, commonly used by an additional USB camera, is not modified.
- The confirmed test firmware is `1.3.5.22`. On other firmware versions, verify that the required factory camera files are still present.
- Do not share the printer root password, local IP address, SSH host keys, serial number, or personal configuration files.

# K1 Max 原廠相機 MJPEG 8080 重啟工具

這個分享包可在已取得 root 權限的 Creality K1 Max 上，重新啟動原廠相機的 MJPEG 串流。已在韌體 `1.3.5.22` 測試。

它只處理原廠相機的 `8080`，不會停止或修改使用 `8081` 的額外 USB 攝影機。

## 內容

- `cam_reload.sh`：啟動 `cam_app`，重新建立 `8080` 的 `mjpg_streamer`，並測試快照。
- `camera_reload.cfg`：提供 Mainsail／Klipper 指令 `CAM_RELOAD`。
- `camera_reload_autostart.cfg`：可選；Klipper 啟動 20 秒後自動執行 `CAM_RELOAD`。
- `install.sh`：檢查依賴、備份現有檔案並安裝。

## 需求

- Creality K1 Max，已開啟 root／SSH。
- 已安裝 K1 Helper Script 提供的 `gcode_shell_command`。
- 印表機內仍有原廠 `/usr/bin/cam_app`、`/usr/bin/mjpg_streamer` 與 `input_memfd.so`。
- 安裝時不可正在列印或暫停列印。

## 上傳與安裝

將 `PRINTER_IP` 換成印表機 IP。新版 Windows OpenSSH 必須使用 `scp -O`，因為部分 K1 韌體沒有 SFTP server。

```powershell
scp -O -r K1Max-CAM_RELOAD-8080-share root@PRINTER_IP:/usr/data/
ssh root@PRINTER_IP
```

只安裝手動 `CAM_RELOAD`：

```sh
cd /usr/data/K1Max-CAM_RELOAD-8080-share
sh install.sh
```

同時啟用每次開機自動重啟相機：

```sh
cd /usr/data/K1Max-CAM_RELOAD-8080-share
sh install.sh --autostart
```

安裝後在 Mainsail 執行：

```gcode
FIRMWARE_RESTART
CAM_RELOAD
```

## 測試

瀏覽器快照：

```text
http://PRINTER_IP:8080/?action=snapshot
```

MJPEG 串流：

```text
http://PRINTER_IP:8080/?action=stream
```

SSH 內測試：

```sh
wget -O /tmp/camera-test.jpg 'http://127.0.0.1:8080/?action=snapshot'
ls -lh /tmp/camera-test.jpg
```

## 紀錄與疑難排解

```sh
cat /tmp/cam_reload_single.log
tail -40 /tmp/factory_mjpg.log
netstat -ltn | grep ':8080'
ps | grep -E 'cam_app|mjpg_streamer' | grep -v grep
```

如果 `CAM_RELOAD` 顯示未知指令，請確認：

1. `printer.cfg` 包含 `[include camera_reload.cfg]`。
2. `gcode_shell_command.py` 已安裝。
3. 修改設定後已執行 `FIRMWARE_RESTART`。

安裝器會將修改前的檔案備份到：

```text
/usr/data/camera-reload-backups/日期時間/
```

## 分享前注意

此資料夾不包含印表機密碼、IP、SSH host key、序號或個人設定。分享時請整個資料夾或 ZIP 一起提供，並提醒使用者先備份自己的 `printer.cfg`。

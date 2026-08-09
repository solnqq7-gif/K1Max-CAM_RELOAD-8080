#!/bin/sh
LOG="/tmp/cam_reload_single.log"
PORT="8080"
SNAP="/tmp/cam_reload_single_snapshot.jpg"

log() {
  echo "$*" >> "$LOG"
}

find_mjpg_on_port() {
  for p in $(pidof mjpg_streamer 2>/dev/null); do
    cmd="$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)"
    case "$cmd" in
      *"-p $PORT"*) echo "$p" ;;
    esac
  done
}

{
  echo "===== CAM_RELOAD single factory camera $(date) ====="
  echo "Mode: factory single camera only; port $PORT; USB/8081 untouched."

  if ! pidof cam_app >/dev/null 2>&1; then
    echo "cam_app missing; starting it"
    /usr/bin/cam_app >/tmp/cam_app_single_restore.log 2>&1 &
    sleep 3
  else
    echo "cam_app already running: $(pidof cam_app 2>/dev/null)"
  fi

  for p in $(find_mjpg_on_port); do
    cmd="$(tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null)"
    echo "Stopping mjpg_streamer on port $PORT: pid=$p cmd=$cmd"
    kill "$p" 2>/dev/null || true
  done
  sleep 2

  export LD_LIBRARY_PATH="/usr/lib:/usr/lib/mjpg-streamer:${LD_LIBRARY_PATH:-}"
  echo "Starting factory input_memfd stream on $PORT"
  /usr/bin/mjpg_streamer \
    -i "/usr/lib/mjpg-streamer/input_memfd.so -t 0" \
    -o "/usr/lib/mjpg-streamer/output_http.so -w /usr/share/mjpg-streamer/www/ -p $PORT" \
    >/tmp/factory_mjpg.log 2>&1 &
  sleep 3

  echo "Processes:"
  ps | grep -Ei 'cam_app|cx_ai|mjpg|webrtc|nginx' | grep -v grep || true

  echo "Ports:"
  netstat -ltn 2>/dev/null | grep -E ':8080|:8081|:4409' || true

  rm -f "$SNAP"
  wget -q -T 5 -O "$SNAP" "http://127.0.0.1:$PORT/?action=snapshot" 2>/dev/null || true
  if [ -s "$SNAP" ]; then
    echo "Snapshot OK: $(wc -c < "$SNAP") bytes"
    exit 0
  fi

  echo "ERROR: snapshot failed or empty"
  tail -40 /tmp/factory_mjpg.log 2>/dev/null || true
  exit 1
} > "$LOG" 2>&1

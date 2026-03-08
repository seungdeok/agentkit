#!/bin/bash
# android-setup.sh — ADB port forward for all connected devices and list WebView targets
# stdout: JSON { devices:[{id,model,android,localPort,targets:[{index,url,title,ws}]}], allTargets:[...] }
# stderr: human-readable progress

set -e

BASE_PORT=9230  # 9230+ to avoid collision with iOS proxy ports (9221–9229)

echo "=== Android WebView Setup ===" >&2

which adb >/dev/null 2>&1 || {
  echo "✗ ADB not found." >&2
  echo "  macOS: brew install android-platform-tools" >&2
  echo "  Linux: sudo apt install adb" >&2
  exit 1
}

DEVICES=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}')
DEV_COUNT=$(echo "$DEVICES" | grep -c '\S' 2>/dev/null || echo 0)

if [ "$DEV_COUNT" -eq 0 ] || [ -z "$DEVICES" ]; then
  echo "✗ No ADB devices found." >&2
  echo "  Emulator: \$ANDROID_HOME/emulator/emulator -avd <AVD_NAME>" >&2
  echo "  Real device: enable USB debugging → adb devices" >&2
  exit 1
fi

echo "$DEV_COUNT device(s) found" >&2

DEV_RESULTS="[]"
target_idx=1
idx=0

for DEVICE in $DEVICES; do
  PORT=$((BASE_PORT + idx))
  MODEL=$(adb -s "$DEVICE" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "unknown")
  ANDROID_VER=$(adb -s "$DEVICE" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || echo "?")

  echo "" >&2
  echo "  [$MODEL — Android $ANDROID_VER — $DEVICE → :$PORT]" >&2

  # Re-forward (remove old binding first to avoid stale state)
  adb -s "$DEVICE" forward --remove tcp:$PORT 2>/dev/null || true
  adb -s "$DEVICE" forward tcp:$PORT localabstract:chrome_devtools_remote 2>/dev/null \
    && echo "  Port forward: :$PORT → WebView debugger" >&2

  sleep 1

  BIND_HOST=""
  for host in localhost 127.0.0.1; do
    if curl -s --connect-timeout 2 "http://$host:$PORT/json" >/dev/null 2>&1; then
      BIND_HOST=$host
      break
    fi
  done

  if [ -z "$BIND_HOST" ]; then
    echo "  · No WebView response on :$PORT" >&2
    echo "    → App must be a DEBUG build with WebView.setWebContentsDebuggingEnabled(true)" >&2
    echo "    → WebView must be visible on screen" >&2
    echo "    → Custom socket? Check: adb -s $DEVICE shell cat /proc/net/unix | grep devtools" >&2
    TARGETS_FOR_DEV="[]"
  else
    RAW=$(curl -s "http://$BIND_HOST:$PORT/json" 2>/dev/null || echo "[]")
    TARGETS_FOR_DEV=$(echo "$RAW" | python3 -c "
import sys, json
raw = json.load(sys.stdin)
out = []
for t in raw:
    if t.get('webSocketDebuggerUrl'):
        out.append({
            'id': t.get('id',''),
            'url': t.get('url',''),
            'title': t.get('title',''),
            'ws': t.get('webSocketDebuggerUrl','')
        })
print(json.dumps(out))
" 2>/dev/null || echo "[]")
    n=$(echo "$TARGETS_FOR_DEV" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
    echo "  ✓ $n WebView(s) found" >&2
    echo "$TARGETS_FOR_DEV" | python3 -c "
import sys, json, os
targets = json.load(sys.stdin)
start = int(os.environ.get('TARGET_IDX', 1))
for i, t in enumerate(targets, start):
    print(f'    [{i}] {t[\"url\"]}  ({t[\"title\"]})')
" TARGET_IDX=$target_idx >&2
    target_idx=$(echo "$TARGETS_FOR_DEV" | python3 -c "import sys,json; print($target_idx + len(json.load(sys.stdin)))")
  fi

  DEV_RESULTS=$(python3 -c "
import json, sys
lst = json.loads(sys.argv[1])
lst.append({
    'id': sys.argv[2],
    'model': sys.argv[3],
    'android': sys.argv[4],
    'localPort': int(sys.argv[5]),
    'targets': json.loads(sys.argv[6])
})
print(json.dumps(lst))
" "$DEV_RESULTS" "$DEVICE" "$MODEL" "$ANDROID_VER" "$PORT" "$TARGETS_FOR_DEV")

  idx=$((idx + 1))
done

echo "" >&2

# Build flat indexed allTargets list
ALL_TARGETS=$(python3 -c "
import json, sys
devs = json.loads(sys.argv[1])
all_t = []
idx = 1
for dev in devs:
    for t in dev['targets']:
        all_t.append({
            'index': idx,
            'type': 'android',
            'device': dev['model'],
            'port': dev['localPort'],
            'url': t['url'],
            'title': t['title'],
            'ws': t['ws']
        })
        idx += 1
print(json.dumps(all_t))
" "$DEV_RESULTS")

python3 -c "
import json, sys
print(json.dumps({
    'devices': json.loads(sys.argv[1]),
    'allTargets': json.loads(sys.argv[2])
}, indent=2))
" "$DEV_RESULTS" "$ALL_TARGETS"

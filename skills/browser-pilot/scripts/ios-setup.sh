#!/bin/bash
# ios-setup.sh — Start ios-webkit-debug-proxy for all booted simulators
#                and list all inspectable WebViews across all devices
# stdout: JSON { simulators:[{udid,name,proxyPort,targets:[{index,url,title,ws}]}], allTargets:[...] }
# stderr: human-readable progress

set -e

BASE_PORT=9221

echo "=== iOS WebView Setup ===" >&2

which xcrun >/dev/null 2>&1 || { echo "✗ xcrun not found. Run: xcode-select --install" >&2; exit 1; }
which ios-webkit-debug-proxy >/dev/null 2>&1 || {
  echo "✗ ios-webkit-debug-proxy not found. Run: brew install ios-webkit-debug-proxy" >&2; exit 1;
}

# Get all booted simulators as TSV: udid<TAB>name
SIMS=$(xcrun simctl list devices -j 2>/dev/null | python3 -c "
import sys, json
for devs in json.load(sys.stdin).get('devices', {}).values():
    for d in devs:
        if d.get('state') == 'Booted':
            print(d['udid'] + '\t' + d['name'])
" 2>/dev/null || true)

SIM_COUNT=$(echo "$SIMS" | grep -c '\S' 2>/dev/null || echo 0)

if [ "$SIM_COUNT" -eq 0 ]; then
  echo "✗ No booted simulator." >&2
  echo "  Available simulators:" >&2
  xcrun simctl list devices available 2>/dev/null | grep "iPhone" | head -6 >&2
  echo "  Boot one: xcrun simctl boot \"iPhone 15 Pro\" && open -a Simulator" >&2
  exit 1
fi

echo "$SIM_COUNT simulator(s) booted" >&2

# Build proxy config: "UDID1:9221,UDID2:9222,..."
PROXY_CONFIG=""
idx=0
while IFS=$'\t' read -r udid name; do
  port=$((BASE_PORT + idx))
  [ -n "$PROXY_CONFIG" ] && PROXY_CONFIG="$PROXY_CONFIG,"
  PROXY_CONFIG="$PROXY_CONFIG$udid:$port"
  echo "  $name ($udid) → :$port" >&2
  idx=$((idx + 1))
done <<< "$SIMS"

# Restart proxy with all simulators
pkill -f ios-webkit-debug-proxy 2>/dev/null || true
sleep 1
ios-webkit-debug-proxy -c "$PROXY_CONFIG" -d >/tmp/iwdp.log 2>&1 &
PROXY_PID=$!
sleep 2
echo "Proxy started (PID $PROXY_PID)" >&2

# Query each simulator for WebViews
SIM_RESULTS="[]"
target_idx=1
idx=0

while IFS=$'\t' read -r udid name; do
  port=$((BASE_PORT + idx))
  echo "" >&2
  echo "  [$name — :$port]" >&2

  PROXY_HOST=""
  for host in localhost 127.0.0.1; do
    if curl -s --connect-timeout 2 "http://$host:$port/json" >/dev/null 2>&1; then
      PROXY_HOST=$host
      break
    fi
  done

  if [ -z "$PROXY_HOST" ]; then
    echo "  · No proxy response on :$port (check /tmp/iwdp.log)" >&2
    targets_json="[]"
  else
    raw=$(curl -s "http://$PROXY_HOST:$port/json" 2>/dev/null || echo "[]")
    targets_json=$(echo "$raw" | python3 -c "
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
    n=$(echo "$targets_json" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
    echo "  ✓ $n WebView(s) found" >&2
    if [ "$n" -eq 0 ]; then
      echo "    → Make sure the app is running and WKWebView is visible on screen" >&2
      echo "    → iOS 16.4+: set webView.isInspectable = true in app code" >&2
    else
      echo "$targets_json" | python3 -c "
import sys, json, os
targets = json.load(sys.stdin)
start = int(os.environ.get('TARGET_IDX', 1))
for i, t in enumerate(targets, start):
    print(f'    [{i}] {t[\"url\"]}  ({t[\"title\"]})')
" TARGET_IDX=$target_idx >&2
    fi
    target_idx=$(echo "$targets_json" | python3 -c "import sys,json; print($target_idx + len(json.load(sys.stdin)))")
  fi

  SIM_RESULTS=$(python3 -c "
import json, sys
lst = json.loads(sys.argv[1])
lst.append({
    'udid': sys.argv[2],
    'name': sys.argv[3],
    'proxyPort': int(sys.argv[4]),
    'targets': json.loads(sys.argv[5])
})
print(json.dumps(lst))
" "$SIM_RESULTS" "$udid" "$name" "$port" "$targets_json")

  idx=$((idx + 1))
done <<< "$SIMS"

# Build flat indexed allTargets list
ALL_TARGETS=$(python3 -c "
import json, sys
sims = json.loads(sys.argv[1])
all_t = []
idx = 1
for sim in sims:
    for t in sim['targets']:
        all_t.append({
            'index': idx,
            'type': 'ios',
            'device': sim['name'],
            'port': sim['proxyPort'],
            'url': t['url'],
            'title': t['title'],
            'ws': t['ws']
        })
        idx += 1
print(json.dumps(all_t))
" "$SIM_RESULTS")

echo "" >&2

python3 -c "
import json, sys
print(json.dumps({
    'simulators': json.loads(sys.argv[1]),
    'allTargets': json.loads(sys.argv[2])
}, indent=2))
" "$SIM_RESULTS" "$ALL_TARGETS"

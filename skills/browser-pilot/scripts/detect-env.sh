#!/bin/bash
# detect-env.sh — Scan all available browser debug targets
# stdout: JSON summary of reachable targets
# stderr: human-readable status

set -e

echo "Scanning debug targets..." >&2

# ── Chrome ────────────────────────────────────────────────────────
# Detection order:
#   1. ps aux — read --remote-debugging-port=N directly from Chrome process args (most reliable)
#   2. lsof   — scan TCP LISTEN ports owned by chrome/chromium process (fallback if arg not found)
#   3. not found — Chrome is not running in debug mode
chrome_port="" chrome_tabs=0 chrome_ver=""

detected_ports=$(ps aux 2>/dev/null \
  | grep -i "remote-debugging-port" \
  | grep -v grep \
  | grep -oE 'remote-debugging-port=[0-9]+' \
  | cut -d= -f2 \
  | sort -u)

if [ -z "$detected_ports" ]; then
  echo "  · Chrome: no --remote-debugging-port in process args, trying lsof..." >&2
  detected_ports=$(lsof -iTCP -sTCP:LISTEN -P 2>/dev/null \
    | grep -iE "chrome|chromium" \
    | awk '{print $9}' \
    | grep -oE '[0-9]+$' \
    | sort -u)
fi

for port in $detected_ports; do
  res=$(curl -s --connect-timeout 1 "http://localhost:$port/json/version" 2>/dev/null || true)
  if [ -n "$res" ]; then
    chrome_port=$port
    chrome_tabs=$(curl -s "http://localhost:$port/json" 2>/dev/null \
      | python3 -c "import sys,json; print(len([t for t in json.load(sys.stdin) if t.get('type')=='page']))" 2>/dev/null || echo 0)
    chrome_ver=$(echo "$res" | python3 -c "import sys,json; print(json.load(sys.stdin).get('Browser',''))" 2>/dev/null || echo "")
    echo "  ✓ Chrome on :$chrome_port — $chrome_tabs tab(s)" >&2
    break
  fi
done

if [ -z "$chrome_port" ]; then
  echo "  · Chrome: not found (no --remote-debugging-port detected)" >&2
  chrome_json='"chrome":{"available":false,"debugPort":null,"tabs":0,"version":null}'
else
  chrome_json="\"chrome\":{\"available\":true,\"debugPort\":$chrome_port,\"tabs\":$chrome_tabs,\"version\":\"$chrome_ver\"}"
fi

# ── Safari ────────────────────────────────────────────────────────
# Detection order:
#   1. /usr/bin/safaridriver exists  — safaridriver is installed (comes with Xcode)
#   2. pgrep -x Safari               — Safari process is currently running
#   3. safaridriver --enable (dry-run via timeout) — "Allow Remote Automation" is enabled in Safari > Develop menu
#      safaridriver exits 0 if automation is allowed, non-zero if not configured
safari_driver=false safari_running=false safari_automation=false
[ -f "/usr/bin/safaridriver" ] && safari_driver=true
pgrep -x Safari >/dev/null 2>&1 && safari_running=true
if $safari_driver; then
  echo "  ✓ safaridriver available" >&2
  # timeout 2s to avoid hanging; exit 0 means automation is permitted
  if timeout 2 safaridriver --enable >/dev/null 2>&1; then
    safari_automation=true
    echo "  ✓ Remote Automation enabled" >&2
  else
    echo "  · Remote Automation not enabled (Safari → Develop → Allow Remote Automation)" >&2
  fi
else
  echo "  · safaridriver not found" >&2
fi
safari_json="\"safari\":{\"available\":$safari_driver,\"running\":$safari_running,\"automationEnabled\":$safari_automation}"

echo "" >&2

# stdout: clean JSON
python3 -c "
import json, sys
print(json.dumps(json.loads('{'+sys.argv[1]+'}'), indent=2))
" "$chrome_json,$safari_json"

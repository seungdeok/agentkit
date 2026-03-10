#!/bin/bash
# detect-env.sh — Discover all inspectable browser/WebView debug targets
# stdout: JSON { targets:[{index,type,device,port,url,title,ws}], summary:{...} }
# stderr: numbered list of found targets
#
# Android: auto-discovers all devtools sockets via /proc/net/unix (no pre-setup needed)
# iOS:     auto-starts ios-webkit-debug-proxy if simulators are booted but proxy is not running
# Chrome:  reads --remote-debugging-port from process args or lsof

set -e

echo "Scanning debug targets..." >&2

# Collect targets as newline-delimited TSV: type<TAB>device<TAB>port<TAB>url<TAB>title<TAB>ws
LINES=""
add_line() { LINES="${LINES}${1}"$'\n'; }

# Find the lowest unused TCP port >= $1
find_free_port() {
  local p=${1:-9200}
  while lsof -iTCP:"$p" -sTCP:LISTEN >/dev/null 2>&1; do
    p=$((p + 1))
  done
  echo "$p"
}

# ── Chrome ────────────────────────────────────────────────────────
# Reads --remote-debugging-port from process args, falls back to lsof.
# Collects ALL open page tabs from ALL detected debug ports.
detected_ports=$(ps aux 2>/dev/null \
  | grep -i "remote-debugging-port" | grep -v grep \
  | grep -oE 'remote-debugging-port=[0-9]+' | cut -d= -f2 | sort -u)

if [ -z "$detected_ports" ]; then
  detected_ports=$(lsof -iTCP -sTCP:LISTEN -P 2>/dev/null \
    | grep -iE "chrome|chromium" | awk '{print $9}' | grep -oE '[0-9]+$' | sort -u)
fi

chrome_count=0
for port in $detected_ports; do
  ver=$(curl -s --connect-timeout 1 "http://localhost:$port/json/version" 2>/dev/null || true)
  [ -z "$ver" ] && continue
  while IFS=$'\t' read -r url title ws; do
    [ -z "$ws" ] && continue
    add_line "chrome	Chrome (:$port)	$port	$url	$title	$ws"
    chrome_count=$((chrome_count + 1))
  done < <(curl -s "http://localhost:$port/json" 2>/dev/null \
    | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    if t.get('type') == 'page' and t.get('webSocketDebuggerUrl'):
        print(t.get('url','') + '\t' + t.get('title','') + '\t' + t.get('webSocketDebuggerUrl',''))
" 2>/dev/null || true)
done

chrome_available=false
if [ "$chrome_count" -gt 0 ]; then
  chrome_available=true
  echo "  ✓ Chrome — $chrome_count tab(s) (debug mode)" >&2
else
  # Fallback: list open Chrome tabs via AppleScript (URL only, no debug access)
  chrome_urls=$(osascript -e 'tell application "Google Chrome" to get URL of tabs of windows' 2>/dev/null || true)
  if [ -n "$chrome_urls" ]; then
    echo "  · Chrome: running but no debug port — listing tabs via AppleScript (read-only)" >&2
    while IFS=', ' read -ra urls; do
      for url in "${urls[@]}"; do
        url=$(echo "$url" | xargs)
        [ -z "$url" ] && continue
        add_line "chrome-readonly	Chrome (no debug port)		$url	(no debug access — restart with --remote-debugging-port)	"
        chrome_count=$((chrome_count + 1))
      done
    done <<< "$chrome_urls"
    echo "  ✓ Chrome — $chrome_count tab(s) visible (read-only)" >&2
  else
    echo "  · Chrome: not found in debug mode" >&2
    echo "    → To enable: open -a \"Google Chrome\" --args --remote-debugging-port=PORT" >&2
  fi
fi

# ── Safari ────────────────────────────────────────────────────────
# CDP not available without Remote Automation. Falls back to AppleScript for URL listing.
safari_driver=false safari_running=false safari_automation=false
[ -f "/usr/bin/safaridriver" ] && safari_driver=true
# pgrep covers both "Safari" and "Safari Technology Preview"
pgrep -xi "safari|safari technology preview" >/dev/null 2>&1 && safari_running=true
if $safari_driver; then
  echo "  ✓ safaridriver available" >&2
  if timeout 2 safaridriver --enable >/dev/null 2>&1; then
    safari_automation=true
    echo "  ✓ Safari Remote Automation enabled" >&2
  else
    echo "  · Safari Remote Automation not enabled (Safari → Develop → Allow Remote Automation)" >&2
  fi
else
  echo "  · safaridriver not found" >&2
fi

# Safari URL fallback via AppleScript
safari_url_count=0
safari_urls=$(osascript -e 'tell application "Safari" to get URL of tabs of windows' 2>/dev/null || true)
if [ -n "$safari_urls" ] && ! $safari_automation; then
  echo "  · Safari: listing tabs via AppleScript (read-only)" >&2
  while IFS=', ' read -ra urls; do
    for url in "${urls[@]}"; do
      url=$(echo "$url" | xargs)
      [ -z "$url" ] && continue
      add_line "safari-readonly	Safari (no automation)		$url	(no debug access — enable Develop → Allow Remote Automation)	"
      safari_url_count=$((safari_url_count + 1))
    done
  done <<< "$safari_urls"
  echo "  ✓ Safari — $safari_url_count tab(s) visible (read-only)" >&2
fi

# ── iOS — auto-start proxy if needed, then scan ports 9221–9230 ───
# If simulators are booted but no proxy is responding, starts
# ios-webkit-debug-proxy automatically (one instance covers all devices).
ios_count=0
if which xcrun >/dev/null 2>&1; then
  booted=$(xcrun simctl list devices -j 2>/dev/null | python3 -c "
import sys, json
sims = []
for devs in json.load(sys.stdin).get('devices', {}).values():
    for d in devs:
        if d.get('state') == 'Booted':
            sims.append(d['udid'] + '\t' + d['name'])
print('\n'.join(sims))
" 2>/dev/null || true)

  booted_count=$(echo "$booted" | grep -v '^\s*$' 2>/dev/null | wc -l | xargs)
  echo "  ✓ xcrun — $booted_count simulator(s) booted" >&2

  if [ "$booted_count" -gt 0 ] && which ios-webkit-debug-proxy >/dev/null 2>&1; then
    # Check if proxy is already answering on any port 9221-9230
    proxy_alive=false
    for p in $(seq 9221 9230); do
      curl -s --connect-timeout 1 "http://localhost:$p/json" >/dev/null 2>&1 && proxy_alive=true && break
    done

    if ! $proxy_alive; then
      echo "  · Proxy not running — starting ios-webkit-debug-proxy..." >&2
      # Build config: "UDID1:9221,UDID2:9222,..."
      PROXY_CONFIG=""
      pidx=0
      while IFS=$'\t' read -r udid name; do
        p=$((9221 + pidx))
        [ -n "$PROXY_CONFIG" ] && PROXY_CONFIG="$PROXY_CONFIG,"
        PROXY_CONFIG="$PROXY_CONFIG$udid:$p"
        pidx=$((pidx + 1))
      done <<< "$booted"
      pkill -f ios-webkit-debug-proxy 2>/dev/null || true
      sleep 1
      ios-webkit-debug-proxy -c "$PROXY_CONFIG" -d >/tmp/iwdp.log 2>&1 &
      sleep 2
      echo "  ✓ Proxy started" >&2
    fi
  fi

  # Collect all WebViews from any responding proxy port
  for port in $(seq 9221 9230); do
    for host in localhost 127.0.0.1; do
      res=$(curl -s --connect-timeout 1 "http://$host:$port/json" 2>/dev/null || true)
      [ -z "$res" ] && continue
      while IFS=$'\t' read -r url title ws; do
        [ -z "$ws" ] && continue
        add_line "ios	iOS Simulator (:$port)	$port	$url	$title	$ws"
        ios_count=$((ios_count + 1))
      done < <(echo "$res" | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    if t.get('webSocketDebuggerUrl'):
        print(t.get('url','') + '\t' + t.get('title','') + '\t' + t.get('webSocketDebuggerUrl',''))
" 2>/dev/null || true)
      break
    done
  done

  if [ "$ios_count" -gt 0 ]; then
    echo "  ✓ iOS — $ios_count WebView(s)" >&2
  elif [ "$booted_count" -gt 0 ]; then
    echo "  · iOS: simulators booted but no WebViews found" >&2
    echo "    → Make sure the app is running and WKWebView is visible (iOS 16.4+: webView.isInspectable = true)" >&2
  fi
else
  echo "  · xcrun not found (macOS + Xcode CLI required)" >&2
fi

ios_available=false
[ "$ios_count" -gt 0 ] && ios_available=true

# ── Android — auto-discover all devtools sockets ──────────────────
# Scans /proc/net/unix on each device for abstract sockets matching
# 'devtools_remote' (covers Chrome, WebView apps, custom app sockets).
# Forwards each to a dynamically-assigned free local port — no fixed
# port needed, no pre-setup required.
#
# Forwarded ports are kept alive so the agent can connect via WS.
# They are re-created fresh each run to avoid stale state.
android_count=0
next_android_port=9230

if which adb >/dev/null 2>&1; then
  devices=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device"{print $1}')
  dev_count=$(echo "$devices" | grep -v '^\s*$' 2>/dev/null | wc -l | xargs)
  echo "  ✓ ADB — $dev_count device(s)" >&2

  for dev in $devices; do
    model=$(adb -s "$dev" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo "$dev")

    # Find all CDP abstract sockets on this device
    sockets=$(adb -s "$dev" shell "cat /proc/net/unix 2>/dev/null" \
      | awk '{print $NF}' \
      | grep -E 'devtools_remote' \
      | sed 's/^@//' \
      | sort -u 2>/dev/null || true)

    [ -z "$sockets" ] && continue

    for socket in $sockets; do
      # Remove any existing forward for this socket to avoid stale state
      old_port=$(adb -s "$dev" forward --list 2>/dev/null \
        | grep "localabstract:$socket" | awk '{print $2}' | grep -oE '[0-9]+' || true)
      [ -n "$old_port" ] && adb -s "$dev" forward --remove "tcp:$old_port" 2>/dev/null || true

      # Assign a free local port
      port=$(find_free_port $next_android_port)
      next_android_port=$((port + 1))

      adb -s "$dev" forward "tcp:$port" "localabstract:$socket" >/dev/null 2>&1 || continue

      for host in localhost 127.0.0.1; do
        res=$(curl -s --connect-timeout 1 "http://$host:$port/json" 2>/dev/null || true)
        [ -z "$res" ] && continue
        while IFS=$'\t' read -r url title ws; do
          [ -z "$ws" ] && continue
          add_line "android	$model ($socket)	$port	$url	$title	$ws"
          android_count=$((android_count + 1))
        done < <(echo "$res" | python3 -c "
import sys, json
for t in json.load(sys.stdin):
    if t.get('webSocketDebuggerUrl'):
        print(t.get('url','') + '\t' + t.get('title','') + '\t' + t.get('webSocketDebuggerUrl',''))
" 2>/dev/null || true)
        break
      done
    done
  done

  if [ "$android_count" -gt 0 ]; then
    echo "  ✓ Android — $android_count WebView(s)" >&2
  elif [ "$dev_count" -gt 0 ]; then
    echo "  · Android: device(s) found but no WebViews" >&2
    echo "    → App must be DEBUG build with WebView.setWebContentsDebuggingEnabled(true)" >&2
    echo "    → WebView must be visible on screen" >&2
  else
    echo "  · ADB: no devices connected" >&2
  fi
else
  echo "  · ADB not found" >&2
fi

android_available=false
[ "$android_count" -gt 0 ] && android_available=true

echo "" >&2

# ── Build output JSON ──────────────────────────────────────────────
python3 -c "
import json, sys

lines = [l for l in sys.argv[1].split('\n') if l.strip()]
targets = []
for i, line in enumerate(lines, 1):
    parts = line.split('\t')
    if len(parts) < 6:
        continue
    type_, device, port, url, title, ws = parts[0], parts[1], parts[2], parts[3], parts[4], parts[5]
    targets.append({
        'index': i,
        'type': type_,
        'device': device,
        'port': int(port) if port.isdigit() else port,
        'url': url,
        'title': title,
        'ws': ws
    })

summary = {
    'chrome': {'available': sys.argv[2]=='true', 'tabCount': sum(1 for t in targets if t['type']=='chrome')},
    'safari': {'available': sys.argv[3]=='true', 'running': sys.argv[4]=='true', 'automationEnabled': sys.argv[5]=='true'},
    'ios': {'available': sys.argv[6]=='true', 'webviewCount': sum(1 for t in targets if t['type']=='ios')},
    'android': {'available': sys.argv[7]=='true', 'webviewCount': sum(1 for t in targets if t['type']=='android')}
}

print(json.dumps({'targets': targets, 'summary': summary}, indent=2))
" "$LINES" "$chrome_available" "$safari_driver" "$safari_running" "$safari_automation" "$ios_available" "$android_available"

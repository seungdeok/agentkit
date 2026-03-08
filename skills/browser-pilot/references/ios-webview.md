# iOS WebView — Dev Loop Reference

> **`$IOS_HOST`** and **`$IOS_PORT`** are set in SKILL.md Step 1 via `detect-env.sh` (`ios.host`, `ios.proxyPort`). Do not hardcode `localhost` or `9221`.

```bash
IOS_HOST=$(echo "$DETECT" | python3 -c "import sys,json; print(json.load(sys.stdin)['ios']['host'] or 'localhost')")
IOS_PORT=$(echo "$DETECT" | python3 -c "import sys,json; print(json.load(sys.stdin)['ios']['proxyPort'])")
```

Connects to WKWebView in iOS Simulator or real device via `ios-webkit-debug-proxy`.
Once connected, all CDP commands from `references/chrome.md` work identically (substitute `$IOS_HOST:$IOS_PORT` for `$CHROME_PORT`).

## Quick Connect

```bash
# Auto-setup → get WS URL in one step
OUTPUT=$(bash /mnt/skills/user/browser-pilot/scripts/ios-setup.sh)
WS=$(echo "$OUTPUT" | python3 -c "import sys,json; t=json.load(sys.stdin)['targets']; print(t[0]['ws'] if t else '')")
echo "WS=$WS"
```

---

## Manual Steps

### Check & boot simulator

```bash
xcrun simctl list devices | grep Booted   # see what's running
xcrun simctl boot "iPhone 15 Pro" && open -a Simulator  # boot if none
UDID=$(xcrun simctl list devices | grep Booted | grep -o '[A-Z0-9-]\{36\}' | head -1)
```

### Start proxy

```bash
pkill -f ios-webkit-debug-proxy 2>/dev/null || true; sleep 1
ios-webkit-debug-proxy -c "$UDID:$IOS_PORT" -d &
sleep 2
curl -s "http://$IOS_HOST:$IOS_PORT/json"  # should return target list
```

### Get WS URL

```bash
WS=$(curl -s "http://$IOS_HOST:$IOS_PORT/json" | python3 -c "
import sys,json
t=[t for t in json.load(sys.stdin) if t.get('webSocketDebuggerUrl')]
print(t[0]['webSocketDebuggerUrl'] if t else '')
")
```

---

## App Management

```bash
BUNDLE="com.yourcompany.yourapp"
UDID=$(xcrun simctl list devices | grep Booted | grep -o '[A-Z0-9-]\{36\}' | head -1)

xcrun simctl launch   "$UDID" "$BUNDLE"    # launch
xcrun simctl terminate "$UDID" "$BUNDLE"   # terminate
xcrun simctl spawn "$UDID" launchctl list | grep "$BUNDLE"  # check running
```

---

## App Requirements

**iOS 16.4+ — must set in code:**

```swift
#if DEBUG
webView.isInspectable = true
#endif
```

**Older iOS / React Native debug builds:** inspectable automatically.

**WebView not appearing?**

- App must be in foreground with WebView **visible on screen**
- Must be a **debug build** (not TestFlight/release)
- Re-run setup script **after** the app is launched

---

## Real Device

```bash
REAL_UDID="your-device-udid"
ios-webkit-debug-proxy -c "$REAL_UDID:$IOS_PORT" &
# Same workflow from here — use $IOS_HOST:$IOS_PORT
```

Requirements: trust this Mac on device, Settings → Safari → Advanced → Web Inspector → ON.

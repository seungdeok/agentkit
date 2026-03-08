# Android WebView — Dev Loop Reference

> **`$ANDROID_PORT`** is set in SKILL.md Step 1 via `detect-env.sh` (`android.port`). Do not hardcode `9222`.

```bash
ANDROID_PORT=$(echo "$DETECT" | python3 -c "import sys,json; print(json.load(sys.stdin)['android']['port'])")
```

Connects to Android WebView via ADB port forwarding.
Once connected, all CDP commands from `references/chrome.md` work identically (substitute `$ANDROID_PORT` for `$CHROME_PORT`).

## Quick Connect

```bash
# Auto-setup → get WS URL in one step
OUTPUT=$(bash /mnt/skills/user/browser-pilot/scripts/android-setup.sh)
WS=$(echo "$OUTPUT" | python3 -c "import sys,json; t=json.load(sys.stdin)['targets']; print(t[0]['ws'] if t else '')")
echo "WS=$WS"
```

---

## Manual Steps

### Check device

```bash
adb devices -l
DEVICE=$(adb devices | awk 'NR==2{print $1}')
```

### Port forward

```bash
adb -s "$DEVICE" forward tcp:$ANDROID_PORT localabstract:chrome_devtools_remote
curl -s http://localhost:$ANDROID_PORT/json  # should return WebView list
```

### Get WS URL

```bash
WS=$(curl -s http://localhost:$ANDROID_PORT/json | python3 -c "
import sys,json
t=[t for t in json.load(sys.stdin) if t.get('webSocketDebuggerUrl')]
print(t[0]['webSocketDebuggerUrl'] if t else '')
")
```

---

## App Management

```bash
PACKAGE="com.yourcompany.yourapp"
DEVICE=$(adb devices | awk 'NR==2{print $1}')

adb -s "$DEVICE" shell "am start -n $PACKAGE/.MainActivity"  # launch
adb -s "$DEVICE" shell "am force-stop $PACKAGE"              # stop
adb -s "$DEVICE" shell "ps | grep $PACKAGE"                  # check running
```

---

## Logcat (combine with WebView console)

```bash
DEVICE=$(adb devices | awk 'NR==2{print $1}')

# Recent errors
adb -s "$DEVICE" logcat -d | grep -E "chromium|WebView|E/" | tail -30

# Live stream
adb -s "$DEVICE" logcat | grep -E "chromium|WebView" &
```

---

## App Requirements

```kotlin
// Application.onCreate() or Activity.onCreate() — debug builds only
if (BuildConfig.DEBUG) {
    WebView.setWebContentsDebuggingEnabled(true)
}
```

**React Native Android:** already enabled in debug builds — no changes needed.

**WebView not appearing?**

- Must be **DEBUG** build
- Re-run `android-setup.sh` **after** launching the app
- Check actual socket name if custom:
  ```bash
  adb -s "$DEVICE" shell cat /proc/net/unix | grep devtools
  adb -s "$DEVICE" forward tcp:$ANDROID_PORT localabstract:<socket-name-found-above>
  ```

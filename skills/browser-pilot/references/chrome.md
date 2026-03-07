# Chrome — Dev Loop Reference

> **`$CHROME_PORT`** is set in SKILL.md Step 1 via `detect-env.sh` — do not hardcode `9222`.

## 1. Start Chrome with Debug Port

### Check if already open

```bash
curl -s "http://localhost:$CHROME_PORT/json/version" \
  | python3 -c "import sys,json; print('✓', json.load(sys.stdin)['Browser'])" 2>/dev/null \
  || echo "✗ Not running in debug mode"
```

### Launch (macOS)

```bash
# Launch with the same port detect-env found (or 9222 as default if starting fresh)
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=${CHROME_PORT:-9222} \
  --user-data-dir=/tmp/chrome-devloop \
  --no-first-run --no-default-browser-check &
sleep 2
curl -s "http://localhost:${CHROME_PORT:-9222}/json/version" | python3 -c "import sys,json; print('✓', json.load(sys.stdin)['Browser'])"
```

### Launch (Linux)

```bash
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-devloop &
```

> **Already running Chrome without a debug port?** You can't attach to it.
> The command above opens a **separate profile** — both can run at the same time.

---

## 2. List Tabs & Get WS URL

```bash
# All open page tabs
curl -s http://localhost:$CHROME_PORT/json | python3 -c "
import sys,json
for t in json.load(sys.stdin):
    if t.get('type')=='page':
        print(t['url'])
        print('  WS:', t.get('webSocketDebuggerUrl',''))
"
```

### Filter by port (monorepo)

```bash
PORT=3001
WS=$(curl -s http://localhost:$CHROME_PORT/json | python3 -c "
import sys,json
tabs=json.load(sys.stdin)
t=next((t for t in tabs if 'localhost:$PORT' in t.get('url','') or '127.0.0.1:$PORT' in t.get('url','')),None)
print(t['webSocketDebuggerUrl'] if t else '')
")
[ -z "$WS" ] && echo "✗ No tab on localhost:$PORT" && exit 1
echo "WS=$WS"
```

---

## 3. Console — Inject Collector + Read Logs

Inject once per session (after attaching), then call the read command as many times as needed:

```bash
WS="ws://..."

# Inject collector
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate --params '{
    "expression": "window.__devLoopLogs=[];[\"log\",\"warn\",\"error\"].forEach(l=>{const o=console[l];console[l]=(...a)=>{window.__devLoopLogs.push({level:l,msg:a.join(\" \"),t:Date.now()});o(...a)}});\"collector:ok\"",
    "returnByValue":true}'

# Read logs
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"JSON.stringify(window.__devLoopLogs)","returnByValue":true}' \
  --extract result.value
```

---

## 4. Network — Check API Calls

```bash
WS="ws://..."

# Test a specific endpoint inline
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"fetch(\"/api/me\").then(r=>({status:r.status,ok:r.ok})).catch(e=>({error:e.message}))","returnByValue":true,"awaitPromise":true}' \
  --extract result.value

# All resource timings (loaded assets + XHR)
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"JSON.stringify(performance.getEntriesByType(\"resource\").slice(-20).map(e=>({url:e.name.split(\"/\").slice(-2).join(\"/\"),ms:Math.round(e.duration),status:e.responseStatus})))","returnByValue":true}' \
  --extract result.value
```

---

## 5. DOM & Interaction

```bash
WS="ws://..."

# Check element state
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"(s=>{ const el=document.querySelector(s); return el?JSON.stringify({exists:true,visible:el.offsetParent!==null,text:el.textContent.trim().slice(0,100)}):JSON.stringify({exists:false}) })(\"#submit-btn\")","returnByValue":true}' \
  --extract result.value

# Click
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"document.querySelector(\"button[type=submit]\").click()","returnByValue":true}'

# Fill input (fires React/Vue events)
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"(el=>{el.value=\"user@example.com\";el.dispatchEvent(new Event(\"input\",{bubbles:true}));el.dispatchEvent(new Event(\"change\",{bubbles:true}))})(document.querySelector(\"input[type=email]\"))","returnByValue":true}'

# Navigate to a route
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Page.navigate --params '{"url":"http://localhost:3001/dashboard"}'
```

---

## 6. Storage & Auth

```bash
WS="ws://..."

# Check auth token
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"JSON.stringify({localStorage:localStorage.getItem(\"token\"),sessionStorage:sessionStorage.getItem(\"token\"),cookie:document.cookie.includes(\"token\")})","returnByValue":true}' \
  --extract result.value

# Full localStorage
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"JSON.stringify(Object.fromEntries(Object.entries(localStorage)))","returnByValue":true}' \
  --extract result.value

# Cookies
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Network.getCookies --params '{}'
```

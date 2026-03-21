# Chrome — Dev Loop Reference

> Connect to Chrome using `npx agent-browser --cdp $PORT` or `npx agent-browser --auto-connect`.

## 1. Start Chrome with Debug Port

### Check if already open

```bash
curl -s "http://localhost:$CHROME_PORT/json/version" \
  | python3 -c "import sys,json; print('✓', json.load(sys.stdin)['Browser'])" 2>/dev/null \
  || echo "✗ Not running in debug mode"
```

### Launch (macOS)

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=${CHROME_PORT:-9222} \
  --user-data-dir=/tmp/chrome-devloop \
  --no-first-run --no-default-browser-check &
sleep 2
```

### Launch (Linux)

```bash
google-chrome --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-devloop &
```

> **Already running Chrome without a debug port?** You can't attach to it.
> The command above opens a **separate profile** — both can run at the same time.

---

## 2. Connect and Navigate

```bash
# Attach to existing Chrome tab
npx agent-browser --cdp $CHROME_PORT open http://localhost:3000

# Auto-discover running Chrome (no port needed)
npx agent-browser --auto-connect open http://localhost:3000
```

### Filter by port (monorepo)

```bash
PORT=3001
npx agent-browser --cdp $CHROME_PORT open http://localhost:$PORT
```

---

## 3. Screenshot

```bash
# Viewport screenshot
npx agent-browser screenshot snapshot.png

# Full-page screenshot
npx agent-browser screenshot --full snapshot-full.png

# Annotated (shows element refs overlaid)
npx agent-browser screenshot --annotate snapshot-annotated.png
```

---

## 4. Element Discovery

```bash
# Interactive elements with refs (@e1, @e2, ...)
npx agent-browser snapshot -i

# Include cursor-interactive divs
npx agent-browser snapshot -i -C

# Scope to a selector
npx agent-browser snapshot -i -s "#root"
```

---

## 5. Console — Inject Collector + Read Logs

```bash
# Inject collector
npx agent-browser eval "window.__devLoopLogs=[];['log','warn','error'].forEach(l=>{const o=console[l];console[l]=(...a)=>{window.__devLoopLogs.push({level:l,msg:a.join(' '),t:Date.now()});o(...a)}});'collector:ok'"

# Read logs
npx agent-browser eval "JSON.stringify(window.__devLoopLogs)"
```

---

## 6. Network — Check API Calls

```bash
# Track HTTP requests
npx agent-browser network requests

# Test a specific endpoint inline
npx agent-browser eval "fetch('/api/me').then(r=>JSON.stringify({status:r.status,ok:r.ok})).catch(e=>JSON.stringify({error:e.message}))"

# Resource timings
npx agent-browser eval "JSON.stringify(performance.getEntriesByType('resource').slice(-20).map(e=>({url:e.name.split('/').slice(-2).join('/'),ms:Math.round(e.duration),status:e.responseStatus})))"
```

---

## 7. DOM & Interaction

```bash
# Check element state
npx agent-browser get text @e3

# Click
npx agent-browser click @e5

# Fill input (fires React/Vue events)
npx agent-browser fill @e2 "user@example.com"

# Navigate to a route
npx agent-browser goto http://localhost:3001/dashboard

# Reload
npx agent-browser eval "location.reload(true)"
```

---

## 8. Storage & Auth

```bash
# Check auth token
npx agent-browser eval "JSON.stringify({localStorage:localStorage.getItem('token'),sessionStorage:sessionStorage.getItem('token'),cookie:document.cookie.includes('token')})"

# Full localStorage
npx agent-browser eval "JSON.stringify(Object.fromEntries(Object.entries(localStorage)))"

# Save/restore session (for auth persistence)
npx agent-browser state save ./auth.json
npx agent-browser state load ./auth.json
```

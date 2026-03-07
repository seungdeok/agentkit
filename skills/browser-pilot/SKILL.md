---
name: browser-pilot
description: AI-native development loop — inspect, debug, and iterate on live browser tabs while writing code. Use this skill whenever the agent needs to see the current UI state, catch runtime errors, or verify a fix worked. Triggers on: "fix this page", "why is it broken", "check the console", "take a screenshot", "something looks wrong on localhost:PORT", "verify my fix worked", "what does the page look like now", "check the network request", "inspect the DOM". Use after every code change to close the see → fix → verify loop. Supports Chrome and Safari.
---

# Browser Dev Loop

Gives the agent eyes and ears on the running app — screenshot, console, DOM, network —
so it can write code, observe the result, and iterate until the problem is solved.

## The Loop

```
detect targets → attach → observe → fix code → reload → verify → repeat
```

Never assume a fix worked. Always reload and confirm with a screenshot or console check.

---

## Step 1 — Detect Available Targets

Run on every new task to see what's reachable:

```bash
DETECT=$(bash /mnt/skills/user/browser-pilot/scripts/detect-env.sh)
echo "$DETECT"

# Extract for use in later steps
CHROME_PORT=$(echo "$DETECT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['chrome']['debugPort'] or '')")
SAFARI_RUNNING=$(echo "$DETECT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['safari']['running'])")
```

Use `$CHROME_PORT` in all subsequent Chrome commands — do **not** hardcode `9222`.

If nothing is detected, ask the user: _"Which environment should I debug? (Chrome / Safari)"_

---

## Step 2 — Connect to the Right Target

**Priority order: use detect-env result first, then fall back to user's message signal.**

| Condition                                                       | Read this reference             |
| --------------------------------------------------------------- | ------------------------------- |
| `chrome.available=true` (or user says "localhost:PORT"/"Chrome")| `references/chrome.md`          |
| `safari.running=true` (or user says "Safari"/"macOS browser")   | `references/safari.md`          |

If both Chrome and Safari are available, prefer Chrome unless the user explicitly mentions Safari.

Read the reference **before** running any commands — it contains the exact connection steps.

**Monorepo / multi-port:** When the user mentions a port (e.g. "localhost:3001"), filter the tab list by that port. List all open localhost tabs first if unsure which one.

---

## Step 3 — Observe (Core Commands)

Once you have `$WS_URL` from the reference file:

```bash
# $CHROME_PORT comes from Step 1 detect output
WS=$(curl -s "http://localhost:$CHROME_PORT/json" | python3 -c "
import sys,json
tabs=json.load(sys.stdin)
t=next((t for t in tabs if t.get('type')=='page'),None)
print(t['webSocketDebuggerUrl'] if t else '')
")

# Screenshot — always start here
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Page.captureScreenshot \
  --params '{"format":"png"}' --extract data --base64-file snapshot.png

# Console errors
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"JSON.stringify(window.__devLoopLogs||[])","returnByValue":true}' \
  --extract result.value
# Note: inject the log collector first (see references/chrome.md § Console)

# DOM snapshot (scoped)
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"document.querySelector(\"#root\").innerHTML","returnByValue":true}' \
  --extract result.value

# Check an API call inline
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"fetch(\"/api/health\").then(r=>r.status+\" \"+r.statusText).catch(e=>\"ERR:\"+e.message)","returnByValue":true,"awaitPromise":true}' \
  --extract result.value
```

---

## Step 4 — Fix, Reload, Verify

```bash
# Hard reload after code change
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Page.reload --params '{"ignoreCache":true}'

# Verify with another screenshot
node /mnt/skills/user/browser-pilot/scripts/cdp.js \
  --ws "$WS" --method Page.captureScreenshot \
  --params '{"format":"png"}' --extract data --base64-file after-fix.png
```

Compare `snapshot.png` (before) vs `after-fix.png` (after). If the issue persists, go back to Step 3.

---

## Quick Reference

| Goal                            | Command                                                                                                                       |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| List Chrome tabs by port        | `curl -s "http://localhost:$CHROME_PORT/json" \| python3 -c "import sys,json; [print(t['url'],t['id']) for t in json.load(sys.stdin)]"` |
| Get WS URL for localhost:3001   | See `references/chrome.md` § "Filter by port"                                                                                 |
| Check localStorage / auth token | See `references/chrome.md` § "Storage"                                                                                        |

## Error Recovery

| Error                               | Cause                                | Fix                                            |
| ----------------------------------- | ------------------------------------ | ---------------------------------------------- |
| `ECONNREFUSED :$CHROME_PORT`        | Chrome not in debug mode             | See `references/chrome.md` § "Starting Chrome" |
| `Target closed`                     | Page navigated away                  | Re-run detect, re-attach                       |

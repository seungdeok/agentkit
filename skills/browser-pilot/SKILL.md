---
name: browser-pilot
description: >
  Activate this skill whenever: (1) the user mentions a localhost URL or running web app,
  (2) asks to fix, debug, or check a UI — "fix this page", "why is it broken",
  "check the console", "take a screenshot", "something looks wrong", "verify my fix",
  "inspect the DOM", "check the network request"; (3) after ANY code change to a frontend
  — always reload, screenshot, and confirm the fix worked before declaring done.
  Korean triggers: "이거 고쳐줘", "왜 안되는거야", "콘솔 확인해줘", "스크린샷 찍어줘",
  "뭔가 깨진 것 같아", "수정한 거 제대로 됐는지 봐줘", "네트워크 요청 확인해줘", "DOM 봐줘".
  Do NOT wait for the user to explicitly ask — apply proactively on any live-UI task.
argument-hint: "<url> [--safari]"
compatibility: Requires Node.js (npx). macOS recommended for Safari support.
license: MIT
metadata:
  author: seungdeok
user-invocable: true
---

# Browser Dev Loop

Gives the agent eyes and ears on the running app — screenshot, element tree, console, network —
so it can write code, observe the result, and iterate until the problem is solved.

```
open url → observe → fix code → reload → verify → repeat
```

---

## When to Activate

Use this skill proactively — not only when the user explicitly asks. Activate whenever:

- The user is iterating on a live UI at a localhost URL
- A code change was just made and needs visual verification
- Console errors, network failures, or rendering issues are suspected
- The user asks what the page looks like or whether a fix worked

**Rule:** After every code change → reload → screenshot → confirm.

---

## Step 1 — Open the URL

```bash
# Chrome (default)
npx agent-browser open http://localhost:3000

# Safari
npx agent-browser -p safari open http://localhost:3000
```

---

## Step 2 — Observe

```bash
# Screenshot — always start here
npx agent-browser screenshot snapshot.png

# Interactive element tree with refs (@e1, @e2, ...)
npx agent-browser snapshot -i

# Console errors
npx agent-browser eval "JSON.stringify(window.__consoleErrors||[])"

# Inject console collector, then read logs
npx agent-browser eval "window.__devLoopLogs=[];['log','warn','error'].forEach(l=>{const o=console[l];console[l]=(...a)=>{window.__devLoopLogs.push({level:l,msg:a.join(' '),t:Date.now()});o(...a)}});'ok'"
npx agent-browser eval "JSON.stringify(window.__devLoopLogs)"

# Check an API call
npx agent-browser eval "fetch('/api/health').then(r=>r.status+' '+r.statusText).catch(e=>'ERR:'+e.message)"

# Network requests
npx agent-browser network requests
```

---

## Step 3 — Interact (if needed)

```bash
# Click a button or link
npx agent-browser click @e5

# Fill a form field
npx agent-browser fill @e2 "user@example.com"

# Navigate to a sub-route
npx agent-browser goto http://localhost:3000/dashboard

# Scroll
npx agent-browser scroll down 500
```

---

## Step 4 — Fix, Reload, Verify

After editing the code:

```bash
# Hard reload
npx agent-browser eval "location.reload(true)"

# Verify with another screenshot
npx agent-browser screenshot after-fix.png
```

Compare `snapshot.png` (before) vs `after-fix.png` (after). If the issue persists, return to Step 2.

```bash
# Close when done
npx agent-browser close
```

---

## Handling Multi-Origin & Embedded Content

### Iframes

Iframe content is **automatically inlined** in snapshots — no extra steps needed.
Refs like `@e3` work across iframe boundaries.

```bash
# Scope snapshot to a specific iframe if needed
npx agent-browser snapshot -i -s "iframe#payment"
```

### Navigation to a different port (same tab)

agent-browser follows navigation automatically. Always confirm after interaction:

```bash
npx agent-browser click @e5
npx agent-browser get url                        # confirm where we ended up
npx agent-browser screenshot snapshot-3001.png
```

### New tab / popup

agent-browser does **not** auto-switch to new tabs. Open a separate session:

```bash
npx agent-browser --session app2 open http://localhost:3001
npx agent-browser --session app2 screenshot snapshot-3001.png
```

---

## Error Recovery

| Error                          | Cause               | Fix                                     |
| ------------------------------ | ------------------- | --------------------------------------- |
| `Target closed`                | Page navigated away | Re-open with `npx agent-browser open`   |
| `npx agent-browser: not found` | Node.js missing     | Install Node.js from https://nodejs.org |

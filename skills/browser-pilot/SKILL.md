---
name: browser-pilot
description: AI-native development loop — inspect, debug, and iterate on live browser tabs and mobile WebViews while writing code. Use this skill whenever the agent needs to see the current UI state, catch runtime errors, or verify a fix worked — even if the user doesn't explicitly ask for it. After every code change to a web or mobile app, always use this skill to reload, screenshot, and confirm the fix actually worked in the running app. Don't assume code changes had the intended effect without checking. Triggers on: "fix this page", "why is it broken", "check the console", "take a screenshot", "the simulator is open", "something looks wrong on localhost:PORT", "the Android WebView is blank", "verify my fix worked", "what does the page look like now", "check the network request", "debug the iOS app", "inspect the DOM", or any situation where the user is iterating on a live UI. Korean triggers: "이거 고쳐줘", "왜 안되는거야", "콘솔 확인해줘", "스크린샷 찍어줘", "뭔가 깨진 것 같아", "localhost:PORT 확인해줘", "수정한 거 제대로 됐는지 봐줘", "화면이 어떻게 생겼어", "네트워크 요청 확인해줘", "DOM 봐줘", "연결해줘", "뭐 열려있어", "웹뷰 리스트 보여줘", "시뮬레이터 연결해줘", "안드로이드 웹뷰 확인해줘". Supports Chrome, Safari, iOS Simulator, and Android WebView.
---

# Browser Dev Loop

Gives the agent eyes and ears on the running app — screenshot, console, DOM, network —
so it can write code, observe the result, and iterate until the problem is solved.

## The Loop

```
detect targets → attach → observe → fix code → reload → verify → repeat
```

Reloading and confirming with a screenshot closes the loop — without it, you're guessing. Bugs often survive the first fix attempt.

---

## Interaction Patterns

### Pattern 1 — "연결해줘" / "뭐 열려있어?" / "list targets"

Run detection, print the full list, and wait for the user to pick:

```bash
DETECT=$(bash "$SKILL_PATH/scripts/detect-env.sh")
echo "$DETECT" | python3 -c "
import sys, json
targets = json.load(sys.stdin)['targets']
if not targets:
    print('No targets found.')
else:
    for t in targets:
        print(f'[{t[\"index\"]}] {t[\"type\"]:8}  {t[\"url\"]}  ({t[\"title\"]})  — {t[\"device\"]}')
"
```

Example output:
```
[1] chrome    http://localhost:3000/       (My App)   — Chrome (:9222)
[2] chrome    http://localhost:3001/admin  (Admin)    — Chrome (:9222)
[3] ios       http://10.0.0.2:3000/       (My App)   — iPhone 15 Pro
[4] android   http://10.0.2.2:3000/       (My App)   — Pixel 8 (webview_devtools_remote_1234)
[5] android   http://10.0.2.2:3001/coin   (Coin)     — Pixel 8 (webview_devtools_remote_5678)
```

Ask the user: _"어떤 타겟에 연결할까요? (번호 입력)"_ — then set `WS` from their choice:

```bash
TARGET_INDEX=3  # from user input
WS=$(echo "$DETECT" | python3 -c "
import sys, json
t = next((t for t in json.load(sys.stdin)['targets'] if t['index'] == $TARGET_INDEX), None)
print(t['ws'] if t else '')
")
```

### Pattern 2 — URL or endpoint given directly

User says: `"http://localhost:9223/json 연결해줘"` or `"ws://localhost:9222/devtools/page/ABC 붙어줘"`

**If a WebSocket URL (`ws://...`) is given** — use it directly:
```bash
WS="ws://localhost:9222/devtools/page/ABC123"
```

**If an HTTP debug endpoint is given** — query it and show the list:
```bash
ENDPOINT="http://localhost:9223"   # from user input
# Try /json then /json/list (path varies by runtime)
TABS=$(curl -s "$ENDPOINT/json" 2>/dev/null || echo "[]")
[ "$(echo "$TABS" | python3 -c 'import sys,json; print(len(json.load(sys.stdin)))')" = "0" ] && \
  TABS=$(curl -s "$ENDPOINT/json/list" 2>/dev/null || echo "[]")

echo "$TABS" | python3 -c "
import sys, json
for i, t in enumerate(json.load(sys.stdin), 1):
    ws = t.get('webSocketDebuggerUrl','')
    print(f'[{i}] {t.get(\"url\",\"\")}  ({t.get(\"title\",\"\")})' + ('  ✓' if ws else '  — no WS'))
"
# Pick one, then:
WS=$(echo "$TABS" | python3 -c "
import sys, json
t = json.load(sys.stdin)[$TARGET_INDEX - 1]
print(t.get('webSocketDebuggerUrl',''))
")
```

---

## Step 1 — Detect Available Targets

`detect-env.sh` handles everything automatically — no pre-setup needed:
- **Chrome**: reads debug port from process args
- **iOS**: starts `ios-webkit-debug-proxy` automatically if simulators are booted
- **Android**: scans `/proc/net/unix` for all `devtools_remote` sockets on every connected device, assigns free local ports dynamically

```bash
# SKILL_PATH is set automatically by the runtime.
# Claude.ai: /mnt/skills/user/browser-pilot
# Claude Code: path to the installed plugin directory
DETECT=$(bash "$SKILL_PATH/scripts/detect-env.sh")
```

**If no targets are found**, ask: _"어떤 환경을 디버깅할까요? (Chrome / Safari / iOS 시뮬레이터 / Android)"_

---

## Step 2 — Select Target and Get WS URL

Use Pattern 1 or Pattern 2 above to obtain `$WS`.

**Reference lookup by target type** (read before running commands):

| Type      | Reference                       |
| --------- | ------------------------------- |
| `chrome`  | `references/chrome.md`          |
| `safari`  | `references/safari.md`          |
| `ios`     | `references/ios-webview.md`     |
| `android` | `references/android-webview.md` |

**Multi-server / multi-port:** If the user mentions a port or path (e.g. "localhost:3001/coin"), filter the list by URL match.

---

## Step 3 — Observe (Core Commands)

Once you have `$WS` from Step 2:

```bash
# WS comes from the selected target's ws field (set in Step 2)
# Example: WS="ws://localhost:9222/devtools/page/ABC123"

# Screenshot — always start here
node "$SKILL_PATH/scripts/cdp.js" \
  --ws "$WS" --method Page.captureScreenshot \
  --params '{"format":"png"}' --extract data --base64-file snapshot.png

# Console errors
node "$SKILL_PATH/scripts/cdp.js" \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"JSON.stringify(window.__devLoopLogs||[])","returnByValue":true}' \
  --extract result.value
# Note: inject the log collector first (see references/chrome.md § Console)

# DOM snapshot (scoped)
node "$SKILL_PATH/scripts/cdp.js" \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"document.querySelector(\"#root\").innerHTML","returnByValue":true}' \
  --extract result.value

# Check an API call inline
node "$SKILL_PATH/scripts/cdp.js" \
  --ws "$WS" --method Runtime.evaluate \
  --params '{"expression":"fetch(\"/api/health\").then(r=>r.status+\" \"+r.statusText).catch(e=>\"ERR:\"+e.message)","returnByValue":true,"awaitPromise":true}' \
  --extract result.value
```

---

## Step 4 — Fix, Reload, Verify

```bash
# Hard reload after code change
node "$SKILL_PATH/scripts/cdp.js" \
  --ws "$WS" --method Page.reload --params '{"ignoreCache":true}'

# Verify with another screenshot
node "$SKILL_PATH/scripts/cdp.js" \
  --ws "$WS" --method Page.captureScreenshot \
  --params '{"format":"png"}' --extract data --base64-file after-fix.png
```

Compare `snapshot.png` (before) vs `after-fix.png` (after). If the issue persists, go back to Step 3.

---

## MCP 연동 (권장)

기존 브라우저 MCP를 사용하면 bash 스크립트 없이 Claude가 직접 브라우저를 제어할 수 있습니다.

### 환경별 추천 MCP

| 환경 | MCP 패키지 |
| ---- | ---------- |
| Chrome / Chromium | `@modelcontextprotocol/server-puppeteer` |
| 크로스브라우저 (Chrome · Firefox · Safari) | `@playwright/mcp` |
| iOS / Android WebView | bash 스크립트 방식 사용 (아래 참고) |

### 설정 방법

MCP가 설치되어 있지 않으면 먼저 설치합니다:

```bash
# Puppeteer MCP (Chrome 전용, 가볍고 빠름)
npm install -g @modelcontextprotocol/server-puppeteer

# 또는 Playwright MCP (크로스브라우저, 더 많은 기능)
npm install -g @playwright/mcp
```

그런 다음 `~/.claude/mcp.json`에 등록합니다:

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-puppeteer"]
    }
  }
}
```

또는 Playwright를 사용하는 경우:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp"]
    }
  }
}
```

### MCP 등록 확인

```bash
# Claude Code에서 확인
cat ~/.claude/mcp.json
```

MCP가 등록되면 Claude Code를 재시작해야 합니다.

**MCP가 있는 경우**: MCP 툴을 우선 사용해 브라우저를 제어합니다.
**MCP가 없거나 iOS/Android WebView인 경우**: 아래 bash 스크립트 방식을 사용합니다.

---

## Platform Setup Scripts

For mobile targets, run the setup script before Step 2:

```bash
# iOS: boots proxy, lists WebViews → outputs JSON with WS URLs
bash "$SKILL_PATH/scripts/ios-setup.sh"

# Android: ADB check, port forward, lists WebViews → outputs JSON with WS URLs
bash "$SKILL_PATH/scripts/android-setup.sh"
```

---

## Quick Reference

| Goal                            | Command                                                                                                                       |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| List Chrome tabs by port        | `curl -s "http://localhost:$CHROME_PORT/json" \| python3 -c "import sys,json; [print(t['url'],t['id']) for t in json.load(sys.stdin)]"` |
| Get WS URL for localhost:3001   | See `references/chrome.md` § "Filter by port"                                                                                 |
| Check localStorage / auth token | See `references/chrome.md` § "Storage"                                                                                        |
| iOS simulator not booted        | `xcrun simctl boot "iPhone 15 Pro" && open -a Simulator`                                                                      |

## Error Recovery

| Error                               | Cause                                | Fix                                            |
| ----------------------------------- | ------------------------------------ | ---------------------------------------------- |
| `ECONNREFUSED :$CHROME_PORT`        | Chrome not in debug mode             | See `references/chrome.md` § "Starting Chrome" |
| `ios-webkit-debug-proxy: not found` | Not installed                        | `brew install ios-webkit-debug-proxy`          |
| `adb: not found`                    | Android SDK missing                  | `brew install android-platform-tools`          |
| No WebViews in list                 | App not running / debugging disabled | See platform reference § "App Requirements"    |
| `Target closed`                     | Page navigated away                  | Re-run detect, re-attach                       |

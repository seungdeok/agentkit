# browser-pilot

**[한국어](./README.ko.md) | English**

**An agent skill for AI-native development — letting your AI agent see, interact with, and iterate on live browser tabs and mobile WebViews as it writes code.**

Instead of writing code blind, your agent can take a screenshot, catch console errors, inspect the DOM, and verify network calls — then fix the code and check again. A real development loop, not just code generation.

---

## What it does

```
You:    "The payment form isn't submitting. Fix it."

Agent:  → attach to localhost:3001
        → take screenshot  ← sees the UI
        → get console logs ← finds TypeError: token is undefined
        → reads auth.js
        → fixes the bug
        → reload page
        → take screenshot  ← confirms it works
        → "Fixed. The token wasn't being passed to the Authorization header."
```

The agent handles the full loop: **see → diagnose → fix → verify.**

---

## Skills

| Skill           | Description                                                |
| --------------- | ---------------------------------------------------------- |
| `browser-pilot` | AI-native dev loop using live browser & WebView inspection |

---

## Supported Platforms

| Platform              | Protocol                       | Requirement                                                  |
| --------------------- | ------------------------------ | ------------------------------------------------------------ |
| Chrome (Desktop)      | CDP over WebSocket             | Launch Chrome with `--remote-debugging-port`                 |
| Safari (macOS)        | WebDriver / safaridriver       | Xcode + "Allow Remote Automation" in Safari                  |
| iOS Simulator WebView | CDP via ios-webkit-debug-proxy | `brew install ios-webkit-debug-proxy`                        |
| Android WebView       | CDP via ADB port forward       | Android SDK + `WebView.setWebContentsDebuggingEnabled(true)` |

---

## Install

```bash
# Interactive (recommended)
npx skills add seungdeok/browser-pilot
```

### Claude Code

```
/plugin install browser-pilot@seungdeok
```

### Claude.ai

Upload the skill manually through the Claude.ai interface. See [Using skills in Claude](https://support.claude.com/en/articles/12512180-using-skills-in-claude#h_a4222fa77b) for instructions.

### API

See the [Skills API Quickstart](https://docs.claude.com/en/api/skills-guide#creating-a-skill) for instructions on uploading and using custom skills via the API.

---

## Usage examples

```
"Fix the login page — it's showing a blank screen"
"Why is the API call to /api/users returning 401?"
"The iOS simulator is open, check the WebView and fix the layout bug"
"Something broke on localhost:3001 after my last commit"
"The Android app WebView is blank — find out why"
"Take a screenshot of the current state and fix what's wrong"
"Check the console on the admin tab (localhost:3002)"
```

---

## Multi-server support

Works across multiple dev servers running on different ports:

```
localhost:3000  →  App shell
localhost:3001  →  Admin dashboard
localhost:3002  →  API docs / Swagger
```

The agent lists all open localhost tabs and selects the right one based on context.

---

## How the dev loop works

1. **Detect** — scan for open debug targets (Chrome ports, simulators, ADB devices)
2. **Attach** — connect to the right tab or WebView
3. **Observe** — screenshot, console logs, DOM, network calls
4. **Fix** — edit code based on what it sees
5. **Verify** — reload and confirm the fix worked
6. **Repeat** — iterate until resolved

---

## License

MIT

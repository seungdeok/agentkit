# browser-pilot

**[한국어](./README.ko.md) | English**

AI-native development loop that lets your agent see, interact with, and verify live browser tabs as it writes code.

```
open url → observe → fix code → reload → verify → repeat
```

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

## Supported Platforms

| Platform                  | Flag / Protocol              | Env var                          | Requirement                                  |
| ------------------------- | ---------------------------- | -------------------------------- | -------------------------------------------- |
| Chrome (Desktop)          | `-p chrome` (default)        | `AGENT_BROWSER_PROVIDER=chrome`  | Launch Chrome with `--remote-debugging-port` |
| Safari (macOS)            | `-p safari`                  | `AGENT_BROWSER_PROVIDER=safari`  | Xcode + "Allow Remote Automation" in Safari  |
| iOS Simulator / Device    | `-p ios --device <name>`     | `AGENT_BROWSER_PROVIDER=ios`     | Xcode + iOS Simulator or connected device    |
| Android Emulator / Device | `-p android --device <name>` | `AGENT_BROWSER_PROVIDER=android` | Android SDK + `adb`                          |

### Device selection

```bash
# iOS
npx agent-browser -p ios --device "iPhone 16 Pro" open http://localhost:3000

# Android
npx agent-browser -p android --device "Pixel 8" open http://localhost:3000

# Or via env vars (useful for CI)
export AGENT_BROWSER_PROVIDER=ios
export AGENT_BROWSER_IOS_DEVICE="iPhone 16 Pro"
npx agent-browser open http://localhost:3000
```

### Sessions

`--session <name>` runs an isolated browser instance per task — ephemeral, cleared on close.

```bash
# Two isolated instances running in parallel
npx agent-browser --session checkout open http://localhost:3000/checkout
npx agent-browser --session admin open http://localhost:3001/admin
```

---

## When to use this

- **Something looks broken** — You pushed a change and the page looks wrong, or someone reported a bug.
  ```
  "The payment page is showing a blank screen — check localhost:3000 and fix it"
  ```
- **Verify a fix actually worked** — Confirm the change had the intended effect before moving on.
  ```
  "I just updated the auth logic — check localhost:3000/login and confirm it works"
  ```
- **See the error but not the cause** — The UI looks wrong but you're not sure which code to look at.
  ```
  "The submit button doesn't do anything when I click it — figure out why"
  ```
- **A click opens a different page** — The flow involves navigating between pages or ports.
  ```
  "Click the checkout button on localhost:3000 and follow through to the confirmation page"
  ```
- **The UI embeds another origin** — The page includes an iframe or widget from a different URL.
  ```
  "The embedded payment widget on localhost:3000 isn't loading — check what's going on inside it"
  ```

---

## How the dev loop works

1. **Open** — navigate to the URL (e.g. `localhost:3000`)
2. **Observe** — screenshot, element tree, console logs, network calls
3. **Fix** — edit code based on what it sees
4. **Verify** — reload and confirm the fix worked
5. **Repeat** — iterate until resolved

# browser-pilot

**[한국어](./README.ko.md) | English**

**An agent skill for AI-native development — letting your AI agent see, interact with, and iterate on live browser tabs as it writes code.**

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

| Skill           | Description                                          |
| --------------- | ---------------------------------------------------- |
| `browser-pilot` | AI-native dev loop using live browser tab inspection |

---

## Supported Platforms

| Platform         | Protocol                             | Requirement                                  |
| ---------------- | ------------------------------------ | -------------------------------------------- |
| Chrome (Desktop) | agent-browser --cdp / --auto-connect | Launch Chrome with `--remote-debugging-port` |
| Safari (macOS)   | agent-browser -p safari              | Xcode + "Allow Remote Automation" in Safari  |

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

## When to use this

### Something looks broken
You pushed a change and the page looks wrong — or someone reported a bug and you're not sure what's happening.

```
"The payment page is showing a blank screen — check localhost:3000 and fix it"
"Something broke after my last commit, look at localhost:3001 and tell me what's wrong"
```

### You want to verify a fix actually worked
You edited the code and want to confirm the change had the intended effect before moving on.

```
"I just updated the auth logic — check localhost:3000/login and confirm it works"
"Does the fix I just made resolve the 401 error on /api/users?"
```

### You can see the error but not the cause
The user sees something off in the UI but isn't sure which part of the code to look at.

```
"The submit button doesn't do anything when I click it — figure out why"
"The form seems to submit but nothing happens after — check what's going on"
```

### A click opens a different page or service
The flow involves navigating between pages or ports, and you want the agent to follow along.

```
"Click the checkout button on localhost:3000 and follow through to the confirmation page"
"Go through the login flow on localhost:3000 and check if the redirect to localhost:3001 works"
```

### The UI embeds another origin
The page includes an iframe or widget from a different URL and you want to inspect or interact with it.

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

```
You:    "localhost:3000 확인해서 고쳐줘"

Agent:  → npx agent-browser open http://localhost:3000
        → npx agent-browser screenshot snapshot.png   ← sees blank screen
        → npx agent-browser eval "JSON.stringify(window.__devLoopLogs)"
                                                      ← finds TypeError: token is undefined
        → reads auth.js
        → fixes the bug
        → npx agent-browser eval "location.reload(true)"
        → npx agent-browser screenshot after-fix.png  ← confirms it works
        → npx agent-browser close
        → "Fixed. The token wasn't being passed to the Authorization header."
```

---

## License

MIT

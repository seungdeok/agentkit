# Safari — Dev Loop Reference

> For macOS desktop Safari only. npx agent-browser connects via safaridriver.

## One-time Setup

```bash
# Enable Develop menu (run once)
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Then manually: Safari → Develop → Allow Remote Automation
```

---

## Connect and Navigate

```bash
# Open URL in Safari
npx agent-browser -p safari open http://localhost:3000
```

---

## Screenshot

```bash
npx agent-browser screenshot safari-snap.png
```

---

## Console + DOM

```bash
# Inject console collector
npx agent-browser eval "window.__devLoopLogs=[];['log','warn','error'].forEach(l=>{const o=console[l];console[l]=(...a)=>{window.__devLoopLogs.push({level:l,msg:a.join(' ')});o(...a)}})"

# Read logs
npx agent-browser eval "JSON.stringify(window.__devLoopLogs)"

# DOM preview
npx agent-browser eval "document.body.innerHTML.slice(0,3000)"
```

---

## Interact

```bash
# Element tree
npx agent-browser snapshot -i

# Click, fill
npx agent-browser click @e1
npx agent-browser fill @e2 "value"
```

---

## Limitations

- safaridriver always opens a **new controlled window** — cannot attach to existing open tabs
- No network interception
- For richer debugging on macOS, **prefer Chrome** with `--remote-debugging-port`

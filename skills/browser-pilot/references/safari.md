# Safari — Dev Loop Reference

> For **iOS Safari on Simulator**, use `ios-webview.md` instead — ios-webkit-debug-proxy is more
> reliable and gives full CDP access. This covers macOS desktop Safari only.

Safari uses WebDriver (not raw CDP), so interaction is via `selenium-webdriver` rather than `cdp.js`.

---

## One-time Setup

```bash
# Enable Develop menu (run once)
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# Then manually: Safari → Develop → Allow Remote Automation
```

```bash
# Install selenium-webdriver (project-local)
npm install selenium-webdriver
```

---

## Dev Loop Commands

### Screenshot

```bash
node -e "
const {Builder}=require('selenium-webdriver'),fs=require('fs');
(async()=>{
  const d=await new Builder().forBrowser('safari').build();
  await d.get('http://localhost:3000');
  fs.writeFileSync('safari-snap.png',await d.takeScreenshot(),'base64');
  console.log(JSON.stringify({saved:'safari-snap.png'}));
  await d.quit();
})();
"
```

### Console + DOM

```bash
node -e "
const {Builder}=require('selenium-webdriver');
(async()=>{
  const d=await new Builder().forBrowser('safari').build();
  await d.get('http://localhost:3000');
  await d.executeScript('window.__devLoopLogs=[];[\"log\",\"warn\",\"error\"].forEach(l=>{const o=console[l];console[l]=(...a)=>{window.__devLoopLogs.push({level:l,msg:a.join(\" \")});o(...a)}})');
  const logs=await d.executeScript('return JSON.stringify(window.__devLoopLogs)');
  const dom=await d.executeScript('return document.body.innerHTML.slice(0,3000)');
  console.log(JSON.stringify({logs:JSON.parse(logs),domPreview:dom.slice(0,500)}));
  await d.quit();
})();
"
```

### Evaluate JS

```bash
node -e "
const {Builder}=require('selenium-webdriver');
(async()=>{
  const d=await new Builder().forBrowser('safari').build();
  await d.get('http://localhost:3000');
  const r=await d.executeScript('return JSON.stringify({title:document.title,url:location.href})');
  console.log(r);
  await d.quit();
})();
"
```

---

## Limitations

- safaridriver always opens a **new controlled window** — cannot attach to existing open tabs
- No network interception (no CDP `Network` domain)
- For richer debugging on macOS, **prefer Chrome** with `--remote-debugging-port`

#!/usr/bin/env node
/**
 * cdp.js — Unified CDP command runner for browser-pilot
 *
 * Works with: Chrome, iOS WebView (via ios-webkit-debug-proxy), Android WebView (via ADB forward)
 * stdout: result data  |  stderr: errors and status
 *
 * Usage:
 *   node cdp.js --ws <ws-url> --method <CDP.Method>
 *               [--params <json>] [--extract <dot.path>]
 *               [--base64-file <outfile>] [--timeout <ms>]
 *
 * Examples:
 *   # Screenshot
 *   node cdp.js --ws ws://localhost:9222/devtools/page/XXX \
 *     --method Page.captureScreenshot --params '{"format":"png"}' \
 *     --extract data --base64-file snap.png
 *
 *   # Evaluate JS
 *   node cdp.js --ws ws://localhost:9222/devtools/page/XXX \
 *     --method Runtime.evaluate \
 *     --params '{"expression":"document.title","returnByValue":true}' \
 *     --extract result.value
 */

const fs = require("fs");
const path = require("path");

// Lazy-load ws, auto-install if missing
function getWS() {
  try {
    return require("ws");
  } catch {
    process.stderr.write("Installing ws...\n");
    require("child_process").execSync(
      "npm install ws --prefix /tmp/cdp-deps --save 2>/dev/null",
      { stdio: "pipe" },
    );
    return require("/tmp/cdp-deps/node_modules/ws");
  }
}

function arg(flag) {
  const i = process.argv.indexOf(flag);
  return i !== -1 ? process.argv[i + 1] : null;
}

function dig(obj, dotPath) {
  return dotPath
    .split(".")
    .reduce((a, k) => (a != null ? a[k] : undefined), obj);
}

function cdp(wsUrl, method, params, timeoutMs) {
  const WS = getWS();
  return new Promise((resolve, reject) => {
    let done = false;
    const finish = (fn, v) => {
      if (!done) {
        done = true;
        clearTimeout(t);
        ws.terminate();
        fn(v);
      }
    };
    const ws = new WS(wsUrl);
    const t = setTimeout(
      () =>
        finish(
          reject,
          new Error(
            `Timeout ${timeoutMs}ms — target may have closed\n  URL: ${wsUrl}`,
          ),
        ),
      timeoutMs,
    );
    ws.on("error", (e) => finish(reject, new Error(`WebSocket: ${e.message}`)));
    ws.on("open", () => ws.send(JSON.stringify({ id: 1, method, params })));
    ws.on("message", (raw) => {
      const msg = JSON.parse(raw.toString());
      if (msg.id !== 1) return;
      msg.error
        ? finish(
            reject,
            new Error(`CDP [${msg.error.code}]: ${msg.error.message}`),
          )
        : finish(resolve, msg.result || {});
    });
  });
}

(async () => {
  const wsUrl = arg("--ws");
  const method = arg("--method");
  const extract = arg("--extract");
  const b64file = arg("--base64-file");
  const timeout = parseInt(arg("--timeout") || "7000", 10);
  let params;

  if (!wsUrl || !method) {
    process.stderr.write(
      "Usage: node cdp.js --ws <url> --method <method> [--params <json>] [--extract <path>] [--base64-file <path>]\n",
    );
    process.exit(1);
  }

  try {
    params = JSON.parse(arg("--params") || "{}");
  } catch {
    process.stderr.write("Invalid JSON in --params\n");
    process.exit(1);
  }

  try {
    const result = await cdp(wsUrl, method, params, timeout);

    if (b64file) {
      const b64 = dig(result, extract || "data");
      if (!b64) {
        process.stderr.write(
          `No data at "${extract}". Keys: ${Object.keys(result)}\n`,
        );
        process.exit(1);
      }
      const out = path.resolve(b64file);
      fs.writeFileSync(out, Buffer.from(b64, "base64"));
      process.stdout.write(
        JSON.stringify({
          saved: out,
          bytes: Buffer.from(b64, "base64").length,
        }) + "\n",
      );
    } else if (extract) {
      const val = dig(result, extract);
      if (val === undefined) {
        process.stderr.write(
          `"${extract}" not found.\n${JSON.stringify(result, null, 2)}\n`,
        );
        process.exit(1);
      }
      process.stdout.write(
        (typeof val === "string" ? val : JSON.stringify(val, null, 2)) + "\n",
      );
    } else {
      process.stdout.write(JSON.stringify(result, null, 2) + "\n");
    }
  } catch (e) {
    process.stderr.write(`✗ ${e.message}\n`);
    if (/ECONNREFUSED|Timeout/.test(e.message)) {
      process.stderr.write(
        "  → Re-run detect-env.sh for a fresh target list\n",
      );
      process.stderr.write(
        "  → Confirm the tab/webview has not navigated away\n",
      );
    }
    process.exit(1);
  }
})();

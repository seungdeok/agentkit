---
name: persona-pilot
description: >
  Multi-agent User Testing skill. Spawn persona agents to test specs, web services, or APIs
  and aggregate feedback into a structured report.
  Trigger when: user provides a spec document, URL, or API and asks for user testing, persona feedback,
  or UX review. Commands: /persona-pilot:init, /persona-pilot:run, /persona-pilot:improve.
  Korean triggers: "유저 테스트", "페르소나 테스트", "사용자 피드백", "UT 실행", "스펙 리뷰해줘", "페르소나 파일럿".
argument-hint: "<target-file|url|endpoint> [--mode spec|web|api] [--preset <name>]"
license: MIT
metadata:
  author: seungdeok
user-invocable: true
---

# Persona Pilot

Multi-agent User Testing skill. Given a product spec, URL, or API — create personas, run testing, and produce a structured feedback report.

```
parse target → generate personas → spawn agents → collect feedback → report
```

---

## Command Routing

| Invocation | Action |
|-----------|--------|
| `/persona-pilot:init` | Configure persona group → save to `.persona-pilot/personas.json` |
| `/persona-pilot:run` | Read personas.json → spawn agents → produce report |
| `/persona-pilot:improve` | Read report → propose concrete improvements |
| `/persona-pilot` | init → run → improve in sequence (one-stop, default) |

If no subcommand is specified, run the full pipeline.

---

## Step 0 — Detect UT Mode

| Mode | Signal | Tools |
|------|--------|-------|
| **spec** | Target is a file path (`.md`, `.txt`, `.yaml`, `.json`, `.pdf`, `.html`) | Read, Glob, Grep |
| **web** | Target contains `http://`, `https://`, or `localhost` | `npx agent-browser` |
| **api** | Target mentions API endpoints, Swagger, OpenAPI, or REST | Bash (curl) |

If ambiguous, ask the user to clarify.

---

## Step 1 — `/persona-pilot:init`

### 1a. Parse the target

**spec mode:**
```
Read the target file(s).
Extract: purpose, target users, key features, user flows, constraints.
```

**web mode:**
```bash
npx agent-browser open <url>
npx agent-browser screenshot .persona-pilot/before-test.png
npx agent-browser snapshot -i
```

**api mode:**
```bash
curl -s <base-url>/openapi.json | head -100
```

### 1b. Generate or select personas

**Option A — Auto-generate from target (recommended)**

After parsing the target, generate 3–5 personas that reflect the product's real user segments.
Each persona must follow this schema:

```json
{
  "id": "persona-1",
  "name": "Sarah",
  "role": "First-time user",
  "age": 28,
  "tech_level": "low",
  "goals": ["Sign up quickly", "Understand the value proposition"],
  "frustrations": ["Jargon-heavy UI", "Too many steps"],
  "device": "mobile",
  "test_focus": ["onboarding flow", "CTA clarity"],
  "questions": [
    "Can I understand what this product does in 10 seconds?",
    "Is the sign-up flow intuitive without a tutorial?"
  ]
}
```

**Option B — Use a preset**

Load from `presets/<preset-name>.json` in the skill directory.
Available presets: `general`, `saas`, `ecommerce`, `mobile-app`.

**Option C — Custom**

If the user provides persona descriptions, parse them into the schema above.

### 1c. Save personas

Write the persona array to `.persona-pilot/personas.json`.
Confirm: "Personas saved. Ready to run `/persona-pilot:run`."

---

## Step 2 — `/persona-pilot:run`

### 2a. Load personas

Read `.persona-pilot/personas.json`. If missing, run init first.

### 2b. Spawn persona agents in parallel

For each persona, spawn an Agent with this prompt:

```
You are <name>, a <role> (<age> years old, tech level: <tech_level>).
Your goals: <goals>
Your frustrations: <frustrations>
You are testing: <target description>
Your focus areas: <test_focus>

Answer each question from your persona's perspective:
<questions>

Then provide:
1. Overall impression (1–5 stars, with reason)
2. Top 3 things that work well
3. Top 3 pain points or confusions
4. Specific suggestions for improvement
5. Would you use this product again? Why?

Be specific. Reference actual content, UI elements, or API fields you encountered.
```

- **spec mode** — Agent uses Read/Glob/Grep to examine the document.
- **web mode** — Agent uses `npx agent-browser` to navigate and interact with the UI.
- **api mode** — Agent uses Bash/curl to call endpoints and evaluate responses.

Run all persona agents in parallel.

### 2c. Aggregate feedback → `.persona-pilot/report.md`

```markdown
# Persona Pilot Report

**Target:** <target>
**Mode:** <spec|web|api>
**Date:** <date>
**Personas tested:** <count>

---

## Executive Summary

<2–3 sentence summary>

**Average rating:** X.X / 5

---

## Persona Feedback

### <Name> — <Role> (★★★★☆)

**Overall impression:** ...
**What works well:** ...
**Pain points:** ...
**Suggestions:** ...
**Would use again:** Yes/No — ...

---

## Aggregated Insights

### Common Pain Points (2+ personas)
1. ...

### Common Strengths
1. ...

### Priority Improvement Areas
| Priority | Area | Personas affected |
|----------|------|------------------|
| High | ... | 3/5 |
| Medium | ... | 2/5 |
```

---

## Step 3 — `/persona-pilot:improve`

Read `.persona-pilot/report.md` and produce concrete improvement proposals → `.persona-pilot/improvements.md`:

```markdown
# Improvement Proposals

> **Priority guide**
> - **P0 — Critical**: Must fix before launch. Blocks core user flows or causes confusion for most users.
> - **P1 — High Impact**: Important improvements that significantly enhance the experience.
> - **P2 — Nice to Have**: Minor polish or enhancements for a better experience.

## P0 — Critical (fix before launch)

### [Issue title]
**Affected personas:** Sarah, Marcus
**Problem:** ...
**Proposed fix:** ...
**Expected impact:** ...

## P1 — High Impact
...

## P2 — Nice to Have
...
```

For each P0/P1 item:
- **spec** → rewrite the relevant section
- **web** → describe the UI/UX change
- **api** → suggest endpoint or response changes

After writing `improvements.md`, also produce `.persona-pilot/prd.md`:

```markdown
# Product Requirements Document (PRD)

**Product:** <product name or target>
**Date:** <date>
**Based on:** Persona Pilot user testing — <N> personas

---

## Background

<Why this product exists and what problem it solves. 2–3 sentences in plain language.>

---

## Goals

- <What success looks like for users>
- <What success looks like for the business>

---

## User Requirements

Requirements identified from persona testing, written in plain language.

| # | Requirement | Priority | Source personas |
|---|-------------|----------|-----------------|
| 1 | <What users need> | Must have / Should have / Nice to have | Sarah, Marcus |
| 2 | ... | | |

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Average user satisfaction | <X>/5 | 4.0/5 |
| <Other observable metric> | | |

---

## Out of Scope

- <What is explicitly NOT included in this round of improvements>

---

## Open Questions

- <Anything that needs a decision before work begins>
```

---

## Default pipeline — `/persona-pilot`

1. Detect mode from target
2. Auto-generate personas
3. Run all persona agents in parallel
4. Aggregate into `.persona-pilot/report.md`
5. Generate `.persona-pilot/improvements.md`

Final summary:
```
✓ Personas: 4 created
✓ Testing: complete (spec mode)
✓ Report: .persona-pilot/report.md
✓ Improvements: .persona-pilot/improvements.md

Average rating: 3.2/5 — Key issue: onboarding flow is unclear for non-technical users.
```

---

## agent-browser Integration (web mode)

### Installation

The CLI uses Chrome/Chromium via CDP directly.

```bash
# Install
npm i -g agent-browser
# or
brew install agent-browser
# or
cargo install agent-browser

# Download Chrome
agent-browser install

# Update to latest version
agent-browser upgrade
```

### Usage

Each persona navigates the live app in an isolated session:

```bash
npx agent-browser --session <persona-id> open <url>
npx agent-browser --session <persona-id> screenshot .persona-pilot/<persona-id>/01-landing.png
npx agent-browser --session <persona-id> snapshot -i
npx agent-browser --session <persona-id> click @e<n>
npx agent-browser --session <persona-id> fill @e<n> "<value>"
npx agent-browser --session <persona-id> screenshot .persona-pilot/<persona-id>/02-after.png
npx agent-browser --session <persona-id> eval "JSON.stringify(window.__consoleErrors||[])"
npx agent-browser --session <persona-id> close
```

---

## File Outputs

| File | Created by | Content |
|------|-----------|---------|
| `.persona-pilot/personas.json` | init | Persona definitions |
| `.persona-pilot/report.md` | run | Aggregated feedback |
| `.persona-pilot/improvements.md` | improve | Improvement proposals |
| `.persona-pilot/prd.md` | improve | Product Requirements Document |
| `.persona-pilot/<persona-id>/*.png` | run (web mode) | Screenshots per persona |

---

## Error Handling

| Situation | Action |
|-----------|--------|
| `personas.json` missing for `run` | Run init automatically |
| `npx agent-browser` not available | Warn user; fall back to text-only observation |
| Target file not found | Ask user to provide correct path |
| No personas generated | Ask user to describe target users manually |

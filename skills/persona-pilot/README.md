# persona-pilot

**English | [한국어](./README.ko.md)**

Multi-agent User Testing skill for Claude Code. Drop a product spec, URL, or API — personas are auto-generated, each agent tests the target from their perspective, and a structured feedback report is produced.

```
parse target → generate personas → spawn agents → collect feedback → report
```

---

## What it does

```
You:    "Run a user test on this spec: ./docs/onboarding.md"

Agent:  → reads the spec
        → generates 4 personas (first-time user, power user, mobile user, accessibility user)
        → each persona agent reviews the spec from their perspective
        → aggregates findings into .persona-pilot/report.md
        → proposes improvements in .persona-pilot/improvements.md
        → "Average rating: 3.2/5. Key issue: onboarding flow unclear for non-technical users."
```

---

## Commands

| Command | Description |
|---------|-------------|
| `/persona-pilot` | Full pipeline — init → run → improve (default) |
| `/persona-pilot:init` | Configure persona group (preset or auto-generated) |
| `/persona-pilot:run` | Run agents with configured personas → generate report |
| `/persona-pilot:improve` | Propose improvements based on the report |

**Quickstart:**
```
/persona-pilot ./docs/product-spec.md
```

---

## UT Modes

Auto-detected from the target:

| Mode | Target | Tools used |
|------|--------|-----------|
| **spec** | File path (`.md`, `.txt`, `.yaml`, `.json`) | Read, Glob, Grep |
| **web** | URL (`http://`, `https://`, `localhost`) | `npx agent-browser` |
| **api** | API endpoint, Swagger, OpenAPI | Bash / curl |

---

## Personas

### Auto-generation

Personas are derived from the target content. The agent reads the spec (or observes the UI/API) and generates 3–5 personas that reflect the product's real user segments.

Example persona:
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

### Presets

Use a built-in preset for common product types:

```
/persona-pilot:init --preset saas
/persona-pilot:init --preset ecommerce
/persona-pilot:init --preset mobile-app
/persona-pilot:init --preset general
```

### Custom personas

Edit `.persona-pilot/personas.json` directly, or describe personas in natural language and the agent will structure them.

---

## Report output

After `/persona-pilot:run`, a report is saved to `.persona-pilot/report.md`:

```markdown
# Persona Pilot Report

Target: ./docs/onboarding.md
Mode: spec
Personas tested: 4
Average rating: 3.2 / 5

## Executive Summary
Overall impression is mixed. Non-technical users struggle with terminology
in the onboarding flow. Power users find the feature set compelling but lack
advanced configuration docs.

## Persona Feedback

### Sarah — First-time user (★★★☆☆)
...

## Aggregated Insights

### Common Pain Points
1. Onboarding terminology too technical (3/4 personas)
2. Missing visual examples in setup guide (2/4 personas)

### Priority Improvements
| Priority | Area | Personas affected |
|----------|------|------------------|
| High | Onboarding language | 3/4 |
| Medium | Visual examples | 2/4 |
```

---

## Improvements output

After `/persona-pilot:improve`, proposals are saved to `.persona-pilot/improvements.md`:

```markdown
# Improvement Proposals

> **Priority guide**
> - **P0 — Critical**: Must fix before launch. Blocks core user flows or causes confusion for most users.
> - **P1 — High Impact**: Important improvements that significantly enhance the experience.
> - **P2 — Nice to Have**: Minor polish or enhancements for a better experience.

## P0 — Critical

### Simplify onboarding terminology
Affected personas: Sarah, Marcus
Problem: "API key provisioning" and "OAuth scope" appear in step 1 with no explanation.
Proposed fix: Replace with plain-language alternatives + tooltip definitions.
Expected impact: Reduce drop-off at step 1 by ~40%
```

---

## PRD output

After `/persona-pilot:improve`, a PRD is also saved to `.persona-pilot/prd.md`:

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

| # | Requirement | Priority | Source personas |
|---|-------------|----------|-----------------|
| 1 | <What users need> | Must have / Should have / Nice to have | Sarah, Marcus |

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Average user satisfaction | <X>/5 | 4.0/5 |

---

## Out of Scope

- <What is explicitly NOT included in this round>

---

## Open Questions

- <Anything that needs a decision before work begins>
```

---

## web mode — agent-browser integration

In web mode, each persona navigates the live app in an isolated browser session:

```bash
npx agent-browser --session persona-1 open http://localhost:3000
npx agent-browser --session persona-1 screenshot .persona-pilot/persona-1/landing.png
npx agent-browser --session persona-1 snapshot -i
npx agent-browser --session persona-1 click @e5
npx agent-browser --session persona-1 close
```

Screenshots are saved per persona under `.persona-pilot/<persona-id>/`.

---

## File structure

```
.persona-pilot/
├── personas.json          # Persona definitions (created by init)
├── report.md              # Aggregated feedback (created by run)
├── improvements.md        # Improvement proposals (created by improve)
├── prd.md                 # Product Requirements Document (created by improve)
└── <persona-id>/
    ├── 01-landing.png     # Screenshots (web mode only)
    └── 02-after-click.png
```

---

## Install

```bash
# Global
cp -r skills/persona-pilot ~/.claude/skills/

# Project-level
cp -r skills/persona-pilot ./.claude/skills/
```

Or via setup.sh:
```bash
./setup.sh
```

---

## License

MIT

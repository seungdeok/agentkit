# bug-poilot

**English | [한국어](./README.ko.md)**

Automated bug-fix skill for Claude Code. Point it at any GitHub repo — it finds an open bug issue with no PR, forks the repo, fixes the code, and opens a Draft PR.

```
find bug issue → fork & clone → analyze code → fix → commit → draft PR
```

---

## What it does

```
You:    "/bug-poilot octocat/Hello-World"

Agent:  → fetches open bug issues from octocat/Hello-World
        → skips issues already linked to a PR
        → picks the first unhandled issue
        → forks the repo to your GitHub account
        → clones the fork locally
        → reads the issue and locates the relevant code
        → applies a minimal fix
        → commits to a new branch: fix/issue-42-short-description
        → pushes to your fork
        → opens a Draft PR to the original repo
        → "Draft PR created: https://github.com/octocat/Hello-World/pull/99"
```

---

## Usage

```
/bug-poilot <owner/repo>
```

**Example:**
```
/bug-poilot vercel/next.js
```

---

## Workflow

| Step | Action |
|------|--------|
| 1. Issue selection | Finds open bug issues with no linked PR |
| 2. Issue detail | Reads full issue body and comments |
| 3. Fork & clone | `gh repo fork --clone` (reuses existing fork) |
| 4. Code analysis | Greps for relevant files, reads context |
| 5. Fix | Minimal targeted code change |
| 6. Commit | `fix/issue-<n>-<slug>` branch, push to fork |
| 7. Draft PR | Opens PR to original repo with `Closes #n` |

---

## Draft PR format

```markdown
## 문제
<what was broken, 1-3 lines>

## 원인
<root cause of the bug>

## 수정 내용
<what file/line was changed and why>

## 테스트
- [ ] test item 1
- [ ] test item 2

Closes #<issue-number>
```

---

## Requirements

- `gh` CLI authenticated (`gh auth login`)
- Write access to your fork (GitHub account with forking enabled)

---

## Install

```bash
# Global
cp -r skills/bug-poilot ~/.claude/skills/

# Project-level
cp -r skills/bug-poilot ./.claude/skills/
```

Or via setup.sh:
```bash
./setup.sh
```

---

## License

MIT

# skills

A collection of agent skills for AI-native development.

---

## Directory structure

```
skills/
├── browser-pilot/
│   ├── SKILL.md        # Skill definition (frontmatter + instructions)
│   ├── README.md       # English documentation
│   └── README.ko.md    # Korean documentation
├── persona-pilot/
│   ├── SKILL.md
│   ├── README.md
│   └── README.ko.md
└── bug-poilot/
    ├── SKILL.md
    ├── README.md
    └── README.ko.md
```

---

## Quick Install

| Skill                                        | Description                                                     | Install                                        |
| -------------------------------------------- | --------------------------------------------------------------- | ---------------------------------------------- |
| **[browser-pilot](./skills/browser-pilot/)** | AI-native dev loop using live browser tab inspection            | `cp -r skills/browser-pilot ~/.claude/skills/` |
| **[persona-pilot](./skills/persona-pilot/)** | Multi-agent user testing — drop a spec and get persona feedback | `cp -r skills/persona-pilot ~/.claude/skills/` |
| **[bug-poilot](./skills/bug-poilot/)**       | Auto-fix bug issues from any GitHub repo and open a Draft PR    | `cp -r skills/bug-poilot ~/.claude/skills/`    |

---

## Skills

### [browser-pilot](./skills/browser-pilot/)

AI-native development loop that lets your agent see, interact with, and verify live browser tabs as it writes code.

```
open url → observe → fix code → reload → verify → repeat
```

See [skills/browser-pilot/README.md](./skills/browser-pilot/README.md) for full documentation.

---

### [persona-pilot](./skills/persona-pilot/)

Multi-agent User Testing skill. Drop a product spec, URL, or API — personas are auto-generated, each agent tests from their perspective, and a structured feedback report is produced.

```
parse target → generate personas → spawn agents → collect feedback → report
```

See [skills/persona-pilot/README.md](./skills/persona-pilot/README.md) for full documentation.

---

### [bug-poilot](./skills/bug-poilot/)

Automated bug-fix skill. Point it at any GitHub repo — it finds an open bug issue with no PR, forks the repo, fixes the code, and opens a Draft PR.

```
find bug issue → fork & clone → analyze code → fix → commit → draft PR
```

See [skills/bug-poilot/README.md](./skills/bug-poilot/README.md) for full documentation.

---

## Install

### Option 1: setup.sh (recommended for teams)

Clone the repo and run the interactive setup script:

```bash
git clone https://github.com/seungdeok/skills.git
cd skills
./setup.sh
```

The script will:

1. List available skills — select individual or all
2. Choose install location:
   - **Global** (`~/.claude/skills/`) — available in all projects
   - **Project** (`./.claude/skills/`) — current project only
3. Handle overwrites with confirmation prompt

### Option 2: Manual

```bash
# Global (user-level)
cp -r skills/browser-pilot ~/.claude/skills/

# Or project-level
cp -r skills/browser-pilot ./.claude/skills/
```

Verify in Claude Code:

```
/skills
```

### Running

Once installed, the skill activates automatically when you mention a localhost URL or ask to debug a live UI. You can also invoke it directly:

```
browser-pilot
persona-pilot
bug-poilot
```

---

## License

MIT

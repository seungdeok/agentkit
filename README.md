# skills

A collection of agent skills for AI-native development.

---

## Directory structure

```
browser-pilot/
└── skills/
    └── browser-pilot/
        ├── SKILL.md        # Skill definition (frontmatter + instructions)
        ├── README.md       # Skill documentation
        └── README.ko.md    # Korean documentation
```

---

## Quick Install

| Skill                                        | Description                                          | Install                                               |
| -------------------------------------------- | ---------------------------------------------------- | ----------------------------------------------------- |
| **[browser-pilot](./skills/browser-pilot/)** | AI-native dev loop using live browser tab inspection | `/plugin marketplace install browser-pilot@seungdeok` |

---

## Skills

### [browser-pilot](./skills/browser-pilot/)

AI-native development loop that lets your agent see, interact with, and verify live browser tabs as it writes code.

```
open url → observe → fix code → reload → verify → repeat
```

See [skills/browser-pilot/README.md](./skills/browser-pilot/README.md) for full documentation.

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
```

---

## License

MIT

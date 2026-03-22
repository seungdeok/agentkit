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

### Option 1: Marketplace (recommended)

**1. Add marketplace**

```
/plugin marketplace add seungdeok/claude-plugins
```

**2. Install skill**

```
/plugin marketplace install seungdeok@browser-pilot
```

**3. Verify installation**

```
/plugin list
```

**4. Update**

```
/plugin update
```

**5. Remove**

```
/plugin remove {plugin_name}
/plugin marketplace remove seungdeok
```

### Option 2: Manual

Copy the skill to your Claude Code skills directory:

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

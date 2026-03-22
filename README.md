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

| Skill                                        | Description                                          | Install                                   |
| -------------------------------------------- | ---------------------------------------------------- | ----------------------------------------- |
| **[browser-pilot](./skills/browser-pilot/)** | AI-native dev loop using live browser tab inspection | `/plugin install browser-pilot@seungdeok` |

---

## Skills

### [browser-pilot](./skills/browser-pilot/)

AI-native development loop that lets your agent see, interact with, and verify live browser tabs as it writes code.

```
open url → observe → fix code → reload → verify → repeat
```

See [skills/browser-pilot/README.md](./skills/browser-pilot/README.md) for full documentation.

---

## License

MIT

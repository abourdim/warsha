# Warsha ورشة v1.3

**بسم الله الرحمن الرحيم**

A web-based terminal multiplexer inspired by tmux — built as a single HTML file. Split panes, manage sessions, customize colors, and connect to a real shell.

---

## Quick Start

### LOCAL mode (no setup)

Open `index.html` in any browser. Done.

### LIVE mode (real terminal)

```bash
pip install websockets
python warsha_server.py
# Open http://localhost:8765
```

---

## What is Warsha?

Warsha (ورشة) means "workshop" in Arabic. It's your digital workspace.

**Dual mode** — works both ways:

- **LOCAL** — open `index.html` directly. Built-in virtual filesystem, zero dependencies, works offline. Status bar shows LOCAL (orange).
- **LIVE** — run the Python server. Every pane becomes a real bash session with xterm.js. Tab completion, vim, colors — everything works. Status bar shows LIVE (green).

---

## Features

### Real Terminal (LIVE mode)
- xterm.js — same terminal emulator VS Code uses
- Full bash: ls --color, git, python, vim, htop, ssh
- Tab completion, Ctrl+C/D/Z, arrow key history
- Each pane is an independent shell session

### Virtual Filesystem (LOCAL mode)
- `pwd`, `ls [-la]`, `cd`, `cat`, `mkdir [-p]`, `touch`
- `rm [-rf]`, `mv`, `cp [-r]`, `tree`, `head`, `wc`
- `echo text > file`, `echo text >> file`
- Per-pane working directory with prompt display
- Persists across sessions via browser storage

### Pane Management
- Split horizontal/vertical (recursive tree)
- Drag dividers to resize
- Zoom any pane to fullscreen and back
- Navigate with keyboard or click

### 14 Islamic & Cultural Themes

| # | Theme | Inspiration |
|---|---|---|
| 0 | Default | Classic dark terminal |
| 1 | Layl ليل | Night — green phosphor |
| 2 | Oud عود | Dark wood, amber gold |
| 3 | Fajr فجر | Dawn — peach and rose |
| 4 | Rawda روضة | Garden of Medina — sage green |
| 5 | Salam سلام | Peace — sky blue |
| 6 | Filastin فلسطين | Palestine — olive, red |
| 7 | Al Madina المدينة | Medina — sandstone and gold |
| 8 | Al Hamra الحمراء | Alhambra — terracotta |
| 9 | Al Quds القدس | Jerusalem — golden stone |
| 10 | Dhahab ذهب | Gold — navy and royal gold |
| 11 | Turathi تراثي | Heritage — teal and burgundy |
| 12 | **Noor نور** | ☀️ Light — warm parchment, deep green |
| 13 | **Yasmin ياسمين** | ☀️ Light — jasmine cream, plum accent |

### Sessions & Tabs
- Save/load sessions with layout, colors, working directories
- Multiple tabs per session
- Multi-session switching
- Export/import as JSON
- Auto-persist across browser close

### tmux-Compatible Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+B "` | Split horizontal |
| `Ctrl+B %` | Split vertical |
| `Ctrl+B x` | Close pane |
| `Ctrl+B z` | Zoom pane |
| `Ctrl+B o` | Next pane |
| `Ctrl+B ↑↓←→` | Navigate panes |
| `Ctrl+B c` | New window |
| `Ctrl+B n/p` | Next/prev window |
| `Ctrl+B 0-9` | Select window |
| `Ctrl+B l` | Last window |
| `Ctrl+B ,` | Rename window |
| `Ctrl+B &` | Close window |
| `Ctrl+B d` | Detach (home) |
| `Ctrl+B s` | Session list |
| `Ctrl+B S` | Save session |
| `Ctrl+B w` | Window list |
| `Ctrl+B [` | Search in pane |
| `Ctrl+B q` | Pane numbers |
| `Ctrl+B t` | Show time |
| `Ctrl+K` | Command palette |
| `F11` | Fullscreen |

### User-Friendly Commands

```
split / hsplit / vsplit    — split panes
theme / theme madina       — list or set theme (partial match)
color hamra                — set color (partial match)
zoom                       — toggle zoom
fullscreen / fs            — toggle fullscreen
detach / home              — go to welcome screen
server / server on/off     — check or toggle server connection
```

---

## Architecture

```
Browser (http://localhost:8765)
  │
  ├─ LOCAL mode: virtual FS in JavaScript
  │
  └─ LIVE mode: xterm.js ──WebSocket──→ warsha_server.py (:8766)
                                              │
                                         PTY (bash)
```

- **HTTP :8765** — serves index.html (Python http.server)
- **WS :8766** — terminal connections (websockets library)
- **Frontend** — auto-detects: HTTP port + 1 = WS port

---

## Files

| File | Description |
|---|---|
| `index.html` | Warsha — the complete app |
| `warsha_server.py` | Python terminal server |
| `launch.sh` | Launcher with interactive menu |
| `Warsha_v1.3_tests.js` | 221 automated tests |
| `README.md` | This file |
| `TODO.md` | Roadmap and plan |
| `COMMIT.msg` | For `git commit -F` |
| `PROMPT.md` | Prompt to continue development |

---

## Testing

```bash
npm install jsdom
node Warsha_v1.3_tests.js
```

221 tests across 35 sections.

---

## The Philosophy

**Build once, save, reuse forever.**

Every time you open Warsha, بسم الله الرحمن الرحيم is at the top. A moment of intention before you work. The themes carry meaning — Filastin, Al Quds, Al Madina — every workspace is a reminder of what matters.

---

**Warsha ورشة** — your digital workshop.

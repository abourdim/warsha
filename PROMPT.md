I'm building **Warsha ورشة** — a web-based terminal multiplexer inspired by tmux. I'll upload the current files (v1.3). Here's the context:

## Architecture
- **Single `index.html`** — the full app (~1800 lines, vanilla HTML/CSS/JS)
- **`warsha_server.py`** — Python server: HTTP on port 8765, WebSocket on port 8766, spawns real bash via PTY
- **`launch.sh`** — launcher with interactive menu, system check, install, port conflict detection
- **`Warsha_v1.3_tests.js`** — 221 automated tests (node + jsdom)

## Dual Mode
- **LOCAL mode** — open `index.html` via file://, virtual filesystem in JS, works offline
- **LIVE mode** — run `python warsha_server.py`, open `http://localhost:8765`, xterm.js terminals with real bash

## What exists
- Recursive pane splitting with drag resize, zoom
- Tabs, sessions, save/load/persist via browser storage
- 14 Islamic themes (12 dark + 2 light: Noor نور, Yasmin ياسمين), Amiri calligraphy Bismillah
- tmux-compatible keybindings (Ctrl+B prefix: " % x z o c n p d s S w [ q t 0-9)
- User-friendly aliases: split, hsplit, vsplit, theme, zoom, fullscreen, detach, exit
- Virtual FS: pwd, ls, cd, cat, mkdir, touch, rm, mv, cp, tree, head, wc, echo > file
- xterm.js (from unpkg CDN) for LIVE mode panes — tab completion, colors, vim work
- Fullscreen (F11), command palette (Ctrl+K), 5 workspace presets, broadcast, watchers, timers
- Basic/Advanced mode toggle
- Server serves index.html over HTTP, auto-detects server on frontend

## Rules
- **Always increment version after each change** — version shows in HTML header, `const VERSION`, server banner, and test file
- **Always run tests after changes** — `node Warsha_v1.3_tests.js` (needs jsdom, reads from /mnt/user-data/outputs/)
- **Keep single-file identity** — index.html must work standalone in LOCAL mode
- **بسم الله الرحمن الرحيم** always visible, centered, Amiri calligraphy, top of page

## TODO / Plan

### Fixes
- [ ] xterm.js panes don't survive `render()` properly — reparenting works but needs testing with splits/resizes
- [ ] Ctrl+B in LIVE mode: xterm.js captures it — needs `attachCustomKeyEventHandler` to let it bubble to Warsha
- [ ] Server: auto-open browser on start (launch.sh does it, but standalone `python warsha_server.py` doesn't)

### Features to add
- [ ] `Ctrl+B :` — tmux command mode (type tmux commands like `split-window -h`)
- [ ] Pane resize via keyboard (`Ctrl+B Alt+↑↓←→`)
- [ ] Copy mode (`Ctrl+B [`) — scroll back, select text, copy
- [ ] Status bar shows current theme name, pane count live
- [ ] Per-session filesystem (currently global shared FS)
- [ ] `cat` with syntax highlighting for .json, .sh, .md
- [ ] `nano`-like simple text editor in LOCAL mode (`edit filename`)
- [ ] Drag-and-drop file upload into virtual FS
- [ ] Export virtual FS as zip
- [ ] Theme preview on hover in context menu color picker
- [ ] Responsive mobile layout
- [ ] `run script.sh` — execute virtual FS scripts line by line

### Quality
- [ ] README.md and README.html need updating for v1.3 changes
- [ ] COMMIT.msg needs updating
- [ ] launch.sh: update port references (8765 HTTP, 8766 WS)
- [ ] Add server health check endpoint (`/health`)
- [ ] Add `--open` flag to `warsha_server.py` to auto-open browser

---

Pick up from here. The uploaded files are the current v1.3.

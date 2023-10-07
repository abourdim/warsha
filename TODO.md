# Warsha ورشة — TODO & Plan

بسم الله الرحمن الرحيم

**Current version: v1.3**

---

## 🔴 Fixes (Priority)

- [ ] **xterm.js render survival** — panes reparent on render() but need thorough testing with multiple splits, resizes, zoom/unzoom, tab switching
- [ ] **Ctrl+B in LIVE mode** — xterm.js captures Ctrl+B before Warsha's global handler. Need `attachCustomKeyEventHandler` on each Terminal instance to intercept Ctrl+B and let it bubble
- [ ] **Server auto-open browser** — `python warsha_server.py` should have `--open` flag to launch browser automatically (launch.sh already does this)
- [ ] **favicon.ico 500** — server returns error for /favicon.ico requests. Add a handler or ignore gracefully

---

## 🟡 Quality (Before next release)

- [ ] **README.md** — update for v1.3: two-port setup, xterm.js, tmux keybindings, light themes, fullscreen
- [ ] **README.html** — regenerate from updated README.md
- [ ] **COMMIT.msg** — write commit message for v1.3
- [ ] **launch.sh ports** — update references: HTTP=8765, WS=8766
- [ ] **Server `/health` endpoint** — return JSON with version, uptime, active sessions count
- [ ] **Test coverage** — add tests for: executeCommand("server on/off"), theme partial match edge cases, fullscreen function

---

## 🟢 Features (Roadmap)

### Terminal
- [ ] **`Ctrl+B :` command mode** — tmux-style command input bar at bottom, parse commands like `split-window -h`, `resize-pane -D 5`
- [ ] **Pane resize via keyboard** — `Ctrl+B Alt+↑↓←→` to grow/shrink panes
- [ ] **Copy mode** — `Ctrl+B [` enters scroll mode, arrow keys to navigate, space to start selection, enter to copy
- [ ] **`run script.sh`** — execute virtual FS shell scripts line by line in LOCAL mode

### Filesystem
- [ ] **Per-session filesystem** — each session gets its own FS instead of global shared
- [ ] **`cat` syntax highlighting** — colorize .json, .sh, .md, .py output
- [ ] **`edit filename`** — nano-like text editor in LOCAL mode (modal, saves to virtual FS)
- [ ] **Drag-and-drop file upload** — drop files onto a pane to import into virtual FS
- [ ] **Export FS as zip** — `export-fs` command downloads the entire virtual FS as a .zip

### UI
- [ ] **Theme preview on hover** — context menu color swatches show a preview tooltip
- [ ] **Status bar live info** — show current theme name, total pane count, FS working directory
- [ ] **Responsive mobile layout** — touch-friendly, stacked panes on small screens
- [ ] **Tab drag reorder** — drag tabs to reorder windows
- [ ] **Pane border glow** — active pane has subtle accent-colored glow matching theme

### Server
- [ ] **`--open` flag** — auto-open browser on server start
- [ ] **`--single-port`** — experimental: serve HTTP and WS on same port
- [ ] **TLS support** — `--cert` and `--key` flags for HTTPS/WSS
- [ ] **Session reconnect** — if browser disconnects, reconnect to the same PTY on reload

---

## 📋 Version History

| Version | Changes |
|---------|---------|
| v0.1–v0.7 | Foundation through basic/advanced mode |
| v1.0 | Full release: automations, presets, layouts, watchers, timers, broadcast, palette, search |
| v1.1 | Virtual filesystem, Python server with PTY, ANSI parsing, dual-mode, per-pane cwd |
| v1.2 | xterm.js for LIVE mode, fullscreen, tmux-compatible keybindings, user-friendly aliases, 14 themes with Amiri calligraphy, HTTP serving |
| v1.3 | Separate HTTP/WS ports (8765/8766), works with any websockets version, version in header |

---

## 📁 File Structure

```
warsha/
├── index.html              # The app (single file, ~1800 lines)
├── warsha_server.py        # Python server (~190 lines)
├── launch.sh               # Launcher with menu (~740 lines)
├── Warsha_v1.3_tests.js    # 221 tests (~650 lines)
├── README.md               # Documentation
├── README.html             # Styled HTML docs
├── COMMIT.msg              # For git commit -F
├── COMMIT.md               # Commit message + instructions
├── PROMPT.md               # Prompt to continue in new chat
└── TODO.md                 # This file
```

---

## 🧪 Testing

```bash
npm install jsdom
node Warsha_v1.3_tests.js
```

221 tests across 35 sections:
Configuration, Tree ops, Serialization, Commands, Mode System, Sessions, Window/Tab, Pane Actions, Quick Layouts, Workspace Presets, Broadcast, Watchers, Timers, Search, Command Palette, Persistence, Utilities, DOM Structure, Integration, Virtual Filesystem, Dual Mode System, Light Themes, Theme Names Arabic, Execute Command (FS, Aliases, Core), ANSI Parsing, Palette tmux commands, Help Text, Session Serialization FS

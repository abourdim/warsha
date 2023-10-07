feat: Warsha v1.3 — real terminal, virtual FS, Islamic themes

بسم الله الرحمن الرحيم

Dual-mode architecture: LOCAL (virtual FS) + LIVE (real bash).
Single HTML file still works standalone offline.

New — Virtual Filesystem:
- ls, cd, cat, mkdir, touch, rm, mv, cp, tree, head, wc, pwd
- echo text > file, echo text >> file
- mkdir -p, rm -rf, cp -r, ls -la
- Per-pane working directory with prompt (~/ ❯)
- Persists with session save and browser storage

New — Python Terminal Server (warsha_server.py):
- HTTP :8765 serves index.html
- WebSocket :8766 spawns real bash via PTY
- Works with any Python 3 + websockets

New — xterm.js LIVE mode:
- Real terminal emulator in each pane
- Tab completion, vim, htop, ssh, colors — all work
- Auto-detects server, falls back to LOCAL mode

New — tmux-compatible keybindings:
- Added: Ctrl+B o d w s S [ q t l 0-9
- Changed: Ctrl+B s → session list, Ctrl+B S → save

New — UI:
- 14 themes → was 12, added Noor نور and Yasmin ياسمين (light)
- Amiri Arabic calligraphy font for Bismillah
- Ornamental header divider ✦ ─── ✦ ─── ✦
- Fullscreen (F11, command, button)
- Friendly aliases: split, theme, zoom, detach, exit
- Partial match: theme madina, color hamra

New — launch.sh:
- Interactive menu (check, install, start, stop, config)
- Port conflict detection with kill/auto-find/manual
- CLI mode: ./launch.sh start --port 9000

New — Testing:
- 221 tests (was 105), 35 sections
- Added: FS, dual mode, themes, executeCommand, aliases
  ANSI parsing, tmux palette, help text, session FS

Files changed:
- index.html — 1800 lines (was 1097)
- warsha_server.py — new, 190 lines
- launch.sh — new, 740 lines
- Warsha_v1.3_tests.js — 650 lines (was 246)
- README.md, README.html — rewritten
- TODO.md, PROMPT.md — new

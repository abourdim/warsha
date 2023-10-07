#!/usr/bin/env python3
"""
Warsha ورشة — Terminal Server
بسم الله الرحمن الرحيم

Usage:
    pip install websockets
    python warsha_server.py [--port 8765]

Opens http://localhost:8765 in your browser.
"""

import asyncio
import fcntl
import http.server
import json
import os
import pty
import select
import signal
import struct
import sys
import termios
import threading
import argparse

try:
    import websockets
except ImportError:
    print("Missing dependency. Install with:\n  pip install websockets")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sessions = {}


def spawn_shell(shell="/bin/bash", cols=80, rows=24):
    env = os.environ.copy()
    env["TERM"] = "xterm-256color"
    env["COLUMNS"] = str(cols)
    env["LINES"] = str(rows)
    pid, fd = pty.fork()
    if pid == 0:
        os.execvpe(shell, [shell, "--login"], env)
    else:
        set_pty_size(fd, rows, cols)
        flags = fcntl.fcntl(fd, fcntl.F_GETFL)
        fcntl.fcntl(fd, fcntl.F_SETFL, flags | os.O_NONBLOCK)
        return pid, fd


def set_pty_size(fd, rows, cols):
    try:
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    except OSError:
        pass


async def read_pty(fd, ws):
    loop = asyncio.get_event_loop()
    try:
        while True:
            await loop.run_in_executor(None, lambda: select.select([fd], [], [], 0.5))
            try:
                data = os.read(fd, 4096)
                if not data:
                    break
                await ws.send(json.dumps({"type": "output", "data": data.decode("utf-8", errors="replace")}))
            except (OSError, BlockingIOError):
                await asyncio.sleep(0.05)
    except Exception:
        pass
    finally:
        try:
            await ws.send(json.dumps({"type": "exit"}))
        except Exception:
            pass


async def handle_client(ws, path=None):
    pid = fd = read_task = None
    shell = "/bin/bash"
    try:
        async for message in ws:
            try:
                msg = json.loads(message)
            except json.JSONDecodeError:
                continue
            t = msg.get("type", "")
            if t == "spawn":
                cols, rows = msg.get("cols", 80), msg.get("rows", 24)
                if msg.get("shell"):
                    shell = msg["shell"]
                if pid is not None:
                    try: os.kill(pid, signal.SIGTERM); os.close(fd)
                    except OSError: pass
                    if read_task: read_task.cancel()
                pid, fd = spawn_shell(shell, cols, rows)
                read_task = asyncio.create_task(read_pty(fd, ws))
                sessions[ws] = {"pid": pid, "fd": fd, "task": read_task}
                await ws.send(json.dumps({"type": "spawned", "pid": pid, "shell": shell}))
            elif t == "input":
                if fd is not None:
                    try: os.write(fd, msg.get("data", "").encode("utf-8"))
                    except OSError: pass
            elif t == "resize":
                if fd is not None:
                    set_pty_size(fd, msg.get("rows", 24), msg.get("cols", 80))
                    if pid:
                        try: os.kill(pid, signal.SIGWINCH)
                        except OSError: pass
            elif t == "ping":
                await ws.send(json.dumps({"type": "pong"}))
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        if read_task: read_task.cancel()
        if pid:
            try: os.kill(pid, signal.SIGTERM)
            except OSError: pass
        if fd:
            try: os.close(fd)
            except OSError: pass
        sessions.pop(ws, None)


class WarshaHTTPHandler(http.server.SimpleHTTPRequestHandler):
    """Serve files from the script directory."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=SCRIPT_DIR, **kwargs)

    def log_message(self, format, *args):
        pass  # Silence HTTP logs

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.path = "/index.html"
        super().do_GET()


def start_http(port):
    """Run HTTP server in a background thread."""
    server = http.server.HTTPServer(("0.0.0.0", port), WarshaHTTPHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


async def main(host="0.0.0.0", ws_port=8766, http_port=8765):
    print(f"""
  ╭──────────────────────────────────────╮
  │  بسم الله الرحمن الرحيم               │
  │  Warsha ورشة v1.3 — Terminal Server   │
  ╰──────────────────────────────────────╯

  → Open   http://localhost:{http_port}
  → WS     ws://{host}:{ws_port}
  Press Ctrl+C to stop.
    """)

    start_http(http_port)

    async with websockets.serve(
        handle_client, host, ws_port,
        max_size=2**20, ping_interval=20, ping_timeout=60,
    ):
        await asyncio.Future()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Warsha Terminal Server")
    parser.add_argument("--port", type=int, default=8765, help="HTTP port (default: 8765)")
    parser.add_argument("--ws-port", type=int, default=8766, help="WebSocket port (default: 8766)")
    parser.add_argument("--host", default="0.0.0.0", help="Bind host")
    parser.add_argument("--shell", default="/bin/bash", help="Shell")
    args = parser.parse_args()

    try:
        asyncio.run(main(args.host, args.ws_port, args.port))
    except KeyboardInterrupt:
        print("\n  Warsha stopped. السلام عليكم")

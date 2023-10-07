#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  Warsha ورشة — Launcher
#  بسم الله الرحمن الرحيم
# ═══════════════════════════════════════════════════════════════

set -e

# ── Config defaults ───────────────────────────────────────────
PORT=8765
HTTP_PORT=8080
HOST="0.0.0.0"
SHELL_CMD="/bin/bash"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_PY="$SCRIPT_DIR/warsha_server.py"
INDEX_HTML="$SCRIPT_DIR/index.html"
PID_FILE="/tmp/warsha_server.pid"

# ── Colors ────────────────────────────────────────────────────
R='\033[0m'
B='\033[1m'
G='\033[32m'
Y='\033[33m'
C='\033[36m'
RD='\033[31m'
D='\033[2m'

# ── Helpers ───────────────────────────────────────────────────
ok()   { echo -e "  ${G}✓${R} $1"; }
fail() { echo -e "  ${RD}✗${R} $1"; }
warn() { echo -e "  ${Y}!${R} $1"; }
info() { echo -e "  ${D}$1${R}"; }

banner() {
    echo ""
    echo -e "${C}${B}"
    echo "  ╭──────────────────────────────────────╮"
    echo "  │  بسم الله الرحمن الرحيم               │"
    echo "  │  Warsha ورشة — Launcher              │"
    echo "  ╰──────────────────────────────────────╯"
    echo -e "${R}"
}

separator() {
    echo -e "  ${D}──────────────────────────────────────${R}"
}

# ── Check functions ───────────────────────────────────────────
check_python() {
    if command -v python3 &>/dev/null; then
        local ver
        ver=$(python3 --version 2>&1 | awk '{print $2}')
        ok "Python 3 found: $ver"
        return 0
    elif command -v python &>/dev/null; then
        local ver
        ver=$(python --version 2>&1 | awk '{print $2}')
        if [[ "$ver" == 3.* ]]; then
            ok "Python 3 found: $ver"
            return 0
        fi
    fi
    fail "Python 3 not found"
    return 1
}

check_pip() {
    if command -v pip3 &>/dev/null; then
        ok "pip3 found"
        return 0
    elif command -v pip &>/dev/null; then
        ok "pip found"
        return 0
    fi
    fail "pip not found"
    return 1
}

check_websockets() {
    if python3 -c "import websockets" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import websockets; print(websockets.__version__)" 2>/dev/null || echo "?")
        ok "websockets installed: $ver"
        return 0
    fi
    fail "websockets not installed"
    return 1
}

check_node() {
    if command -v node &>/dev/null; then
        local ver
        ver=$(node --version 2>&1)
        ok "Node.js found: $ver"
        return 0
    fi
    warn "Node.js not found (optional, for tests)"
    return 1
}

check_jsdom() {
    if node -e "require('jsdom')" 2>/dev/null; then
        ok "jsdom installed"
        return 0
    fi
    warn "jsdom not installed (optional, for tests)"
    return 1
}

check_browser() {
    local found=0
    for cmd in xdg-open open google-chrome chromium firefox brave; do
        if command -v "$cmd" &>/dev/null; then
            ok "Browser launcher: $cmd"
            BROWSER_CMD="$cmd"
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        warn "No browser launcher found"
        return 1
    fi
    return 0
}

check_files() {
    local all_ok=0
    if [ -f "$SERVER_PY" ]; then
        ok "warsha_server.py"
    else
        fail "warsha_server.py not found"; all_ok=1
    fi
    if [ -f "$INDEX_HTML" ]; then
        ok "index.html"
    else
        fail "index.html not found"; all_ok=1
    fi
    return $all_ok
}

check_server_running() {
    if [ -f "$PID_FILE" ]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

check_port() {
    # Returns 0 if port is FREE, 1 if port is IN USE
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | grep -q ":$1 " && return 1
    elif command -v netstat &>/dev/null; then
        netstat -tlnp 2>/dev/null | grep -q ":$1 " && return 1
    elif command -v lsof &>/dev/null; then
        lsof -i :"$1" &>/dev/null && return 1
    fi
    # Fallback: bash /dev/tcp
    if (echo >/dev/tcp/localhost/"$1") 2>/dev/null; then
        return 1
    fi
    # Fallback: python socket connect
    local py_cmd
    py_cmd=$(get_python 2>/dev/null)
    if [ -n "$py_cmd" ]; then
        if $py_cmd -c "
import socket,sys
s=socket.socket()
s.settimeout(1)
try: s.connect(('localhost',$1)); s.close(); sys.exit(0)
except: sys.exit(1)
" 2>/dev/null; then
            return 1
        fi
    fi
    return 0
}

port_owner() {
    # Try to identify what's using the port
    if command -v ss &>/dev/null; then
        ss -tlnp 2>/dev/null | grep ":$1 " | sed 's/.*users:(("\([^"]*\)".*/\1/' | head -1
    elif command -v lsof &>/dev/null; then
        lsof -i :"$1" -sTCP:LISTEN 2>/dev/null | awk 'NR==2{print $1}' | head -1
    else
        echo "unknown"
    fi
}

find_free_port() {
    # Find a free port starting from $1
    local p=$1
    local max=$((p + 20))
    while [ $p -le $max ]; do
        if check_port "$p"; then
            echo "$p"
            return 0
        fi
        p=$((p + 1))
    done
    return 1
}

handle_port_conflict() {
    # Called when PORT is in use. Offers options to the user.
    local owner
    owner=$(port_owner "$PORT")
    [ -z "$owner" ] && owner="unknown process"

    fail "Port $PORT is already in use by: $owner"
    echo ""
    echo -e "  ${C}Options:${R}"
    echo -e "  ${C}1${R})  Kill the process using port $PORT"
    echo -e "  ${C}2${R})  Use a different port (auto-find)"
    echo -e "  ${C}3${R})  Enter a port manually"
    echo -e "  ${C}4${R})  Cancel"
    echo ""
    echo -ne "  ${B}❯${R} "
    read -r choice

    case "$choice" in
        1)
            echo ""
            if command -v fuser &>/dev/null; then
                fuser -k "$PORT"/tcp 2>/dev/null && ok "Killed process on port $PORT" || fail "Could not kill process"
            elif command -v lsof &>/dev/null; then
                local pids
                pids=$(lsof -ti :"$PORT" 2>/dev/null)
                if [ -n "$pids" ]; then
                    echo "$pids" | xargs kill 2>/dev/null && ok "Killed process on port $PORT" || fail "Could not kill process"
                fi
            else
                fail "No tool available to kill port process (install lsof or fuser)"
                return 1
            fi
            sleep 1
            if check_port "$PORT"; then
                ok "Port $PORT is now free"
                return 0
            else
                fail "Port $PORT still in use"
                return 1
            fi
            ;;
        2)
            local free
            free=$(find_free_port "$((PORT + 1))")
            if [ -n "$free" ]; then
                PORT="$free"
                ok "Switched to port $PORT"
                update_frontend_port
                return 0
            else
                fail "No free port found in range $((PORT+1))-$((PORT+20))"
                return 1
            fi
            ;;
        3)
            echo -ne "  Port: "
            read -r new_port
            if [[ "$new_port" =~ ^[0-9]+$ ]] && [ "$new_port" -gt 0 ] && [ "$new_port" -lt 65536 ]; then
                if check_port "$new_port"; then
                    PORT="$new_port"
                    ok "Using port $PORT"
                    update_frontend_port
                    return 0
                else
                    fail "Port $new_port is also in use"
                    return 1
                fi
            else
                fail "Invalid port number"
                return 1
            fi
            ;;
        *)
            info "Cancelled"
            return 1
            ;;
    esac
}

update_frontend_port() {
    # Patch the WS_URL in index.html to match the current PORT
    if [ -f "$INDEX_HTML" ] && [ "$PORT" != "8765" ]; then
        if grep -q 'const WS_URL="ws://localhost:8765"' "$INDEX_HTML"; then
            sed -i "s|const WS_URL=\"ws://localhost:8765\"|const WS_URL=\"ws://localhost:$PORT\"|" "$INDEX_HTML"
            info "Updated index.html → ws://localhost:$PORT"
        fi
    fi
}

get_python() {
    if command -v python3 &>/dev/null; then
        echo "python3"
    elif command -v python &>/dev/null; then
        echo "python"
    fi
}

get_pip() {
    if command -v pip3 &>/dev/null; then
        echo "pip3"
    elif command -v pip &>/dev/null; then
        echo "pip"
    fi
}

# ── Actions ───────────────────────────────────────────────────
do_check() {
    echo ""
    echo -e "  ${B}System Check${R}"
    separator
    echo ""
    echo -e "  ${C}Required:${R}"
    check_python
    check_pip
    check_websockets
    echo ""
    echo -e "  ${C}Files:${R}"
    check_files
    echo ""
    echo -e "  ${C}Optional:${R}"
    check_browser
    check_node
    check_jsdom
    echo ""
    echo -e "  ${C}Server:${R}"
    if check_server_running; then
        local pid
        pid=$(cat "$PID_FILE")
        ok "Server running (PID $pid) on port $PORT"
    else
        info "Server not running"
    fi
    if check_port "$PORT"; then
        ok "Port $PORT is free"
    else
        local owner
        owner=$(port_owner "$PORT")
        [ -z "$owner" ] && owner="unknown"
        warn "Port $PORT is in use by: $owner"
    fi
    echo ""
}

do_install() {
    echo ""
    echo -e "  ${B}Install Dependencies${R}"
    separator
    echo ""

    if ! check_python; then
        fail "Python 3 is required. Install it first:"
        info "  Ubuntu/Debian:  sudo apt install python3 python3-pip"
        info "  macOS:          brew install python3"
        info "  Arch:           sudo pacman -S python python-pip"
        echo ""
        return 1
    fi

    local pip_cmd
    pip_cmd=$(get_pip)
    if [ -z "$pip_cmd" ]; then
        fail "pip not found. Install it first:"
        info "  sudo apt install python3-pip"
        echo ""
        return 1
    fi

    echo -e "  ${C}Installing websockets...${R}"
    if $pip_cmd install --upgrade websockets --break-system-packages 2>/dev/null || $pip_cmd install --upgrade websockets 2>/dev/null; then
        ok "websockets installed"
    else
        fail "Failed to install websockets"
        info "Try: $pip_cmd install websockets --user"
        echo ""
        return 1
    fi

    echo ""
    echo -e "  ${C}Install test dependencies? (optional)${R}"
    read -r -p "  Install jsdom for tests? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        if command -v npm &>/dev/null; then
            echo -e "  ${C}Installing jsdom...${R}"
            cd "$SCRIPT_DIR" && npm install jsdom 2>/dev/null && ok "jsdom installed" || warn "jsdom install failed (tests won't run)"
        else
            warn "npm not found — skip jsdom"
        fi
    fi

    echo ""
    ok "Installation complete"
    echo ""
}

do_start() {
    echo ""
    echo -e "  ${B}Starting Warsha${R}"
    separator
    echo ""

    if ! check_python; then
        fail "Python 3 required. Run install first."
        echo ""
        return 1
    fi

    if ! check_websockets; then
        fail "websockets not installed. Run install first."
        echo ""
        return 1
    fi

    if ! [ -f "$SERVER_PY" ]; then
        fail "warsha_server.py not found in $SCRIPT_DIR"
        echo ""
        return 1
    fi

    if check_server_running; then
        local pid
        pid=$(cat "$PID_FILE")
        warn "Server already running (PID $pid)"
        echo ""
    else
        # Check if port is available
        if ! check_port "$PORT"; then
            handle_port_conflict || return 1
        fi

        local py_cmd
        py_cmd=$(get_python)
        echo -e "  ${C}Starting server on port $PORT...${R}"
        $py_cmd "$SERVER_PY" --port "$PORT" --http-port "$HTTP_PORT" --host "$HOST" --shell "$SHELL_CMD" --no-browser &
        local server_pid=$!
        echo "$server_pid" > "$PID_FILE"
        sleep 1
        if kill -0 "$server_pid" 2>/dev/null; then
            ok "Server started (PID $server_pid)"
            info "ws://$HOST:$PORT"
        else
            fail "Server failed to start"
            rm -f "$PID_FILE"
            echo ""
            return 1
        fi
    fi

    # Open browser
    if [ -f "$INDEX_HTML" ]; then
        echo ""
        echo -e "  ${C}Opening browser...${R}"
        check_browser 2>/dev/null
        if [ -n "$BROWSER_CMD" ]; then
            $BROWSER_CMD "http://localhost:$HTTP_PORT" 2>/dev/null &
            ok "Opened index.html"
        else
            info "Open manually: http://localhost:$HTTP_PORT"
        fi
    fi

    echo ""
    ok "Warsha is running"
    info "Press Ctrl+C in server terminal to stop"
    echo ""
}

do_start_foreground() {
    echo ""
    echo -e "  ${B}Starting Warsha (foreground)${R}"
    separator
    echo ""

    if ! check_python; then
        fail "Python 3 required."; echo ""; return 1
    fi
    if ! check_websockets; then
        fail "websockets required."; echo ""; return 1
    fi

    # Check if port is available
    if ! check_port "$PORT"; then
        handle_port_conflict || return 1
    fi

    # Open browser first
    if [ -f "$INDEX_HTML" ]; then
        check_browser 2>/dev/null
        if [ -n "$BROWSER_CMD" ]; then
            (sleep 1 && $BROWSER_CMD "http://localhost:$HTTP_PORT" 2>/dev/null) &
        fi
    fi

    local py_cmd
    py_cmd=$(get_python)
    $py_cmd "$SERVER_PY" --port "$PORT" --http-port "$HTTP_PORT" --host "$HOST" --shell "$SHELL_CMD"
}

do_stop() {
    echo ""
    echo -e "  ${B}Stopping Warsha${R}"
    separator
    echo ""

    if check_server_running; then
        local pid
        pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null && ok "Server stopped (PID $pid)" || warn "Could not stop PID $pid"
        rm -f "$PID_FILE"
    else
        # Try to find by process name
        local pids
        pids=$(pgrep -f "warsha_server.py" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            echo "$pids" | while read -r p; do
                kill "$p" 2>/dev/null && ok "Stopped process $p"
            done
        else
            info "Server not running"
        fi
    fi
    echo ""
}

do_restart() {
    do_stop
    sleep 1
    do_start
}

do_status() {
    echo ""
    echo -e "  ${B}Server Status${R}"
    separator
    echo ""

    if check_server_running; then
        local pid
        pid=$(cat "$PID_FILE")
        ok "Server running"
        info "PID:  $pid"
        info "Port: $PORT"
        info "Host: $HOST"
        info "URL:  ws://$HOST:$PORT"
    else
        info "Server not running"
    fi
    echo ""
}

do_test() {
    echo ""
    echo -e "  ${B}Running Tests${R}"
    separator
    echo ""

    local test_file="$SCRIPT_DIR/Warsha_v1.1_tests.js"
    if [ ! -f "$test_file" ]; then
        fail "Test file not found: $test_file"
        echo ""
        return 1
    fi

    if ! command -v node &>/dev/null; then
        fail "Node.js required for tests"
        info "Install: https://nodejs.org"
        echo ""
        return 1
    fi

    if ! node -e "require('jsdom')" 2>/dev/null; then
        warn "jsdom not found, installing..."
        cd "$SCRIPT_DIR" && npm install jsdom 2>/dev/null || { fail "Could not install jsdom"; echo ""; return 1; }
    fi

    echo ""
    node "$test_file"
}

do_local() {
    echo ""
    echo -e "  ${B}Opening LOCAL mode${R}"
    separator
    echo ""

    if [ ! -f "$INDEX_HTML" ]; then
        fail "index.html not found"
        echo ""
        return 1
    fi

    check_browser 2>/dev/null
    if [ -n "$BROWSER_CMD" ]; then
        $BROWSER_CMD "http://localhost:$HTTP_PORT" 2>/dev/null &
        ok "Opened index.html in LOCAL mode (no server)"
    else
        info "Open manually: http://localhost:$HTTP_PORT"
    fi
    echo ""
}

do_config() {
    echo ""
    echo -e "  ${B}Configuration${R}"
    separator
    echo ""
    echo -e "  ${C}Current settings:${R}"
    info "Port:    $PORT"
    info "Host:    $HOST"
    info "Shell:   $SHELL_CMD"
    info "Dir:     $SCRIPT_DIR"
    echo ""

    read -r -p "  Port [$PORT]: " new_port
    [ -n "$new_port" ] && PORT="$new_port"

    read -r -p "  Host [$HOST]: " new_host
    [ -n "$new_host" ] && HOST="$new_host"

    read -r -p "  Shell [$SHELL_CMD]: " new_shell
    [ -n "$new_shell" ] && SHELL_CMD="$new_shell"

    echo ""
    ok "Updated:"
    info "Port:  $PORT"
    info "Host:  $HOST"
    info "Shell: $SHELL_CMD"
    echo ""
}

# ── Menu ──────────────────────────────────────────────────────
show_menu() {
    local running=""
    if check_server_running; then
        running="${G}● LIVE${R}"
    else
        running="${Y}○ LOCAL${R}"
    fi

    echo ""
    echo -e "  ${B}Menu${R}                            $running"
    separator
    echo ""
    echo -e "  ${C}1${R})  Check system"
    echo -e "  ${C}2${R})  Install dependencies"
    echo -e "  ${C}3${R})  Start server + open browser"
    echo -e "  ${C}4${R})  Start server (foreground)"
    echo -e "  ${C}5${R})  Stop server"
    echo -e "  ${C}6${R})  Restart server"
    echo -e "  ${C}7${R})  Server status"
    echo -e "  ${C}8${R})  Open LOCAL mode (no server)"
    echo -e "  ${C}9${R})  Run tests"
    echo -e "  ${C}c${R})  Configure (port, host, shell)"
    echo -e "  ${C}q${R})  Quit"
    echo ""
    echo -ne "  ${B}❯${R} "
}

menu_loop() {
    while true; do
        show_menu
        read -r choice
        case "$choice" in
            1) do_check ;;
            2) do_install ;;
            3) do_start ;;
            4) do_start_foreground; break ;;
            5) do_stop ;;
            6) do_restart ;;
            7) do_status ;;
            8) do_local ;;
            9) do_test ;;
            c|C) do_config ;;
            q|Q|"") echo -e "\n  ${D}السلام عليكم${R}\n"; break ;;
            *) warn "Invalid choice" ;;
        esac
    done
}

# ── CLI interface ─────────────────────────────────────────────
usage() {
    echo ""
    echo -e "  ${B}Usage:${R} ./launch.sh [command]"
    echo ""
    echo -e "  ${C}Commands:${R}"
    echo "    (none)      Interactive menu"
    echo "    check       Check system requirements"
    echo "    install     Install dependencies"
    echo "    start       Start server + open browser"
    echo "    run         Start server (foreground)"
    echo "    stop        Stop server"
    echo "    restart     Restart server"
    echo "    status      Server status"
    echo "    local       Open LOCAL mode (no server)"
    echo "    test        Run test suite"
    echo "    help        Show this help"
    echo ""
    echo -e "  ${C}Options:${R}"
    echo "    --port N    Server port (default: 8765)"
    echo "    --host H    Bind host (default: 0.0.0.0)"
    echo "    --shell S   Shell path (default: /bin/bash)"
    echo ""
}

# ── Parse args ────────────────────────────────────────────────
CMD=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)  PORT="$2"; shift 2 ;;
        --host)  HOST="$2"; shift 2 ;;
        --shell) SHELL_CMD="$2"; shift 2 ;;
        check|install|start|run|stop|restart|status|local|test|help)
            CMD="$1"; shift ;;
        -h|--help) CMD="help"; shift ;;
        *) warn "Unknown option: $1"; shift ;;
    esac
done

# ── Main ──────────────────────────────────────────────────────
banner

case "$CMD" in
    check)   do_check ;;
    install) do_install ;;
    start)   do_start ;;
    run)     do_start_foreground ;;
    stop)    do_stop ;;
    restart) do_restart ;;
    status)  do_status ;;
    local)   do_local ;;
    test)    do_test ;;
    help)    usage ;;
    "")      menu_loop ;;
esac

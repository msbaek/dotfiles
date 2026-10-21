#!/bin/bash
# visd_test.sh — regression tests for bin/visd daemon lifecycle
#
# Usage: bash tests/visd_test.sh
#
# Runs visd against a scratch port, PID file, and log file (VISD_* overrides),
# so the real vis daemon on 8741 is never touched. A fake daemon accepts TCP
# connections but never answers HTTP, which reproduces a daemon busy with a
# long rerank (health check times out while the port is still held).
#
# Regression context (2026-10-22): `visd start` treated a busy daemon as dead,
# deleted its PID file, and spawned a duplicate; afterwards `visd stop` could not
# find the daemon, so nightly reindex never reloaded the in-memory index.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VISD="$REPO_DIR/bin/visd"

WORK="$(mktemp -d)"
FAKE_PID=""
FAILURES=0

cleanup() {
  [[ -n "$FAKE_PID" ]] && kill "$FAKE_PID" 2>/dev/null
  rm -rf "$WORK"
}
trap cleanup EXIT

free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()'
}

# Listens on the port but never accepts, so HTTP requests hang until timeout
start_busy_daemon() {
  python3 -c '
import socket, sys, time
s = socket.socket()
s.bind(("127.0.0.1", int(sys.argv[1])))
s.listen(16)
time.sleep(600)
' "$VISD_PORT" &
  FAKE_PID=$!
  for _ in $(seq 1 50); do
    lsof -nP -t -iTCP:"$VISD_PORT" -sTCP:LISTEN >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  echo "setup error: fake daemon did not listen on $VISD_PORT" >&2
  exit 2
}

# Stub `vis` on PATH records any attempt to spawn a server
install_vis_stub() {
  mkdir -p "$WORK/bin"
  cat > "$WORK/bin/vis" <<EOF
#!/bin/bash
echo "\$*" >> "$WORK/vis-invocations"
EOF
  chmod +x "$WORK/bin/vis"
}

setup() {
  [[ -n "$FAKE_PID" ]] && kill "$FAKE_PID" 2>/dev/null
  FAKE_PID=""
  rm -f "$WORK/vis-invocations" "$WORK/visd.pid"
  export VISD_PORT="$(free_port)"
  export VISD_PID_FILE="$WORK/visd.pid"
  export VISD_LOG_FILE="$WORK/visd.log"
}

pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1: $2"; FAILURES=$((FAILURES + 1)); }

test_start_does_not_spawn_duplicate_when_busy_daemon_holds_port() {
  local name="${FUNCNAME[0]}"
  setup
  start_busy_daemon
  install_vis_stub

  PATH="$WORK/bin:$PATH" timeout 20 "$VISD" start > "$WORK/out" 2>&1
  local rc=$?

  if [[ -s "$WORK/vis-invocations" ]]; then
    fail "$name" "spawned a new server: $(cat "$WORK/vis-invocations")"
  elif [[ $rc -ne 0 ]]; then
    fail "$name" "exit code $rc: $(cat "$WORK/out")"
  elif [[ "$(cat "$VISD_PID_FILE" 2>/dev/null)" != "$FAKE_PID" ]]; then
    fail "$name" "PID file '$(cat "$VISD_PID_FILE" 2>/dev/null)' != listener $FAKE_PID"
  else
    pass "$name"
  fi
}

test_stop_kills_port_owner_when_pid_file_is_missing() {
  local name="${FUNCNAME[0]}"
  setup
  start_busy_daemon

  timeout 30 "$VISD" stop > "$WORK/out" 2>&1
  local rc=$?

  if kill -0 "$FAKE_PID" 2>/dev/null; then
    fail "$name" "daemon $FAKE_PID still alive: $(cat "$WORK/out")"
  elif [[ $rc -ne 0 ]]; then
    fail "$name" "exit code $rc: $(cat "$WORK/out")"
  else
    pass "$name"
  fi
}

test_status_reports_busy_daemon_as_running() {
  local name="${FUNCNAME[0]}"
  setup
  start_busy_daemon

  timeout 20 "$VISD" status > "$WORK/out" 2>&1

  if grep -q "not running" "$WORK/out"; then
    fail "$name" "reported busy daemon as not running: $(cat "$WORK/out")"
  elif ! grep -q "$FAKE_PID" "$WORK/out"; then
    fail "$name" "listener PID $FAKE_PID missing: $(cat "$WORK/out")"
  else
    pass "$name"
  fi
}

# Skills auto-start the daemon only when status says "not running"
test_status_reports_not_running_when_port_is_free() {
  local name="${FUNCNAME[0]}"
  setup

  timeout 20 "$VISD" status > "$WORK/out" 2>&1

  if grep -q "not running" "$WORK/out"; then
    pass "$name"
  else
    fail "$name" "expected 'not running': $(cat "$WORK/out")"
  fi
}

test_start_does_not_spawn_duplicate_when_busy_daemon_holds_port
test_stop_kills_port_owner_when_pid_file_is_missing
test_status_reports_busy_daemon_as_running
test_status_reports_not_running_when_port_is_free

echo "---"
if [[ $FAILURES -gt 0 ]]; then
  echo "$FAILURES test(s) failed"
  exit 1
fi
echo "all tests passed"

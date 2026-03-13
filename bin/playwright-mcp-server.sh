#!/bin/bash
# Playwright MCP HTTP Server (on-demand start/stop)

PORT=8931
CONFIG="$HOME/.playwright-mcp.json"
PID_FILE="/tmp/playwright-mcp-server.pid"
LOG_FILE="$HOME/.claude/logs/playwright-mcp-server.log"

mkdir -p "$(dirname "$LOG_FILE")"

# Subcommand: stop
if [[ "${1:-}" == "stop" ]]; then
  if [[ -f "$PID_FILE" ]]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
    echo "Playwright MCP server stopped"
  else
    echo "No running server found"
  fi
  exit 0
fi

# Already running?
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "Playwright MCP server already running (PID: $(cat "$PID_FILE"))"
  exit 0
fi

# Stale PID file cleanup
rm -f "$PID_FILE"

echo "Starting Playwright MCP server on port $PORT..."
npx @playwright/mcp@latest --config "$CONFIG" >> "$LOG_FILE" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

# Wait for ready (max 30s) — check port listening via lsof
for i in $(seq 1 30); do
  if lsof -i :"$PORT" -sTCP:LISTEN > /dev/null 2>&1; then
    echo "Playwright MCP server started (PID: $PID, log: $LOG_FILE)"
    exit 0
  fi
  sleep 1
done

echo "ERROR: Server failed to start within 30s (check $LOG_FILE)"
kill "$PID" 2>/dev/null
rm -f "$PID_FILE"
exit 1

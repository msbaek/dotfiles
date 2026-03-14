#!/bin/bash
# vis daemon server management (start/stop/status/logs)

PORT=8741
PID_FILE="$HOME/.vis-server.pid"
LOG_FILE="$HOME/.claude/logs/vis-server.log"
HEALTH_URL="http://localhost:$PORT/health"

mkdir -p "$(dirname "$LOG_FILE")"

case "${1:-start}" in
  stop)
    if [[ -f "$PID_FILE" ]]; then
      pid=$(cat "$PID_FILE")
      kill "$pid" 2>/dev/null
      rm -f "$PID_FILE"
      echo "vis daemon stopped (PID: $pid)"
    else
      echo "No running server found"
    fi
    ;;

  status)
    if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
      pid=$(cat "$PID_FILE" 2>/dev/null || echo "?")
      info=$(curl -sf "$HEALTH_URL")
      docs=$(echo "$info" | jq -r '.document_count // "?"')
      indexed=$(echo "$info" | jq -r '.indexed // "?"')
      echo "✅ vis daemon running (PID: $pid, port: $PORT)"
      echo "   Documents: $docs, Indexed: $indexed"
      echo "   Log: $LOG_FILE"
    else
      echo "❌ vis daemon not running"
    fi
    ;;

  logs)
    if [[ -f "$LOG_FILE" ]]; then
      tail -${2:-30} "$LOG_FILE"
    else
      echo "No log file: $LOG_FILE"
    fi
    ;;

  restart)
    "$0" stop
    sleep 1
    "$0" start
    ;;

  start|"")
    # Already running?
    if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
      pid=$(cat "$PID_FILE" 2>/dev/null || echo "?")
      echo "vis daemon already running (PID: $pid)"
      exit 0
    fi

    # Stale PID cleanup
    rm -f "$PID_FILE"

    echo "Starting vis daemon on port $PORT..."
    nohup vis serve >> "$LOG_FILE" 2>&1 &
    pid=$!
    echo "$pid" > "$PID_FILE"

    # Wait for ready (max 60s — first start needs index building)
    for i in $(seq 1 60); do
      if curl -sf "$HEALTH_URL" > /dev/null 2>&1; then
        docs=$(curl -sf "$HEALTH_URL" | jq -r '.document_count // "?"')
        echo "vis daemon started (PID: $pid, docs: $docs, log: $LOG_FILE)"
        exit 0
      fi
      sleep 1
    done

    echo "ERROR: vis daemon failed to start within 60s (check $LOG_FILE)"
    kill "$pid" 2>/dev/null
    rm -f "$PID_FILE"
    exit 1
    ;;

  *)
    echo "Usage: vis-daemon.sh [start|stop|restart|status|logs [N]]"
    exit 1
    ;;
esac

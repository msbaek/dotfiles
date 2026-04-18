#!/bin/bash
# obsidian-summarize.sh — Claude Obsidian Summarization
# Self-invoking pattern: Launcher mode → Executor mode (tmux)
#
# Usage:
#   Launcher:   obsidian-summarize.sh youtube-en|youtube-kr|article       (URL from Dia/clipboard)
#   With URL:   obsidian-summarize.sh --with-url youtube-en|... <url>     (URL passed directly)
#   Executor:   obsidian-summarize.sh --execute youtube-en|... <url>      (runs inside tmux)

set -euo pipefail

VAULT_ROOT="${VAULT_ROOT:-$HOME/DocumentsLocal/msbaek_vault}"
ERROR_LOG="$VAULT_ROOT/001-INBOX/error-list.md"
NOTIFIER="/opt/homebrew/bin/terminal-notifier"
SCRIPT_PATH="$(realpath "$0")"
SHARED_LOG="/tmp/obsidian-summarize.log"

# ── Helpers ──────────────────────────────────────

extract_url_from_dia() {
  osascript -e '
tell application "Dia"
    tell window 1
        repeat with t in tabs
            if isFocused of t then
                return URL of t
            end if
        end repeat
    end tell
end tell' 2>/dev/null
}

extract_url() {
  local url
  # Try Dia Browser first
  url=$(extract_url_from_dia) && [[ -n "$url" ]] && {
    echo "$url"
    return 0
  }
  # Fallback to clipboard
  url=$(pbpaste 2>/dev/null)
  echo "$url"
}

validate_url() {
  [[ "$1" =~ ^https?:// ]]
}

validate_type() {
  case "$1" in
  youtube-en | youtube-kr | article) return 0 ;;
  *) return 1 ;;
  esac
}

get_skill_command() {
  local type="$1" url="$2"
  case "$type" in
  youtube-en) echo "/obsidian:summarize-youtube en $url" ;;
  youtube-kr) echo "/obsidian:summarize-youtube kr $url" ;;
  article) echo "/obsidian:summarize-article $url" ;;
  *) return 1 ;;
  esac
}

log_error() {
  local cmd="$1" url="$2" error="$3"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Create error log with header if missing
  if [[ ! -f "$ERROR_LOG" ]]; then
    mkdir -p "$(dirname "$ERROR_LOG")"
    cat >"$ERROR_LOG" <<'HEADER'
# Obsidian Summarization Error Log

| Timestamp | Command | URL | Error |
|-----------|---------|-----|-------|
HEADER
  fi

  echo "| $timestamp | $cmd | $url | $error |" >>"$ERROR_LOG"
}

send_notification() {
  local title="$1" message="$2"
  "$NOTIFIER" \
    -title "$title" \
    -message "$message" \
    -sound default \
    -group "obsidian-summarize"
}

log() {
  local msg="[$(date '+%H:%M:%S')] $*"
  echo "$msg"
  echo "$msg" >> "$SHARED_LOG"
}

# ── Executor mode (runs inside tmux) ────────────

run_executor() {
  local type="$1" url="$2"
  local skill_cmd
  skill_cmd=$(get_skill_command "$type" "$url")

  local short_url="${url:0:60}"
  local job_id="$type | $short_url"
  log ""
  log "┏━━━ START: $job_id ━━━"
  log "┃ URL: $url"
  log "┃ Skill: $skill_cmd"

  # Serialize access — Playwright MCP server doesn't handle concurrent clients well
  local lock_file="/tmp/obsidian-summarize.lock"
  exec 9>"$lock_file"
  if ! flock -n 9; then
    log "⏳ Waiting for previous job to finish..."
    send_notification "Obsidian Summarize ⏳" "Queued: $type (waiting)"
    flock 9
  fi

  # Ensure Playwright MCP server is fresh and responsive
  # Restart if server has been running for more than 1 hour (prevents stale connections)
  local pid_file="/tmp/playwright-mcp-server.pid"
  if [[ -f "$pid_file" ]]; then
    local server_age=$(( $(date +%s) - $(stat -f%m "$pid_file") ))
    if (( server_age > 3600 )); then
      log "🔄 Server running for ${server_age}s, restarting..."
      ~/bin/playwright-mcp-server.sh stop
      sleep 1
    fi
  fi
  ~/bin/playwright-mcp-server.sh || {
    flock -u 9
    log "❌ Playwright MCP server failed to start"
    send_notification "Obsidian Summarize ❌" "Playwright MCP server failed"
    return 1
  }

  # Ensure vis daemon server is running (speeds up vis search from ~15s to ~0.1s)
  visd start 2>/dev/null | while read -r line; do log "  $line"; done

  send_notification "Obsidian Summarize" "Started: $type — $url"

  # Run claude from VAULT_ROOT so skills save files to the correct vault
  cd "$VAULT_ROOT" || {
    flock -u 9
    log "❌ Cannot cd to $VAULT_ROOT"
    send_notification "Obsidian Summarize ❌" "Cannot cd to $VAULT_ROOT"
    return 1
  }
  log "Working directory: $(pwd)"
  log "Running claude..."
  local exit_code=0
  OBSIDIAN_EXEC=1 claude --dangerously-skip-permissions --model claude-sonnet-4-6 --output-format stream-json -p "$skill_cmd" 2>&1 \
    | while IFS= read -r line; do
        # Log tool_use from assistant messages
        if [[ "$line" == *'"tool_use"'* && "$line" == *'"name"'* ]]; then
          tool=$(echo "$line" | sed -n 's/.*"tool_use".*"name":"\([^"]*\)".*/\1/p')
          [[ -z "$tool" ]] && tool=$(echo "$line" | grep -o '"name":"[^"]*"' | head -1 | sed 's/"name":"//;s/"//')
          [[ -n "$tool" ]] && log "  🔧 $tool"
        elif [[ "$line" == *'"type":"result"'* ]]; then
          log "  ✅ Complete"
        fi
      done
  exit_code=${PIPESTATUS[0]}

  flock -u 9

  if [[ $exit_code -eq 0 ]]; then
    log "✅ Done"
    log "┗━━━ END: $job_id ━━━"
    send_notification "Obsidian Summarize ✅" "Done: $type"
    sleep 3
  else
    local error_msg="claude exited with code $exit_code"
    log_error "$skill_cmd" "$url" "$error_msg"
    log "❌ Failed: $error_msg"
    log "┗━━━ END: $job_id ━━━"
    send_notification "Obsidian Summarize ❌" "Failed: $error_msg"
    echo ""
    echo "Press Enter to close this session..."
    read -r
  fi
}

# ── Tmux helper ──────────────────────────────────

launch_tmux_window() {
  local type="$1" url="$2"
  local tmux_session="obsidian"
  local window_name="$type-$(date +%H%M%S)"
  local escaped_url
  escaped_url=$(printf '%q' "$url")
  local cmd="$SCRIPT_PATH --execute $type $escaped_url"

  if tmux has-session -t "$tmux_session" 2>/dev/null; then
    tmux new-window -t "$tmux_session" -n "$window_name" "$cmd"
  else
    tmux new-session -d -s "$tmux_session" -n "$window_name" "$cmd"
  fi
}

# ── With-URL mode (called from Claude skills) ────

run_with_url() {
  local type="$1" url="$2"
  validate_type "$type" || { echo "Unknown type: $type"; exit 1; }
  validate_url "$url" || { echo "Invalid URL: $url"; exit 1; }
  launch_tmux_window "$type" "$url"
}

# ── Launcher mode (URL from Dia/clipboard) ───────

run_launcher() {
  local type="$1"
  validate_type "$type" || {
    send_notification "Obsidian Summarize ❌" "Unknown type: $type"
    exit 1
  }

  if [[ ! -d "$VAULT_ROOT/001-INBOX" ]]; then
    send_notification "Obsidian Summarize ❌" "INBOX directory not found"
    exit 1
  fi

  local url
  url=$(extract_url)

  if [[ -z "$url" ]]; then
    send_notification "Obsidian Summarize ❌" "URL을 먼저 복사하세요"
    exit 1
  fi

  if ! validate_url "$url"; then
    log_error "$type" "$url" "Invalid URL format"
    send_notification "Obsidian Summarize ❌" "Invalid URL: $url"
    exit 1
  fi

  launch_tmux_window "$type" "$url"
}

# ── Main dispatch ────────────────────────────────

if [[ "${1:-}" == "--execute" ]]; then
  shift
  run_executor "$@"
elif [[ "${1:-}" == "--with-url" ]]; then
  shift
  run_with_url "$@"
else
  run_launcher "${1:?Usage: obsidian-summarize.sh youtube-en|youtube-kr|article}"
fi

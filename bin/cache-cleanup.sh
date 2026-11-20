#!/usr/bin/env bash
# Weekly cleanup of regenerable package-manager caches (uv, npm).
#
# Usage:
#   cache-cleanup.sh                   # clean caches now and report freed space
#   cache-cleanup.sh install-agent     # run weekly (Sun 10:00) via LaunchAgent com.msbaek.cache-cleanup
#   cache-cleanup.sh uninstall-agent   # remove the LaunchAgent
#
# Hugging Face (~/.cache/huggingface) is intentionally excluded:
# vis uses both BAAI/bge-m3 and BAAI/bge-reranker-v2-m3, and re-downloading costs ~6.4G.
set -uo pipefail

# LaunchAgent runs without Homebrew on PATH.
PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

AGENT_LABEL="com.msbaek.cache-cleanup"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"
LOG_DIR="$HOME/Library/Logs/cache-cleanup"

free_kb() { df -k / | awk 'NR==2 {print $4}'; }

clean() {
  local before after
  before=$(free_kb)
  echo "== $(date '+%Y-%m-%d %H:%M:%S') cache-cleanup"

  if command -v uv >/dev/null 2>&1; then
    # No --force: skip when another uv process holds the cache instead of breaking it.
    du -sh "$(uv cache dir)" 2>/dev/null
    uv cache clean || echo "uv: cache in use, skipped"
  fi

  if command -v npm >/dev/null 2>&1; then
    du -sh "$(npm config get cache)" 2>/dev/null
    npm cache clean --force || echo "npm: cache clean failed"
  fi

  after=$(free_kb)
  echo "freed: $(( (after - before) / 1024 )) MB (free now $(( after / 1024 / 1024 )) GB)"
}

cmd="${1:-run}"
case "$cmd" in
  run)
    clean
    ;;
  install-agent)
    # The plist is a real file, not a stow symlink: launchd may skip symlinked plists at login.
    mkdir -p "$(dirname "$AGENT_PLIST")" "$LOG_DIR"
    cat >"$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$AGENT_LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/bin/cache-cleanup.sh</string><string>run</string></array>
  <key>StartCalendarInterval</key><dict>
    <key>Weekday</key><integer>0</integer>
    <key>Hour</key><integer>10</integer>
    <key>Minute</key><integer>0</integer>
  </dict>
  <key>StandardOutPath</key><string>$LOG_DIR/cleanup.log</string>
  <key>StandardErrorPath</key><string>$LOG_DIR/cleanup.log</string>
</dict>
</plist>
EOF
    launchctl bootout "gui/$(id -u)/$AGENT_LABEL" >/dev/null 2>&1 || true
    launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
    echo "cache-cleanup: weekly agent installed ($AGENT_PLIST)"
    ;;
  uninstall-agent)
    launchctl bootout "gui/$(id -u)/$AGENT_LABEL" >/dev/null 2>&1 || true
    rm -f "$AGENT_PLIST"
    echo "cache-cleanup: agent removed"
    ;;
  -h|--help|help)
    sed -n '2,10p' "$0"
    ;;
  *)
    echo "unknown command: $cmd" >&2
    exit 2
    ;;
esac

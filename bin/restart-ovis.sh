#!/usr/bin/env bash
# Manage the Ovis server (herdr-core runtime) installed at ~/.local/share/ovis/app.
#
# Usage:
#   restart-ovis.sh            # stop + start + status (default)
#   restart-ovis.sh restart
#   restart-ovis.sh start|stop|status|pair|link|phone|phone-setup   # passthrough to plugin.ts
#   restart-ovis.sh install-agent     # start Ovis at login (LaunchAgent sh.ovis.server)
#   restart-ovis.sh uninstall-agent   # remove the login agent
#
# The env values below must stay identical to the ones used at install time:
# server.pid lives under HERDR_PLUGIN_STATE_DIR, so any drift makes `stop` miss the running server.
set -euo pipefail

OVIS_APP_DIR="${OVIS_APP_DIR:-$HOME/.local/share/ovis/app}"
export HERDR_PLUGIN_CONFIG_DIR="${HERDR_PLUGIN_CONFIG_DIR:-$HOME/.config/ovis}"
export HERDR_PLUGIN_STATE_DIR="${HERDR_PLUGIN_STATE_DIR:-$HOME/.local/state/ovis}"

# Non-interactive callers (Alfred, LaunchAgent, herdr actions) may not have Homebrew on PATH.
if ! command -v bun >/dev/null 2>&1; then
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
fi
if ! command -v bun >/dev/null 2>&1; then
  echo "restart-ovis: bun not found on PATH" >&2
  exit 127
fi

if [[ ! -f "$OVIS_APP_DIR/scripts/plugin.ts" ]]; then
  echo "restart-ovis: $OVIS_APP_DIR/scripts/plugin.ts not found (set OVIS_APP_DIR)" >&2
  exit 1
fi
cd "$OVIS_APP_DIR"

plugin() { bun scripts/plugin.ts "$@"; }

AGENT_LABEL="sh.ovis.server"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

cmd="${1:-restart}"
case "$cmd" in
  restart)
    # `stop` exits 0 when Ovis is not running, non-zero only when it failed to stop.
    plugin stop
    # `start` waits for /api/health itself and exits non-zero if the server never answers.
    plugin start
    plugin status
    ;;
  install-agent)
    # Register a LaunchAgent that runs `restart-ovis.sh start` at login (same shape as Ovis install.sh).
    # The plist is a real file, not a stow symlink: launchd may skip symlinked plists at login.
    mkdir -p "$(dirname "$AGENT_PLIST")" "$HOME/Library/Logs/Ovis"
    cat >"$AGENT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$AGENT_LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$HOME/bin/restart-ovis.sh</string><string>start</string></array>
  <key>EnvironmentVariables</key><dict>
    <key>PATH</key><string>$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <!-- the server that start leaves running must survive the start process exiting -->
  <key>AbandonProcessGroup</key><true/>
  <key>StandardOutPath</key><string>$HOME/Library/Logs/Ovis/start.log</string>
  <key>StandardErrorPath</key><string>$HOME/Library/Logs/Ovis/start.log</string>
</dict>
</plist>
EOF
    launchctl bootout "gui/$(id -u)/$AGENT_LABEL" >/dev/null 2>&1 || true
    launchctl bootstrap "gui/$(id -u)" "$AGENT_PLIST"
    echo "restart-ovis: Ovis starts at login ($AGENT_PLIST)"
    ;;
  uninstall-agent)
    launchctl bootout "gui/$(id -u)/$AGENT_LABEL" >/dev/null 2>&1 || true
    rm -f "$AGENT_PLIST"
    echo "restart-ovis: login agent removed (the running server is left as is)"
    ;;
  -h|--help|help)
    sed -n '2,10p' "$0"
    ;;
  *)
    exec bun scripts/plugin.ts "$@"
    ;;
esac

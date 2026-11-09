#!/usr/bin/env bash
# Manage the Ovis server (herdr-core runtime) installed at ~/.local/share/ovis/app.
#
# Usage:
#   restart-ovis.sh            # stop + start + status (default)
#   restart-ovis.sh restart
#   restart-ovis.sh start|stop|status|pair|link|phone|phone-setup   # passthrough to plugin.ts
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

cmd="${1:-restart}"
case "$cmd" in
  restart)
    # `stop` exits 0 when Ovis is not running, non-zero only when it failed to stop.
    plugin stop
    # `start` waits for /api/health itself and exits non-zero if the server never answers.
    plugin start
    plugin status
    ;;
  -h|--help|help)
    sed -n '2,8p' "$0"
    ;;
  *)
    exec bun scripts/plugin.ts "$@"
    ;;
esac

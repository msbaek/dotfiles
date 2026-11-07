#!/bin/bash
# Install minimal Korean/English toggle setup for the current macOS user.
# - Karabiner: shift+space -> F18, Ctrl+H/J/K/L -> force English
# - macOS: "Select previous input source" hotkey = F18
# Run as the target user (not sudo). Requires Karabiner-Elements already installed system-wide.
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
KB_DIR="$HOME/.config/karabiner"

if [ ! -d /Applications/Karabiner-Elements.app ]; then
  echo "Karabiner-Elements.app not found. Install it first: brew install --cask karabiner-elements" >&2
  exit 1
fi

# 1. Karabiner config (backup existing)
mkdir -p "$KB_DIR"
if [ -f "$KB_DIR/karabiner.json" ]; then
  cp "$KB_DIR/karabiner.json" "$KB_DIR/karabiner.json.bak.$(date +%Y%m%d%H%M%S)"
fi
cp "$SRC_DIR/karabiner.json" "$KB_DIR/karabiner.json"

# 2. macOS hotkey 60 (previous input source) = F18 (keycode 79)
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 \
  '<dict><key>enabled</key><true/><key>value</key><dict><key>type</key><string>standard</string><key>parameters</key><array><integer>65535</integer><integer>79</integer><integer>8388608</integer></array></dict></dict>'
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# 3. Launch Karabiner (first launch asks for Input Monitoring permission)
open -a Karabiner-Elements

cat <<MSG

Done.
Remaining manual steps:
  1. Approve Input Monitoring for karabiner_grabber / karabiner_observer when prompted
     (System Settings > Privacy & Security > Input Monitoring).
  2. System Settings > Keyboard > Input Sources: add "2-Set Korean" if not present.
  3. Test: press shift+space in any app.
MSG

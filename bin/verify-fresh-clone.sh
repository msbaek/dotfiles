#!/usr/bin/env bash
# Verify that a fresh clone of this repo boots a clean shell on a new machine.
# Acceptance criterion: zero error lines from an interactive zsh startup.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -n "$(git -C "$REPO" status --porcelain)" ]; then
  echo "WARNING: working tree is dirty — testing committed HEAD only." >&2
fi

git clone -q "$REPO" "$WORK/clone"
mkdir -p "$WORK/home"
(cd "$WORK/clone" && stow --target="$WORK/home" .) || { echo "FAIL: stow conflict"; exit 1; }

BREW_BIN="$(dirname "$(command -v brew)")"

raw="$(env -i HOME="$WORK/home" TERM=xterm SHELL=/bin/zsh \
        PATH="$BREW_BIN":/usr/bin:/bin:/usr/sbin:/sbin \
        /bin/zsh -i -c exit 2>&1)"

# TODO(human): decide which startup output counts as a real failure.
# `is_noise <line>` must return 0 (true) for lines to ignore, 1 for real errors.
# Observed noise from this harness that is NOT a config defect:
#   "(eval):1: can't change option: zle"   ← env -i has no real tty
#   "==> Downloading Homebrew API data"    ← brew metadata fetch
#   "✔︎ JSON API packages..."
# Real defects look like:
#   "...msbaek.zsh:109: no such file or directory: .../fzf-git.sh"
#   ".zshrc:67: command not found: agf"
is_noise() {
  :
}

fails=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  if is_noise "$line"; then continue; fi
  echo "FAIL: $line"
  fails=$((fails + 1))
done <<< "$raw"

if [ "$fails" -eq 0 ]; then
  echo "PASS: fresh clone boots with no startup errors."
else
  echo "$fails error line(s) — a new machine would see these."
  exit 1
fi

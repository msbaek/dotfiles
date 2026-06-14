#!/usr/bin/env bash

# Update Brewfile with currently installed packages before commit.
#
# Homebrew 6.x note: `brew bundle dump` fails to serialize some third-party
# tap formulae (`brew info <bare-name>` returns empty), silently dropping them
# from the dump even though they are installed and their tap is present. A naive
# overwrite therefore loses still-installed packages and breaks `brew bundle
# install` reproducibility.
#
# Fix: merge instead of overwrite. Take the fresh dump, then re-append any old
# Brewfile entry the dump dropped that is *still installed*. Genuinely
# uninstalled packages are still allowed to drop, so install/uninstall sync is
# preserved in both directions.

set -eo pipefail

echo "🍺 Updating Brewfile with currently installed packages..."

# Check if Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Skipping Brewfile update."
    exit 0
fi

BREWFILE="Brewfile"
NEW="$(mktemp)"
MERGED="$(mktemp)"
KEYS="$(mktemp)"
trap 'rm -f "$NEW" "$MERGED" "$KEYS"' EXIT

# Fresh dump (may drop third-party tap formulae on Homebrew 6.x)
brew bundle dump --force --file="$NEW"

# Normalized identity for an entry line: "<type>|<basename>".
# brew/cask compare by basename so a tap-qualified name and a bare name match.
entry_key() {
    local line="$1" type rest name base
    type=${line%% *}
    rest=${line#*\"}; name=${rest%%\"*}
    case "$type" in
        brew|cask) base=${name##*/} ;;   # strip tap prefix
        *)         base=$name ;;          # tap/mas/vscode: full name
    esac
    printf '%s|%s' "$type" "$base"
}

# Keys already present in the fresh dump
grep -E '^(brew|cask|tap|mas|vscode) ' "$NEW" 2>/dev/null | while IFS= read -r line; do
    entry_key "$line"; echo
done > "$KEYS" || true

# Installed sets for the "still installed?" guard
FORMULAE=$(brew list --formula -1 2>/dev/null || true)
CASKS=$(brew list --cask -1 2>/dev/null || true)
TAPS=$(brew tap 2>/dev/null || true)

still_installed() {
    local type="$1" base="$2"
    case "$type" in
        brew) grep -qxF "$base" <<<"$FORMULAE" ;;
        cask) grep -qxF "$base" <<<"$CASKS" ;;
        tap)  grep -qxF "$base" <<<"$TAPS" ;;
        *)    return 0 ;;   # mas/vscode: preserve to be safe
    esac
}

# Collect old entries the dump dropped but that are still installed
PRESERVED_COUNT=0
cp "$NEW" "$MERGED"
if [ -f "$BREWFILE" ]; then
    {
        FIRST=1
        while IFS= read -r line; do
            key="$(entry_key "$line")"
            grep -qxF "$key" "$KEYS" && continue        # dump already kept it
            type=${key%%|*}; base=${key#*|}
            still_installed "$type" "$base" || continue # genuinely uninstalled
            if [ "$FIRST" -eq 1 ]; then
                echo ""
                echo "# --- preserved: brew bundle dump (Homebrew 6.x) drops these still-installed tap formulae ---"
                FIRST=0
            fi
            echo "$line"
            PRESERVED_COUNT=$((PRESERVED_COUNT + 1))
        done < <(grep -E '^(brew|cask|tap|mas|vscode) ' "$BREWFILE" 2>/dev/null || true)
    } >> "$MERGED"
    # PRESERVED_COUNT updated in a subshell above; recompute for the message
    PRESERVED_COUNT=$(grep -cE '^(brew|cask|tap|mas|vscode) ' "$MERGED" 2>/dev/null || echo 0)
    PRESERVED_COUNT=$((PRESERVED_COUNT - $(grep -cE '^(brew|cask|tap|mas|vscode) ' "$NEW" 2>/dev/null || echo 0)))
fi

# Write + stage only if the merged result differs from the current Brewfile
if [ ! -f "$BREWFILE" ] || ! cmp -s "$MERGED" "$BREWFILE"; then
    cp "$MERGED" "$BREWFILE"
    git add "$BREWFILE"
    if [ "$PRESERVED_COUNT" -gt 0 ]; then
        echo "✅ Brewfile updated and staged (preserved $PRESERVED_COUNT dump-dropped package(s))"
    else
        echo "✅ Brewfile updated and staged for commit"
    fi
else
    echo "ℹ️  Brewfile is already up to date"
fi

echo "✨ Brewfile update complete"

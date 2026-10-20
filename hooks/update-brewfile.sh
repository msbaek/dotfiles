#!/usr/bin/env bash

# Add newly installed packages to Brewfile (and new apps to Applications.txt)
# before commit. Add-only: nothing is ever removed or rewritten.
#
# Why add-only: one Brewfile is shared by several Macs (Intel MBP, Mac mini,
# work MacBook) whose installed sets differ. Overwriting with
# `brew bundle dump --force` deleted every entry the committing machine lacked
# (77b1f3a lost ~100 packages; e156d11 lost 67). Appending only what is new
# keeps the union, and leaves hand-written comments and
# `if Hardware::CPU.intel?` blocks intact.
#
# Removing a package is manual: `brew uninstall <pkg>`, then delete its line.

set -eo pipefail

echo "🍺 Adding newly installed packages to Brewfile..."

if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Skipping Brewfile update."
    exit 0
fi

BREWFILE="Brewfile"
APPSFILE="Applications.txt"
APPS_DIR="${APPS_DIR:-/Applications}"
NEW="$(mktemp)"
KEYS="$(mktemp)"
ADDED="$(mktemp)"
NEW_APPS="$(mktemp)"
trap 'rm -f "$NEW" "$KEYS" "$ADDED" "$NEW_APPS"' EXIT

ENTRY_RE='^[[:space:]]*[a-z_]+ "'

# Normalized identity for an entry line: "<type>|<name>".
# brew/cask compare by basename so a tap-qualified name and a bare name match.
entry_key() {
    local line="${1#"${1%%[![:space:]]*}"}" type rest name
    type=${line%% *}
    rest=${line#*\"}; name=${rest%%\"*}
    case "$type" in
        brew|cask) name=${name##*/} ;;
    esac
    printf '%s|%s\n' "$type" "$name"
}

brew bundle dump --force --file="$NEW"

touch "$BREWFILE"
# Keys already in Brewfile, including entries indented inside conditionals
grep -E "$ENTRY_RE" "$BREWFILE" | while IFS= read -r line; do
    entry_key "$line"
done > "$KEYS" || true

# Collect dump entries that Brewfile lacks, with their description comment
comment=""
while IFS= read -r line; do
    if [[ "$line" == \#* ]]; then
        comment="$line"
        continue
    fi
    if [[ "$line" =~ $ENTRY_RE ]] && ! grep -qxF "$(entry_key "$line")" "$KEYS"; then
        [ -n "$comment" ] && echo "$comment"
        echo "$line"
    fi
    comment=""
done < "$NEW" > "$ADDED"

if [ -s "$ADDED" ]; then
    cat "$ADDED" >> "$BREWFILE"
    git add "$BREWFILE"
    echo "✅ Brewfile: added $(grep -cE "$ENTRY_RE" "$ADDED") package(s)"
else
    echo "ℹ️  Brewfile already lists every installed package"
fi

# --- Applications.txt: union of recorded and installed app names ---
touch "$APPSFILE"
{ cat "$APPSFILE"; ls "$APPS_DIR" 2>/dev/null | grep '\.app$'; } | sort -u > "$NEW_APPS"

if ! cmp -s "$NEW_APPS" "$APPSFILE"; then
    cp "$NEW_APPS" "$APPSFILE"
    git add "$APPSFILE"
    echo "✅ Applications.txt: added new app(s)"
else
    echo "ℹ️  Applications.txt already lists every installed app"
fi

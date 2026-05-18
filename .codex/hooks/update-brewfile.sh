#!/usr/bin/env bash

# Update Brewfile with currently installed packages before commit

set -e

echo "🍺 Updating Brewfile with currently installed packages..."

# Check if Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew not found. Skipping Brewfile update."
    exit 0
fi

# Get the original Brewfile modification time if it exists
BREWFILE="Brewfile"
if [ -f "$BREWFILE" ]; then
    ORIGINAL_TIME=$(stat -f "%m" "$BREWFILE" 2>/dev/null || echo "0")
else
    ORIGINAL_TIME="0"
fi

# Update Brewfile
brew bundle dump --force

# Check if Brewfile was actually changed
if [ -f "$BREWFILE" ]; then
    NEW_TIME=$(stat -f "%m" "$BREWFILE" 2>/dev/null || echo "0")
    if [ "$NEW_TIME" != "$ORIGINAL_TIME" ]; then
        # Add the updated Brewfile to the commit
        git add "$BREWFILE"
        echo "✅ Brewfile updated and staged for commit"
    else
        echo "ℹ️  Brewfile is already up to date"
    fi
else
    echo "⚠️  Warning: Brewfile not found after brew bundle dump"
fi

echo "✨ Brewfile update complete"

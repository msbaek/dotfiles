#!/bin/bash
# Check for hardcoded personal paths

FILES_WITH_PATHS=$(git diff --cached --name-only | xargs grep -l "/Users/msbaek" 2>/dev/null | grep -v "SECURITY.md" | grep -v "check-hardcoded-paths.sh" || true)

if [ -n "$FILES_WITH_PATHS" ]; then
    echo "Error: Hardcoded path /Users/msbaek found! Use \$HOME or ~ instead."
    echo "Files with hardcoded paths:"
    echo "$FILES_WITH_PATHS"
    exit 1
fi

exit 0

#!/bin/bash
# Check for actual env files (non-example)

if git diff --cached --name-only | grep -E "^\.env\.[^.]*$" | grep -v "\.example$"; then
    echo "Error: Actual .env files should not be committed! Only .env.*.example files are allowed."
    exit 1
fi

exit 0

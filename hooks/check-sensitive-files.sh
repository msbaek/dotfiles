#!/bin/bash
# Check for sensitive file extensions

if git diff --cached --name-only | grep -E "\.(pem|key|p12|pfx|jks|crt|cer)$"; then
    echo "Error: Sensitive file detected! These should be in .gitignore."
    exit 1
fi

exit 0

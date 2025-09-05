#!/bin/bash

# Claude Code Hook for Apple Watch Notifications
# This script sends notifications when Claude uses tools

# Extract tool information from environment variables
TOOL_NAME="${CLAUDE_HOOK_TOOL_NAME:-Unknown Tool}"
TIMESTAMP=$(date '+%H:%M:%S')

# Create notification title and message
TITLE="🤖 Claude Code Activity"
MESSAGE="Tool: $TOOL_NAME\nTime: $TIMESTAMP"

# Send notification via terminal-notifier
/opt/homebrew/bin/terminal-notifier \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -sound default \
    -group "claude-code" \
    -activate "com.anthropic.claude-code"

# Log for debugging (optional)
echo "[$(date)] Tool called: $TOOL_NAME" >> /tmp/claude-hook.log

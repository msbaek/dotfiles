#!/bin/bash

# Claude Code Apple Watch Notification Hook
# This script sends notifications that will appear on Apple Watch when iPhone is locked

# Parse the hook event type from environment variable
EVENT_TYPE="${CLAUDE_HOOK_EVENT:-unknown}"
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
EXIT_CODE="${CLAUDE_TOOL_EXIT_CODE:-0}"

# Function to send notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-default}"

    # Check if terminal-notifier is installed
    if ! command -v terminal-notifier &> /dev/null; then
        echo "Warning: terminal-notifier not installed. Please run: brew install terminal-notifier" >&2
        return 1
    fi

    # Send notification with high priority to ensure Apple Watch delivery
    terminal-notifier \
        -title "$title" \
        -message "$message" \
        -sound "$sound" \
        -ignoreDnD \
        -activate "com.anthropic.claude-code"
}

# Handle different event types
case "$EVENT_TYPE" in
    "PostToolUse")
        # Check for specific conditions that need user attention
        if [[ "$EXIT_CODE" != "0" ]]; then
            # Tool failed - needs attention
            send_notification "Claude Code: Error" "Tool $TOOL_NAME failed. Check required." "Basso"
        elif [[ "$TOOL_NAME" == "AskUser" || "$TOOL_NAME" == "PermissionRequest" ]]; then
            # User input needed
            send_notification "Claude Code: Input Needed" "Your response is required" "Glass"
        fi
        ;;

    "Stop")
        # Claude finished responding
        send_notification "Claude Code: Complete" "Task completed. Ready for review." "Ping"
        ;;

    "UserPromptSubmit")
        # Check if this is a permission request or error state
        if [[ "$1" == *"permission"* ]] || [[ "$1" == *"error"* ]] || [[ "$1" == *"blocked"* ]]; then
            send_notification "Claude Code: Attention" "Action required in Claude" "Purr"
        fi
        ;;
esac

# Always exit successfully to not block Claude's operation
exit 0

#!/bin/bash
# Claude Code hook — notifies VS Code extension
# Works for both Stop and Notification events
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# PID chain: zsh (shell) → claude/node (PPID) → this script
# VS Code terminal.processId = shell PID = grandparent of this script
SHELL_PID=$(ps -p $PPID -o ppid= 2>/dev/null | tr -d ' ')

WORKSPACE_PATH=$(pwd)

mkdir -p /tmp/claude-notify

HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "Stop"')

if [ "$HOOK_EVENT" = "Notification" ]; then
    SUMMARY="Needs your input"
else
    SUMMARY=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | head -1 | cut -c1-100)
fi

jq -n --arg shellPid "${SHELL_PID:-0}" --arg summary "$SUMMARY" --arg workspacePath "$WORKSPACE_PATH" \
    '{shellPid: ($shellPid | tonumber), summary: $summary, workspacePath: $workspacePath}' \
    > "/tmp/claude-notify/${SESSION_ID}.json"
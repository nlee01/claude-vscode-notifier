#!/bin/bash
# Claude Code Stop hook — generates session name, notifies VS Code extension
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')

# PID chain: zsh (shell) → claude/node (PPID) → this script
# VS Code terminal.processId = shell PID = grandparent of this script
SHELL_PID=$(ps -p $PPID -o ppid= 2>/dev/null | tr -d ' ')

WORKSPACE_PATH=$(pwd)

mkdir -p /tmp/claude-notify /tmp/claude-notify-names

NAME_FILE="/tmp/claude-notify-names/${SESSION_ID}"
if [ ! -f "$NAME_FILE" ]; then
    NAME=""
    if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
        FIRST_MSG=$(grep '"type":"user"' "$TRANSCRIPT_PATH" \
            | grep -v '"Request interrupted' \
            | head -1 \
            | jq -r '.message.content | if type == "array" then .[0].text else . end' 2>/dev/null \
            | head -1)
    fi

    if [ -n "$FIRST_MSG" ]; then
        NAME=$(echo "$FIRST_MSG" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alpha:]' ' ' | tr -s ' ' | sed 's/^ //' | cut -d' ' -f1-3 | sed 's/ *$//')
    fi

    [ -z "$NAME" ] && NAME="claude session"
    echo "$NAME" > "$NAME_FILE"
else
    NAME=$(cat "$NAME_FILE" 2>/dev/null || echo "claude session")
fi

SUMMARY=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | head -1 | cut -c1-100)

jq -n --arg shellPid "${SHELL_PID:-0}" --arg name "$NAME" --arg summary "$SUMMARY" --arg workspacePath "$WORKSPACE_PATH" \
    '{shellPid: ($shellPid | tonumber), name: $name, summary: $summary, workspacePath: $workspacePath}' \
    > "/tmp/claude-notify/${SESSION_ID}.json"

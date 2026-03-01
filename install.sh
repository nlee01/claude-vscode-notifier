#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check dependencies
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
fi

if ! command -v code &>/dev/null; then
    echo "Warning: VS Code 'code' CLI not found. Notification click-to-open may not work."
    echo "Install it: VS Code → Cmd+Shift+P → 'Shell Command: Install code command in PATH'"
fi

# 1. Install the stop hook script
cp "$SCRIPT_DIR/notify.sh" ~/.claude/notify.sh
chmod +x ~/.claude/notify.sh
echo "✓ Installed notify.sh → ~/.claude/notify.sh"

# 2. Install the notifier app (terminal-notifier with Claude icon)
mkdir -p ~/.claude/notifier
rm -rf ~/.claude/notifier/claude-notifier.app
cp -R "$SCRIPT_DIR/claude-notifier.app" ~/.claude/notifier/claude-notifier.app
echo "✓ Installed claude-notifier.app → ~/.claude/notifier/"

# 3. Install the VS Code extension
EXT_DIR="$HOME/.vscode/extensions/custom.claude-code-notifier-0.0.1"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/extension/"* "$EXT_DIR/"
echo "✓ Installed VS Code extension → $EXT_DIR/"

# 4. Configure Claude Code hooks (Stop + Notification)
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

HOOK_CMD="/Users/$USER/.claude/notify.sh"
HOOK_ENTRY='{"matcher": ".*", "hooks": [{"type": "command", "command": "'"$HOOK_CMD"'"}]}'

for EVENT in Stop Notification; do
    if jq -e ".hooks.${EVENT}[]?.hooks[]? | select(.command == \"$HOOK_CMD\")" "$SETTINGS_FILE" &>/dev/null; then
        echo "✓ ${EVENT} hook already configured"
    else
        jq ".hooks.${EVENT} = ((.hooks.${EVENT} // []) + [$HOOK_ENTRY])" "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
        echo "✓ Added ${EVENT} hook to $SETTINGS_FILE"
    fi
done

# 5. Create temp directory
mkdir -p /tmp/claude-notify

echo ""
echo "Done! Reload VS Code (Cmd+Shift+P → 'Developer: Reload Window') to activate."

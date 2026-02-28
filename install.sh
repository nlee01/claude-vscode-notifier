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

# 4. Configure the Claude Code stop hook
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{}' > "$SETTINGS_FILE"
fi

HOOK_CMD="/Users/$USER/.claude/notify.sh"

# Check if hook already exists
if jq -e '.hooks.Stop[]?.hooks[]? | select(.command == "'"$HOOK_CMD"'")' "$SETTINGS_FILE" &>/dev/null; then
    echo "✓ Stop hook already configured"
else
    # Add the stop hook
    jq '.hooks.Stop = ((.hooks.Stop // []) + [{"matcher": ".*", "hooks": [{"type": "command", "command": "'"$HOOK_CMD"'"}]}])' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
    mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    echo "✓ Added Stop hook to $SETTINGS_FILE"
fi

# 5. Create temp directories
mkdir -p /tmp/claude-notify /tmp/claude-notify-names

echo ""
echo "Done! Reload VS Code (Cmd+Shift+P → 'Developer: Reload Window') to activate."

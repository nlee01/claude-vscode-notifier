# Claude Code Notifier for VS Code

macOS notifications when Claude Code needs your attention in VS Code.

**What it does:**
- Shows a macOS notification + sound when Claude finishes a task or needs your input (questions, permission prompts)
- Uses your terminal tab name in the notification banner (rename tabs to identify sessions)
- Clicking the notification opens the right VS Code workspace and switches to the Claude terminal
- Works across multiple VS Code windows — each window only claims its own terminals

**What it doesn't do:**
- Notify you if you're already watching the terminal (no spam)

## Requirements

- macOS
- VS Code
- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)
- `jq` — install with `brew install jq`

## Install

```bash
git clone git@github.com:nlee01/claude-vscode-notifier.git
cd claude-vscode-notifier
./install.sh
```

Then reload VS Code: `Cmd+Shift+P` → "Developer: Reload Window"

## What gets installed

| File | Location | Purpose |
|------|----------|---------|
| `notify.sh` | `~/.claude/notify.sh` | Claude Code hook — writes notify file with summary |
| `claude-notifier.app` | `~/.claude/notifier/` | terminal-notifier with Claude icon |
| `extension.js` | `~/.vscode/extensions/custom.claude-code-notifier-0.0.1/` | VS Code extension — sends notification, handles click |

The install script also adds Stop and Notification hooks to `~/.claude/settings.json`.

## Uninstall

```bash
rm ~/.claude/notify.sh
rm -rf ~/.claude/notifier
rm -rf ~/.vscode/extensions/custom.claude-code-notifier-0.0.1
```

Remove the Stop and Notification hook entries from `~/.claude/settings.json` manually.

## How it works

1. Claude Code fires a **Stop** hook after each response and a **Notification** hook when it needs user input (questions, permission prompts)
2. `notify.sh` writes a JSON file to `/tmp/claude-notify/` with the summary ("Needs your input" for notifications, last assistant message for stops)
3. The VS Code extension watches that directory, filters by workspace path, matches the terminal by PID, and sends a macOS notification using your terminal tab name
4. Clicking the notification runs `code <workspace-path>` to focus the right window, then the extension switches to the correct terminal

**Tip:** To make notifications persist until dismissed, go to **System Settings → Notifications → terminal-notifier** and change from "Banners" to "Alerts".

## Attribution

Uses [terminal-notifier](https://github.com/julienXX/terminal-notifier) (MIT license) by Julien Blanchard.

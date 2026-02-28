# Claude Code Notifier for VS Code

macOS notifications when Claude Code finishes a task in VS Code.

**What it does:**
- Plays a sound and shows a macOS notification when Claude finishes
- Renames the terminal tab to the first few words of your prompt (e.g. "fix auth bug")
- Clicking the notification opens the right VS Code workspace and switches to the Claude terminal
- Works across multiple VS Code windows

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
| `notify.sh` | `~/.claude/notify.sh` | Claude Code stop hook — extracts session name + summary, writes notify file |
| `claude-notifier.app` | `~/.claude/notifier/` | terminal-notifier with Claude icon |
| `extension.js` | `~/.vscode/extensions/custom.claude-code-notifier-0.0.1/` | VS Code extension — renames tab, sends notification, handles click |

The install script also adds a Stop hook to `~/.claude/settings.json`.

## Uninstall

```bash
rm ~/.claude/notify.sh
rm -rf ~/.claude/notifier
rm -rf ~/.vscode/extensions/custom.claude-code-notifier-0.0.1
```

Remove the Stop hook entry from `~/.claude/settings.json` manually.

## How it works

1. Claude Code fires a Stop hook after each response
2. `notify.sh` extracts a 3-word session name from your first message, grabs the last response as a summary, and writes a JSON file to `/tmp/claude-notify/`
3. The VS Code extension watches that directory, matches the terminal by PID, renames the tab, and sends a macOS notification
4. Clicking the notification runs `code <workspace-path>` to focus the right window, then the extension switches to the correct terminal

## Attribution

Uses [terminal-notifier](https://github.com/julienXX/terminal-notifier) (MIT license) by Julien Blanchard.

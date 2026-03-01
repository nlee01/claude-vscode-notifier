const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const NOTIFY_DIR = '/tmp/claude-notify';
let watcher = null;
let pendingTerminalShow = null; // auto-focus terminal when window regains focus

function activate(context) {
    try { fs.mkdirSync(NOTIFY_DIR, { recursive: true }); } catch (e) {}

    watcher = fs.watch(NOTIFY_DIR, (_, filename) => {
        if (filename?.endsWith('.json')) setTimeout(() => handleNotify(filename), 200);
    });

    context.subscriptions.push(
        vscode.window.onDidChangeWindowState(s => {
            if (s.focused && pendingTerminalShow) {
                pendingTerminalShow.show(false);
                pendingTerminalShow = null;
            }
        }),
        { dispose: () => watcher?.close() }
    );
}

// Match terminal by shell PID, retrying up to 3 times (300ms apart)
async function findTerminalByPid(shellPid, retries = 3) {
    for (let i = 0; i < retries; i++) {
        const terminals = vscode.window.terminals;
        const pids = await Promise.all(terminals.map(t => t.processId));
        const idx = pids.indexOf(shellPid);
        if (idx !== -1) return terminals[idx];
        if (i < retries - 1) await new Promise(r => setTimeout(r, 300));
    }
    return null;
}

// Show terminal and wait for it to become activeTerminal before renaming
async function renameTerminal(target, name) {
    const prev = vscode.window.activeTerminal;
    target.show(true); // preserveFocus=true, no flicker

    const deadline = Date.now() + 500;
    while (vscode.window.activeTerminal !== target && Date.now() < deadline) {
        await new Promise(r => setTimeout(r, 10));
    }

    await vscode.commands.executeCommand('workbench.action.terminal.renameWithArg', { name });

    if (prev && prev !== target) prev.show(true);
}

async function handleNotify(filename) {
    const filepath = path.join(NOTIFY_DIR, filename);

    // Banner click signal — show the pending terminal
    if (filename === 'click.json') {
        try { fs.unlinkSync(filepath); } catch (e) {}
        if (pendingTerminalShow) {
            pendingTerminalShow.show(false);
            pendingTerminalShow = null;
        }
        return;
    }

    let data;
    try { data = JSON.parse(fs.readFileSync(filepath, 'utf8')); } catch (e) { return; }

    const { shellPid, name, summary, workspacePath } = data;

    if (workspacePath) {
        const wsRoot = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
        if (wsRoot && !workspacePath.startsWith(wsRoot)) return;
    }

    const target = await findTerminalByPid(shellPid);

    if (!target) {
        // Not our terminal — clean up orphan after 3s
        setTimeout(() => { try { fs.unlinkSync(filepath); } catch (e) {} }, 3000);
        return;
    }

    try { fs.unlinkSync(filepath); } catch (e) { return; } // claim

    const watching = target === vscode.window.activeTerminal && vscode.window.state.focused;

    if (name && name !== 'claude session') {
        await renameTerminal(target, name);
    }

    if (watching) return;

    // macOS banner — click opens the right workspace, focus handler shows the terminal
    pendingTerminalShow = target;
    const wsPath = vscode.workspace.workspaceFolders?.[0]?.uri.fsPath;
    const openCmd = wsPath ? `/opt/homebrew/bin/code "${wsPath}"` : 'open -a "Visual Studio Code"';
    const label = summary ? `${name}: ${summary}` : `${name || 'Claude'}: Task complete`;
    const escaped = label.replace(/"/g, '\\"');
    const clickSignal = `echo '{}' > ${NOTIFY_DIR}/click.json`;
    const notifier = `${process.env.HOME}/.claude/notifier/claude-notifier.app/Contents/MacOS/terminal-notifier`;
    exec(`"${notifier}" -title "Claude Code" -message "${escaped}" -sound Purr -execute '${clickSignal} && ${openCmd}'`);
}

function deactivate() { watcher?.close(); }

module.exports = { activate, deactivate };

#!/bin/bash
# Claude Code install & configuration
# Run standalone or via setup_rocky.sh. Requires Node.js/npm (installed by setup_rocky.sh).

if ! command -v npm >/dev/null 2>&1; then
	echo "[ERROR] npm not found — run setup_rocky.sh first (installs Node.js 20)."
	exit 1
fi

# Claude Code
echo "Claude Code installation..."
npm install -g @anthropic-ai/claude-code

echo "Claude Code configuration..."
mkdir -p ~/.claude/projects/-data
ln -sfn ~/dotfiles/claude/CLAUDE.md   ~/.claude/CLAUDE.md
ln -sfn ~/dotfiles/claude/skills      ~/.claude/skills
ln -sfn ~/dotfiles/claude/memory      ~/.claude/projects/-data/memory
ln -sfn ~/dotfiles/claude/admin-core  ~/.claude/admin-core

# Restore previous Claude state from old server (requires OLD_SERVER env var; skip silently if unset)
#if [ -n "$OLD_SERVER" ]; then
#	echo "restoring Claude state from $OLD_SERVER..."
#	REMOTE_DIR="/root/claude-backups"
#	LATEST=$(ssh -o StrictHostKeyChecking=accept-new root@"$OLD_SERVER" \
#		"ls -1t $REMOTE_DIR/claude-*.tar.gz 2>/dev/null | head -1")
#	if [ -n "$LATEST" ]; then
#		scp "root@$OLD_SERVER:$LATEST" /tmp/
#		tar -xzf "/tmp/$(basename "$LATEST")" -C /root
#		chmod 600 /root/.claude/.credentials.json 2>/dev/null || true
#		TS=$(basename "$LATEST" | sed -n 's/claude-\(.*\)\.tar\.gz/\1/p')
#		REDMINE_REMOTE="$REMOTE_DIR/redmine-$TS.tar.gz"
#		if ssh root@"$OLD_SERVER" "test -f $REDMINE_REMOTE" 2>/dev/null; then
#			scp "root@$OLD_SERVER:$REDMINE_REMOTE" /tmp/
#			mkdir -p /data
#			tar -xzf "/tmp/redmine-$TS.tar.gz" -C /data
#		fi
#		echo "  restored: $(basename "$LATEST")"
#	else
#		echo "  [WARN] no backup found at $OLD_SERVER:$REMOTE_DIR"
#	fi
#else
#	echo "[skip] Claude state restore — set OLD_SERVER=<ip> before running to auto-fetch backup."
#fi

# Claude Code statusLine (status bar: ctx · 5h · weekly usage)
echo "Claude statusLine configuration..."
ln -sfn ~/dotfiles/claude/statusline-usage.py ~/.claude/statusline-usage.py
python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.claude/settings.json")
try:
    d = json.load(open(p))
except Exception:
    d = {}
d["statusLine"] = {"type": "command", "command": "python3 $HOME/.claude/statusline-usage.py"}
os.makedirs(os.path.dirname(p), exist_ok=True)
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
print("[ok] statusLine merged into ~/.claude/settings.json")
PY

# Redmine working directory (ticket .md files live here)
mkdir -p /data/redmine

# MCP servers (separate script — can be re-run independently)
#"$(dirname "$0")/setup_mcp.sh"

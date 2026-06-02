#!/bin/bash

# enable repo
echo "installing repo "
dnf install -y epel-release
dnf makecache

# install pakages
echo "installing pakages git, tmux, vimm gcc fd..."
dnf install -y git tmux vim gcc fd-find ctags || true

# Node.js 20 (Redmine MCP needs global fetch, available since Node 18)
echo "installing Node.js 20..."
dnf module reset  -y nodejs
dnf module enable -y nodejs:20
dnf module install -y nodejs:20/common

# Dotfile configuration
echo "Dotfile configuration start"
if [ -f ~/.vimrc ]; then
	echo "original .vimrc backup...."
	mv ~/.vimrc ~/.vimrc.bak
fi

if [ -f ~/.tmux.conf ] && [ ! -L ~/.tmux.conf ]; then
	echo "original .tmux.conf backup...."
	mv ~/.tmux.conf ~/.tmux.conf.bak
fi

# Symbolic link
ln -sf ~/dotfiles/vimrc ~/.vimrc
ln -sf ~/dotfiles/tmux.conf ~/.tmux.conf

# Point dotfiles remote at SSH so `git push` uses the SSH key (idempotent)
echo "Setting dotfiles remote to SSH..."
if [ -d ~/dotfiles/.git ]; then
	git -C ~/dotfiles remote set-url origin git@github.com:hyolim98/dotfiles.git
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
if [ -n "$OLD_SERVER" ]; then
	echo "restoring Claude state from $OLD_SERVER..."
	REMOTE_DIR="/root/claude-backups"
	LATEST=$(ssh -o StrictHostKeyChecking=accept-new root@"$OLD_SERVER" \
		"ls -1t $REMOTE_DIR/claude-*.tar.gz 2>/dev/null | head -1")
	if [ -n "$LATEST" ]; then
		scp "root@$OLD_SERVER:$LATEST" /tmp/
		tar -xzf "/tmp/$(basename "$LATEST")" -C /root
		chmod 600 /root/.claude/.credentials.json 2>/dev/null || true
		TS=$(basename "$LATEST" | sed -n 's/claude-\(.*\)\.tar\.gz/\1/p')
		REDMINE_REMOTE="$REMOTE_DIR/redmine-$TS.tar.gz"
		if ssh root@"$OLD_SERVER" "test -f $REDMINE_REMOTE" 2>/dev/null; then
			scp "root@$OLD_SERVER:$REDMINE_REMOTE" /tmp/
			mkdir -p /data
			tar -xzf "/tmp/redmine-$TS.tar.gz" -C /data
		fi
		echo "  restored: $(basename "$LATEST")"
	else
		echo "  [WARN] no backup found at $OLD_SERVER:$REMOTE_DIR"
	fi
else
	echo "[skip] Claude state restore — set OLD_SERVER=<ip> before running to auto-fetch backup."
fi

# Redmine working directory (ticket .md files live here)
mkdir -p /data/redmine

# MCP servers (separate script — can be re-run independently)
"$(dirname "$0")/setup_mcp.sh"

# bash
cat >> "$HOME/.bashrc" << 'EOF'
export PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
alias mkbuild='make && make mk-docker-img && make push-docker-img'
alias authkey='pcli auth -u admin -p Admin123! -s; echo'
EOF

source $HOME/.bashrc

# remove timeout in /etc/profile
echo "remove time out"
sed -i 's/^export TMOUT=/#export TMOUT=/' /etc/profile
grep '^#\?export TMOUT=' /etc/profile

# permit root login
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep '^PermitRootLogin' /etc/ssh/sshd_config

echo "restart sshd..."
systemctl restart sshd

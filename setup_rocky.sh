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

# Symbolic link
ln -sf ~/dotfiles/vimrc ~/.vimrc

# Claude Code
echo "Claude Code installation..."
npm install -g @anthropic-ai/claude-code

echo "Claude Code configuration..."
mkdir -p ~/.claude/projects/-data
ln -sfn ~/dotfiles/claude/CLAUDE.md   ~/.claude/CLAUDE.md
ln -sfn ~/dotfiles/claude/skills      ~/.claude/skills
ln -sfn ~/dotfiles/claude/memory      ~/.claude/projects/-data/memory
ln -sfn ~/dotfiles/claude/admin-core  ~/.claude/admin-core

# Redmine working directory (ticket .md files live here)
mkdir -p /data/redmine

# Redmine MCP server (requires REDMINE_API_KEY env var; skip silently if unset)
if [ -n "$REDMINE_API_KEY" ]; then
	echo "registering Redmine MCP..."
	claude mcp add redmine \
		--scope user \
		--env REDMINE_URL=https://redmine.piolink.com \
		--env REDMINE_API_KEY="$REDMINE_API_KEY" \
		-- npx -y @onozaty/redmine-mcp-server
else
	echo "[skip] Redmine MCP — set REDMINE_API_KEY before running to auto-register."
	echo "       Or run later: REDMINE_API_KEY=xxx claude mcp add redmine --scope user \\"
	echo "         --env REDMINE_URL=https://redmine.piolink.com \\"
	echo "         --env REDMINE_API_KEY=\$REDMINE_API_KEY \\"
	echo "         -- npx -y @onozaty/redmine-mcp-server"
fi

# bash
cat >> "$HOME/.bashrc" << 'EOF'
export PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
alias mkbuild='make && make mk-docker-img && make push-docker-img'
alias authkey='pcm-cli auth -u admin -p Admin123! -s; echo'
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

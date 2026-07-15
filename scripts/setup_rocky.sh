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

# Optional: Claude Code (install/config split into setup_claude.sh)
read -rp "Claude Code도 설치·설정할까요? [y/N] " ans
case "$ans" in
	[yY] | [yY][eE][sS])
		"$(dirname "$0")/setup_claude.sh"
		;;
	*)
		echo "[skip] Claude — 필요하면 나중에 ./setup_claude.sh 실행하세요."
		;;
esac

#!/bin/bash

# enable repo
echo "installing repo "
dnf install epel-release
dnf makecache

# install pakages
echo "installing pakages git, tmux, vimm gcc fd..."
dnf install -y git tmux vim gcc fd-find ctags || true

# Dotfile configuration
echo "Dotfile configuration start"
if [ -f ~/.vimrc ]; then
	echo "original .vimrc backup...."
	mv ~/.vimrc ~/.vimrc.bak
fi

# Symbolic link
ln -sf ~/dotfiles/vimrc ~/.vimrc

# bash
cat >> "$HOME/.bashrc" << 'EOF'
export PS1="\[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
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

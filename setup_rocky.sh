#!/bin/bash


# install pakages
echo "installing pakages git, tmux, vimm gcc fd..."
dnf install -y git tmux vim gcc fd-find

# Dotfile configuration
echo "Dotfile configuration start"
if [ -f ~/.vimrc ]; then
	echo "original .vimrc backup...."
	mv ~/.vimrc ~/.vimrc.bak
fi

# Symbolic link
ln -sf ~/dotfiles/vimrc ~/.vimrc

# remove timeout in /etc/profile
echo "remove time out"
sed -i 's/^export TMOUT=/#export TMOUT=/' /etc/profile
grep '^#\?export TMOUT=' /etc/profile

# permit root login
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep '^PermitRootLogin' /etc/ssh/sshd_config

echo "restart sshd..."
systemctl restart sshd

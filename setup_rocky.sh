#!/bin/bash


echo "Dotfile configuration start"
if [ -f ~/.vimrc ]; then
	echo "original .vimrc backup...."
	mv ~/.vimrc ~/.vimrc.bak
fi

# Symbolic link
ls -sf ~/dotfiles/vimrc ~/.vimrc

# install pakages
echo "installing pakages"
dnf install -y git tmux vim gcc

# remove timeout in /etc/profile
echo "remove time out"
sed -i 's/^export TMOUT=/#export TMOUT=/' /etc/profile
grep '^#\?export TMOUT=' /etc/profile

# permit root login
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
grep '^PermitRootLogin' /etc/ssh/sshd_config

echo "restart sshd..."
systemctl restart sshd

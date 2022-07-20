#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo 'usage: install-ssh.sh [username]'
    exit
fi

myuser="$1"

[[ -e /var/local/status/verbose ]] && set -x && set -v 
# If our sshd_conf is different from one in /etc/sshd_config ...
# diff /var/local/sys_root_dir/etc/ssh/sshd_config /etc/sshd_config > /dev/null
# ... then it's because this is the first time we're running the script
# ... so install the openssh-server
#[[ "$?" != 0 ]] && sudo apt -y install openssh-server

# Create a public key for security purposes
if [[ ! -e /home/$myuser/.ssh ]]; then
    mkdir -p /home/$myuser/.ssh
    chown $myuser:$myuser /home/$myuser/.ssh
    chmod 700 /home/$myuser/.ssh
    cd /home/$myuser/.ssh
    sudo -u $myuser ssh-keygen -t rsa -b 4096 -q -N "" -C $myuser@XUBUNTU -f /home/$myuser/.ssh/id_rsa
    for key in ssh_host_rsa_key ssh_ssh_host_dsa_key ssh_host_ecdsa_key ssh_host_ed25519_key; do
	if [[ -e /etc/ssh/$key ]]; then
	    ln -s /etc/ssh/$key .
	    ln -s /etc/ssh/$key.pub .
	fi
    done
fi    


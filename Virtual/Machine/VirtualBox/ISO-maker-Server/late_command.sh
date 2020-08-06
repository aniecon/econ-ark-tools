#!/bin/bash
chroot /target curl -L -o /var/local/late_command.sh https://raw.githubusercontent.com/econ-ark/econ-ark-tools/master/Virtual/Machine/VirtualBox/ISO-maker-Server/late_command.sh 
     chroot /target curl -L -o /var/local/start.sh https://raw.githubusercontent.com/econ-ark/econ-ark-tools/master/Virtual/Machine/VirtualBox/ISO-maker-Server/start.sh 
     chroot /target curl -L -o /var/local/finish.sh https://raw.githubusercontent.com/econ-ark/econ-ark-tools/master/Virtual/Machine/VirtualBox/ISO-maker-Server/finish.sh 
     chroot /target curl -L -o /etc/rc.local https://raw.githubusercontent.com/econ-ark/econ-ark-tools/master/Virtual/Machine/VirtualBox/ISO-maker-Server/rc.local 
     chroot /target chmod +x /var/local/start.sh 
     chroot /target chmod +x /var/local/finish.sh 
     chroot /target chmod +x /etc/rc.local 
     chroot /target curl -L -o /etc/lightdm/lightdm.conf.d/autologin-econ-ark.conf https://raw.githubusercontent.com/econ-ark/econ-ark-tools/master/Virtual/Machine/VirtualBox/ISO-maker-Server/root/etc/lightdm/lightdm.conf.d/autologin-econ-ark.conf 
     chroot /target chmod 755 /etc/lightdm/lightdm.conf.d/autologin-econ-ark.conf 



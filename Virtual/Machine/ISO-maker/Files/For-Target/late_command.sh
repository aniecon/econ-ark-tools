#!/bin/sh
 apt -y update 
 apt -y install git 
 mkdir -p /usr/local/share/data/GitHub/econ-ark /var/local 
 chmod -Rf a+rwx /usr/local/share/data 
 git clone https://github.com/econ-ark/econ-ark-tools /usr/local/share/data/GitHub/econ-ark/econ-ark-tools 
 /bin/bash -c "cd /usr/local/share/data/GitHub/econ-ark/econ-ark-tools 
 git checkout Make-ISO-Installer 
 git pull" 
 rm -f /var/local/grub /var/local/rc.local 
 /bin/bash -c "cd /usr/local/share/data/GitHub/econ-ark/econ-ark-tools 
 cp -r Virtual/Machine/ISO-maker/Files/For-Target/* /var/local" 
 cd /var/local 
 mv /etc/rc.local /etc/rc.local_orig 
 mv rc.local /etc/rc.local &>/dev/null 
 mv /etc/default/grub /etc/default/grub_orig 
 mv grub /etc/default/grub &>/dev/null 
 chmod 755 /etc/default/grub 
 df -hT > /tmp/target-partition 
 cat /tmp/target-partition | grep /$ | cut -d ' ' -f1 | sed 's/.$//' > /tmp/target-dev 
 sd=$(cat /tmp/target-dev) 
 grub-install $sd 
 chmod a+x /var/local/start.sh /var/local/finish.sh /var/local/finish-MAX-Extras.sh /var/local/grub-menu.sh /var/local/late_command.sh 
 chmod a+x /etc/rc.local 
 mkdir -p /usr/share/lightdm/lightdm.conf.d /etc/systemd/system/getty@tty1.service.d 
 wget -O /etc/systemd/system/getty@tty1.service.d/override.conf https://raw.githubusercontent.com/econ-ark/econ-ark-tools/Make-ISO-Installer/Virtual/Machine/ISO-maker/Files/For-Target/root/etc/systemd/system/getty@tty1.service.d/override.conf 
 chmod 755 /etc/systemd/system/getty@tty1.service.d/override.conf 
 apt-get --yes purge shim 
 apt-get --yes purge mokutil 
 sed -i 's/COMPRESS=lz4/COMPRESS=gzip/g' /etc/initramfs-tools/initramfs.conf 
 update-initramfs -v -c -k all 
 sleep 24h

#!/bin/bash
# Autostart terminal upon autologin so that ~/.bash_alias will be executed automatically

myuser=econ-ark
sudo -u $myuser mkdir -p   /home/$myuser/.config/autostart
sudo chown $myuser:$myuser /home/$myuser/.config/autostart

# sudo apt -y install tasksel         # A bit mysterious why these two aren't already there
sudo add-apt-repository universe				    
sudo apt -y install xubuntu-desktop # but the xubuntu-desktop, at least, is not

cat <<EOF > /home/$myuser/.config/autostart/xfce4-terminal.desktop
[Desktop Entry]
Encoding=UTF-8
Version=0.9.4
Type=Application
Name=xfce4-terminal
Comment=Terminal
Exec=xfce4-terminal
OnlyShowIn=XFCE;
StartupNotify=false
Terminal=false
Hidden=false
EOF

sudo chown $myuser:$myuser /home/$myuser/.config/autostart/xfce4-terminal.desktop
# Set up vnc server so students can connect to instructor machine


# # Get some key apps that should be available immediately
# sudo apt -y install hfsplus
# sudo apt -y install hfsutils
# sudo apt -y install hfsprogs
sudo apt -y install tigervnc-scraping-server


# # Now finish configuring the partitions
# devBoot=`sudo fdisk -l | grep '^/dev/[a-z]*[0-9]' | grep -iv empty | awk '$2 == "*" { print $1 }'`
# #mkfs.hfsplus -v reFindBoot "$devBoot"
# #sudo mkdir /mnt/reFindBoot
# #sudo mount -t hfsplus /dev/sda1 /mnt/reFindBoot
# #echo 'Run reFind bootloader to boot on a Mac' > /mnt/reFindBoot/README.txt

# #sudo apt -y install efibootmgr libefiboot1 libefivar1 sbsigntool 

#sudo apt-add-repository ppa:rodsmith/refind
#sudo apt-get --assume-yes install refind # installs ReFind to EFI System Partition
# sudo refind-install --usedefault "$devBoot"

# Set up vnc server 
# https://askubuntu.com/questions/328240/assign-vnc-password-using-script
myuser="econ-ark"
mypass="kra-noce"
echo "$mypass" >  /tmp/vncpasswd # First is the read-write password
echo "$myuser" >> /tmp/vncpasswd # Next  is the read-only  password (useful for sharing screen with students)

[[ -e /home/$myuser/.vnc ]] && rm -Rf /home/$myuser/.vnc  # If a previous version exists, delete it
sudo mkdir -p /home/$myuser/.vnc

/usr/bin/vncpasswd -f < /tmp/vncpasswd > /home/$myuser/.vnc/passwd  # Create encrypted versions

# Give the files the right permissions
chown -R $myuser:$myuser /home/$myuser/.vnc
chmod 0600 /home/$myuser/.vnc/passwd

touch /home/$myuser/.bash_aliases

echo '# If not already running, launch the vncserver whenever an interactive shell starts' >> /home/$myuser/.bash_aliases
echo 'pgrep x0vncserver > /dev/null'  >> /home/$myuser/.bash_aliases
echo '[[ $? -eq 1 ]] && (x0vncserver -display :0 -PasswordFile=/home/'$myuser'/.vnc/passwd >> /dev/null 2>&1 &)' >> /home/$myuser/.bash_aliases


# A few things to do quickly at the very beginning; the "finish" script is stuff that runs in the background for a long time 
# set defaults
default_hostname="$(hostname)"
default_domain=""

# define download function
# courtesy of http://fitnr.com/showing-file-download-progress-using-wget.html
download()
{
    local url=$1
#    echo -n "    "
    wget --progress=dot $url 2>&1 | grep --line-buffered "%" | \
        sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'
#    echo -ne "\b\b\b\b"
#    echo " DONE"
}

tmp="/tmp"

myuser="econ-ark"

# Change the name of the host to the date and time of its creation
datetime="$(date +%Y%m%d%H%S)"
sed -i "s/xubuntu/$datetime/g" /etc/hostname
sed -i "s/xubuntu/$datetime/g" /etc/hosts

cd /home/"$myuser"

# Add stuff to bash login script
bashadd=/home/"$myuser"/.bash_aliases
[[ -e "$bashadd" ]] && mv "$bashadd" "$bashadd-orig"
touch "$bashadd"

cat /var/local/.bash_aliases-add >> "$bashadd"

# Make ~/.bash_aliases be owned by "$myuser" instead of root
chmod a+x "$bashadd"
chown $myuser:$myuser "$bashadd" 

# Security (needed for emacs)
sudo apt -y install ca-certificates

# Play nice with Macs
sudo apt -y install avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan

# Create .emacs.d directory with proper permissions -- avoids annoying startup warning msg
cd    /home/$myuser
echo "downloading .emacs file"

download "https://raw.githubusercontent.com/ccarrollATjhuecon/Methods/master/Tools/Config/tool/emacs/dot/emacs-ubuntu-virtualbox"

cp emacs-ubuntu-virtualbox /home/econ-ark/.emacs
cp emacs-ubuntu-virtualbox /root/.emacs
chown "root:root" /root/.emacs

cp /var/local/.bash_aliases-add /home/$myuser/.bash_aliases-add
chown "$myuser:$myuser"         /home/$myuser/.bash_aliases-add
chmod a+x                       /home/$myuser/.bash_aliases-add

chmod a+rwx /home/$myuser/.emacs
chown "$myuser:$myuser" /home/$myuser/.emacs


rm -f emacs-ubuntu-virtualbox

[[ ! -e /home/$myuser/.emacs.d ]] && sudo mkdir /home/$myuser/.emacs.d && sudo chown "$myuser:$myuser" /home/$myuser/.emacs.d
[[ ! -e /root/.emacs.d ]] && mkdir /root/.emacs.d

chmod a+rw /home/$myuser/.emacs.d 

# Remove the linux automatically created directories like "Music" and "Pictures"
# Leave only required directories Downloads and Desktop
cd /home/$myuser

for d in ./*/; do
    if [[ ! "$d" == "./Downloads/" ]] && [[ ! "$d" == "./Desktop/" ]] && [[ ! "$d" == "./snap/" ]]; then
	rm -Rf "$d"
    fi
done


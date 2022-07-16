#!/bin/bash
# start.sh installs GUI then reboots;
# finish.sh automatically starts with newly-installed GUI

# Conditionally enable verbose output 
[[ -e /var/local/status/verbose ]] && set -x && set -v

# Now install own stuff
vncuser="econ-ark"
rdpuser="econ-ark-xrdp"
mypass="kra-noce"

# enable connection by ssh
sudo apt -y install openssh-server
sudo /var/local/installers/install-ssh.sh $vncuser |& tee -a /var/local/status/install-ssh.log
sudo /var/local/installers/install-and-configure-xrdp.sh $vncuser |& tee -a /var/local/status/install-and-configure-xrdp.log

# xubuntu desktop
sudo bash -c '/var/local/installers/install-xubuntu-desktop.sh |& tee /var/local/status/install-xubuntu-desktop.log'

# on some vm's it is necessary to stop then restart the vm before it works
# sudo service lightdm stop; sudo service lightdm start

cd /var/local

# Get info about install
commit_msg="$(cat /var/local/About_This_Install/commit-msg.txt)"
short_hash="$(cat /var/local/About_This_Install/short.git-hash)"
commit_date="$(cat /var/local/About_This_Install/commit_date)"

# Change the name of the host to the date and time of its creation
##  Get existing
default_hostname="$(</etc/hostname)"
default_domain=""

# long hostname is date plus commit hash for econ-ark-tools repo
build_date="$(</var/local/status/build_date.txt)"
build_time="$(</var/local/status/build_time.txt)"

new_hostname="xubark-$commit_date-$commit_hash"
# short hostname: xubark+date of commit
[[ ! -e /var/local/status/verbose ]] && new_hostname="xubark-$commit_date" && echo "$new_hostname" > /var/local/status/new_hostname

if [[ "$default_hostname" == "-" ]]; then # not yet defined
    echo "$new_hostname" > /etc/hostname
    echo "$new_hostname" > /etc/hosts
else # replace the default
    sed -i "s/$default_hostname/$new_hostname/g" /etc/hostname
    sed -i "s/$default_hostname/$new_hostname/g" /etc/hosts
fi

# GitHub command line tools
sudo /var/local/installers/install-gh-cli-tools.sh

# LaTeX - minimal (required for auctex install on emacs)
sudo apt -y install texlive-latex-base
[[ "$(which emacs)"  != "" ]] && sudo emacs -batch -eval "(setq debug-on-error t)" -l /root/.emacs

# Prepare for emacs install
sudo apt -y install xsel xclip # Allow interchange of clipboard with system
sudo apt -y install gpg gnutls-bin # Required to set up security for emacs package downloading

sudo apt -y reinstall emacs # Might have already been installed; update if so
sudo /var/local/installers/install-emacs.sh |& tee /var/local/status/install-emacs.log

# Install Chrome browser 
wget --quiet -O /var/local/status/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt -y install /var/local/status/google-chrome-stable_current_amd64.deb

# Populate About_This_Install directory with info specific to this run of the installer

## Create the "About This Install" markdown file
cat <<EOF > /var/local/About_This_Install.md
# Detailed Info About This Installation

This machine (virtual or real) was built using 

https://github.com/econ-ark/econ-ark-tools.git

using scripts in commit $short_hash 
with commit message "$commit_msg"
on date "$commit_date"

Starting at the root of a cloned version of that repo,
you should be able to reproduce the installer with:

    git checkout $short_hash
    cd Virtual/Machine/ISO-maker ; ./create-unattended-iso_Econ-ARK-by-size.sh [ MIN | MAX ]

A copy of the ISO installer that generated this machine should be in the

    /installers

directory.

EOF

## mdadm is for managing RAID systems but can cause backup problems; disable
# sudo apt -y remove mdadm

# Start the GUI if not already running
[[ "$(pgrep lightdm)" == '' ]] && service lightdm start 

# Packages present in "live" but not in "legacy" version of server
# https://ubuntuforums.org/showthread.php?t=2443047
sudo apt-get -y install cloud-init console-setup eatmydata gdisk libeatmydata1 

# More useful default tools 
sudo apt -y install build-essential module-assistant parted gparted xsel xclip cifs-utils nautilus exo-utils rclone autocutsel gnome-disk-utility rpl  net-tools network-manager-gnome snap evince nodejs timeshift deja-dup

cd /var/local
branch_name="$(</var/local/status/git_branch)"
online="https://raw.githubusercontent.com/econ-ark/econ-ark-tools/"$branch_name"/Virtual/Machine/ISO-maker"

for user in $vncuser $rdpuser root; do

    user_dir=/home/$user && [[ "$user" == "root" ]] && user_dir=/root

    # Configure emacs
    sudo -u $user /var/local/config/emacs-user.sh $user

    # Let user control networks
    sudo adduser  $user netdev

    # Get to systemwide GitHub via ~/GitHub whoever you are
    [[ ! -e $user_dir/GitHub ]] && ln -s /usr/local/share/data/GitHub $user_dir/GitHub
    [[ ! -e $user_dir/installer ]] && [[ -e /installer ]] && [[ ! -z /installer ]] && ln -s /installer $user_dir/installer

    # Everything should be accessible to members of the econ-ark group
    [[ "$user" != "root" ]] && chown -Rf $user:econ-ark $user_dir

    # Remove the linux automatically created directories like "Music" and "Pictures"
    # Leave only required directories Downloads and Desktop
    cd $user_dir
    for d in ./*/; do
	if [[ ! "$d" == "./Downloads/" ]] && [[ ! "$d" == "./Desktop/" ]] && [[ ! "$d" == "./snap/" ]] && [[ ! "$d" == "./GitHub/" ]] && [[ ! "$d" == "./thinclient_drives" ]]; then
	    rm -Rf "$d"
	fi
    done

    # Add stuff to bash login script
    bashadd=$user_dir/.bash_aliases
    [[ -e "$bashadd" ]] && mv "$bashadd" "$bashadd-$datetime"
    if [[ "$user" == "root" ]]; then
	ln -s /var/local/root/home/user_root/bash_aliases "$bashadd"
    else
	ln -s /var/local/root/home/user_regular/bash_aliases "$bashadd"
    fi

    # Make ~/.bash_aliases be owned by the user instead of root
    chmod a+x "$bashadd"
    chown $user:$user "$bashadd" 

    sudo -u $user xdg-settings set default-web-browser google-chrome.desktop

    # Make sure that everything in the home user's path is owned by home user 
    chown -Rf $user:$user $user_dir

    if [[ ! "$user" == "root" ]]; then # never run latex as root
	# Configure latexmkrc: https://mg.readthedocs.io/latexmk.html
	ltxmkrc=$user_dir/.latekmkrc
	echo "'"'$dvi_previewer = start xdvi -watchfile 1.5'"';" > "$ltxmkrc"
	echo "'"'$ps_previewer = start gv --watch'"';" >> "$ltxmkrc"
	echo "'"'$pdf_previewer = start evince'"';" >> "$ltxmkrc"
    fi
    
done

# Play nice with Macs (in hopes of being able to monitor it)
sudo apt -y install avahi-daemon avahi-discover avahi-utils libnss-mdns mdns-scan ifupdown
#sudo apt -y install at-spi2-core # Prevents some mysterious "AT-SPI" errmsgs when apps are launched

# Start avahi so machine can be found on local network -- happens automatically in ubuntu
mkdir -p /etc/avahi/

cp /var/local/root/etc/avahi/avahi-daemon.conf /etc/avahi

# Enable ssh over avahi
cp /usr/share/doc/avahi-daemon/examples/ssh.service /etc/avahi/services


## The boot process looks for /EFI/BOOT directory and on some machines can use this stuff
if [[ -e /EFI/BOOT ]]; then
    cp /var/local/root/EFI/BOOT/Econ-ARK.disk_label    /EFI/BOOT/.disk_label
    cp /var/local/root/EFI/BOOT/Econ-ARK.disk_label_2x /EFI/BOOT/.disk_label2x
    echo 'Econ-ARK'    >                 /EFI/BOOT/.disk_label_contentDetails
fi

cd /var/local
size="MAX" # Default to max, unless there is a file named Size-To-Make-Is-MIN
[[ -e /var/local/status/Size-To-Make-Is-MIN ]] && size="MIN"

isoSize="$size"
welcome="# Welcome to the Econ-ARK Machine XUBUNTARK-$size, build "
welcome+="$(cat /var/local/About_This_Install/short.git-hash)"

cat <<EOF > XUBUNTARK.md
$welcome


This machine contains all the software necessary to use all parts of the
Econ-ARK toolkit.

EOF


# Download the installer (very meta!)
echo ''
echo 'Fetching online image of this installer to '
echo "/media/"

[[ -e "/media/*.iso" ]] && sudo rm "/media/*.iso"

# bring system up to date
sudo apt -y update && sudo apt -y upgrade

# Install either minimal or maximal system
if [[ "$size" == "MIN" ]]; then
    /var/local/installers/install-conda-x.sh miniconda
    sudo -E pip install --yes econ-ark 
    conda install --yes -c nbval
    conda install --yes -c jupyterlab # jupyter notebook is no longer maintained
    conda install --yes -c conda-forge pytest
    conda install --yes -c conda-forge nbval     # use pytest on notebooks
else
    /var/local/installers/install-conda-x.sh anaconda
    sudo -E pip install --yes econ-ark 
    sudo chmod +x /var/local/finish-MAX-Extras.sh
    sudo /var/local/finish-MAX-Extras.sh
    source /etc/environment # Update the path
    echo '' >> XUBUNTARK.md
    echo 'In addition, it contains a rich suite of other software (like LaTeX) widely ' >> XUBUNTARK.md
    echo 'used in scientific computing, including full installations of Anaconda, '     >> XUBUNTARK.md
    echo 'scipy, quantecon, and more.' >> XUBUNTARK.md
    echo '' >> XUBUNTARK.md
fi

sudo apt -y install python-is-python3

# elpy is for syntax checking in emacs
sudo -E pip install elpy

# Now that elpy has been installed, rerun the emacs setup to connect to it
emacs -batch --eval "(setq debug-on-error t)" -l     /root/.emacs  # Run in batch mode to setup everything

cat /var/local/About_This_Install/XUBUNTARK-body.md >> /var/local/XUBUNTARK.md

mv /var/local/XUBUNTARK.md /var/local/About_This_Install

# 20220602: For some reason jinja2 version obained by sudo -E pip install is out of date
sudo -E pip install jinja2

# Configure jupyter notebook tools

sudo -E pip install jupyter_contrib_nbextensions
sudo jupyter contrib nbextension install
sudo jupyter nbextension enable codefolding/main
sudo jupyter nbextension enable codefolding/edit
sudo jupyter nbextension enable toc2/main
sudo jupyter nbextension enable collapsible_headings/main
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo jupyter labextension install jupyterlab-jupytext
sudo -E pip install ipywidgets
sudo apt -y install nodejs

# Install systemwide copy of econ-ark 
sudo -E pip install --upgrade nbreproduce

# Install user-owned copies of useful repos
# Download and extract HARK, REMARK, DemARK, econ-ark-tools from GitHub

# Allow reading of MacOS HFS+ files
sudo apt -y install hfsplus hfsutils hfsprogs

# # Prepare partition for reFind boot manager in MacOS
# hfsplusLabels="$(sudo sfdisk --list --output Device,Sectors,Size,Type,Attrs,Name | grep "HFS+" | awk '{print $1}')"

sudo apt-get update
sudo apt-get upgrade
sudo apt-get install unattended-upgrades

sudo mkdir -p /etc/apt/apt.conf.d
[[ -e /etc/apt/apt.conf.d/20auto-upgrades ]] && sudo mv /etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades_orig
sudo cp /var/local/root/etc/apt/apt.conf.d/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades 

# Restore printer services (disabled earlier because sometimes cause hang of boot)
sudo systemctl enable cups-browsed.service 

# Meld is a good file/folder diff tool
sudo apt -y install meld

# ssh was installed in start.sh
#/var/local/installers/install-ssh.sh "$user"    |& tee /var/local/status/install-ssh.log
#/var/local/config/config/config-keyring.sh "$user" |& tee /var/local/config/config-keyring.log

sudo apt -y upgrade

# Kill tail monitor if it is running
tail_monitor="$(pgrep tail | grep -v pgrep)"
[[ ! -z "$tail_monitor" ]] && sudo kill "$tail_monitor"

# Signal that we've finished software install
touch /var/local/status/finished-software-install.flag 

sudo chmod -Rf a+rw /var/local/status

sudo apt -y autoremove # Remove unused packages

sudo reboot

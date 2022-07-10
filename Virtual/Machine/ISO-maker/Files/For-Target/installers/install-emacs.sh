
# Installs emacs for root user and creates systemwide resources

echo '' ; echo 'User must have sudoer privileges ...' ; echo ''
sudoer=false
sudo -v &> /dev/null && echo '... sudo privileges are available.' && sudoer=true
[[ "$sudoer" == "false" ]] && echo 'Exiting because no valid sudoer privileges.' && exit

# Install emacs before the gui because it crashes when run in batch mode on gtk

[[ -e /var/local/status/verbose ]] && set -x && set -v

## Needs gpg for security to connect and download packages
[[ -z "$(which gpg)" ]] && sudo apt -y install gpg gnutls-bin

shared=/usr/local/share/emacs
user_root=user/root

sudo mkdir -p "$shared/root"
sudo mkdir -p "$user_root"

install_time="$(date +%Y%m%d%H%M)"
# Create .emacs stuff
## Preserve any existing original config for root user
shared_root=$shared/$user_root
[[ -e /root/.emacs   ]]        && mv /root/.emacs         /root/.emacs_orig_$install_time
[[ -e $shared_root/.emacs.d ]] && mv $shared/.emacs.d $shared/.emacs.d_orig_$install_time

localhome=var/local/root/home

# copy so user can change it; make link so user knows origin
cp    /$localhome/user_root/dotemacs-root-user /root/.emacs
ln -s /$localhome/user_root/dotemacs-root-user /root/.emacs_econ-ark_$(</var/local/status/date_time)

# Set up gpg security before emacs itself
# avoids error messages
sudo mkdir -p $shared/.emacs.d/elpa/gnupg

if [[ ! -e /usr/share/gnupg/gpg.conf ]]; then # global gpg conf not set up
    # So add it
    sudo mkdir -p /usr/share/gnupg
    echo 'keyserver hkps://keyserver.ubuntu.com:443' | sudo tee /root/.emacs.d/elpa/gnupg/gpg.conf
fi

sudo gpg $shared/.emacs.d/elpa/gnupg --list-keys  # creates the ~/.gnupg directory if it does not exist
[[ -e $shared/.gnupg ]] && rm -Rf $shared/.gnupg
sudo ln -s /root/.gnupg $shared/.gnupg
sudo gpg --keyserver hkps://keyserver.ubuntu.com --list-keys
sudo gpg --keyserver hkps://keyserver.ubuntu.com --receive-keys 066DAFCB81E42C40

# finally ready to install it
sudo apt -y install emacs 

# As of 20220628 there is a problem with a default certificate; comment out that certificate:
sudo apt -y install ca-certificates 
sudo sed -i 's|mozilla/DST_Root_CA_X3.crt|!mozilla/DST_Root_CA_X3.crt|g' /etc/ca-certificates.conf

# Do emacs first-time setup (including downloading packages)
emacs -batch --eval "(setq debug-on-error t)" -l     /root/.emacs  

# make .emacs.d directory accessible to all users, so anybody can add packages
sudo chmod -Rf a+rwx $shared/.emacs.d 

# Finished with emacs

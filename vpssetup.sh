#!/usr/bin/bash
# Use in Ubuntu 20.04+
USERNAME=merlyn
HOMEPATH=/home/$USERNAME

#Preparation of apt
read -n 1 -p "Change sources.list to mirrors.tuna.tsinghua.edu.cn?[y/N]" tf
case $tf in 
    Y|y)
        echo Replace default source to tuna.
        mv /etc/apt/sources.list /etc/apt/sources.list.default
        cat << EOF > /etc/apt/sources.list
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
EOF
        ;;
    *)
        echo Skip.
        ;;
    N|n)
        echo Canceled.
        ;;
esac
apt update && apt upgrade
clear
echo Installing prequsites.
apt install \
    python3 \
    sudo \
    zsh \
    nvim \
    vim \
    socat \
    wget \
    curl \



#Unable ufw teporarily.
ufw disable
clear
echo Setting up accounts.
# First setup new account `merlyn`.
useradd -m $USERNAME 
while true ; do
    echo "Please enter a password for $USERNAME:"
    passwd $USERNAME
    echo "Re-enter password for $USERNAME:"
    passwd $USERNAME
    if [ $? -eq 0 ]; then
        break
    else
        echo "Password not match, please try again."
    fi
done

# Add to sudoers
usermod -aG sudo $USERNAME
echo Editting sshd settings.
cat << EOF > /etc/ssh/sshd_config

# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# This sshd was compiled with PATH=/usr/bin:/bin:/usr/sbin:/sbin

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

Include /etc/ssh/sshd_config.d/*.conf

Port 22222
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

#HostKey /etc/ssh/ssh_host_rsa_key
#HostKey /etc/ssh/ssh_host_ecdsa_key
#HostKey /etc/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
PermitRootLogin yes
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

PubkeyAuthentication yes

# Expect .ssh/authorized_keys2 to be disregarded by default in future.
#AuthorizedKeysFile    .ssh/authorized_keys .ssh/authorized_keys2

#AuthorizedPrincipalsFile none

#AuthorizedKeysCommand none
#AuthorizedKeysCommandUser nobody

# For this to work you will also need host keys in /etc/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
PasswordAuthentication no
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes
#KerberosGetAFSToken no

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes
#GSSAPIStrictAcceptorCheck yes
#GSSAPIKeyExchange no

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes

AllowAgentForwarding yes
AllowTcpForwarding yes
#GatewayPorts no
X11Forwarding yes
#X11DisplayOffset 10
#X11UseLocalhost yes
#PermitTTY yes
PrintMotd no
#PrintLastLog yes
TCPKeepAlive yes
#PermitUserEnvironment no
#Compression delayed
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

# override default of no subsystems
Subsystem    sftp    /usr/lib/openssh/sftp-server

# Example of overriding settings on a per-user basis
#Match User anoncvs
#    X11Forwarding no
#    AllowTcpForwarding no
#    PermitTTY no
#    ForceCommand cvs server
EOF
echo Now importing ssh pubkey from github...
mkdir -p $HOMEPATH/.ssh
wget -O- --tries=5 https://github.com/MerlynAllen.keys >> $HOMEPATH/.ssh/authorized_keys
if [ $? -ne 0 ]; then
    echo Failed to import from GitHub. Now socat is listening on port 23456. Use socat to import key.
    socat tcp-listen:23456 - | tee -a $HOMEPATH/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
        echo Error! Please continue manually!
        exit 1
    fi
    echo Successfully imported!
fi
echo Successfully imported from GitHub!
cat $HOMEPATH/.ssh/authorized_keys
echo Now you can access this instance with user $USERNAME from port 22222.

# Now setting up working environments.
curl -L git.io/antigen > antigen.zsh
cat << EOF > $HOMEPATH/.zshrc
source $HOME/antigen.zsh
# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found
antigen bundle sudo
antigen bundle z
# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle pkulev/zsh-rustup-completion 
# Load the theme.
antigen theme romkatv/powerlevel10k

# Tell Antigen that you're done.
antigen apply
EOF
echo "alias vi=vim" >> $HOMEPATH/.zshrc
echo "alias vim=nvim" >> $HOMEPATH/.zshrc
ln -s /usr/bin/nvim /usr/bin/vim
ln -s /usr/bin/nvim /usr/bin/vi
# Install v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

# Install zerotier
curl -s https://install.zerotier.com | sudo bash


# Install wireguard?




ufw enable

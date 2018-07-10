#!/usr/bin/env bash
#
#  Install LXD on DEBIAN
#  Install Snapd
#  Add  /snap/bin to secure_path
#  Configure LXD with nat  
#  Create LXC Group and LXD User
#  Reboot Host server 
#  
#!/bin/sh

set -e


# 
SUDO_RIGHTS_MSG="This script must be run with sudo command or as root"

# Cchek the user running script has sudo rights
if [[ $UID != 0 ]]; then
  printf "${SUDO_RIGHTS_MSG}\n"
  exit 1
fi


apt install -y snapd

# INFO snap "core" has bad plugs or slots: core-support-plug (unknown interface)
# https://forum.snapcraft.io/t/tests-broken-in-master/457/4
snap install core
snap install lxd

# Add /snap/bin path to secure_path.
sed -e 's;secure_path="\(.*\)";secure_path=\1:/snap/bin;g' -i /etc/sudoers

# Initialize LXD with NAT network.
lxd waitready
cat <<EOF | sudo lxd init
yes
default
dir
no
yes
yes
lxdbr0
auto
auto
EOF

# Add lxd group.
addgroup --system lxd
gpasswd -a "${USER}" lxd

# Reboot for updating group.
reboot


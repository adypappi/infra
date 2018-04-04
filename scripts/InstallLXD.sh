#!/usr/bin/env bash
#
# SNAPD LXD installation
# Install snapd and uses snap to install lxd
# Add snapd binary to system path 
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh
isUserRootOrSudo
aptFP=`which apt-get`
$aptFP install -y snapd 
snap install lxd
#Display the path to snapd and snap and lxd
bin="snap lxd lxc"
for bn in $(echo $bin); do 
  printf " The binary $bn is located in $(which $bn)\n"
 done
# Set snap environment
snapdBinPath=/etc/profile.d/apps-bin-path.sh
chmod +x $snapdBinPath 
source $snapdBinPath 

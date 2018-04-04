#!/usr/bin/env bash
# This script should be run once after lxc instance creation
# Execute Copy of ssh-key  between the orchestraction server and the lxc instance just created
# Rsync infra scripts folders (normal=ly future uses Terraform) between orchestrator server and lxc instance created
# Scp the debian lxc aliases sh file to the new lxc instance.
# Use the default adimida user and it password for this operation
# Arguments:
# arg1: The IP address or dsn's hostname of the new lxc instance
# Depends:
# sshpass
#
# Attention used the password.
# source utilities
export PAPI_SCRIPTS_HOME=/papi/scripts/infra
source $PAPI_SCRIPTS_HOME/AdipappiUtils.sh
if [[ $# -ne 1 ]]; then 
  printf "$0 <lxcNewInstanceIpAddress>\n"
  exit -1
elif [[ $(isIpv4Address $1) == $KO  ]]; then
  printf "The ipv4 address $1 has incorrect format pattern\n"
  exit -2
fi  
readonly newLXCInstanceIp=$1
adimidaUser=adimida
adimidaPassword=Adimida*_1438
cd ~$adimidaUser 

printf "Copy the ssh key of user $adimidaUser into created lxc instance with ip address $newLXCInstanceIp\n"
sshpass   -p "$adimidaPassword" ssh-copy-id $newLXCInstanceIp


printf "Deploy adipappi infrastructure client scripts into new lxc instance:\n\t(future usage of automation will remove this step)\n"
rsync -avhz $PAPI_SCRIPTS_HOME/ $newLXCInstanceIp:$PAPI_SCRIPTS_HOME

printf "Copy debian adipappi aliases  file into new lxc instance"
scp $PAPI_SCRIPTS_HOME/adipappi_debian_aliases.sh  $newLXCInstanceIp:~/

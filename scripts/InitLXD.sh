#!/usr/bin/env bash
# Check lxd installation and  init it with bridge mod
# Install snapd and uses snap to install lxd
# Parameters: 
# mandatory
# 	$1: the name of the bridge interface to used by future container
#	$2: the name of the host interface to which the lxd must be bridged
#       $3: the ip address of the bridge nic within the host's network
#	$4: the host gateway address used  by bridge nic
#	$5: the name 
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh
isUserRootOrSudo

# Check input parameters
if [[ $# -ne 5 ]]; then
  printf "Usage: $0 <BridgeNicName> <HostNicName> <BridgeIPAddress> <HostGatewayAddress> <storagePoolName>\n"
  printf "\tthis script  create  a bridged nic which will be used by future lxd container\n"
  exit 1
fi
bridgeNicName="$1"
hostNicName="$2"
bridgeIpAddress="$3"
hostGatewayAddress="$4"
storagePoolName="$5"
#Host net  mask 
hostNetMask=255.255.240.0

# The primary network interface
printf "Coonfigure the bridge interface $bridgeNicName on host nic $hostNicName\n"
if [[ "$(ip link | grep $bridgeNicName)" == "" ]]; then
  printf "#@ADI_BEGIN\nauto $bridgeNicName\niface $bridgeNicName inet static\n\taddress $bridgeIpAddress\n\tnetmask $hostNetMask\n\tgateway $hostGatewayAddress\n\t# bridge options\n\tbridge_ports ${hostNicName}\n#@ADI_END\n" >> /etc/network/interfaces
fi
# restart interface
ifdown $hostNicName && ifup $hostNicName

#Display the path to snapd and snap and lxd
lxdBin=$(which lxd)

# Intitialized 
LXD_STORAGE_POOL_NAME=lxdinsts
if [[ ! $(lxc storage list | grep "${LXD_STORAGE_POOL_NAME}") ]]; then 
cat << EOF | $lxdBin init --preseed
config:
  core.https_address: ${LXC_CORE_HTTPS_IP_ADDR}:${LXC_CORE_HTTPS_PORT}
  core.trust_password: ${LXC_CORE_TRUST_PASSWORD}
  images.auto_update_interval: 15
storage_pools:
- name: $storagePoolName
  driver: zfs
  config:     
    source: ${LXC_HOST_ZPOOL_DATASET}
networks:
- name: $bridgeNicName
  type: bridge
  config:
    ipv6.address: none
EOF
fi

# Restart lxd
#sudo systemctl restart lxd.service


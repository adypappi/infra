#!/usr/bin/env bash 
# Check lxd installation and initialyzes it according to adipappi lxd configuration retained
# Install snapd and uses snap to install lxd
# Parameters: 
# mandatory
# 	$1: the name lxd storage pool to used by lxd instances
#       $2: the name of dataset to create for  lxd instance.  
#       $3: the name of the host's nic used by container as macvlan parent
#       $4: the name of the lxd mac vlan nic 
set -x
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh
#source ${PAPI_INFRA_SCRIPTS}/AdipappiEnvironmentVariables.sh
#isUserRootOrSudo
# Check input parameters
if [[ $# -ne 4 ]]; then
  printf "Usage: $0 <StoragePoolName> <ZfsDatasetToCreate> <HostNICNameForMacVlan> <MacVlanNic>"
  printf "\tthis script create a macvlan nic interface on the host which will be used by future lxd container\n"
  exit -1
fi
storagePoolName="$1"
lxdDatasetName="$2"
hostNicName="$3"
macVlanNicName="$4"

#Display the path to snapd and snap and lxd
lxdBin=$(which lxd)

# Create the zfs dataset for lxd instance
if [[ $(sudo zfs list | awk '/fs1/ {print $1}') == "" ]]; then 
   printf "The dataset $lxdDatasetName must be created on ${LXC_ZPOOL_DATASET_ROOT} before executing this script\n"
   exit -2
fi	

# Intitialized 
if [[ "$(lxc storage list | grep \"${storagePoolName}\")" == "" ]]; then 
cat <<EOF | $lxdBin init --preseed
config:
  core.https_address: '0.0.0.0:9999'
  core.trust_password: ${LXD_RMT_PASSWORD}
cluster: null
networks: []
storage_pools:
- config:
    source: ${LXC_ZPOOL_DATASET}/${lxdDatasetName}
  description: ""
  name: $storagePoolName
  driver: zfs
profiles:
- config: {}
  description: "Adypappi macvlan lxd container to customer lan interface"
  devices:
    enp0s1:
      name: $macVlanNicName
      nictype: macvlan
      parent: $hostNicName
      type: nic
    root:
      path: /
      pool: $storagePoolName
      type: disk
  name: papi-host-profile
EOF
else
 printf "The LXD was already been initialyzed\n Remove first the storagepool $storagePoolName and the macvlan nic $macVlanNicName before running this script\n"
 exit -3
fi


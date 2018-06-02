#!/usr/bin/env bash
# LXC instance template file
# subuid and subgid are related to lxcadmin user
set -o errexit
set -o pipefail
set -o nounset

printf "Configure the data used in lxc's template file\n"

## Include environments
source /etc/environment

source $PAPI_INFRA_SCRIPTS/PapiLXCInstance.cfg

# Get some network properties from this file. 
source $PAPI_INFRA_SCRIPTS/PapiLXCNetwork.cfg

# Generate the container template data fileecho 
# Reset the content of container configuratio data
touch  ${CNTR_CFG_DATA}
printf "" > ${CNTR_CFG_DATA}
printf "#Template data file for $cntrName container template file\n" >> ${CNTR_CFG_DATA}
printf "# Variables used in LXC instance template file definitioni\n" >>  ${CNTR_CFG_DATA}
printf "cntrName=$cntrName\n" >> ${CNTR_CFG_DATA} 
subuidc=$(grep ${PAPI_CNTR_ADM_USER} /etc/subuid) 
subgidc=$(grep ${PAPI_CNTR_ADM_GROUP} /etc/subgid)  
printf "subUid=$(echo $subuidc | cut -d':' -f2)\n" >> ${CNTR_CFG_DATA}
printf "subUidCount=$(echo $subuidc | cut -d':' -f3)\n" >> ${CNTR_CFG_DATA}
printf "subGid=$(echo $subgidc | cut -d':' -f2)\n">>${CNTR_CFG_DATA}
printf "subGidCount=$(echo $subgidc | cut -d':' -f3)\n">>${CNTR_CFG_DATA}
#printf "cntrRootFS=$cntrRootFS\n">>${CNTR_CFG_DATA}
printf "# The name of host’s bridge to which container’s nic will be attached\n">>${CNTR_CFG_DATA}
printf "bridgeNicName=$bridgeNicName\n">>${CNTR_CFG_DATA}
printf "# Container internal nic name attached to bridge\n">>${CNTR_CFG_DATA}
printf "cntrNicName=$cntrNicName\n">>${CNTR_CFG_DATA}
printf "# this value must be the first free ip address of green interface from 172.16.224.1 → to 172.16.239.254\n">>${CNTR_CFG_DATA}
printf "cntrIpCIDR=$cntrIpCIDR\n">>${CNTR_CFG_DATA}
printf "# container internal nic mac address\n">>${CNTR_CFG_DATA}
printf "cntrNicMacAddress=$cntrNicMacAddress\n">>${CNTR_CFG_DATA}
printf "cntrAndHostGateway=$hostBridgeGateway\n">>${CNTR_CFG_DATA}

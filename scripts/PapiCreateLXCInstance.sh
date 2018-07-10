#!/usr/bin/env bash
#
# This is the main script for lxc instance creation
#
set -o errexit
set -o pipefail
set -o nounset
nbParam=3
if [[ $# -ne $nbParam ]]; then 
  printf "$0 script need $nbParam parameters  <distributionName> <ReleaseNameOrVersion> <distributionArchitecture>\nExamples:\n\t$0 debian stretch amd64\n\tubuntu bionic amd64\n"
  exit -1
fi 
  # Check that the user running this script is lxc admin user
if [[ "$(whoami)" != "${PAPI_CNTR_ADM_USER}" ]]; then
  printf "And must be run as user: ${PAPI_CNTR_ADM_USER}\n"
  exit -2
fi

distrib=$1
release=$2
arch=$3

printf "Create papi's lxc container with $distrib $release $arch\n"

# Global papi environment variables
source /etc/environment 

# Get the cntr name
cntrName=$(grep -Po "cntrName=(\w+)" ${PAPI_INFRA_SCRIPTS}/PapiLXCInstance.cfg|cut -d'=' -f2)

# Clean lxc fs 
${PAPI_INFRA_SCRIPTS}/PapiLXCInstanceCleaner.sh $cntrName

# Configure host bridge used for container
source ${PAPI_INFRA_SCRIPTS}/PapiCreateLXCHostBridgeNic.cfg

# Get the name of container from its configuration file
source ${PAPI_INFRA_SCRIPTS}/PapiLXCInstance.cfg

# Init LXC instance 
${PAPI_INFRA_SCRIPTS}/PapiLXCInstanceInit.sh

# Papi set ZFS permission
${PAPI_INFRA_SCRIPTS}/PapiZFSPermissionConfiguration.sh

#Papi create container #todo change the log directory
cd ${PAPI_CNTR_ADM_HOME}

# Create log file 
logFile=${PAPI_LXC_LOG_ROOTFS}/$cntrName
touch $logFile

# Run instance creation
res=$(lxc-create -n $cntrName -t download -- -d $distrib -r $release -a $arch)
#res=$(lxc-create -n $cntrName -B dir -f ${CNTR_CFG} -t download --logpriority=TRACE --logfile=$logFile  -- -d $distrib -r $release -a $arch)

# Check that instance has been created successfully
if [[ $(sudo su - ${PAPI_CNTR_ADM_USER} -c "lxc-ls | grep $cntrName") != "" ]]; then
  printf "Papi lxc container $cntrName created successfully owner is ${PAPI_CNTR_ADM_USER}\n\tEach lxc-xxxx management command must be run as ${PAPI_CNTR_ADM_USER}\n" 
else
  printf "Problem occurs in Papi lxc container creation\n$res\n"
  exit -3
fi




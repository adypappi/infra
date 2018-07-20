#!/usr/bin/env bash
# Init the configuration of papi's lxc container configuration 
# Check that the user running this script is PAPI_CNTR_ADM_USER
set -o errexit
set -o pipefail
set -o nounset

## Include environment
source /etc/environment

runUser=${SUDO_USER:-$USER}
printf "%s\n" $runUser

if [[ "$runUser" != "${PAPI_CNTR_ADM_USER}" ]]
then
  printf "This script must be run as ${PAPI_CNTR_ADM_USER}\n"
  exit -1
fi

# Set User space id map 
idMapInterval="100000-200000"
#sudo usermod -v $idMapInterval -w $idMapInterval ${PAPI_CNTR_ADM_USER}

# Configure a LXC template for container creation (FS, Network, Permission, etc)
source ${PAPI_INFRA_SCRIPTS}/PapiGenerateLXCInstanceConfig.sh

# Get LXC source 
cd ${PAPI_CNTR_ADM_HOME}
apt source lxc
grep -ri hkp: .

# Call the lxc instance creation script. 


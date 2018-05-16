#!/usr/bin/env bash

# Papi context parameter
export PAPI_ADM_USER=adimida
export PAPI_ADM_GROUP=adimida
export PAPI=/papi
export PAPI_INFRA=$PAPI/infra
export PAPI_INFRA_SCRIPTS=$PAPI_INFRA/scripts

# Adypappi repository github --> move to gitlab
PAPI_GIT_ACCOUNT=adypappi
PAPI_GIT_REPO=infra
PAPI_GIT_INFRA_REPO=https://github.com/$adypappi/infra.git

# Script allowing to create the fs tree structure of papi cloud management plateform 
mkdir -p /papi/devprj
mkdir -p /papi/infra/cntrs
mkdir -p /papi/infra/vms
mkdir -p /papi/infra/scripts
mkdir -p /papi/infra/tools
mkdir -p /papi/infra/tools/pxe
mkdir -p /papi/infra/docs
mkdir -p /papi/infra/drivers
mkdir -p /papi/tools/binary
mkdir -p /papi/tools/src
mkdir -p /papi/app
mkdir -p /papi/appsrv
mkdir -p /papi/docs
mkdir -p /papi/dataset
mkdir -p /papi/papibackup # normally must be somewhere other than /papi

# All papi FS are member of linux group adimida 
sudo setfacl -R -m g:$PAPI_ADM_GROUP:rwx  $PAPI

# Set the /etc/environment
echo "Clone adipappi git repository $PAPI_GIT_INFRA_REPO"
sudo su - $PAPI_ADM_USER -c "cd $PAPI_INFRA; git clone $PAPI_GIT_INFRA_REPO;git checkout dev;git status"

# Caution for git management
echo "Add .gitkeep in each empty director of tree to take them in account in git commit and push" 

#!/usr/bin/env bash
# Script allowing to create the fs tree structure of papi cloud management plateform 

#!/usr/bin/env bash
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
sudo chown -R :adimida  /papi

# Caution for git management
echo "Add .gitkeep in each empty director of tree to take them in account in git commit and push" 


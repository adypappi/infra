#!/usr/bin/env bash
# Script allowing to create the fs tree structure of papi cloud management plateform 
mkdir -p /papi/devprj
mkdir -p /papi/infraas
mkdir -p /papi/infra/cntrs
mkdir -p /papi/infra/vms
mkdir -p /papi/infra/scripts
mkdir -p /papi/infra/tools
mkdir -p /papi/infra/docs
mkdir -p /papi/tools/binary
mkdir -p /papi/tools/src
mkdir -p /papi/app
mkdir -p /papi/appsrv
mkdir -p /papi/docs
mkdir -p /papi/appsrv
mkdir -p /papi/dataset
mkdir -p /papibackup

# All papi FS are member of linux group adimida 
sudo chown -R :adimida  /papi

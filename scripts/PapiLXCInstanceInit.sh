#!/usr/bin/env bash
# Init the configuration of papi's lxc container configuration 

## Include environments
source /etc/environment
source $PAPI_INFRA_SCRIPTS/PapiLXCInstanceTemplate.tplt

# Set the default lxc config file for unprivileged container to 
ln -s $CNTR_CFG  /home/$PAPI_CNTR_ADM_USER/.config/lxc/default.config


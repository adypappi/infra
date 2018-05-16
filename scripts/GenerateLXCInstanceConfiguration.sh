#!/usr/bin/env bash
# Genrate the global configuration file a LXC's instance 

## Include environments
source /etc/environment
source $PAPI_INFRA_SCRIPTS/PapiLXCInstanceTemplate.tplt

# Copy the default template file then remplate template tag with the values in $CNTR_CFG_DATA
cp $CNTR_CFG_DFLT $CNTR_CFG
# Replace each tag by its value
while IFS== read k v; do if [[ "$v" != "" ]]; then sed -i "s#<$k>#$v#g" $CNTR_CFG; fi done < $CNTR_CFG_DATA
cat $CNTR_CFG

#!/usr/bin/env bash
# Genrate the global configuration file a LXC's instance 

## Include environments
source /etc/environment
source $PAPI_INFRA_SCRIPTS/PapiGenerateLXCInstanceTemplateDataFile.sh

# Copy the default template file then remplate template tag with the values in $CNTR_CFG_DATA
printf "Copy default template file ${CNTR_CFG_DFLT} as $cntrName container config file ${CNTR_CFG}\n"
printf "Template data file of $cntrName container's template: ${CNTR_CFG_DATA}\n"
cp ${CNTR_CFG_DFLT} ${CNTR_CFG}
# Replace each tag by its value
while IFS== read k v; do if [[ "$v" != "" ]]; then sed -i "s#<$k>#$v#g" $CNTR_CFG; fi done < ${CNTR_CFG_DATA}
	

#Copy the cntr file generate by PapiGenerateLXCInstanceConfiguration.sh script as unprivileged lxc default config
mkdir -p ${PAPI_LXC_UPRVLG_DFLT_CFG_ROOTFS}
ln -sf ${CNTR_CFG}  ${PAPI_LXC_UPRVLG_DFLT_CFG_ROOTFS}/default.config

# Display the current un privileged container configuration 
printf "Lxc container $cntrName configuration\c"
cat ${CNTR_CFG}


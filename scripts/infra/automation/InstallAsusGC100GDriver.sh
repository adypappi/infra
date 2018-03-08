#!/usr/bin/env bash
#Application de l’installation du drivers sur une nouvelles machines
# Release for Ubuntu/Debian/ from 4.4+ kernel. Test for others distros and tel 
# us.
# Version 1.0 based on version 5005 of asus
# In this process the drivers  of nic will be registered into   
# kernel header version /lib/modules/$headerVersion/  (replace header version 
# export below by yours.
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh

# Check that script is run as root user
isUserRootOrSudo

# Install git and  configure to automatic connection 
apt-get install -y git
git config --global http.proxy http://172.16.230.99:8989
git config --global github.user "devjj2ee@gmail.com"
git config --global github.token "87546f11c6a1914dfd422037348e5ac77683950d"

# Clone adipappi github repository of asus gc100c drivers repository
export headerVersion=$(uname -r)
moduleName=atlantic
moduleFile=atlantic.ko
moduleSourceParent=/papi/projects/asusxgc100
moduleSourceTree=axgc100c/Atlantic
moduleBuildPath=$moduleSourceParent/$moduleSourceTree
mkdir -p $moduleSourceParent
cd $moduleSourceParent
git clone https://github.com/adypappi/axgc100c.git

# Install kernel dependencies and driver build tools and environment
apt-get install -y build-essential linux-headers-$headerVersion


# Remove old build module an rebuild new one against current kernel
rm -rf $moduleBuildPath/$moduleFile
cd $moduleSourceTree
make

# Configure module drivers to automatic load in boot
# remove existing module
moduleDestination=/lib/modules/$headerVersion/kernel/drivers
cp $moduleBuildPath/$moduleFile  $moduleDestination/ 
depmod 
if [[ ! $(grep -q  atlantic /etc/modules.conf) ]]
then
   echo atlantic >>  /etc/modules.conf
fi
update-initramfs -u

# reboot
reboot

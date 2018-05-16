#!/usr/bin/env bash
#
# Since the creation of lxc unprivileged container's is not reliable as for privileged container
# destruction of this kind of container leave some fs on system. To make functional create destroy 
# of container on Debian Stretch for the container this script had been created. 
# Remove some symbolik link and recreate them
# Arguments:
#   Param: cntrName the name of container
# Dependencies: locate and sudo

# Scripts Includes
source /etc/environment
source $PAPI_INFRA_SCRIPTS/AdipappiUtils.sh

if [[ $# -ne 1  ]]
then 
  printf "A mandatory argument container name must be provided to script $0\nUsage: $0 vmproto\n"
  return -1
else  
# Do this to avoid deleting your / !!!!!!
cntrName=$1
fi
if [[ $(lxc-ls|grep "$cntrName") != "" ]]
then 
  lxc-stop -n $cntrName; lxc-destroy -n $cntrName 
  #home directory of lxc admin user
  LXCADMIN_HOME=/home/${PAPI_CNTR_ADM_USER}

  # update the locate db and delete all entry containing /cntrName/
  sudo updatedb
  sudo rm -rf  $(sudo locate /$cntrName/)

  # Check that the $LXC_DEFAULT_LOCATION and LXC_DEFAULT_FS_LOCATION have been deleted
  # sudo rm -rf ${LXC_DEFAULT_LOCATION}*

  # Create some necessaries symbolic links in container admin’s home directory
  for d in cache config local
  do 
    rm -rf ${LXCADMIN_HOME}/.$d
    ln -s ${PAPI_LXC_ROOTFS}/$d ${LXCADMIN_HOME}/.$d 
  done

  # the following two symbolic links relocate lxc main fs into /caldrons FS tree.
  for d in lxc lxcfs
  do 
    sudo ln -s ${PAPI_LXC_ROOTFS}/$d ${VAR_LIB}/$d 
  done

  # Set the facl x for other user on LXC ADMIN USER HOME
  sudo setfacl -R -m o::rx ${LXCADMIN_HOME}
fi



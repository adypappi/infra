#!/usr/bin/env bash
#Set the permission of the  zfs file system dedicated to lxc container in papi context.
# Since all the lxc container's admin and group are lxcadmin:adimida in Papi context 
# We set the zfs zcaldrons/cntrs to this user and group
# Depends on sudo user
set -o errexit
set -o pipefail
set -o nounset

## Include environment
source /etc/environment
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh

if [[ $(isUserRootOrSudo) != "-1" ]]; then
# Here is set the name of future lxc'instance to create
  sudo zfs set acltype=${PAPI_ZFS_ACLTYPE} ${CALDRON_ZPOOL}
  sudo zfs set xattr=${PAPI_ZFS_XATTR}  ${CALDRON_ZPOOL}
  sudo zfs set aclinherit=${PAPI_ZFS_ACLINHERIT} ${CALDRON_ZPOOL} 
  sudo zfs allow -d -g ${PAPI_CNTR_ADM_GROUP} ${PAPI_ZFS_ADM_PERM} ${PAPI_CNTR_DS}

  # Mount all the zfs on the host
  sudo zfs mount -a -O
  # Set permission for lxc user and group 
  sudo setfacl -R -m u:${PAPI_CNTR_ADM_USER}:rwx,g:${PAPI_CNTR_ADM_GROUP}:rwx,o::x /caldrons
  sudo chown -R ${PAPI_ADM_USER}:${PAPI_ADM_GROUP} /caldrons
  sudo chown -R ${PAPI_CNTR_ADM_USER}:${PAPI_CNTR_ADM_GROUP} /caldrons/cntrs/lxcs
fi


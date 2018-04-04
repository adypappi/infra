#!/usr/bin/env bash 
# Backup the active OS  disk device to another local disk device with pv command.
# take one parameter: 
# $1 = OS active block device disk
# $2 = block device disk to which the active disk will be copied
# Root is mandatory to run this script
# Check argument provided 
if [ "$#" -ne 2 ]
then
  printf "Copy the active OS disk device to another disk device.\n!!!! Attention make sure that the first disk device provided to script is OS main device\n"
  printf "Usage : $0 /dev/sda /dev/sdb  where OS is installed on /dev/sda and /dev/sdb is where the \n"
  exit -1
else
  if [[ ! $1 =~ ^/dev/.+ ]] || [[ !  $2 =~ ^/dev/.+ ]]; then
    printf "$1 and $2 must be a block device"
    exit -2
  fi
  osDisk=$1
  backupDisk=$2
fi
logDir=/papi/scripts/infra/logs
logFileName="$logDir/$(basename $0).$(date +%s).exec.log"
touch $logFileName
sudo su  - -c "pv -B 64K < $osDisk  > $backupDisk | tee  $logFileName"


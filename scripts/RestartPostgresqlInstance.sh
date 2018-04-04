#!/usr/bin/env bash 
# This script restart a postgresql cluster instance from it name 

SUDO_RIGHTS_MSG="This script must be run with sudo command or as root"
if [[ $UID != 0 ]]; then 
  printf "${SUDO_RIGHTS_MSG}\n"
  exit 1
fi
if [[ $# -lt 1 ]] || ! [[ "$1" =~ "pginstusr"[1-9] ]]
then
  printf "Usage: $0 pginstusr[1-9] [version] \n\t [version] is cluster version number\n"
  exit 1
else 
  pginst=$1
  instnbr=${pginst:-1}
  scriptsDir=$(dirname "$BASH_SOURCE")
  vrs=`$scriptsDir/GetPostgresqlVersionNumber.sh`
fi

if [[ $# -eq  2 ]]; then 
  vrs=$2 
fi

msgSuffix="start postgresql cluster instance $vrs $pginst using pg_ctlcluster" 
echo "$msgSuffix"
cmd="pg_ctlcluster $vrs $pginst"

# Check if running 
status=$(pg_lsclusters | grep $vrs.*$pginstusr|cut -d' ' -f4)
if [ "$status" == "online" ]
then 
  sudo su - ${pginst} -c "$cmd stop"
fi	
  sudo su - ${pginst} -c "$cmd start"
if [[ "$?" -ne 0 ]]; then
   printf "Some errors occur when $msgSuffix\n" >&2
  exit 2
fi


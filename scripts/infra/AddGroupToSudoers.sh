#!/usr/bin/env bash
#
# This script add a given group to sudoers file /etc/sudoers.d/papi
# user running this script should have sudoer right.
# args:mandatory
#   $1: grpname
# versions: 
#        1.0  08/2017   
# author: A. Djiguiba
#set -o errexit
if [[ "$#" -lt 1 ]]; then
    printf "Usage: $0 <userGroup>\n"
    exit -1
fi
declare -r GRPNAME="$1"
declare -r SUDOERS_FILE=/etc/sudoers.d/papi

#
echo "Putting group $GRPNAME into sudoer file $SUDOERS_FILE"

# check that the groups exists else create it
if [[ ! $(getent group $GRPNAME) ]]; then
    printf "The group $0 does not exist\n"
    exit 1
fi

# Check that the group is not already  declared into papi sudoer file 
if [[ ! -f $SUDOERS_FILE ]]; then
   touch $SUDOERS_FILE
fi

# Put group into papi sudoer file. 
isGroupInSudoers=$(grep "$GRPNAME.*NOPASSWD" $SUDOERS_FILE)
if [[ "$isGroupInSudoers" == "" ]]; then
   echo "%$GRPNAME ALL=(ALL:ALL) NOPASSWD: ALL" >> $SUDOERS_FILE
else
   printf "The group $1 is already declared into $SUDOERS_FILE file\n"
   exit 2
fi


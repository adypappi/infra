#!/usr/bin/env bash
#
# This script creates an user with his group and optionnaly set the user home directory
# user runing this script must be have sudoer right.
# args:mandatory
#   $1: usrname
#   $2: grpname

# args:optional
#   $3: usrhome is optional argument default /home/usrname
# versions: 
#        1.0  08/2017   
# author: A. Djiguiba
set -o errexit
if [[ "$#" -lt 2 ]]; then
    printf "Usage: $0 <userName> <userGroup> [<userhomedir>].\n"
    exit 1
fi
declare -r USRNAME="$1"
declare -r GRPNAME="$2"
declare -r ADMGROUP="adm"
export USRHOME="/home/$1"
if [[ -n "$3" ]]; then export USRHOME="$3";fi

# check that the groups exists else create it
if [[ ! $(getent group $GRPNAME) ]]; then
   groupadd ${GRPNAME}
fi
if [[ ! $(getent group $USRNAME) ]]; then
   groupadd ${USRNAME}
fi
if [[ ! $(getent group $ADMGROUP) ]]; then
   groupadd ${ADMGROUP}
fi
if [[ ! -d $USRHOME ]]; then
  mkdir -p $USRHOME 
  cp -r /etc/skel/.  $USRHOME/
fi

# check that user exists else create it
if [[ $(id -u $USRNAME > /dev/null 2>&1; echo $?) -ne 0  ]]; then
   useradd ${USRNAME} -m -g ${USRNAME} -G ${GRPNAME},${ADMGROUP} -s /bin/bash -d $USRHOME 
#   chown -R ${USRNAME}:${USRNAME} $USRHOME
else 
   printf "User $USRNAME already exists:\n$(id $USRNAME)\n" 
fi


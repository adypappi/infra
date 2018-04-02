#!/usr/bin/env bash
#
# Defines all usefull functions used in laapi infra managemnt 
#
#set -x

# Adipappi infra scripts repository root 
export PAPI_SCRIPTS_HOME=/papi/scripts/infra
export OK="OK"
export KO="KO"

# Use full Regex 
export IPV4_REGEX="^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"


#FNCT: 1 
#
#
# Chech that the runner of script is sudo or root
# $1: the UID 
# Exit code -1 : if $1 is not equal to 1
# Return 0. 
function isUserRootOrSudo() {
   local SUDO_RIGHTS_MSG="This script must be run with sudo command or root"	
   if [ ! $UID -eq 0 ] ; then
      printf "${SUDO_RIGHTS_MSG}\n"
      exit -1
   fi
   return 0
}


#FNCT: 2
#
#
# Print any array each element in one line into console output
function printArray {
  tab=("$@")
  printf '%s\n' "${tab[@]}" 
}


#FNCT: 3
#
#
function aptgetUpdate {
  apt-get update
}


#FNCT: 4
#
#
function aptgetForceUpgrade {
  apt-get upgrade -y
}


#FNCT: 5
# Install list of package or single package
#
function aptgetForceInstall {
  for pkg in $(echo $@); do 
    apt-get install -y $pkg
  done
}


#FNCT: 6
# Check provided argument agains X.Y  where X and Y re interger
#
function checkPgsql10PlusVersion() {
	if [[ $1 =~ [0-9]+(\.[0-9])? ]]; then
       echo $OK
    else
       echo $KO
  fi
}

#FNCT: 7
# Check provided argument agains X.Y  where X and Y re interger
#
function checkXDotYVersion() {
  if [[ $1 =~ [0-9]+\.[0-9]+ ]]; then
       echo $OK
    else
       echo $KO
  fi
}


#FNCT: 8
#
# Check provided argument agains X.Y  where X and Y re interger
function checkXDotYDotZVersion() {
  if [[ $1 =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
       echo $OK
    else
       echo $KO
  fi
}



#FNCT: 9
#
#heck that the argument is "OK"
# $1: version number to check
function isVersionNumberOK() {
  if [[ "$1" != "OK" ]]; then
    printf "The version number $1 KO (is incorrect)\n"
    exit -2
  fi
}


#FNCT: 10
#
# Chekc that given debian package is installed or not.
#
#  parm: $1 package name
#  return: OK if package is installed and KO otherwise.
function isPackageInstalled() {
   cmd=$(dpkg -s $1 2>/dev/null >/dev/null)
   if [[ $cmd -eq 0 ]]; then
       echo $OK
    else
       echo $KO
   fi
}


#FNCT: 11
# 
# Add the main ppa repository of postgresql database 
#
# return OK if postgresq's  apt repository is already installed
function addPostgresqlAptRepository() {
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  printf "OK\n"
}


#FNCT: 12
#
# Add postgresql apt repository media key 
# 
# Need sudo user
#   
function addPostgresqlAptRepositoryKey(){
  local pkgName1="wget"
  local pkgName2="ca-certificates"
  for pkg in $pkgName1 $pkgName2; do
    if [[ $(isPackageInstalled $pkg) == $KO ]]; then
     aptgetForceInstall $pkg
    fi
  done
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc|apt-key add -
  aptgetUpdate
  aptgetForceUpgrade
}


#FNCT: 13
# 
# Check that postgresql is installed or not 
#
# Script parameters:  
#    $1: The name of script in ${PAPI_SCRIPTS_HOME} folder used to get postgresql version
#    $2: version number of postgresql to check
# Return: 'OK' if postgresql is installed. 'KO' if not
#
function checkPostgresql() {
  pgVersion=$(${PAPI_SCRIPTS_HOME}/$1)
   if [[ "$pgVersion" == "$2" ]]; then
       echo $OK
    else
       echo $KO
    fi
}


#FNCT: 14
# Install specific version of postgresql
#
#  Script parameters 
#   $1: The version number of postgresql to install
function installPostgresql() {
  printf "Install postgresql database version $postgresqlVersion \n"
  aptgetForceInstall "postgresql-"$1
}


#FNCT: 15
#
#  List all postgresql instance user and group in laapi infrastructure architecture
#  
# in laapi postgresql instance is named pginst<i>  user associated is named pginstusr<i> and the usergroup is pginstgrp
# where <i> is an integer.
# Per default the number of instances per insfrastructure host depend on its capacity. 
# 
# By default each instance is installed on each host (VM, Container, Baremetal...) into File system /caldron/pg/pginst<i>
# The prefix is so: pginst. 
#
# Return all postgresql instance as a bash string convertible to array "instanceName<i>:instanceUser<i>:instanceGroup:instanceRootFS<i>"
function listPgInstanceGroupUser() {
  local PREFIX1="pginst"
  local PREFIX2="${PREFIX1}usr"
  local PREFIX3="${PREFIX1}grp"
  allPgInstUsers=($(grep -P "^$PREFIX2\d+" /etc/passwd | cut -d':' -f1| tr '\n' ' '|uniq))
  declare -a pgInstGroupsUsers
  local j=1
  for user in "${allPgInstUsers[@]}"; do
    userIndex=${user#$PREFIX2} 
    userGroup=$(id -Gn $user | grep -o "$PREFIX3")
    # Check FS of pg instance normally associated to the user
    pginstFSPrefix="/caldron/pg/${PREFIX1}"
    instRootFS="${pginstFSPrefix}${userIndex}"
    if [[ ! -e $instRootFS ]] ; then 
      instRootFS=""
    fi
    pgInstGroupsUsers[$j]="${PREFIX1}${userIndex}:${PREFIX2}${userIndex}:${userGroup}:${instRootFS}"
   j=$((j+1))
  done
  printf "%s\n" ${pgInstGroupsUsers[@]}
}


#FUNC: 16
# Create selft signed certificat for sysetele. Three files are generated .key .csr and .crt
#
# Generate certificat with openssl rsa4096
#
#String  X.500 AttributeType none interactively
#------------------------------
#CN      commonName
#L       localityName
#ST      stateOrProvinceName
#O       organizationName
#OU      organizationalUnitName
#C       countryName
#STREET  streetAddress
#DC      domainComponent
#UID     userid
#
#parameters:mandatory
#   $1: Name of root folder holding all certificats
#   $2: certificat name file name without extension. Example for www.crt www.key and www.csr files provides www
#   $3: countryName
#   $4: stateOrProvinceName
#   $5: localityName
#   $6: organizationName
#   $7: domainComponent
# Depends on openssl
function createDomainSSLCertificat() {
  if [[ "$(which openssl)" == "openssl:" ]]; then
    printf "Function ${FUNCNAME[0]} needs openssl to be installed\n"
    exit -1
  fi
  local CERT_ROOT_DIR=$1
  local CERT_FILE_PREFIX=$2
  local countryName=$3
  local stateOrProvinceName=$4
  local localityName=$5
  local organizationName=$6
  local domainComponent=$7
  mkdir -p ${CERT_ROOT_DIR}
  cd ${CERT_ROOT_DIR}
  openssl req -nodes -newkey rsa:4096 -keyout ${CERT_FILE_PREFIX}.key -out ${CERT_FILE_PREFIX}.csr  -subj "/C=${countryName}/ST=${stateOrProvinceName}/L=${localityName}/O=${organizationName}/CN=${domainComponent}"
  openssl x509 -req -days 730 -in ${CERT_FILE_PREFIX}.csr -signkey ${CERT_FILE_PREFIX}.key -out ${CERT_FILE_PREFIX}.crt
}

#FUNC: 17
# Check that the provided String represents a correct username or group name in linux lsb
function isValidUsername() {
  res=$(echo $1 | grep -Po '^([a-z_][a-z_0-9]{2,16})$')
  if [[ "$res" == "$1"  ]]; then
    echo $OK
  else
    echo $KO
  fi		
}


#FUNC: 18
# Check that linux user exists or not. 
# 
#parameters:mandatory
#   $1: username to check
#return: OK is user exists KO otherwise. 
function isUserExists() {
	if [[ $(id -u $1 > /dev/null 2>&1) ]]; then
             echo $OK
	else
             echo $KO
	fi
}


#FUNC: 19
#   $1: username to check
#return: OK is user exists KO otherwise. 
function isUserExists() {
	if [[ $(id -u $1 > /dev/null 2>&1) ]]; then
             echo $OK
	else
             echo $KO
	fi
}


#FUNC: 20
#parameters:mandatory
#   $1: username to check
#return: OK is user exists KO otherwise. 
function isUserExists() {
	if [[ $(id -u $1 > /dev/null 2>&1) ]]; then
             echo $OK
	else
             echo $KO
	fi
}


#FUNC: 21
# Check that linux group exists or not. 
# 
#parameters:mandatory
#   $1: groupname to check
#return: OK if group exists KO otherwise. 
function isGroupExists() {
	if [[ $(id -g "$1" > /dev/null 2>&1) ]]; then
             echo $OK
	else
             echo $KO
	fi
}


#FUNC: 22 
# Check that given user exist and it is in given group. 
# 
#parameters:mandatory
#   $1: username to check
#   $2: groupname in which user will be checked.
#return: OK is user exists in group. Othewise return KO 
function isUserInGroup() {
  local res=$(id -Gn $1 | grep -c "\b$2\b")
  if [[ $res -gt 0 ]]; then 
       echo $OK
  else
      echo $KO
  fi 
}


#FUNC: 23
# Return the ipv4 of a nic interface from its name by using ip command
#
#parameters:mandatory
# $1: nic name
#
#return: ipv4 of nic or empty string. 
function getNicIpv4(){
  local res=$(ip addr show $1 2>/dev/null | grep -Po "(?<=inet\s)((\d+\.){3}\d+)")
  echo $res
}


#FUNC: 24
# @todo
# Return the ipv6 of a nic interface from its name by using ip command

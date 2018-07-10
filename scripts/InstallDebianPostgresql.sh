#!/usr/bin/env bash
# 
# Script allowing to install : Postgresql >= 9.6.x
# 
#  Constraints: Script for debian >= 8.x or Ubuntu  >= 16.0.4  based OS  use apt-get
#  
#  Each function stop when an execution error arrives
#  Each check function return "OK" on success 
#
#  Each container <app> is installed into fs /cauldron/<app>
#  <app>=pgslq for postgresql  Database
#  Each fs has a proprietary user named: <app>usr01 
#  
#  Parameters: 
#      MANDATORY: 
#	 $1 <postgresqlVersion> as x.y where x y are integers. 
set -e

## laapi infra scripts util functions
export PAPI_UTIL_SCRIPT_NAME=AdipappiUtils.sh
source ${PAPI_INFRA_SCRIPTS}/${PAPI_UTIL_SCRIPT_NAME}
export TOOLS_ROOT_FOLDER=/caldrons


# The default configurations of postgresql user must customize this parameters of put them into a configuration file.  
## Create one instance of database
# Create a database on this instance
# Create an owner of this database
# Each instance 'i' is named pginstusr'i' when i an integer {1..}
#Create a database which will be used for application using the postgresql database.

# Index number of the postgresql instance 
export pgInstIndex=1

# The name of application using postgresql
export appUsingPgsql=bacula

# The name of postgresql database create within postgresql instance 
export pgDatabaseName=${appUsingPgsql}db

# The user which is owner of postgresql instance and database
export pgDatabaseUser=${appUsingPgsql}dbusr

# Password and listening port of  postgresql database
export pgDatabasePassword="${pgDatabaseUser}*_1439"
export pgDatabasePort=5402

# Set the^parameters of the 
declare -r PG_INST_ROOT_DIR=/caldrons/pg
declare -r PG_INST_DIR=${PG_INST_ROOT_DIR}/pginst$pgInstIndex
declare -r PG_INST_USR=pginstusr$pgInstIndex
declare -a  pgAllInstConfigs=$(listPgInstanceGroupUser)

# The format of postgresql sql instance name instance user  and instance data folder. 
declare -r pgInstConfig="pginst${pgInstIndex}:pginstusr${pgInstIndex}:pginstgrp:/caldron/pg/pginst${pgInstIndex}"

#### Install dependencies 
aptgetForceInstall "software-properties-common gnupg2 apt-transport-https"

#### Check arguments
if [[ $# -lt 1 ]]; then
  printf "This script must be executed with the version number of <postgresqlVersion> x.y\n" 
  printf "Example Usage: $0 10.1\n" 
  exit -1
else
  export postgresqlVersion=$1 
  # Check versions
  isVersionNumberOK $(checkPgsql10PlusVersion $postgresqlVersion)
fi

### Check If Postgresql is installed otherwise install it 
scriptUsedInFunction='GetPostgresqlVersionNumber.sh'
chckPG=$(checkPostgresql $scriptUsedInFunction $postgresqlVersion)
echo "CH VERS PG:***********************************************$chckPG"
if [[ "$KO" == "$chckPG" ]]; then
  printf "Postgresql version $1 is not installed on $HOSTNAME system\n"
  printf "Install latest stable version of postgresql database\n"
  addPostgresqlAptRepository
  addPostgresqlAptRepositoryKey
  res=$(installPostgresql $postgresqlVersion postgresql-devel postgresql-contrib)
 # check that postgresql is installed
  chckPG=$(checkPostgresql $scriptUsedInFunction $postgresqlVersion)
  if [[ "$KO" == "$chckPG" ]]; then
    echo -e "The postgresql version $postgresqlVersion had not been installed.\nCheck install logs \n$res"
    exit -2
  elif [[ "$OK" == "$chckPG" ]]; then
    # Stop and then remove the default  installed postgresql 'main' instance
    pg_ctlcluster $postgresqlVersion main stop
    pg_dropcluster $postgresqlVersion main 
  fi
fi


# Create postgresql instance
isInstExists=$(echo ${pgAllInstConfigs[@]} | grep -x "$pgInstConfig" | wc -w)
echo "ISEX$isInstExists"
if [[ $isInstExists -eq 0  ]]; then 
  printf "Create the postgresql instance with the following configs(user, group, inst) :  $pgInstConfig"
  $PAPI_INFRA_SCRIPTS/CreatePostgresqlInstance.sh $pgInstIndex ${PG_INST_ROOT_DIR} $postgresqlVersion
  $PAPI_INFRA_SCRIPTS/RestartPostgresqlInstance.sh pginstusr${pgInstIndex} $postgresqlVersion
fi
$PAPI_INFRA_SCRIPTS/CreateDatabaseInPostgresqlInstance.sh $pgDatabaseName  $pgDatabaseUser $pgDatabasePassword  ${PG_INST_USR} $postgresqlVersion


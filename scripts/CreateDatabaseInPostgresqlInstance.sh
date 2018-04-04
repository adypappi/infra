#!/usr/bin/env bash 
#
# Create a new database withing  running postgresql instance  
# Must be run in sudo mode  or as root user.
# User is created on template1
# Parameters: 
#    $1: databaseName
#    $2: databaseOwner
#    $3: databaseOwnerPassword  
#    $4: postgresql instance name
#    $5: postgresql instance version
set -x 
MAX_ARGS=5
ARGS_INCORRECT_NUmBER_MSG="The number of argument for this script must be ${MAX_ARGS}"

# Check arguement number
if [[ $# -ne 5 ]]; then 
	printf "${ARGS_INCORRECT_NUmBER_MSG}\nUsage: $0 <dbName> <dbOwnerName> <dbOwnerPassword> <pginstName> <pgInstVersion>\n\t"
	printf "Example: $0 nextcloud nxtcldmngr NxtCld*_1437 pginstusr01 9.6\n"
	exit -1
fi

databaseName=$1
databaseOwner=$2
databaseOwnerPassword=$3
pginstName=$4
pginstVersion=$5
PG_INST_STATUS_PREFIX_MSG="The postgresql instance name:$pginstName version:$pginstVersion %s\n"


# Check that the postgresql instance exist otherwise stop scrip	t
scriptFolder=/papi/scripts/infra
source  ${scriptFolder}/AdipappiUtils.sh
res=$(pg_lsclusters 2>/dev/null | grep "${pginstVersion}.*${pginstName}")
if [[ "$res" == "" ]]; then
  printf "${PG_INST_STATUS_PREFIX_MSG}" "does not exist" 
  exit -2
else
  # Check that the instance is running 
  res=$(pg_ctlcluster ${pginstVersion} ${pginstName} status 2>/dev/null | grep -Po "(?<=PID:\s)(\d+)")
  if [[ ! $res =~ [1-9][0-9]* ]]; then
    printf "${PG_INST_STATUS_PREFIX_MSG}" "does not running"
    exit -3 
  fi
fi

# Create database
## Check if db already exist with owner 
res=$(sudo su - $pginstName  -c "psql -lqtA" | grep ${databaseName}.*${databaseOwner})
if [[ "$res" != "" ]]; then
	printf "The database $databaseName with owner $databaseOwner already exist\n"
	exit -4
fi


## Create DB with template1 
#res=$(sudo su -  $pginstName psql -d template1 "CREATE USER $databaseOwner CREATEDB CREATEROLE WITH PASSWORD '$databaseOwnerPassword'; CREATE DATABASE $databaseName OWNER $databaseOwner")1
pginstPort=$(echo `pg_lsclusters | grep ${pginstVersion}.*${pginstName} | cut -d' ' -f3`)
echo "Instance PORT = $pginstPort"
res1=$(sudo su - $pginstName -c "psql -p $pginstPort -d template1 -c \"CREATE USER $databaseOwner WITH CREATEDB CREATEROLE LOGIN PASSWORD '$databaseOwnerPassword';\"" 2>&1)
res2=$(sudo su - $pginstName -c "psql -p $pginstPort -d template1 -c \"CREATE DATABASE $databaseName WITH OWNER $databaseOwner ENCODING 'UTF-8' TEMPLATE template1;\"" 2>&1)
res3=$(sudo su - $pginstName -c "psql -p $pginstPort -d template1 -c \"GRANT ALL PRIVILEGES ON DATABASE $databaseName TO  $databaseOwner;\"" 2>&1)


# Check that database has been created
res=$(sudo su - $pginstName  -c "psql -p $pginstPort -lqtA" | grep "${databaseName}.*${databaseOwner}")
if [[ "$res" != "" ]]; then
  printf "The database $databaseName with owner $databaseOwner has been successfully created\n"
else
  printf "Error when creating database $databaseName with owner $databaseOwner\n\tRootCausis1:$res1\n\tRootCausis2:$res2\n"
fi


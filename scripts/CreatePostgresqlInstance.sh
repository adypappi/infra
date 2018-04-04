#!/usr/bin/env bash
# Sudoer script used to create an instance of specific postgresql version: CLSTR_VRS variable value
# Only user with mandatory right can run the script
# Postgresql instance is created  on a folder called /apps/pg/$pginstusr01 as PG_DATA_DIR
# Postgresql instance owner user pginstusr0$1 and it group is pginstgrp
# PGINST_PORT= 5402 + 10*($1 - 1)
# Default parent directory of all postgresql instance : /apps/pg 
# $1: postgresql instance index 
# $2: parent directory of postgresql instance
# $3: postgresql version number
# WARNING: This script destroys existing postgres data directory if user confirms by entering 'yes'. Pg cluster is also destroyed 

# MESSAGES USED IN LOGGING 
PG_CLUSTER_EXIST_MSG="cluster configuration already exists"
SUDO_RIGHTS_MSG="This script must be run with sudo command or as root"

export PAPI_SCRIPTS_HOME=/papi/scripts/infra
source $PAPI_SCRIPTS_HOME/AdipappiUtils.sh
# Check the user running script has sudo rights
$(isUserRootOrSudo)

if [[ $# -ne 3 ]] || ! [[ $1 =~ ^[1-9]$ ]] || [[ "$2" == "" ]] || ! [[ $3 =~ [0-9]+\.?|[0-9]* ]]
then
  echo -e "Usage: $0  <digit>  <pginst_parent_dir> <pg_version>\n\t digit is a normal digit integer\n\tParent directory of all postgres instance to create"
  exit 2
else 
  USRNBR=$1
  PGINST_PARENT_DIR=$2
  CLSTR_VRS=$3
fi

# Convention constant
declare -r START_PORT=5402
declare -r PG_USERS_HOME_PARENT_DIR=/apps/users

# Set of read variables
declare -r USRIDX=$USRNBR
declare -r GRPNAME=pginstgrp${USRIDX}
declare -r USRNAME=pginstusr${USRIDX}
declare -r PGINST_PORT=$(( START_PORT + 10 * $(( USRNBR - 1)) ))
declare -r PGINST_LOG_DIR=${PGINST_PARENT_DIR}/log
declare -r PGINST_PID_DIR=${PGINST_PARENT_DIR}/run
declare -r PGINST_LOG_FILE=${PGINST_LOG_DIR}/${USRNAME}.cluster.log
declare -r PGINST_PID_FILE=${PGINST_PID_DIR}/${USRNAME}.pid
declare -r PGINST_CONFIG_DIR=${PGINST_PARENT_DIR}/configs
declare -r PGINST_CONFIG_FILE=${PGINST_CONFIG_DIR}/postgresql.${USRNAME}.conf


# Check if the cluster exists if it is this case task for deleting at confirmation stop drop instance 
res=$(pg_lsclusters | grep -P ".*${CLSTR_VRS}.*${USRNAME}.*${PGINST_PORT}.*" 2>&1)
if [[ "$res" != "" ]]; then 
  read -r -p "The postgresql cluster ${res} already exists Do you want to destroy and create new one?  enter [yes/no]:\n\gtno to cancel\n_tyes to destroy it !!!!" choice
  if [[ "$choice" == "yes" ]]; then
    printf "Destroying existing postgresql cluster $res \n"
    # stop drop
    pg_ctlcluster ${CLSTR_VRS} ${USRNAME} stop
    res=$(pg_dropcluster ${CLSTR_VRS} ${USRNAME} 2>&1)
    if [[ "$?" -ne 0 ]]; then
      printf "Error during drop pg cluster  ${CLSTR_VRS} ${USRNAME}\n\tRoot cause:${res}\n"
      exit 4
    fi
  fi
fi


# Check that the pg_data_dir for instance does not already exist if so ask for deleting 
declare -r PGINST_DATA_DIR=${PGINST_PARENT_DIR}/pginst${USRIDX}/data
if [[ -d ${PGINST_DATA_DIR} ]];then 
    printf "%s\n" "The pg data dir ${PGINST_DATA_DIR} already exist  do yoy want to reinitialyze it [yes|no] tape yes !!! destroy existing database" 
    read -r -p "Are you sure to destroy postgres existing data dir ${PGINST_DATA_DIR} [yes/no]  no to cancel| yes destroy: " choice
    if [[  "$choice" == "no" ]]; then
        exit 3
    elif [[ "$choice" == "yes" ]]; then 
       printf "Pg data directory will be destroy ${PGINST_DATA_DIR}\n"
       rm -rf "${PGINST_DATA_DIR}"
    fi 
fi


# Create  pg instance data and log directories
#mkdir -p  ${PGINST_DATA_DIR}
#mkdir -p  ${PGINST_LOG_DIR} 

printf "%s\n"  "Create Postgresql Instance $USRIDX with Data Directory located at ${PGINST_DATA_DIR}"  

echo -e "Create User ${USRNAME} with UID ${USRUID}\nCreate Group ${GRPNAME}"
${PAPI_SCRIPTS_HOME}/CreateAdmGroupUsers.sh $USRNAME $GRPNAME ${PG_USERS_HOME_PARENT_DIR}

# Get postgresql user id and primary group
USRUID=$( id -u $USRNAME ) 
GRPUID=$( id -g $USRNAME )

# Init postgresql instance
echo -e "Create postgresql database instance ${GRPNAME} and pg directory ${PGINST_DATA_DIR}"
declare -r stats_temp_directory=${PGINST_DATA_DIR}/run
#mkdir -p ${stats_temp_directory}

# Add USRNAME to postgres group 
printf "%s\n" "Add ${USRNAME} to postgres group"
usermod -a -G postgres ${USRNAME}
printf "%s\n" "Init pg cluster ${USRNAME} from data dir ${PGINST_DATA_DIR} "

# Create all directories and files needs and chown to instance user
directoriesToCreate=$(set | egrep "^PGINST_\w+_DIR=")
for dr in $directoriesToCreate; do 
	dr=$(echo $dr | cut -d'=' -f2)
        mkdir -p "$dr"
done
filesToCreate=$(set | egrep "^PGINST_\w+_FILE=")
for fl in $filesToCreate; do 
   fl=$(echo $fl | cut -d'=' -f2)
   touch ${fl}
done
for dr in $directoriesToCreate; do 
    dr=$(echo $dr | cut -d'=' -f2)
    chown -R ${USRNAME}:${GRPNAME} $dr
done

# Create cluster
res=$(pg_createcluster -u ${USRNAME} -g ${GRPNAME} -D ${PGINST_DATA_DIR} -l ${PGINST_LOG_FILE} -c ${PGINST_CONFIG_FILE} -s ${stats_temp_directory} -e "UTF-8" -p ${PGINST_PORT} ${CLSTR_VRS} ${USRNAME} 2>&1)
if [[ "$?" -ne 0 ]]; then
  printf "Error during create  pg cluster version:${CLSTR_VRS} name:${USRNAME} port:\n\tRoot cause:${res}\n"
  exit 5
fi

# Set the pid file location for the instance created
pg_conftool ${CLSTR_VRS} ${USRNAME}  ${PGINST_CONFIG_FILE}  set external_pid_file ${PGINST_PID_FILE}  


printf "Script processing time=%d seconds\n" $SECONDS



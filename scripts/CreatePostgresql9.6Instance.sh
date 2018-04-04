#!/usr/bin/env bash
# Sudoer script used to create an instance of postgresql 9.6
# Only user with mandatory right can run the script
# Postgresql instance is created  on a folder called /apps/pg/$pginstusr01 as PG_DATA_DIR
# Postgresql instance owner user pginstusr0$1 and it group is pginstgrp
# PGINST_PORT= 5402 + 10*($1 - 1)
# Default parent directory of all postgresql instance : /apps/pg 
# $1: postgresql instance index 
# $2: parent directory of postgresql instance
# WARNING: This script destroys existing postgres data directory if user confirms by entering 'yes'. Pg cluster is also destroyed 

# MESSAGES USED IN LOGGING 
PG_CLUSTER_EXIST_MSG="cluster configuration already exists"


if [[ $# -ne 2 ]] || ! [[ $1 =~ ^[1-9]$ ]] || [[ "$2" == "" ]]
then
  echo -e "Usage: $0  <digit>  <pginst_parent_dir> \n\t digit is a normal digit integer\n\tParent directory of all postgres instance to create"
  exit 1
else 
  USRNBR=$1
  PGINST_PARENT_DIR=$2
fi

# Check that the pg_data_dir for instance does not already exist 
declare -r PGINST_DATA_DIR=${PGINST_PARENT_DIR}/data
if [[ -d ${PGINST_DATA_DIR} ]];then 
    printf "%s\n" "The pg data dir ${PGINST_DATA_DIR} already exist  do yoy want to reinitialyze it [yes|no] tape yes !!! destroy existing database" 
    read -r -p "Are you sure to destroy postgres existing data dir ${PGINST_DATA_DIR} [yes/no]  no to cancel| yes destroy: " choice
    if [[  "$choice" == "no" ]]; then
        exit 2
    elif [[ "$choice" == "yes" ]]; then 
       printf "Pg data directory will be destroy ${PGINST_DATA_DIR}\n"
       rm -rf "${PGINST_DATA_DIR}"
    fi 
fi

# Convention constant
declare -r START_PORT=5402
declare -r PG_USERS_HOME_PARENT_DIR=/apps/users

# Set of read variables
declare -r USRIDX=$(printf "%02d" $USRNBR)
declare -r GRPNAME=pginstgrp${USRIDX}
declare -r USRNAME=pginstusr${USRIDX}
declare -r PGINST_PORT=$(( START_PORT + 10 * $(( USRNBR - 1)) ))
declare -r PGINST_LOG_DIR=${PGINST_PARENT_DIR}/log
declare -r PGINST_LOG_FILE=${PGINST_LOG_DIR}/${USRNAME}.cluster.log

# Create  pg instance data and log directories
mkdir -p  ${PGINST_DATA_DIR}
#mkdir -p  ${PGINST_LOG_DIR} 

printf "%s\n"  "Create Postgresql Instance $USRIDX with Data Directory located at ${PGINST_DATA_DIR}"  

echo -e "Create User ${USRNAME} with UID ${USRUID}\nCreate Group ${GRPNAME}"
./CreateAdmGroupUsers.sh $USRNAME $GRPNAME ${PG_USERS_HOME_PARENT_DIR}


# Get postgresql user id and primary group
USRUID=$( id -u $USRNAME ) 
GRPUID=$( id -g $USRNAME )

# Init postgresql instance
echo -e "Create postgresql database instance ${GRPNAME} and pg directory ${PGINST_DATA_DIR}"
declare -r stats_temp_directory=${PGINST_DATA_DIR}/run
#mkdir -p ${stats_temp_directory}
declare -r CLSTR_VRS=9.6

# Add USRNAME to postgres group 
printf "%s\n" "Add ${USRNAME} to postgres group"
usermod -a -G postgres ${USRNAME}

printf "%s\n" "Init pg cluster ${USRNAME} from data dir ${PGINST_DATA_DIR} "
#mkdir -p ${PGINST_LOG_DIR}
chown -R ${USRNAME}:${GRPNAME} $PGINST_DATA_DIR

# Check if the cluster exists if so delete it 
res=$(pg_lsclusters | grep -P ".*${CLSTR_VRS}.*${USRNAME}.*${PGINST_PORT}.*" 2>&1)
if [[ "$res" != "" ]]; then 
  if [[ "$choice" == "yes" ]]; then
    printf "Destroying existing postgresql cluster $res \n"
    res=$(pg_dropcluster ${CLSTR_VRS} ${USRNAME} 2>&1)
    if [[ "$?" -ne 0 ]]; then
      printf "Error during drop pg cluster  ${clstr_vrs} ${usrname}\n\tRoot cause:${res}\n"
      exit 2
    fi
  fi
fi

# Create new cluster
res=$(pg_createcluster -u ${USRNAME} -g ${GRPNAME} -D ${PGINST_DATA_DIR} -l ${PGINST_LOG_FILE} -s ${stats_temp_directory} -e "UTF-8" -p ${PGINST_PORT} ${CLSTR_VRS} ${USRNAME} 2>&1)
## Check result
if [[ "$?" -ne 0 ]]; then
  printf "Error during create  pg cluster version:${clstr_vrs} name:${usrname} port:\n\tRoot cause:${res}\n"
  exit 3
fi

# Display processing time. 
printf "Script processing time=%d seconds\n" $SECONDS



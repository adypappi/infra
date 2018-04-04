#!/usr/bin/env bash
# Full integrale restoring the redmine pg's database from dump file created by adipappi's script BackupRedmine.sh 
# Script argument: 2 
# arg1: the system user who is the propertary of postgresql instance containing the redmine database 
# arg12: the name of redmine database
# args3: the full path to dump file to restore
if [[ $# -ne 5 ]];then
   printf "Usage:$0 <pgInstanceUserName> <pgInstancePort> <redmineDatabaseName> <redmineDbUser> <dumpFileFullPathToRestore>\nDump file is in format: pg_dump custom compressed\n"
   exit -1
fi
pgInstUsr=$1
pgInstPort=$2
redmineDbName=$3
redmineDbuser=$4
dumpFilePath=$5
dumpFileName=$(basename $5) 
cmd="sudo su - $1 -c 'pg_restore -p $2 --no-owner --no-privileges -d $3 --role=$4 -c -C $5'"
eval $cmd
if [[ $? -ne 0 ]]; then 
   printf "Error when restore file $dumpFilePath with comman $cmd\n" 
fi	


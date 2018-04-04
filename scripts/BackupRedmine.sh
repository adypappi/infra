#!/usr/bin/env bash 
# Get all the redmine folder to backup without cache
# Attention: only folder ending by redmine word is keeped for backup.
# The backup is for postgresql database
# backup is for debian redmine 3.X install default directory.  	 
# take one parameter: $1 = redmine database name to backup 

# Default redmine database is redmine_default 
DEFAULT_REDMINE_DB_NAME="redmine_default"
redmineDBName=$DEFAULT_REDMINE_DB_NAME

# Backup folders organization
redmineDBBackupRootDir=/backups/db/laapiknowledge
redmineFSBackupRootDir=/backups/fs/laapiknowledge
mkdir -p -m 775 $redmineDBBackupRootDir
mkdir -p -m 775 $redmineFSBackupRootDir

# Check argument provided 
if [ "$#" -ne 1 ]
then
  echo "Save the default redmine database $redmineDBName into "
  echo "Tar Gzip with level 9 compression each main folders of redmine into file within directory $redmineFSBackupRootDir"
else
  redmineDBName=$1
fi



# Find directory to  ackup
export AllDirToBackup=`find / -type d 2>/dev/null | grep -i redmine | grep -vP "(cache|test|log|tmp|about)" | grep -Poi "(/\w+){2,4}" | grep -P "redmine$" | grep -Pv "^/lib/redmine" | sort | uniq -u`
echo "**************************************************************************************************************"
echo $AllDirToBackup
# Save current directory
echo -e "---- Begin Backuping following redmine's fs\n$AllDirToBackup\n----"
backupTime=`date +%Y%m%d%H%M%S`
currentBackupFolder=$redmineFSBackupRootDir/${backupTime}
mkdir -p -m 775 $currentBackupFolder
for dir in $AllDirToBackup
do
  dirName=`echo $dir | cut -c 2- | tr '/' '_'`
  fsBckpCmd="export GZIP=\"-9\" && tar -cvzf ${currentBackupFolder}/${dirName}.tgz $dir"
  echo -e "\t\t: Backup $dir intto archive file $dirName" 
  eval "$fsBckpCmd"
done
sudo chown -R adimida:adm ${currentBackupFolder}
echo "---- End Backup redmine's fs `date +%Y%m%d%H%M%S` ----"

# Current backup directory
backupTime=`date +%Y%m%d%H%M%S`
redmineDBBackupDir=$redmineDBBackupRootDir/$backupTime
sudo mkdir -p -m 775 $redmineDBBackupDir
sudo chown adimida:adm $redmineDBBackupDir

# Backup command and it execution
echo "--- Begin Processing Laapi Redmine database backup action : $backupTime  ----"
dbBackupFile=$redmineDBBackupDir/${redmineDBName}.pg.dump.gzip
dbBckpCmd="cd $redmineDBBackupDir && sudo su - postgres -c 'pg_dump -F c -Z 9 ${redmineDBName}  > $dbBackupFile'"
eval "$dbBckpCmd"
sudo chown adimida:adm $dbBackupFile 
chmod 775 $dbBackupFile 
endTime=`date +%Y%m%d%H%M%S`
echo "--- End Processing Laapi Redmine database backup action :  $endTime ----"


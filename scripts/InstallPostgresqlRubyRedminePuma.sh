#!/usr/bin/env bash
# 
# Script allowing to install : Postgresql >= 9.6.x, Ruby >= 2.4, Puma-redmine integration and ruby native webrick http server   
# https://gist.githubusercontent.com/jbradach/6ee5842e5e2543d59adb/raw/   
# 
#  Constraints: Script for debian >= 8.x or Ubuntu  >= 16.0.4  based OS  use apt-get
#  
#  Each function stop when an execution error arrives
#  Each check function return "OK" on success 
#
#  Each executor container <app> is installed into fs /cauldron/<app>
#  <app>=pgslq for postgresql  Database
#  <app>=redmine for redmine Project manager
#  <app>=ruby for ruby programmaing Language
#  etc.
#  Each fs has a proprietary user named: <app>usr01 
#  
#  Parameters: 
#      MANDATORY: $1 <postgresqlVersion> as x.y $2 <rubyVersion> as x.y.z  $3 <redmineVersion> as x.y  where x y and z are integers. 
set -e


## laapi infra scripts util functions
export PAPI_INFRA_SCRIPTS=/papi/scripts/infra
export PAPI_UTIL_SCRIPT_NAME=AdipappiUtils.sh
source ${PAPI_INFRA_SCRIPTS}/${PAPI_UTIL_SCRIPT_NAME}
export TOOLS_ROOT_FOLDER=/caldrons


#### Check arguments
if [[ $# -ne 3 ]]; then
  printf "This script must be executed with <postgresqlVersion> x.y <rubyVersion>x.y.z  <redmineVersion> x.y\n" 
  printf "Ensure that the compatibility between <rubyVersion> <redmineVersion> at \n\thttp://www.redmine.org/projects/redmine/wiki/redmineinstall \n"
  printf "Example Usage: $0 9.6 2.4.1 3.4 \n" 
  exit -1
else
  postgresqlVersion=$1 
  rubyVersion=$2 
  redmineVersion=$3 
  # Check versions
  isVersionNumberOK $(checkXDotYVersion $postgresqlVersion)
  isVersionNumberOK $(checkXDotYDotZVersion $rubyVersion)
  isVersionNumberOK $(checkXDotYVersion $redmineVersion)
fi


#### Install dependencies 
aptgetForceInstall "software-properties-common gnupg2"

### Check If Postgresql is installed otherwise install it 
scriptUsedInFunction='GetPostgresqlVersionNumber.sh'
chckPG=$(checkPostgresql $scriptUsedInFunction $postgresqlVersion)
echo "CH VERS PG:***********************************************$chckPG"
if [[ "$KO" == "$chckPG" ]]; then
  printf "Postgresql version $1 is not installed on $HOSTNAME system\n"
  printf "Install latest stable version of postgresql database\n"
  addPostgresqlAptRepository
  addPostgresqlAptRepositoryKey
  res=$(installPostgresql $postgresqlVersion)
 # check that postgresql is installed
  chckPG=$(checkPostgresql $scriptUsedInFunction $postgresqlVersion)
  if [[ "$KO" == "$chckPG" ]]; then
    printf "The postgresql version $postgresqlVersion was not installed.\nCheck install logs \n$res"
    exit -2
  elif [[ "$OK" == "$chckPG" ]]; then
    # Stop and then remove the default  installed postgresql 'main' instance
    pg_ctlcluster $postgresqlVersion main stop
    pg_dropcluster $postgresqlVersion main 
  fi
fi

## Create one instance of postgresql database on this instance
# Create in instance of postgresql database
# Each instance 'i' is named pginstusr'i' when i an integer {1..}
#Create a database which will be used for redmine.
export pgInstIndex=1
export pgDatabaseName=redminedb
export pgDatabaseUser=redminedbusr
export pgDatabasePassword=redminedb*_1438
export pgDatabasePort=5402
declare -r PG_INST_ROOT_DIR=/caldrons/pg
declare -r PG_INST_DIR=${PG_INST_ROOT_DIR}/pginst$pgInstIndex
declare -r PG_INST_USR=pginstusr$pgInstIndex
declare -a  pgAllInstConfigs=$(listPgInstanceGroupUser)
declare -r pgInstConfig="pginst${pgInstIndex}:pginstusr${pgInstIndex}:pginstgrp:/caldron/pg/pginst${pgInstIndex}"
isInstExists=$(echo ${pgAllInstConfigs[@]} | grep -x "$pgInstConfig" | wc -w)

# Create instance parent directory 
mkdir -p ${PG_INST_ROOT_DIR}

if [[ $isInstExists -eq 0  ]]; then 
  printf "Create the postgresql instance with the following configs(user, group, inst) :  $pgInstConfig"
  $PAPI_INFRA_SCRIPTS/CreatePostgresqlInstance.sh $pgInstIndex ${PG_INST_ROOT_DIR} $postgresqlVersion
  $PAPI_INFRA_SCRIPTS/RestartPostgresqlInstance.sh pginstusr${pgInstIndex} $postgresqlVersion
fi
$PAPI_INFRA_SCRIPTS/CreateDatabaseInPostgresqlInstance.sh $pgDatabaseName  $pgDatabaseUser $pgDatabasePassword  ${PG_INST_USR} $postgresqlVersion


#### Install redmine ruby some dependencies 
deps="git build-essential libpq-dev libssl-dev libreadline-dev zlib1g-dev imagemagick libmagickcore-dev libmagickwand-dev"
aptgetUpdate 
aptgetForceUpgrade 
aptgetForceInstall $deps


### Create user projectmgr add it to group adm as secondary group and home into /apprd10/users/home 
rdUser=projectmgr
rdGroup=projectgrp
rdInstallFolderName=${TOOLS_ROOT_FOLDER}/prjmgr
declare -r REDMINE_HOME=${rdInstallFolderName}/redmine
rubyInstallDefaultBin="/opt/rubies/ruby-"$rubyVersion/bin 
rdUserHome="/home/$rdUser"
if [[ "$(isUserInGroup $rdUser $rdGroup)" == "KO" ]]; then
  printf "Create project manager admin : $rdUser  with the group $rdGroup"
  ${PAPI_INFRA_SCRIPTS}/CreateAdmGroupUsers.sh $rdUser $rdGroup 
  usermod -a -G adm $rdUser
fi


### Clone redmine lastest version and create database yml file and remine configuration yml file 
githubRepo="https://github.com/redmine" 
printf "Clone redmine version $redmineVersion from and create database's yml file and redmine's yml configuration file\n" 
install -m 775  -o $rdUser -g adm -d $rdInstallFolderName
cd $rdInstallFolderName
rm -rf redmine
git clone -b ${redmineVersion}-stable  $githubRepo/redmine.git
cd redmine
for fl in database configuration; do cp config/$fl.yml.example config/$fl.yml; done


### Change the group of REDMINE_HOME
chown -R $rdUser:www-data ${REDMINE_HOME}

#### Install chruby and ruby-install environment manager as projectmgr user
githubRepo="https://github.com/postmodern"
printf "Install chruby and ruby-install environment manager from postmodern github  $githubRepo\n"
bashrcFile="${rdUserHome}/.bashrc"
for bnr in chruby ruby-install; do 
  cd ${rdUserHome} 
  rm -rf ${bnr}
  git clone $githubRepo/${bnr}.git
  cd ${bnr}
  make install
  echo "source /usr/local/share/${bnr}/${bnr}.sh" >> $bashrcFile  
  if [[ "$bnr" == "chruby" ]]; then
    echo 'source /usr/local/share/chruby/auto.sh' >> $bashrcFile
  fi
done
chown -R $rdUser:$rdUser $rdUserHome


#### Install ruby version with ruby-install
printf "Installing ruby version $rubyVersion with ruby-install\n"
okMesg="Successfully installed ruby $rubyVersion"
res=$(ruby-install ruby $rubyVersion)
if [[ "$res" != *$okMesg* ]]; then
  printf "Installation of ruby version $rubyVersion  by ruby-install tools failed\n"
  exit -4
else
  echo 'export PATH=$PATH:/opt/rubies/ruby-'$rubyVersion/bin >> $bashrcFile
fi

### Download puma configuration for ruby rails from jbradach's github repo then change 'application_path' key value  to redmine home folder
pumaRbFile=${REDMINE_HOME}/config/puma.rb
pumaRvFileRepo="https://gist.githubusercontent.com/jbradach/6ee5842e5e2543d59adb/raw/"
curl -Lo  ${pumaRbFile} ${pumaRvFileRepo}
sed -i "s#/home/redmine/redmine#${REDMINE_HOME}#g" $pumaRbFile

## Update the database parameter in database.yml and email configuration in configuraition.yml of redmine installation folder
redmineDbYmlFile=${REDMINE_HOME}/config/database.yml
redmineConfigYmlFile=${REDMINE_HOME}/config/configuration.yml
## Add database port into database.yml config file @todo parametrize port number
sed -ri  "s/(.+)password:(.+)/\1password:\2\n\1port: ${pgDatabasePort}/g" $redmineDbYmlFile
declare -A dbConfig
dbConfig=([adapter]=" postgresql" [database]=" $pgDatabaseName" [host]=" 127.0.0.1" [username]=" $pgDatabaseUser" [password]=" $pgDatabasePassword")
for k in "${!dbConfig[@]}"; do
 sed -i -e "s/$k:.*/$k:${dbConfig[$k]}/g" $redmineDbYmlFile
done

## Email configuration settings 
#Put in a .sh file call RedmineGmailSmtpConfig.sh: params: redmine configuration.yml. file, gmail user, gmail password.
declare -A emailConfig
declare -a keyAndPosition
declare -r p2="    " # 4 space chars
declare -r p4="      " # 6 spaces chars
key[1]="delivery_method"
key[2]="smtp_settings"
key[3]="enable_starttls_auto"
key[4]="address"
key[5]="port"
key[6]="domain"
key[7]="authentication"
key[8]="user_name"
key[9]="password"

# Set the space of key
declare keyspace[1]=$p2
declare keyspace[2]=$p2
for i in {3..9}; do declare keyspace[$i]=$p4; done

email="infracloud@sysetele.com"
emailPasswd="Adimida-.1439"
emailConfig=([${key[1]}]=" smtp" [${key[2]}]="" [${key[3]}]=" true" [${key[4]}]=" \"smtp.gmail.com\"" [${key[5]}]=" 587" [${key[6]}]=" \"gmail.com\"" [${key[7]}]=" plain" [${key[8]}]=" \"$email\"" [${key[9]}]=" \"$emailPasswd\"")
emailYmlString=""
for i in {1..9}; do
 keyi=${key[$i]}
 emailYmlString="${emailYmlString}${keyspace[$i]}$keyi:${emailConfig[$keyi]}\n"
done
pattern="email_delivery:"
sed -i "0,/$pattern/ s/$pattern/$pattern\n$emailYmlString/" $redmineConfigYmlFile


# Create alias for each  binary within bin directory of ruby into /usr/bin/
for  binary in $(ls ${rubyInstallDefaultBin})
do
    sudo ln -sf ${rubyInstallDefaultBin}/$binary /usr/bin/$binary 
done	


#  Install puma from rubygems by bundler as projectmgr
redmineInstallBin=${REDMINE_HOME}/bin
gemfile=${REDMINE_HOME}/Gemfile
sudo su - $rdUser -c "printf 'gem: --no-rdoc\n' >> $rdUserHome/.gemrc;cd $REDMINE_HOME;if [[ \"$(grep -P 'gem\s+"puma"' $gemfile)\" == \"\" ]]; then sed -ri 's/^source(.*)/source \1\ngem \"puma\"\n/' $gemfile; fi"
${rubyInstallDefaultBin}/gem install bundler
sudo su - $rdUser -c "cd ${REDMINE_HOME}; ${rubyInstallDefaultBin}/bundler install --without development test; ${rubyInstallDefaultBin}/bundle install;export PATH=$PATH:${rubyInstallDefaultBin};${redmineInstallBin}/rake generate_secret_token;${redmineInstallBin}/rake db:migrate;RAILS_ENV=production REDMINE_LANG=en ${redmineInstallBin}/rake redmine:load_default_data"

# Set log directory access mod
mkdir -p ${REDMINE_HOME}/log
chmod -R 0664 ${REDMINE_HOME}/log
chown -R $rdUser:www-data  ${REDMINE_HOME}/log

## Start webrick server with 0.0.0.0 binding + http port 8090
webrickHttpPort=8090
res=$(${rubyInstallDefaultBin}/ruby ${REDMINE_HOME}/bin/rails server webrick -b 0.0.0.0 -p 8090 -e production -d)


#
#--> Check Ok with login admin admin 
#
#### Change admin user password :  redmine*_1437
#
#
### @todo create systemd service for running redmine 
### @todo create nginx font for webric. 
#
#
## INSTALL NEXTCLOUD 13 php 7.2 NGINX PGSQL 9.6
#```sh
#apt update
#apt upgrade
#apt dist-upgrade
#apt-get install apt-transport-https lsb-release ca-certificates
#get -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
#echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
#apt-get update
#apt-get upgrade
#```
#
### Install php7.2
#
#apt install --no-install-recommends unzip php7.2 php7.2-fpm php7.2-pgsql php7.2-curl php7.2-json php7.2-gd  php7.2-intl php7.2-gmp  php7.2-mbstring php7.2-xml php7.2-zip
#
#
#
### Install nginx
####  Add nginx repos 
#```sh 
#  printf "deb http://nginx.org/packages/debian/ $( lsb_release -c | sed 's/Codename:\s\+//g') nginx\n" >> /etc/apts/sources.list.d/nginx.list 
#  curl http://nginx.org/keys/nginx_signing.key | apt-key add - 
#  apt update
#  apt upgrade
#  apt dist-upgrade
#  apt install nginx
#  curl -is http://vmbackuplnx1 | grep HTTP/
#```
#Latest command return HTTP/1.1 200 OK
#
#
### Download install latest version of nextcloud configure folder chmod owner 
#
#### Download lastest version 
#export downloads=/apps/downloads
#mkdir -p ${downloads}
#cd ${downloads}
#export nxtcld_archive=nextcloudlatest.zip
#curl -o ${nxtcld_archive} https://download.nextcloud.com/server/releases/latest.zip
#
#### Prepare nextcloud engine and nextcloud data
#export nxtcld_root_dir=/app/wifte
#export nxtcld_engine_dir=${nxtcld_root_dir}
#export nxtcld_data_dir=/datas/wifte
#mkdir -p ${nxtcld_engine_dir} 
#mkdir -p ${nxtcld_data_dir} 
#unzip ${nxtcld_archive} -d ${nxtcld_engine_dir}  
#chown -R www-data:www-data ${nxtcld_root_dir} 
#
### Create postgresql instance and wiftedb database instance on this postgresql instance
#cd $PAPI_INFRA_SCRIPTS 
#./CreatePostgresqlInstance.sh  1 /apps/pg
#./CreateDatabaseInPostgresqlInstance.sh wiftedb wiftemngr wifte*_1437 pginstusr01 9.6
#
### Create selft signed certificat for sysetele. 
#
#Generate certificat  with openssl
#
#```sh
#export WIFTE_CERT_ROOT_DIR=$nxtcld_root_dir/cert/ssl
#kdir -p $WIFTE_CERT_ROOT_DIR
#openssl req -x509 -nodes -days 730 -newkey rsa:4096 -keyout $WIFTE_CERT_ROOT_DIR/wifte.key -out $WIFTE_CERT_ROOT_DIR/wifte.crt
#
#```
#Country code: FR 
#State name: IDF
#City: Cergy
#Organization name: adipappi.net
#Organization unit: SYSETELE
#FQDN: wifte.adipappi.net
#Email: devprg@gmail.com
#
#
#### Create the nginx  configuration for nextcloud :   /app/wifte/nextcloud/nginx.conf 
#```sh
# mv  /etc/nginx/conf.d/default /home/adimida/backups/nginx_default_vhost_conf.conf
# sed '36,173 !d' /app/wifte/nextcloud/core/doc/admin/_sources/installation/ngnx.txt >> /app/wifte/nextcloud/nginx.conf 
#```
#For our version of nextcloud the config of nginx is between  line 36 and 173. This line number must be adapted.
#
#### Modify /app/wifte/nextcloud/nginx.conf 
#Adjusting the path to ssl certificat, the root of nexcloud installation etc. 
#
#### Modify php-fpm configuration file /etc/php/7.2/fpm/pool.d/www.conf by  listen on 127.0.0.1:9000 instead of unix local sockert 
#
#```sh
#  ;listen = /run/php/php7.2-fpm.sock
#  listen = 127.0.0.1:9000
#  systemctl restart php7.2-fpm
#  ss -pant | grep 9000
#```
#
#### Test and Validate local nginx url 
#```sh
#   systemctl restart nginx
#   curl -is http://172.16.0.4 | grep HTTP/
#```
#
### Configure wifte (nextcloud)
#
#Change the owner of /datas/wifte to ww w-data
#   
#```sh
#  chown -R www-data:www-data /data/wifte
#  systemctl restart nginx 
#```
#
#Go to url **https://172.16.0.4/index.php** and fill forms. 
#
#Admin: wifteadmin/wifte*_1438
#data folder: /datas/wifte
#dbmanager: wiftemngr
#dbpassword: wifte*_1437
#
#
### @todo install mattermost for slack replacement 
### @todo Explore best paper usenix portals
#
#
## INFRA HOW TO 
#
#Create .bash_profile for adimida user containing the papi infra tools 
#
#echo "export PAPI_INFRA_SCRIPTS=/papi/scripts/infra" >> .bash_profile


# Folder containing the Full Installation Process of each software installed on adjiguiba home infra
## Installation of Nextcloud om nasad01

In this article I will show you  how to install a full ready to used Nextcloud application. 


### Create a third partition of 10 GiB on each block device /dev/sda, /dev/sdb, /dev/sdc, /dev/sdd
```sh
for i in a b c d; do sudo ./CreateMultiplePartionOnDevice.sh /dev/sd$i 1 3 $(( 10 * 1024 *1024 * 2)) papird10; done
sudo ./CreateMultiplePartionOnDevice.sh /dev/sdb 1 3 $(( 10 * 1024 *1024 * 2)) papird10
sudo ./CreateMultiplePartionOnDevice.sh /dev/sdc 1 3 $(( 10 * 1024 *1024 * 2)) papird10
sudo ./CreateMultiplePartionOnDevice.sh /dev/sdd 1 3 $(( 10 * 1024 *1024 * 2))  
./PciDevicePathId.sh 
```

### Create a raid10 zfs pool with four 10GiB partitions on disks sda sdb sdc sdd: papird10

```sh
sudo zpool create papird10 mirror pci-0000:00:17.0-ata-1-part3 pci-0000:00:17.0-ata-2-part3 mirror pci-0000:00:17.0-ata-3-part3 pci-0000:00:17.0-ata-4-part3
```

### Create nfs shared zfs papird10/papi mounted on /papi on papird10 pool

```sh
sudo zfs create -o mountpoint=/papi -o sharenfs=on papird10/papi
``

### Authorization from all local network 
```sh
sudo zfs set sharenfs=sec=sys,rw=@192.168.1.1/24 papird10/papi
```

### Make ZFS persistent after reboot 

set share properties to yes within file /etc/default/zfs

ZFS_SHARE='yes'
ZFS_UNSHARE='yes'


### Mounting share /papi on a client machine devad01

To mount correctly the nfs export we use systemd auto mount function. 

```bash
sudo echo "nasad01:/papi   /papi  nfs  noauto,x-systemd.automount,x-systemd.device-timeout=10,timeo=14,x-systemd.idle-timeout=1min 0 0" >> /etc/fstab
sudo systemctl restart /papi
ls /papi
```
This allow systemd to mount the /papi on boot. If an error occurs after timesout the boot process will not hangup. 


### Clone the nextcloud lastest version from it github repository

```bash
cd /rc/configure && make -C srcpprd10/tools/nextcloud
git clone  https://github.com/nextcloud/server.git
```

## Install latest stable version of postgresql 

```bash
sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
sudo apt-get update
sudo apt install -y postgresql-9.6
```

### Create postgresql instance 01 for nextcloud

Postgresql instance are defined  per user pgusr0i (i in 1..N) group pginstgrp and zfs  fs apprd10/pg/pginst0i  i in (1..N) 
Each user home are located into apprd10/users/home
The guid of postgresql group is 11111.
The guid of postgresql user  is 11101 11102 11103 ... 1110N  so max number of possible postgresql users on one host is 9

*Each postgresql instance is associated to one only one postgresal user*  
* The port of instances are  5402  5412 5422 5432 5442 5452 5462...5492
*The script is located into /papi/scripts/infra/CreatePostgresqlInstance.sh*



# Create and Start and Check  the instance service 

```sh
 sudo su - pginstusr01
 cd /papi/scripts/infra
./CreatePostgresqlInstance.sh 1 /app/pg
sudo su - pginstusr01 -c "pg_ctlcluster 9.6 pginstusr01 start"
sudo su - pginstusr01 -c "pg_ctlcluster 9.6 pginstusr01 status"
```
last command return output with the pid of postgresql instance service running. 


## Install Redmine Nginx Puma Postgresql

### Install all dependencies 

```sh
apt update && apt upgrade && apt dist-upgrade && apt install -y git postgresql build-essential libpq-dev libssl-dev libreadline-dev zlib1g-dev imagemagick libmagickcore-dev libmagickwand-dev```

### Create user projectmgr add it to group adm as secondary group and home into /apprd10/users/home 

```bash
#!/usr/bin/env bash
#
# This script is used to create a user with group and add it to 'adm'  group
# user runing this script must be have sudoer right.
# args 
# $1: username
# $2:Â groupname
set -o errexit
if [[ "$#" -ne 2 ]]; then
    printf "Usage: $0 <userName> <userGroup>.\n"
    exit 1
fi
declare -r USRNAME="$1"
declare -r GRPNAME="$2"
declare -r ADMGROUP="adm"

# check that group exists else create it
if [[ ! $(getent group $GRPNAME) ]]; then
   groupadd ${GRPNAME}
fi

# check that user exists else create it
if [[ ! $(getent user $USRNAME) ]]; then
   useradd ${USRNAME} -m -g ${GRPNAME} -G ${GRPNAME},${ADMGROUP} -s /bin/bash -b /apprd10/users/home
fi
```
sudo /papi/scripts/infra/CreateAdmGroupUsers.sh projectmgr projectgrp


### Clone redmine lastest version and create database yml file and remine configuration yml file 
sudo u - project 
cd /apprd10/tools
git clone -b 3.4-stable  https://github.com/redmine/redmine.git 
cd redmine
cp config/database.yml.example config/database.yml
cp config/configuration.yml.example config/configuration.yml


### Install chruby and ruby-install environment manager as projectmgr

```bash
sudo su - projectmgr

for bnr in chruby ruby-install
do 
  cd /apprd10/tools/
  sudo git clone https://github.com/postmodern/${bnr}.git
  cd ${bnr}
  sudo make install
  echo 'source /usr/local/share/'"$bnr/$bnr".sh >>  ~/.bashrc
  if [[ "$bnr" == "chruby" ]]; then
    echo 'source /usr/local/share/chruby/auto.sh' >> ~/.bashrc
  fi
done
```

### Install latest version of ruby with ruby-install

#### List all version of Ruby, JRuby, Rubinius, MagLev or MRuby 

`ruby-install`

#### Install latex version of ruby 

`ruby-install --latest ruby`

wait for long minutes at the end on get the following similar message 

>>> Successfully installed ruby 2.4.1 into /apprd10/users/home/projectmgr/.rubies/ruby-2.4.1

### Add ruby in user projectmgr PATH

`export PATH=$PATH:/apprd10/users/home/projectmgr/.rubies/ruby-2.4.1/bin`


## Create *redmine* database User with password 'redmine*_1437'  and Database redminedb

```bash
sudo su - pginstusr01 -c "dropuser redmine"
sudo su - pginstusr01 -c "create user redmine with password 'redmine*_1437'"
sudo su - pginstusr01 -c "createdb -p 5402 -E UTF8 -O redmine -T template0  redminedb"
```
Check the database agains user pginstusr01

`sudo su - pginstusr01 -c "psql -c \"select datname from pg_database JOIN  pg_authid on pg_database.datdba = pg_authid.oid where rolname='redmine';\""`

Other possibility more verbose : print the psql short command. 

`sudo su - pginstusr01 -c "psql -E  -c \"\l+\""
********* QUERY **********
SELECT d.datname as "Name",
       pg_catalog.pg_get_userbyid(d.datdba) as "Owner",
       pg_catalog.pg_encoding_to_char(d.encoding) as "Encoding",
       d.datcollate as "Collate",
       d.datctype as "Ctype",
       pg_catalog.array_to_string(d.datacl, E'\n') AS "Access privileges",
       CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
            THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
            ELSE 'No Access'
       END as "Size",
       t.spcname as "Tablespace",
       pg_catalog.shobj_description(d.oid, 'pg_database') as "Description"
FROM pg_catalog.pg_database d
  JOIN pg_catalog.pg_tablespace t on d.dattablespace = t.oid
ORDER BY 1;
**************************

@todo : I'am here

# Create zfs for redmine, git clone redmine repo and change it owner to projectmgr:www-data
```bash
export REDMINE_ZFS=apprd10/tools/redmine
export REDMINE_HOME=/${REDMINE_ZFS}
export VRS=3.4
sudo zfs create ${REDMINE_ZFS} 
sudo -u projectmgr git clone https://github.com/redmine/redmine.git ${REDMINE_HOME}/${VRS}
sudo chown -R projectmgr:www-data ${REDMINE_HOME}
```


# Download puma configuration for ruby rails from jbradach and chnage application_path to redmine version folder

curl -Lo /apprd10/tools/redmine/3.4/config/puma.rb https://gist.githubusercontent.com/jbradach/6ee5842e5e2543d59adb/raw/

replace within  file **/apprd10/tools/redmine/3.4/config/puma.rb**  the path "/home/redmine/redmine" by  "/apprd10/tools/redmine/3.4"

# Update the database parameter in database.yml and email configuration in configuraition.yml of redmine installation folder

## database.yml modification section 
production:
  adapter: postgresql
  database: redminedb
  host: localhost
  username: redmine
  password: "redmine*_1437"


## configurqtion.yml modification section 
 email_delivery:
      delivery_method: :smtp
      smtp_settings:
        enable_starttls_auto: true
        address: "smtp.gmail.com"
        port: 587
        domain: "smtp.gmail.com" # 'your.domain.com' for GoogleApps
        authentication: :plain
        user_name: "devjj2ee@gmail.com"
        password: "Bza2Eth*"


#  Install puma from rubygems by bundler as projectmgr

```bash
echo "gem: --no-rdoc" >> ~/.gemrc
printf "# Gemfile\nsource 'https://rubygems.org'\ngem 'puma'\n" >> Gemfile
gem install bundler
bundler install --without development test
cd /apprd10/tools/redmine/3.4/
bundle install 
rake generate_secret_token
RAILS_ENV=production rake db:migrate
RAILS_ENV=production rake redmine:load_default_data
```

# Start webrick server with 0.0.0.0 binding + http port 8090

`ruby  bin/rails server webrick -b 0.0.0.0 -p 8090 -e production`

=> Booting WEBrick
=> Rails 4.2.8 application starting in production on http://0.0.0.0:8090
=> Run `rails server -h` for more startup options
=> Ctrl-C to shutdown server
[2017-07-12 05:43:32] INFO  WEBrick 1.3.1
[2017-07-12 05:43:32] INFO  ruby 2.4.1 (2017-03-22) [x86_64-linux]
[2017-07-12 05:43:32] INFO  WEBrick::HTTPServer#start: pid=6189 port=8090

--> Check Ok with login admin admin 

### Change admin user password :  redmine*_1437


## @todo create systemd service for running redmine 
## @todo create nginx font for webric. 


# INSTALL NEXTCLOUD 13 php 7.2 NGINX PGSQL 9.6
```sh
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt-get install apt-transport-https lsb-release ca-certificates
sudo get -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sudo echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
sudo apt-get update
sudo apt-get upgrade
```

## Install php7.2

sudo apt install --no-install-recommends unzip php7.2 php7.2-fpm php7.2-pgsql php7.2-curl php7.2-json php7.2-gd  php7.2-intl php7.2-gmp  php7.2-mbstring php7.2-xml php7.2-zip



## Install nginx
###  Add nginx repos 
```sh 
  sudo printf "deb http://nginx.org/packages/debian/ $( lsb_release -c | sed 's/Codename:\s\+//g') nginx\n" >> /etc/apts/sources.list.d/nginx.list 
  sudo curl http://nginx.org/keys/nginx_signing.key | sudo apt-key add - 
  sudo apt update
  sudo apt upgrade
  sudo apt dist-upgrade
  sudo apt install nginx
  curl -is http://vmbackuplnx1 | grep HTTP/
```
Latest command return HTTP/1.1 200 OK


## Download install latest version of nextcloud configure folder chmod owner 

### Download lastest version 
export downloads=/apps/downloads
sudo mkdir -p ${downloads}
cd ${downloads}
export nxtcld_archive=nextcloudlatest.zip
sudo curl -o ${nxtcld_archive} https://download.nextcloud.com/server/releases/latest.zip

### Prepare nextcloud engine and nextcloud data
export nxtcld_root_dir=/app/wifte
export nxtcld_engine_dir=${nxtcld_root_dir}
export nxtcld_data_dir=/datas/wifte
sudo mkdir -p ${nxtcld_engine_dir} 
sudo mkdir -p ${nxtcld_data_dir} 
sudo unzip ${nxtcld_archive} -d ${nxtcld_engine_dir}  
sudo chown -R www-data:www-data ${nxtcld_root_dir} 

## Create postgresql instance and wiftedb database instance on this postgresql instance
cd $PAPI_SCRIPTS_HOME 
sudo ./CreatePostgresqlInstance.sh  1 /apps/pg
sudo ./CreateDatabaseInPostgresqlInstance.sh wiftedb wiftemngr wifte*_1437 pginstusr01 9.6

## Create selft signed certificat for sysetele. 

Generate certificat  with openssl

```sh
export WIFTE_CERT_ROOT_DIR=$nxtcld_root_dir/cert/ssl
sudo kdir -p $WIFTE_CERT_ROOT_DIR
sudo openssl req -x509 -nodes -days 730 -newkey rsa:4096 -keyout $WIFTE_CERT_ROOT_DIR/wifte.key -out $WIFTE_CERT_ROOT_DIR/wifte.crt

```
Country code: FR 
State name: IDF
City: Cergy
Organization name: adipappi.net
Organization unit: SYSETELE
FQDN: wifte.adipappi.net
Email: devprg@gmail.com


### Create the nginx  configuration for nextcloud :   /app/wifte/nextcloud/nginx.conf 
```sh
 mv  /etc/nginx/conf.d/default /home/adimida/backups/nginx_default_vhost_conf.conf
 sed '36,173 !d' /app/wifte/nextcloud/core/doc/admin/_sources/installation/ngnx.txt >> /app/wifte/nextcloud/nginx.conf 
```
For our version of nextcloud the config of nginx is between  line 36 and 173. This line number must be adapted.

### Modify /app/wifte/nextcloud/nginx.conf 
Adjusting the path to ssl certificat, the root of nexcloud installation etc. 

### Modify php-fpm configuration file /etc/php/7.2/fpm/pool.d/www.conf by  listen on 127.0.0.1:9000 instead of unix local sockert 

```sh
  ;listen = /run/php/php7.2-fpm.sock
  listen = 127.0.0.1:9000
  sudo systemctl restart php7.2-fpm
  ss -pant | grep 9000
```

### Test and Validate local nginx url 
```sh
   sudo systemctl restart nginx
   curl -is http://172.16.0.4 | grep HTTP/
```

## Configure wifte (nextcloud)

Change the owner of /datas/wifte to ww w-data
   
```sh
  sudo chown -R www-data:www-data /data/wifte
  sudo systemctl restart nginx 
```

Go to url **https://172.16.0.4/index.php** and fill forms. 

Admin: wifteadmin/wifte*_1438
data folder: /datas/wifte
dbmanager: wiftemngr
dbpassword: wifte*_1437


## @todo install mattermost for slack replacement 
## @todo Explore best paper usenix portals


# INFRA HOW TO 

Create .bash_profile for adimida user containing the papi infra tools 

echo "export PAPI_SCRIPTS_HOME=/papi/scripts/infra" >> .bash_profile



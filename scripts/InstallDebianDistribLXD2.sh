#!/usr/bin/env bash
# Create on provided host a LXC instance  with 
# ipv4 and ipv6 addresses
# macvlan network 
# activate remote lxd ssh features
# customizable parameters: vm_name, vm_nic_interface name, vm_admin user, vm_admin password, 
# This cript supposed that the default bridged profile exist on the host. 
# Arguments
#   $1: the name of the lxd container to create. The name of container must be compliant to 
#	linux user name  or group name. 
#   $5: The dataset name for lxd instance (in adipappi context in installed on zpool zcaldrons)	
# Parameter implicit: host admin: adimida 
set -e
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh

# CHeck that user running this script is sudo 
isUserRootOrSudo

# #bin path ##
readonly binapt=$(which apt-get) 
readonly binsnap=$(which snap)
readonly binlxd=$(which lxd)
readonly binlxc=$(which lxc)

#Check installation of the host of lxd and snap
echo ${PAPI_INFRA_SCRIPTS}
${PAPI_INFRA_SCRIPTS}/InstallLXD.sh

## Check that vm does not exist
isCntrExists="$binlxc list| grep -Po '\s($1)\s'"

if [[ $# -ne 4 ]]; then
  printf "Usage: $0 <ContainerName> <ContainerAdminGroup> <ContainerAdmin> <ContainerAdminPassword>\n"
  printf "\tThe host sudoer user is for adipappi : adimida\n"
  exit 1
fi
vm_name="$1"
vm_admin_group="$2"
vm_admin="$3"
vm_admin_password="$4"
vm_dataset_name=$6

# Check that the vm_name vm admin and vm admin group are correct
for kv in vm_name:$1 vm_admin_group:$2 vm_admin:$3; do
       IFS=':' read -r a k a v <<<$kv
       if [[ $(isValidUsername $v) == $KO ]]; then 
	       printf "Variable $k value $v does not match the regex ([a-z_][a-z0-9_]{0,30})\n" 
		exit -1
       fi
done

## VM distro. I am using Debian ##
if [[ "${isCntrExists}" == "$vm_name" ]]; then
	printf "The container $vm_name already exists \n"
	exit 1
else
     printf "Creating container instance named:*****$1*****\n"
fi

#### Check arguments
## Global LXF FS ENV /cntr in laapi context
line=$(printf '_%.0s' {1..80})

# Configuration Parameters
## Network dns firewall proxy if they exist
local_network_firewall_ip=${DNS_SERVER_1}
local_network_firewall_hostname="${proxy_hostname}.${local_domain_name_1}"
local_dns_server=${local_network_firewall_ip}

# Network Proxy and dns servers
local_proxy_server_name=${local_network_firewall_ip}
local_proxy_server_name=${local_network_firewall_hostname}
local_proxy_server_port=${proxy_port}
proxy_server_1=${https_proxy}
dns_server=($DNS_SERVER_1 $DNS_SERVER_2 $DNS_SERVER_3)

## The host and it nnics properties
host_admin="adimida"
host_bridge_nic_name="frontbr0"
vm_primary_nic_name="enp1s0"
host_primary_nic=$(ip route show | awk '/^default/ {print $5}')

## VM distro. I am using Debian ##
vm_distro="debian/stretch/amd64"
 
# OS Debian upgrade 
export updateCommands="update upgrade dist-upgrade"
for op in $(echo $updateCommands) ; do $binapt $op -y; done
 
## Install LXD on base os with snap##
$PAPI_INFRA_SCRIPTS/InstallLXD.sh

# Add /snap/bin path to secure_path.
sed -e 's;secure_path="\(.*\)";secure_path=\1:/snap/bin;g' -i /etc/sudoers

# Add host admin into lxd group.
addgroup --system lxd
usermod -aG lxd ${host_admin}

## Disable apparmor
if [ "$(systemctl list-units | grep apparmor)" != "" ]; then
  systemctl stop apparmor*
  systemctl disable apparmor.service
fi

# Init LXD on Zcaldrons


## Correct bug lxc socket permission bg in debian 9.1 kernel 4.9
#sockectFile=/var/snap/lxd/common/lxd/unix.socket
#touch $sockectFile
#chown ${host_admin}:lxd  $sockectFile || true 
#chmod 775 $sockectFile || true

#echo "hjdhjhdjhdjhdjhjhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh"
mcvlnProfile="papi-host-profile"
$binlxc launch images:${vm_distro} ${vm_name}  

# Configure network macvlanProfile if need and apply to container
isProfileExists=$($binlxc profile list | grep -Po "($mcvlnProfile)") 
if [[ "$isProfileExists" == "" ]]; then
  $binlxc profile copy default $mcvlnProfile 
  $binlxc profile device set $mcvlnProfile $vm_primary_nic_name nictype macvlan
  $binlxc profile device set $mcvlnProfile $vm_primary_nic_name parent ${host_primary_nic}
  ## Set some consoles
  for c in console tty tty1 tty2 tty3 tty4 tty5 tty6 S0
  do  
    $binlxc profile device add $mcvlnProfile $c unix-char path=/dev/$c
  done
fi


## Assign profil to new vm
$binlxc profile assign ${vm_name} ${mcvlnProfile}

## Make sure vm boot after host reboots ##
$binlxc config set ${vm_name} boot.autostart true

# Restart lxc instance 
$binlxc restart ${vm_name}

## Set resolv.conf because httpredirect.debian url resolvng
for  srv in ${dns_server[@]}
do 
   $binlxc exec ${vm_name} -- bash -c "echo 'nameserver $srv' >> /etc/resolv.conf;" 
done 

## Add proxy to /etc/environment
for prtcl in http https
do
   $binlxc exec ${vm_name} -- bash -c "echo '${prtcl}_proxy=${proxy_server_1}' >> /etc/environment;" 
done

# Restart lxc instance 
$binlxc restart ${vm_name}

## Install updates VM  OS##
for op in update upgrade dist-upgrade; do $binlxc exec ${vm_name} -- $binapt $op -y; done
 
## Install package (optional) ##
basicLXCInstanceDatabase="sudo iproute2 iputils* rsync dnsutils ifmetric vim mlocate openssh-server lsb wget curl dstat htop software-properties-common"
$binlxc exec ${vm_name} -- $binapt install -y $basicLXCInstanceDatabase 

# add adimida with it password to adm group.
$binlxc exec ${vm_name} -- useradd -m -p $(openssl passwd -1 ${vm_admin_password}) -s /bin/bash -G adm ${vm_admin} 

# Set sudoer without password for group 
$binlxc exec ${vm_name} -- bash -c 'echo "%adm ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers' 

# Set the .bashrc of container  to use adipappi_debian_aliases
$binlxc exec ${vm_name} -- bash -c "echo 'if [ -f ~/adipappi_debian_aliases.sh ]; then source ~/adipappi_debian_aliases.sh; fi'  >> /home/${vm_admin}/.bashrc" 

# Create adipappi file systems
backupFs="/backups"
for fs in  $PAPI_INFRA_SCRIPTS $backupFs; do 
  $binlxc exec ${vm_name} -- bash -c "install  -o ${vm_admin} -g ${vm_admin_group} -m 775  -d $fs" 
done

# Set PAPI_INFRA_SCRIPTS into container
$binlxc exec ${vm_name} -- bash -c "echo 'export PAPI_INFRA_SCRIPTS=${PAPI_INFRA_SCRIPTS}' >> /home/${vm_admin}/.bashrc" 

# Activate remote lxd 
$binlxc config set core.https_address "[::]" 
$binlxc config set core.trust_password ${vm_admin_password} 

# Display vm usefull informations
vmInfos=$($binlxc list | grep ${vm_name}) 
printf "$line\nLxc instance created:${vm_name}\nInstance Admin user:${vm_admin}\nInstance Deployed on host:$(hostname)\n${vmInfos}\n$line\n"

### SET ALL LC  i,nto /etc/environment if not exist 
$binlxc exec ${vm_name} -- bash -c "echo LC_ALL=\"en_US.utf-8\" >> /etc/environment"

# Normally reboot the lxc
$binlxc restart ${vm_name}

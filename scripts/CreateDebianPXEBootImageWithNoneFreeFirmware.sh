#!/bin/bash
##########################################################################
# 
# Script actions:
#  - download the pxelinux.0 (A), kernel (B) and initrd (C) for debian current stable version
#  - add all the non free firmware to the initrd 
#  - update your tftp directory
#  - restart nfs and dnsmasq servcies
# Example of a tftp directory :
#
# Required:
#  sudo rights
#  packages :
#  - wget
#  - pax
#  - syslinux
# 
# See: 
# http://wiki.debian.org/DebianInstaller/NetbootFirmware
##########################################################################
# Script parameters to customize for your need
export dist=stretch
export version=current
export tftp_root_dir="/papi/infra/tools/pxe/tftp"
export deps="wget pax syslinux"
export LINE_SEP=$(printf '_%.0s' {1..100})

# Install dependencies
printf "${LINE_SEP}\n"
printf "Install dependencies: ${deps}\n"
sudo apt-get install -y $deps

# Download netboot.tar.gz into tftp_root_idr
archiveFile=netboot.tar.gz
archiveUrl=http://ftp.fr.debian.org/debian/dists/$dist/main/installer-amd64/$version/images/netboot/$archiveFile
cd ${tftp_root_idr} 
printf "\n${LINE_SEP}\n"
printf "Download archive from: ${archiveUrl}\n\t and extract into ${tftp_root_dir}"
wget -e robots=off -r -np  $archiveUrl
tar -xvf $archiveFile
export firmware_base_url=http://ftp.fr.debian.org/debian/pool/non-free/f/firmware-nonfree/
mkdir ./tmp
cd ./tmp

# Download all .deb files of all non-free firmware 
printf "\n${LINE_SEP}\n"
printf "Download all .deb files of all non-free firmware from ${firmware_base_url}\n" 
wget  -e robots=off -r -np --accept deb -nd ${firmware_base_url}

# Decompress .deb file extract lib file and add them into initrd.gz
initrdFile="../debian-installer/amd64/initrd.gz"
printf "\n${LINE_SEP}\n"
printf "Decrompress all lib files from .dev and add them to ${initrdFile}\n"
for deb in *.deb; do dpkg-deb -x $deb ./; done
pax -x sv4cpio -s '%lib%/lib%' -w lib | gzip -c >> $initrdFile
cd ..; rm -rf tmp; rm -rf $archiveFile

# Change right on tft_root_dir and restart services
printf "\n${LINE_SEP}\n"
printf "Change rights on ${tftp_root_dir} and restart dnsmasq and nfs-kernel-server services\n"
sudo chmod -R 755 ${tftp_root_dir}
sudo systemctl restart dnsmasq nfs-kernel-server


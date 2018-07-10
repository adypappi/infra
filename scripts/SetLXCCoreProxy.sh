#!/usr/bin/env bash 
# Set the proxy configuration for lxc core 
# Parameters: 
# mandatory
# 	$1: the url of http proxy to user
# 	$2: the url of https proxy to user
#       $3: the local lxd image server which does not need proxy
set -x
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh
#isUserRootOrSudo
# Check input parameters
if [[ $# -ne 3 ]]; then
  printf "Usage: $0 <httpProxyUrl> <httpsProxyUrl> <localImagesServerFQDN>"
  printf "Run this script after lxd init is better"
  exit -1
fi
httpProxyUrl="$1"
httpsProxyUrl="$2"
localImagesServer="$3"

# Get the path to lxc
lxcBin=$(which lxc)
$lxcBin config set core.proxy_http $httpProxyUrl
$lxcBin config set core.proxy_https $httpsProxyUrl
$lxcBin config set core.proxy_ignore_hosts $localImagesServer

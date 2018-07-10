#!/usr/bin/env bash 
# Install go lang compiler into /papi/tools/golang for current user
# user has rights to write into /papi/tools/golang folder
# Set GOROOT=/papi/tools/golang/go in ~/.profile
# Add $GOROOT/bin tp PATH in ~/.profile 
# Add GOPATH=/papi/tootls/golang/go in  ~/.bash_profile
# Add GOBIN=/papi/tootls/golang/go/bin in  ~/.bash_profile
# Parameter: go lang version number
# default architecture is amd64
# os=linux
# install dir is: /papi/tools/golang
set -e 

# Check the script argument
if [[ $# -lt 1 ]] 
then
	printf "Usage: $0 <goversionNumber>\nExample: $0 1.10.3\n"
        exit -1
fi

# default parameters
readonly  ARCH=amd64
readonly  OS=linux
readonly  INST_DIR=/papi/tools/golang

# Script arguments
readonly  GO_VERSION=$1

# Create destination directory download binary and uncompress it by overwriting existing files
mkdir -p ${INST_DIR}
cd  ${INST_DIR}
readonly  BINARIES=go${GO_VERSION}.${OS}-${ARCH}.tar.gz 
rm -rf ${BINARIES} 
curl -O https://dl.google.com/go/${BINARIES} 
sudo tar --overwrite -zxvf ${BINARIES}  

# Check GOROOT and go bin path into ~/.profile 
declare -x envFile=~/.profile
declare -x GOROOT=${INST_DIR}/go
declare -x GOROOT_BIN=${GOROOT}/bin

if !  grep -q "${GOROOT}" $envFile
then
  printf "GOROOT=$GOROOT\n" >> $envFile
else
  printf "The $envFile contains already GOROOT variable\n"
fi  
if ! grep -q "${GOROOT_BIN}" $envFile
then
  printf "PATH=\$PATH:${GOROOT_BIN}" >> $envFile
else
  printf "The $envFile contains already PATH to GOROOT/bin \n"
fi		


# Check GOPATH and GOBIN from ~/.bash_profile
envFile=~/.bash_profile
declare -x GOPATH=${GOROOT}
declare -x GOBIN=${GOPATH}/bin
declare -A VARS=([GOPATH]="$GOPATH" [GOBIN]="${GOBIN}") 

for key in ${!VARS[@]};do 
  if !  grep -q "${VARS[$key]}" $envFile
  then
    printf "$key=${VARS[$key]}\n" >> $envFile
  else
    printf "The $envFile contains already $key variable\n"
  fi  
done


#!/usr/bin/env bash
# Arguments: 
#  mandatory: $1 The version number of lua
# Depends on curl tar
if [[ $# != 1 ]]
then
  printf "Lua interpreter installer need at list lua version number:\nUsgae: $0 5.3.2"
  exit -1
fi

LUA_VERSION=$(echo -e "$1") # trim argument
rgx='^([0-9]+\.){1,2}([0-9])$'

if [[ ! ${LUA_VERSION} =~ $rgx ]]
then
  printf "The version number given for lua ${LUA_VERSION} is incorrect\nSee https://www.lua.org/versions.html "
fi

#
LUA_INSTALL_DIR="/papi/tools/lua"
mkdir -p ${LUA_INSTALL_DIR}
cd ${LUA_INSTALL_DIR}
curl -R -O http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz
tar zxf lua-${LUA_VERSION}.tar.gz
cd lua-${LUA_VERSION}
sudo make linux test
sudo make install


#!/usr/bin/env bash
# this script run a webrick server  installed by adipappi script : /papi/infra/scripts/InstallPostgresqlRubyRedminePuma.sh 
## Start webrick server with 0.0.0.0 binding + http port 8090
source /papi/infra/scripts/AdipappiUtils.sh

# Check that user is sudo
isUserRootOrSudo
webrickHttpPort=8090
rubyBin=$(find /opt -type f | grep /opt/.*/bin/ruby)
railsBin=$(find  /caldrons -type f | grep -P ".*/bin/railsi$")
echo "rail:$railsBin"
echo "ruby:$rubyBin"
$rubyBin $railsBin server webrick -b 0.0.0.0 -p 8090 -e production -d
echo $cmd

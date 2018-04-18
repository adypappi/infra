#!/usr/bin/env bash
######################################
#>CreateEnvironmentVariables.sh
# Usage: Define all usefull variables as global environment to put into /etc/environment 
# or put the entire script under /etc/profile.d/
# Auteur: A. Djiguiba <antimbedjiguiba@adipappi.net>
# Create: 18/4/2018
######################################

# Vim IS DEFAULT EDITOR IN ADIPAPPI.NET CONTEXT
export VISUAL=vim
export EDITOR="$VISUAL"

# Adipappi environment variables used by server os
export http_proxy=http://pfwprxlnx1.adipappi.int:8989
export https_proxy=http://pfwprxlnx1.adipappi.int:8989
export no_proxy='127.0.0.1,localhost,adipappi.int'

#Environment variables usefull for adipappi actions
export PAPI_HOME=/papi
export PAPI_SCRIPTS=/papi/scripts
export PAPI_INFRA=/papi/infra
export PAPI_INFRA_SCRIPTS=/papi/infra/scripts
export PAPI_SCRIPTS_LOGS_DIR=/papi/infra/scripts/logs

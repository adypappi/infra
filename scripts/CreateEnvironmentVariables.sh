#!/usr/bin/env bash
######################################
#>CreateEnvironmentVariables.sh
# Usage: Define all usefull variables as global environment to put into /etc/environment 
# or put the entire script under /etc/profile.d/
# Auteur: A. Djiguiba <antimbedjiguiba@adipappi.net>
# Create: 18/4/2018
######################################

# Adipappi environment variables used by server os
http_proxy=http://pfwprxlnx1.adipappi.int:8989
https_proxy=http://pfwprxlnx1.adipappi.int:8989
no_proxy='127.0.0.1,localhost,adipappi.int'

#Environment variables usefull for adipappi actions
PAPI_HOME=/papi
PAPI_SCRIPTS=/papi/scripts
PAPI_INFRA=/papi/infra
PAPI_INFRA_SCRIPTS=/papi/infra/scripts
PAPI_SCRIPTS_LOGS_DIR=/papi/infra/scripts/logs

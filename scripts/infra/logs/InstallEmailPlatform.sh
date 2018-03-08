#!/usr/bin/env bash
#
# Install  an instance of adipappi Email Plateform Server
# Postgresql server
# Nginx 
# Postfix
# Davecot
# MESSAGES USED IN LOGGING
SUDO_RIGHTS_MSG="This script must be run with sudo command or as root"

# Cchek the user running script has sudo rights
if [[ $UID != 0 ]]; then
  printf "${SUDO_RIGHTS_MSG}\n"
  exit 1
fi

# Define useful variables

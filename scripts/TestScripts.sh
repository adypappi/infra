#!/usr/bin/env bash
source ${PAPI_INFRA_SCRIPTS}/AdipappiUtils.sh
declare -a  pgconfigs=$(listPgInstanceGroupUser)
printf "%s\n" ${pgconfigs[@]}
createDomainSSLCertificat "/tmp/certificats/ssl"  "www.sysetele.com" "FR" "IDF" "CERGY" "sysetele" "sysetele.com"


# Run this scirpt as user adimida
newLXCInstanceIp=172.16.0.55
ssh-copy-id $newLXCInstanceIp
rsync -avhz /papi/infra/scripts/ $newLXCInstanceIp:/papi/infra/scripts/
scp /papi/infra/scripts/adipappi_debian_aliases.sh  $newLXCInstanceIp:~/

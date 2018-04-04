
# Run this scirpt as user adimida
newLXCInstanceIp=172.16.0.55
ssh-copy-id $newLXCInstanceIp
rsync -avhz /papi/scripts/infra/ $newLXCInstanceIp:/papi/scripts/infra/
scp /papi/scripts/infra/adipappi_debian_aliases.sh  $newLXCInstanceIp:~/

#! /bin/bash

shutdown_servers_fn ( )
{

while read line
do
    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

    ssh_expect $vm_name 5 "shutdown -h now"

    host_unavailible $vm_name
    sudo virsh undefine $vm_name
# No sanity check for ./tmp/hosts
done < $TMP_HOSTS_FILE_PATH

}
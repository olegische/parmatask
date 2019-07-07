#! /bin/bash

source ./lib/config_gitlab_mem_fn.sh

first_start_fn ( )
{

while read line
do

    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

# Sanity checks for error conditions
    if test -z "$vm_name"; then
        error VM name missing or empty
    elif [ ! -f "$VM_DIR_PATH/images/$vm_name.img" ]; then
        error No $vm_name img file in $VM_DIR_PATH. Try create-vm.sh
    elif [ ! -f "$VM_DIR_PATH/xmls/$vm_name.xml" ]; then
        error No $vm_name xml file in $VM_DIR_PATH. Try create-vm.sh
    elif [ ! -f "./passwd/root.$vm_name" ]; then
        error No root.$vm_name file in ./passwd directory
    fi

    sudo virsh undefine $vm_name
    sudo virsh define $VM_DIR_PATH/xmls/$vm_name.xml

    if [[ $vm_name == gitlab* ]]
    then
# Check gitlab's RAM and swap and start gitlab
        if [ $SOURCE_SWAP_SIZE -lt 4 ]; then
            if [ ! -f "$VM_DIR_PATH/images/$vm_name-swap.img" ]; then
                config_gitlab_mem_fn
            else
                sudo virsh start $vm_name
                host_availible $vm_name
                sleep 5
            fi
        else
            sudo virsh setmaxmem $vm_name $(( 1024 * $GITLAB_RAM_SIZE ))M
            sudo virsh start $vm_name
            sudo virsh setmem $vm_name $(( 1024 * $GITLAB_RAM_SIZE ))M
            sudo sh -c "virsh dumpxml $vm_name > $VM_DIR_PATH/xmls/$vm_name.xml"
            host_availible $vm_name
            sleep 5
        fi
        ssh_expect $vm_name 600 "yum update -y"
        ssh_expect $vm_name 5 reboot
        host_unavailible $vm_name
        host_availible $vm_name
        sleep 5
    else
        sudo virsh start $vm_name
        host_availible $vm_name
        sleep 5
        ssh_expect $vm_name 600 "yum update -y"
        ssh_expect $vm_name 5 reboot
        host_unavailible $vm_name
        host_availible $vm_name
        sleep 5
    fi
    unset vm_name
# No sanity check for ./tmp/hosts
done < $TMP_HOSTS_FILE_PATH

}
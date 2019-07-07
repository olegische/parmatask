#! /bin/bash

create_servers_fn ( )
{

host_file_text="# Append to systems /etc/hosts"

for vm_name in "$@"
do
    if test -z "$vm_name"; then
        error VM name missing or empty
    fi

    cp ./passwd/root.$os_type ./passwd/root.$vm_name

    sudo virsh undefine $vm_name
    sudo rm -i $VM_DIR_PATH/images/$vm_name*
    sudo rm -i $VM_DIR_PATH/xmls/$vm_name*

    sudo virsh define $VM_SOURCE_DIR_PATH/$os_type.xml
    sudo virt-clone -o $os_type -n $vm_name --file $VM_DIR_PATH/images/$vm_name.img
    sudo virsh undefine $os_type
    sudo sh -c "virsh dumpxml $vm_name > $VM_DIR_PATH/xmls/$vm_name.xml"

    sudo virsh start $vm_name
    echo Hello, enter $vm_name IP address.
    read ip

    host_file_text="$host_file_text\n$ip $vm_name"

    sudo virsh shutdown $vm_name && sudo virsh undefine $vm_name
done

echo -e "$host_file_text"
echo -e "$host_file_text\n" >> $TMP_HOSTS_FILE_PATH

}
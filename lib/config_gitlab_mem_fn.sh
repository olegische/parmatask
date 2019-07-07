#! /bin/bash

config_gitlab_mem_fn ( )
{

sudo virsh setmaxmem $vm_name $(( 1024 * $GITLAB_RAM_SIZE ))M
sudo virsh start $vm_name
sudo virsh setmem $vm_name $(( 1024 * $GITLAB_RAM_SIZE ))M
gitlab_swap_lack=$(( 4 - $SOURCE_SWAP_SIZE ))
sudo dd if=/dev/zero of=$VM_DIR_PATH/images/$vm_name-swap.img bs=1M count=$(( 1024 * $gitlab_swap_lack ))
sudo virsh attach-disk $vm_name $VM_DIR_PATH/images/$vm_name-swap.img vdb --cache none
sudo sh -c "virsh dumpxml $vm_name > $VM_DIR_PATH/xmls/$vm_name.xml"

host_availible $vm_name
sleep 5

ssh_expect $vm_name 5 "pvcreate /dev/vdb"
ssh_expect $vm_name 5 "vgextend $SWAP_VG /dev/vdb"
ssh_expect $vm_name 5 "lvextend -L +${gitlab_swap_lack}M /dev/mapper/${SWAP_VG}-${SWAP_LV}"
ssh_expect $vm_name 5 "swapoff /dev/mapper/${SWAP_VG}-${SWAP_LV}"
ssh_expect $vm_name 5 "mkswap /dev/mapper/${SWAP_VG}-${SWAP_LV}"
ssh_expect $vm_name 5 "swapon /dev/mapper/${SWAP_VG}-${SWAP_LV}"

}
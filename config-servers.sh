#! /bin/bash

# Configure servers from ready-to-use VM
#
# Usage:
# config-servers.sh [--?] [--help] [--version]

VM_DIR_PATH="/mnt/homelab/libvirt"

error( )
{
    echo "$@" 1>&2
    usage_and_exit 1
}
usage( )
{
    cat <<EOF
Before usage check dns record for servers in /etc/hosts or in zone file
Configure servers from ready-to-use VM
Usage:
    $PROGRAM [ --? ]
        [ --help ]
        [ --version ]

EOF
}

usage_and_exit( )
{
    usage
    exit $1
}
version( )
{
    echo "$PROGRAM version $VERSION"
}

host_availible( )
{
    while ! ping -q -c 1 $1
    do
        sleep 5
    done
    echo "Connected to $1 - `date`"
}

host_unavailible( )
{
    while ping -q -c 1 $1
    do
        sleep 5
    done
    echo "Disconnected from $1 - `date`"
}

ssh_expect ( )
{
    ./subscripts/ssh_expect.sh root $( cat ./passwd/root."$1") "$1" "$2" "$3"
}

scp_expect ( )
{
    ./subscripts/scp_expect.sh root $( cat ./passwd/root."$1") "$1" "$2" "$3"
}

PROGRAM=`basename $0`
VERSION=1.0

while test $# -gt 0
do
    case $1 in
    --help | --hel | --he | --h | '--?' | -help | -hel | -he | -h | '-?' )
        usage_and_exit 0
        ;;
    --version | --versio | --versi | --vers | --ver | --ve | --v | \
    -version | -versio | -versi | -vers | -ver | -ve | -v )
        version
        exit 0
        ;;
    -*)
        error "Unrecognized option: $1"
        ;;
    *)
        break
        ;;
    esac
    shift
done

expect_enter( )
{
    cat <<EOF
        set timeout 1
        spawn ssh root@$vm_name
        expect "*(yes/no)?*" {send "yes\r"}
        expect "password:" {send "$( cat ./passwd/root.$vm_name)\r"}

        expect "*]#"
        send "echo $@ >> $ans_dest_fl\r"
        expect "*]#"
        send "exit\r"
EOF
}
ans_dest_fl="/etc/hosts"

# First start servers loop
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
        if [ ! -f "$VM_DIR_PATH/images/$vm_name-swap.img" ]; then
# Increase RAM and swap for gitlab
            sudo dd if=/dev/zero of=$VM_DIR_PATH/images/$vm_name-swap.img bs=1M count=$(( 1024 * 3 ))
            sudo virsh setmaxmem $vm_name $(( 1024 * 4 ))M
            sudo virsh start $vm_name
            sudo virsh setmem $vm_name $(( 1024 * 4 ))M
            sudo virsh attach-disk $vm_name $VM_DIR_PATH/images/$vm_name-swap.img vdb --cache none ;\
            sudo sh -c "virsh dumpxml $vm_name > $VM_DIR_PATH/xmls/$vm_name.xml"

            host_availible $vm_name
            sleep 5

            ssh_expect $vm_name 5 "pvcreate /dev/vdb"

            ssh_expect $vm_name 5 "vgextend centos /dev/vdb"
            ssh_expect $vm_name 5 "lvextend -L +$(( 1024 * 3 ))M /dev/mapper/centos-swap"
            ssh_expect $vm_name 5 "swapoff /dev/mapper/centos-swap"
            ssh_expect $vm_name 5 "mkswap /dev/mapper/centos-swap"
            ssh_expect $vm_name 5 "swapon /dev/mapper/centos-swap"
        fi
        sudo virsh start $vm_name

        host_availible $vm_name
        sleep 5
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
done < "./tmp/hosts"

# Ansible server configuration loop
while read line
do
    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

    if [[ $vm_name == ansible* ]]; then
        ssh_expect $vm_name 100 "yum install -y expect"
        ssh_expect $vm_name 100 "yum install -y rsync"
        ssh_expect $vm_name 100 "yum install -y epel-release"
        ssh_expect $vm_name 3 "yum repolist | grep epel"
        ssh_expect $vm_name 3 "rpm -qa | grep ansible"
        ssh_expect $vm_name 600 "yum install -y ansible"
        ssh_expect $vm_name 3 "ansible --version"
        ssh_expect $vm_name 3 "hostnamectl set-hostname $vm_name"
        ssh_expect $vm_name 5 "ssh-keygen -f ~/.ssh/id_rsa -q -N ''"
        scp_expect $vm_name "./subscripts/ssh-copy-id_expect.sh" "/tmp"
        scp_expect $vm_name "./passwd/root.$vm_name" "/tmp"


        if [ -f "./tmp/ansible_hosts" ]; then
            rm -f "./tmp/ansible_hosts"
        fi

        while read line2
        do
            if [[ $line2 == \#* ]]; then continue; fi

# Add record about slave to Ansible's /etc/hosts
            expect -c "$( expect_enter $line2 )"

            tmp_host=$( cut -d ' ' -f2 <<< $line2 )
            if [ $tmp_host = $vm_name ]; then
                unset tmp_host
                continue
            fi
            tmp_passwd=$( cat ./passwd/root.$tmp_host)
            ssh_expect $vm_name 5 "/tmp/ssh-copy-id_expect.sh root $tmp_passwd $tmp_host"
            unset tmp_passwd

            if [[ $tmp_host == jenkins* ]]
            then
                echo '[jenkins]' >> "./tmp/ansible_hosts"
            elif [[ $tmp_host == gitlab* ]]
            then
                echo '[gitlab]' >> "./tmp/ansible_hosts"
            elif [[ $tmp_host == testbox* ]]
            then
                echo '[test]' >> "./tmp/ansible_hosts"
            fi
            echo "$tmp_host" >> "./tmp/ansible_hosts"
            unset tmp_host
        done < "./tmp/hosts"

        if [ -f "./tmp/ansible_hosts" ]; then
            cp "./tmp/ansible_hosts" "./test-ansible/hosts"
            rsync -arv --rsh="sshpass -p $( cat ./passwd/root."$vm_name") ssh -o StrictHostKeyChecking=no -l root"\
                --progress "./tmp/ansible_hosts" root@$vm_name:"/etc/ansible/hosts"
            rm -f "./tmp/ansible_hosts"
        fi
        ssh_expect $vm_name 2 "sed -i 's/#pipelining = False/pipelining = True/g' /etc/ansible/ansible.cfg"
        rsync -arv --rsh="sshpass -p $( cat ./passwd/root."$vm_name") ssh -o StrictHostKeyChecking=no -l root"\
            --progress "./ansible-srv-data/" root@$vm_name:"/etc/ansible"
    fi
# No sanity check for ./tmp/hosts
done < "./tmp/hosts"

# Shutdown servers
while read line
do
    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

    ssh_expect $vm_name 5 "shutdown -h now"

    host_unavailible $vm_name
    sudo virsh undefine $vm_name
# No sanity check for ./tmp/hosts
done < "./tmp/hosts"


exit 0
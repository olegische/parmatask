#! /bin/bash

# Start Ansible playbooks for servers
# Double check SSH connections to slaves
# Usage:
# start-ansible.sh [--?] [--help] [--version]

LIBVIRT_DIR="/mnt/homelab/libvirt"

error( )
{
    echo "$@" 1>&2
    usage_and_exit 1
}
usage( )
{
    cat <<EOF
Start Ansible playbooks for servers
Double check SSH connections to slaves
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


# Sanity checks for error conditions
# No sanity check for ./tmp/hosts
if [ ! -f "./tmp/hosts" ]; then
    error No "./tmp/hosts" file
fi

# Start Ansible playbooks
while read line
do
    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

    if [[ $vm_name != ansible* ]]; then continue; fi

    ansible_dir="/etc/ansible"

    rsync -arv --rsh="sshpass -p $( cat ./passwd/root."$vm_name") ssh -o StrictHostKeyChecking=no -l root"\
        --progress "./ansible-srv-data/" root@$vm_name:"$ansible_dir"

    ssh_expect $vm_name 10 "ansible all -m ping"

    ssh_expect $vm_name 5 "ansible-playbook $ansible_dir/common.yml --list-host"
    ssh_expect $vm_name 600 "ansible-playbook $ansible_dir/common.yml"

    ssh_expect $vm_name 5 "ansible-playbook $ansible_dir/jenkins.yml --list-host"
    ssh_expect $vm_name 1200 "ansible-playbook $ansible_dir/jenkins.yml"

    ssh_expect $vm_name 5 "ansible-playbook $ansible_dir/gitlab.yml --list-host"
    ssh_expect $vm_name 7200 "ansible-playbook $ansible_dir/gitlab.yml"

    unset vm_name
done < "./tmp/hosts"

exit 0
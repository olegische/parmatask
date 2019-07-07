#! /bin/bash

# Start Ansible playbooks for servers
# Double check SSH connections to slaves
# Usage:
# start-ansible.sh [--?] [--help] [--version]

source ./lib/support_fn.sh

source ./conf.d/task.conf

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

PROGRAM=`basename $0`
VERSION=2.0

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
if [ ! -f $TMP_HOSTS_FILE_PATH ]; then
    error No $TMP_HOSTS_FILE_PATH file
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
done < $TMP_HOSTS_FILE_PATH

exit 0
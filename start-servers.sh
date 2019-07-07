#! /bin/bash

# Start all servers
#
# Usage:
# start-servers.sh [--?] [--help] [--version]

source ./lib/support_fn.sh

source ./conf.d/task.conf

usage( )
{
    cat <<EOF
Start all servers
Usage:
    $PROGRAM [ --? ]
        [ --help ]
        [ --version ]
EOF
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
if [ ! -f $TMP_HOSTS_FILE_PATH ]; then
    error No $TMP_HOSTS_FILE_PATH file
fi

# Start servers
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
    sudo virsh start $vm_name

    host_availible $vm_name
    sleep 5
    unset vm_name
done < $TMP_HOSTS_FILE_PATH

exit 0
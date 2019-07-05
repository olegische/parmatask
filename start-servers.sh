#! /bin/bash

# Start all servers
#
# Usage:
# start-servers.sh [--?] [--help] [--version]

LIBVIRT_DIR="/mnt/homelab/libvirt"

error( )
{
    echo "$@" 1>&2
    usage_and_exit 1
}
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

# Start servers
while read line
do
    if [[ $line == \#* ]]; then continue; fi
    vm_name=$( cut -d ' ' -f2 <<< $line )

# Sanity checks for error conditions
    if test -z "$vm_name"; then
        error VM name missing or empty
    elif [ ! -f "$LIBVIRT_DIR/images/$vm_name.img" ]; then
        error No $vm_name img file in $LIBVIRT_DIR. Try create-vm.sh
    elif [ ! -f "$LIBVIRT_DIR/xmls/$vm_name.xml" ]; then
        error No $vm_name xml file in $LIBVIRT_DIR. Try create-vm.sh
    elif [ ! -f "./passwd/root.$vm_name" ]; then
        error No root.$vm_name file in ./passwd directory
    fi

    sudo virsh undefine $vm_name
    sudo virsh define $LIBVIRT_DIR/xmls/$vm_name.xml
    sudo virsh start $vm_name

    host_availible $vm_name
    sleep 5
    unset vm_name
done < "./tmp/hosts"

exit 0
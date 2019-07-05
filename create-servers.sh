#! /bin/sh

# Create multiple vm with virsh-clone from clone source
#
# Usage:
# create-servers.sh --os <OS type> [--?] [--help] [--version] VM_NAME(s)
# With the --os specify OS type (centos7.0 for now)
# Disadvantages: 
# - no IP address sanity check
# - don't take paths from arguments

# Enter your directory path with source OS image
VM_SOURCE_PATH="/mnt/sdb10/libvirt"

# Enter your directory path with destination OS image
# dirs $LIBVIRT_DIR/images and $LIBVIRT_DIR/xmls must be created
LIBVIRT_DIR="/mnt/homelab/libvirt"

error( )
{
    echo "$@" 1>&2
    usage_and_exit 1
}
usage( )
{
    cat <<EOF
Create multiple vm with virsh-clone from clone source
Usage:
    $PROGRAM [ --? ]
        [ --os <OS type> ]
        [ --help ]
        [ --version ]
        VM_NAME(s)
With the --os specify OS type (centos7.0 for now)
Disadvantages: 
- no IP address sanity check
- don't take paths from arguments
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

is_source=no
os_type=
PROGRAM=`basename $0`
VERSION=1.0

while test $# -gt 0
do
    case $1 in
    --os | --o | -os | -o )
        is_source=yes
        ;;
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

os_type=$1
test $# -gt 0 && shift

# Sanity checks for error conditions
if [ "$is_source" = "no" ]; then
    error Enter OS source. Use centos7.0
elif [ ! -f "$VM_SOURCE_PATH/$os_type.img" ]; then
    error No source $os_type img file. Use centos7.0
elif [ ! -f "$VM_SOURCE_PATH/$os_type.xml" ]; then
    error No source $os_type xml file. Use centos7.0
elif [ $# -eq 0 ]; then
    error Enter new VM name\(s\)
elif test -z "$os_type"; then
    error OS type missing or empty
elif [ ! -f "./passwd/root.$os_type" ]; then
    error No root.$os_type file in ./passwd directory
fi

host_file="# Append to systems /etc/hosts"

for vm_name in "$@"
do
    if test -z "$vm_name"; then
        error VM name missing or empty
    fi

    cp ./passwd/root.$os_type ./passwd/root.$vm_name

    sudo virsh undefine $vm_name
    sudo rm -i $LIBVIRT_DIR/images/$vm_name*
    sudo rm -i $LIBVIRT_DIR/xmls/$vm_name*

    sudo virsh define $VM_SOURCE_PATH/$os_type.xml
    sudo virt-clone -o $os_type -n $vm_name --file $LIBVIRT_DIR/images/$vm_name.img
    sudo virsh undefine $os_type
    sudo sh -c "virsh dumpxml $vm_name > $LIBVIRT_DIR/xmls/$vm_name.xml"

    sudo virsh start $vm_name
    echo Hello, enter $vm_name IP address.
    read ip

    host_file="$host_file\n$ip $vm_name"

    sudo virsh shutdown $vm_name && sudo virsh undefine $vm_name
done

echo -e "$host_file"
echo -e "$host_file\n" >> ./tmp/hosts

echo "Please, configure <vcpu> in xml file for new VMs"
echo "WARNING! Please, check ./tmp/hosts file sanity"

exit 0
#! /bin/bash

# Create multiple VMs with virsh-clone from clone source
#
# Usage:
# create-servers.sh --os <OS type> [--?] [--help] [--version] VM_NAME(s)
# With the --os specify OS type (centos7.0 for now)
# Disadvantages: 
# - no IP address sanity check

source ./lib/support_fn.sh

source ./conf.d/task.conf
source ./lib/create_servers_fn.sh

# Support functions
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
Specify OS type with --os option (centos7.0 for now)
EOF
}

is_source=no
PROGRAM=`basename $0`
VERSION=2.0

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
# Support functions end


# Sanity checks for existence of --os argument
if [ "$is_source" = "no" ]; then
    error Enter OS source. Use centos7.0
fi

os_type=$1
test $# -gt 0 && shift

if [ "$os_type" != "centos7.0" ]; then
    error Use centos7.0 source OS type
fi

# Sanity checks for error conditions
if [ ! -d $VM_SOURCE_DIR_PATH ]; then
    error No source path found. Pleace, check ./conf.d/task.conf file
elif [ ! -d $VM_DIR_PATH ]; then
    error No VM images path found. Pleace, check ./conf.d/task.conf file
elif [ ! -f "$VM_SOURCE_DIR_PATH/$os_type.img" ]; then
    error No source $os_type img file. Use centos7.0
elif [ ! -f "$VM_SOURCE_DIR_PATH/$os_type.xml" ]; then
    error No source $os_type xml file. Use centos7.0
elif [ $# -eq 0 ]; then
    error Enter new VM name\(s\)
elif test -z "$os_type"; then
    error OS type missing or empty
elif [ ! -f "./passwd/root.$os_type" ]; then
    error No root.$os_type file in ./passwd directory
fi
# Sanity checks end

for dirs in images xmls
do
    if [ ! -d $VM_DIR_PATH/$dirs ]; then
        sudo mkdir $VM_DIR_PATH/$dirs
    fi
done

create_servers_fn $@

echo "Please, configure <vcpu> in xml file for new VMs"
echo "WARNING! Please, check $TMP_HOSTS_FILE_PATH file sanity"

exit 0
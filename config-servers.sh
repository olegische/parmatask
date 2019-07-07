#! /bin/bash

# Configure servers from ready-to-use VM
#
# Usage:
# config-servers.sh [--?] [--help] [--version]

source ./lib/support_fn.sh

source ./lib/config_support_fn.sh
source ./lib/config_first_start_fn.sh
source ./lib/config_ansible_server_fn.sh
source ./lib/config_shutdown_servers_fn.sh

source ./conf.d/task.conf
source ./conf.d/config-servers.conf

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

first_start_fn

config_ansible_server_fn

shutdown_servers_fn

exit 0
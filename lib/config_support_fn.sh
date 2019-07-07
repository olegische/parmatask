#! /bin/bash

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

expect_enter_hosts( )
{
    cat <<EOF
        set timeout 1
        spawn ssh root@$vm_name
        expect "*(yes/no)?*" {send "yes\r"}
        expect "password:" {send "$( cat ./passwd/root.$vm_name)\r"}

        expect "*]#"
        send "echo $@ >> $ANS_HOSTS_PATH\r"
        expect "*]#"
        send "exit\r"
EOF
}
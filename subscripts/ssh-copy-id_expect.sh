#! /bin/bash

USER=$1 && shift
PASSWD=$1 && shift
HOST=$1 && shift

# Expect commands:
expect_enter()
{
    cat <<EOF
        spawn ssh-copy-id $USER@$HOST
        expect "*(yes/no)?*" {send "yes\r"}
        expect "password:" {send "$PASSWD\r"}
        interact
EOF
}

expect -c "$( expect_enter)"

exit 0
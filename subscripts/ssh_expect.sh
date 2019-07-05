#! /bin/bash

USER=$1 && shift
PASSWD=$1 && shift
HOST=$1 && shift
TIMEOUT=$1 && shift
SSH_CMD=$1 && shift

EXPECT_SYMBOL="$"
if [ $USER = "root" ]; then
    EXPECT_SYMBOL="#"
fi

# Expect commands:
expect_enter()
{
    cat <<EOF
        set timeout 1

        spawn ssh $USER@$HOST
        expect "*(yes/no)?*" {send "yes\r"}
        expect "password:" {send "$PASSWD\r"}

        set timeout $TIMEOUT
        expect "*]$EXPECT_SYMBOL"
        send "$@\r"
        expect "*(y/n)?*" {send "y\r"}
        expect "*]$EXPECT_SYMBOL"
        send "exit\r"
EOF
}

# One command one time
expect -c "$( expect_enter $SSH_CMD)"

exit 0
#! /bin/bash

USER=$1 && shift
PASSWD=$1 && shift
HOST=$1 && shift
SRC_FILE=$1 && shift
DEST_FILE=$1

# Expect commands:
expect_enter()
{
    cat <<EOF
        spawn scp -p -r -q $SRC_FILE $USER@$HOST:$DEST_FILE
        expect "*(yes/no)?*" {send "yes\r"}
        expect "password:" {send "$PASSWD\r"}
        interact
EOF
}

expect -c "$( expect_enter )"

exit 0
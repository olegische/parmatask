#! /bin/sh

# add new user with passwd from file ./passwd/{esername}passwd

USER_NAME=$1

if [ $# -eq 0 ]; then
    echo "No args." >&2
    exit 1
fi

if [ $# -gt 1 ]; then
    echo "Too much args." >&2
    exit 1
fi

if [ ! -f "./passwd/${USER_NAME}" ]; then
    echo "File ./passwd/${USER_NAME} not found." >&2
    exit 1
fi

sudo useradd -m -p $(openssl passwd -in ./passwd/${USER_NAME}) ${USER_NAME}
exit 0
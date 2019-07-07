#! /bin/bash

error( )
{
    echo "$@" 1>&2
    usage_and_exit 1
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
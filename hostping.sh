#!/bin/bash
# host ping scan cli
# https://github.com/robertluwang

## import common functions 

source ./util/sysmon-common.sh
source ./util/alarm-common.sh

## main loop 

unset SERVER FILE  

PING=0

usage()
{
    echo "Usage: $0 [-s localhost|server] [-f serverfile] [-p] [-h]"
    echo "-s server string, need -p for ping test"
    echo "-f server filename, cannot exist with -s at sametime; need -p for ping test"
    echo "-p ping host, need to work with -s or -f option"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":s:f:ph" opt; do
case $opt in
    s) SERVER="$OPTARG"
    if [[ -z "$SERVER" ]];then 
        echo "Cannot be empty for server"
        usage
    fi
    ;;
    f) FILE="$OPTARG"
    if [[ -z "$FILE" ]];then 
        echo "Cannot be empty for server file"
        usage
    fi
    ;;
        p) PING=1
    ;;
    h) usage
    ;;
    *) echo Invalid options
    usage
    ;; 
esac
done

## rules for options check 

if [[ $PING -eq 1 ]];then 
    if [[ -z $FILE ]] && [[ -z $SERVER ]];then
        echo "-s|-f needed for ping test"
        usage
    elif [[ -n $FILE ]] && [[ -n $SERVER ]];then
        echo "Cannot have -s and -f at sametime"
        usage
    fi
fi

## host ping scan task
if [[ $PING -eq 1 ]];then 
    if [[ -n $FILE ]];then
        host_ping "$FILE"
        exit
    else
        host_ping "$SERVER"
        exit
    fi
fi

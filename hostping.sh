#!/bin/bash
# host ping scan cli
# https://github.com/robertluwang

## import common functions 

SYSMON=`pwd`
source $SYSMON/util/sysmon-common.sh
source $SYSMON/util/sysmon-kpi.sh
source $SYSMON/util/alarm-common.sh

# disable debug and email 
DEBUG=0
EMAILYES=0

## main loop 

unset SERVER FILE  

PING=0

usage()
{
    echo "Usage: $0 [-s localhost|server] [-f serverfile] [-p] [-d] [-e emaillist] [-h]"
    echo "-s server string, need -p for ping test"
    echo "-f server filename, cannot exist with -s at sametime; need -p for ping test"
    echo "-p ping flag, need to work with -s or -f option"
    echo "-d debug flag"
    echo "-e email list, will use default list if leave as ''"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":s:f:e:pdh" opt; do
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
    d) DEBUG=1
    ;;
    e) [[ -n "$OPTARG"  ]] && EMAIL_LIST="$OPTARG"
    EMAILYES=1
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





    
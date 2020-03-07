#!/bin/bash
# local monitoring cli
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

unset KPI 
SERVER=localhost

usage()
{
    echo "Usage: $0 [-k all|kpi] [-l] [-d] [-e emaillist] [-h]"
    echo "-k kpi name, all or valid kpi name like fs, mem and cpu etc"
    echo "-l list available kpi list"
    echo "-d debug flag"
    echo "-e email list, will use default list if leave as ''"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":k:m:e:ldh" opt; do
case $opt in
    k) KPI="`upcase "$OPTARG"`"
    if [[ "$KPI" == "ALL" ]];then 
        KPI="$KPIFULL"  
    elif [[ $(belongset "$KPI" "$KPIFULL") == 0 ]];then
        echo Invalid kpi $KPI
        usage
    fi 
    ;;
    l) echo `lowcase "$KPIFULL"`
    exit
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

## system monitor task 

if [[ -n $KPI ]];then
    local_monitor
fi




    
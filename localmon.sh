#!/bin/bash
# local monitoring cli
# https://github.com/robertluwang

## import common functions 

source ./util/sysmon-common.sh
source ./util/sysmon-kpi.sh
source ./util/alarm-common.sh

## main loop 

unset KPI 
SERVER=localhost

usage()
{
    echo "Usage: $0 [-k all|kpi] [-l] [-h]"
    echo "-k kpi name, all or valid kpi name like fs, mem and cpu etc"
    echo "-l list available kpi list"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":k:m:lh" opt; do
case $opt in
    k) KPI="`upcase "$OPTARG"`"
    if [[ "$KPI" == "ALL" ]];then 
        KPI="$KPIFULL"  
    elif [[ "`validkpi "$KPI" "$KPIFULL"|tail -1`" == "Validkpi" ]];then
        :
    else
        echo Invalid kpi $KPI
        usage
    fi 
    ;;
    l) echo `lowcase "$KPIFULL"`
    exit
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




    

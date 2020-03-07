#!/bin/bash
# remote monitoring cli
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

unset SERVER FILE KPI MODE 

usage()
{
    echo "Usage: $0 [-s localhost|server] [-f serverfile] [-k all|kpi] [-m key|pass] [-d] [-e emaillist] [-l] [-h]"
    echo "-s server string, localhost need -k option; remote server need -k -m options for system monitor"
    echo "-f server filename, cannot exist with -s at sametime; need -k -m options for system monitor"
    echo "-k kpi name, all or valid kpi name like fs, mem and cpu etc"
    echo "-m access mode, ssh remote access with key or user/password"
    echo "-d debug flag"
    echo "-e email list, will use default list if leave as ''"
    echo "-l list available kpi list"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":s:f:k:m:e:ldh" opt; do
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
    k) KPI="`upcase "$OPTARG"`"
    if [[ "$KPI" == "ALL" ]];then 
        KPI="$KPIFULL"  
    elif [[ $(belongset "$KPI" "$KPIFULL") == 0 ]];then
        echo Invalid kpi $KPI
        usage
    fi 
    ;;
    m) MODE="`upcase "$OPTARG"`"
    if [[ "$MODE" == "PASS" ]] || [[ "$MODE" == "KEY" ]];then
        :
    else
        echo Invalid access mode $MODE
        usage
    fi
    ;;
    d) DEBUG=1
    ;;
    e) [[ -n "$OPTARG"  ]] && EMAIL_LIST="$OPTARG"
    EMAILYES=1
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

## rules for options check 

if [[ -n $KPI ]] && [[ -n $MODE ]];then
    if [[ -z $SERVER ]] && [[ -z $FILE ]];then
        echo "4 -s|-f needed for system monitor"
        usage
    fi
fi

if [[ -n $KPI && -z $MODE && ( -n $SERVER || -n $FILE ) ]];then
    if [[ "$SERVER" == "localhost" ]];then
        :
    else
        echo "5 -m needed for remote access"
        usage
    fi
fi

if [[ "$SERVER" == "localhost" ]];then
    if [[ -n $MODE ]];then
        echo "6 no -m needed for localhost monitor"
        usage
    elif [[ -n $FILE ]];then 
        echo "7 Cannot have -f with -s at sametime"
        usage
    elif [[ -z $KPI ]];then 
        echo "8 -k needed for localhost monitor"
        usage
    fi
fi

if [[ -z $KPI && -n $MODE && ( -n $SERVER || -n $FILE ) ]];then
    echo "9 -k needed for system monitor"
    usage
fi

if [[ -z $KPI && -z $MODE && ( -n $SERVER || -n $FILE ) ]];then
    echo "10 -k and -m needed for system monitor"
    usage
fi

if [[ -n $KPI ]];then
    if [[ "$SERVER" == "localhost" ]];then
        :
    elif [[ -z $MODE || ( -z $SERVER && -z $FILE ) ]];then
        echo "11 -m or -s|-f needed for system monitor"
        usage
    fi
fi

if [[ -n $MODE ]];then
    if [[ -z $KPI || ( -z $SERVER && -z $FILE ) ]];then
        echo "12 -k or -s|-f needed for system monitor"
        usage
    fi
fi

## system monitor task 

if [[ -n $SERVER && -z $FILE ]];then
    if [[ -n $KPI && -z $MODE ]];then
        if [[ "$SERVER" == "localhost" ]];then
            local_monitor
        fi 
    fi
fi

if [[ -n $KPI && -n $MODE && ( -n $SERVER || -n $FILE ) ]];then
    if [[ $MODE == "KEY" ]]; then
        if [[ -n $FILE ]];then
            remote_monitor_key "$FILE"
        else
            remote_monitor_key "$SERVER"
        fi
    elif [[ $MODE == "PASS" ]]; then 
        if [[ -n $FILE ]];then
            remote_monitor_pass "$FILE"
        else
            remote_monitor_pass "$SERVER"
        fi
    fi
fi



    
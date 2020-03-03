#!/bin/bash
# system monitoring solution cli
# https://github.com/robertluwang
# v1.1 kpi for FS space usage  Feb 20, 2020 
# v1.2 supports kpi loop  Feb 22, 2020 
# v1.3 add alarm, email functions  Feb 22, 2020 
# v1.4 add sqlite3 alarmdb Feb 23, 2020 
# v1.5 add getopts for cli  Feb 29, 2020
# v1.6 March 1st, 2020
# add host ping -p and -f filename
# move kpi customization to sysmon-kpi.bash 
# v1.7 move common function to sysmon-common.sh,sysmon-kpi.sh,alarm-common.sh under ./util  Mar 3rd,2020

## import common functions 

source ./util/sysmon-common.sh
source ./util/sysmon-kpi.sh
source ./util/alarm-common.sh

## main loop 

unset SERVER FILE KPI MODE 

PING=0

usage()
{
    echo "Usage: $0 [-s localhost|server] [-f serverfile] [-k all|kpi] [-m key|pass] [-p] [-l] [-h]"
    echo "-s server string, localhost need -k option; remote server need -k -m options for system monitor or need -p for ping test"
    echo "-f server filename, cannot exist with -s at sametime; need -k -m options for system monitor or need -p for ping test"
    echo "-k kpi name, all or valid kpi name like fs, mem and cpu etc"
    echo "-m access mode, ssh remote access with key or user/password"
    echo "-p ping host, need to work with -s or -f option"
    echo "-l list available kpi list"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":s:f:k:m:plh" opt; do
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
    elif [[ "`validkpi "$KPI" "$KPIFULL"|tail -1`" == "Validkpi" ]];then
        :
    else
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
    p) PING=1
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

if [[ $PING -eq 1 ]];then 
    if [[ -n $KPI || -n $MODE ]];then
        echo "1 No -k and -m needed for ping test"
        usage
    elif [[ -z $FILE ]] && [[ -z $SERVER ]];then
        echo "2 -s|-f needed for ping test"
        usage
    elif [[ -n $FILE ]] && [[ -n $SERVER ]];then
        echo "3 Cannot have -s and -f at sametime"
        usage
    fi
fi

if [[ $PING -eq 0 ]] && [[ -n $KPI ]] && [[ -n $MODE ]];then
    if [[ -z $SERVER ]] && [[ -z $FILE ]];then
        echo "4 -s|-f needed for system monitor"
        usage
    fi
fi

if [[ $PING -eq 0 && -n $KPI && -z $MODE && ( -n $SERVER || -n $FILE ) ]];then
    if [[ "$SERVER" == "localhost" ]];then
        :
    else
        echo "5 -m needed for remote access"
        usage
    fi
fi

if [[ $PING -eq 0 ]] && [[ "$SERVER" == "localhost" ]];then
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

if [[ $PING -eq 0 && -z $KPI && -n $MODE && ( -n $SERVER || -n $FILE ) ]];then
    echo "9 -k needed for system monitor"
    usage
fi

if [[ $PING -eq 0 && -z $KPI && -z $MODE && ( -n $SERVER || -n $FILE ) ]];then
    echo "10 -k and -m needed for system monitor"
    usage
fi

if [[ $PING -eq 0 && -n $KPI ]];then
    if [[ "$SERVER" == "localhost" ]];then
        :
    elif [[ -z $MODE || ( -z $SERVER && -z $FILE ) ]];then
        echo "11 -m or -s|-f needed for system monitor"
        usage
    fi
fi

if [[ $PING -eq 0 && -n $MODE ]];then
    if [[ -z $KPI || ( -z $SERVER && -z $FILE ) ]];then
        echo "12 -k or -s|-f needed for system monitor"
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

## system monitor task 

if [[ $PING -eq 0 && -n $SERVER && -z $FILE ]];then
    if [[ -n $KPI && -z $MODE ]];then
        if [[ "$SERVER" == "localhost" ]];then
            local_monitor
        fi 
    fi
fi

if [[ $PING -eq 0 && -n $KPI && -n $MODE && ( -n $SERVER || -n $FILE ) ]];then
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
















    


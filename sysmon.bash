#!/bin/bash
# system monitoring solution
# https://github.com/robertluwang
# v1.1 kpi for FS space usage  Feb 20, 2020 
# v1.2 supports kpi loop  Feb 22, 2020 
# v1.3 add alarm, email functions  Feb 22, 2020 
# v1.4 add sqlite3 alarmdb Feb 23, 2020 
# v1.5 add getopts for cli  Feb 29, 2020
# v1.6 add host ping -p and -f filename  March 1st, 2020

## common setting

source ./sysmon-kpi.sh

DEBUG=1  # 1 - keep outlog    0 - remove outlog 
readonly LOGFOLDER=`pwd`/.sysmon/outlog  # it must be at shared FS , accessable by all nodes
readonly REPFOLDER=`pwd`/.sysmon/report  # it must be at shared FS , accessable by all nodes

[ ! -d "$LOGFOLDER" ] && sudo mkdir -p $LOGFOLDER
sudo chmod 666 $LOGFOLDER

[ ! -d "$REPFOLDER" ] && sudo mkdir -p $REPFOLDER
sudo chmod 666 $REPFOLDER

# email setting
EMAILYES=0 # 1 - send email  0 - not send email 

EMAIL_LIST="demo@sysmon.com"
EMAIL_FILTER="HIGH"
readonly REPORT_TS=` date '+%m-%d-%Y-%H-%M-%S'`
EMAIL_SUB="System monitoring report - ${REPORT_TS}"
readonly REPORT=$REPFOLDER/report_${REPORT_TS}.log

# node access 
USERNAME='sysmon'
PASSWORD='sysmon'
readonly SSHKEY="~/.ssh/id_rsa"

# alarm db setting
readonly DBPATH="."
readonly ALARMDB="alarm.db"
readonly DBDUMP="alarmdb_dump.txt-$REPORT_TS"
ALARMID=1000000
readonly SQLITECONN="sqlite3 $DBPATH/$ALARMDB"

lowcase()
{
local _str
_str="$1"

echo "${_str}" | tr 'A-Z' 'a-z'
}

upcase()
{
local _str
_str="$1"

echo "${_str}" | tr 'a-z' 'A-Z'
}

validkpi()
{
local _kpi _kpifull
_kpi="$1"
_kpifull="$2"

for k in ${_kpi}
do
    if [[ ${_kpifull} != *"$k"* ]];then
        echo "Invalidkpi"
        break
    else
        echo "Validkpi"
    fi
done
}

syslocal()
{
local _cmd _kpi _ts
_cmd="$1"
_kpi="$2"
_ts="$3" 

eval ${_cmd} > $LOGFOLDER/${_kpi}_localhost_${_ts}.log
}

ssh_run_pass()
{
local _server _username _password _cmd _kpi _ts 

_server="$1"
_username="$2"
_password="$3" 
_cmd="$4"
_kpi="$5"
_ts="$6" 

expect << EOF
log_user 0
spawn sudo ssh -o StrictHostKeyChecking=no ${_username}@${_server}
expect "${_username}: "
send "${_password}\r"
expect "password: "
send "${_password}\r"
expect "$ "
send "${_cmd} > $LOGFOLDER/${_kpi}_${_server}_${_ts}.log\r"
expect "$ "
send "exit\r"
EOF
}

ssh_run_key()
{
local _server _username _key _cmd _kpi _ts 
_server="$1"
_username="$2"
_key="$3" 
_cmd="$4"
_kpi="$5"
_ts="$6"

ssh -n -i ${_key} -o StrictHostKeyChecking=no ${_username}@${_server} -C "${_cmd}" > $LOGFOLDER/${_kpi}_${_server}_${_ts}.log

}

alarm()
{
local _ts _node _kpi _severity _alarm alarmid

_ts="$1"
_node="$2"
_kpi="$3"
_severity="$4"
_alarm="$5"

echo ${_ts} " " ${_node} " " ${_kpi} " " `upcase ${_severity}` "[ " ${_alarm} " ]" 
alarmid=$(alarm_add "${_ts}" "${_node}" "${_kpi}" "`upcase ${_severity}`" "${_alarm}")
#echo new alarm $alarmid added 
}

alarm_add()
{
local _ts _node _kpi _severity _alarm alarmid sqlstr sqlresult

_ts="$1"
_node="$2"
_kpi="$3"
_severity="$4"
_alarm="$5"

if [ -f "$DBPATH"/"$ALARMDB" ];then 
    sqlstr="select id from activealarm order by id desc limit 1;"
    sqlresult=$(echo "$sqlstr" | $SQLITECONN)
    alarmid=$(echo $sqlresult + 1 | bc)
    sqlstr="insert into activealarm (id,ts,node,kpi,severity,alarm) values ($alarmid,\"${_ts}\",\"${_node}\",\"${_kpi}\",\"${_severity}\",\"${_alarm}\");"
    echo "$sqlstr" | $SQLITECONN
else
    alarmid=$(echo $ALARMID + 1|bc)
    sqlstr="create table activealarm (id INT PRIMARY KEY,ts TEXT,node TEXT,kpi TEXT,severity TEXT,alarm TEXT);\
    insert into activealarm (id,ts,node,kpi,severity,alarm) values ($alarmid,\"${_ts}\",\"${_node}\",\"${_kpi}\",\"${_severity}\",\"${_alarm}\");"
    echo "$sqlstr" | $SQLITECONN
fi

echo $alarmid

}

send_email()
{
local _subject _body _filter _list lines

_subject="$1"
_body="$2"
_filter="$3"
_list="$4"

lines=`cat ${_body} | grep "${_filter}" | wc -l | awk '{print $1}'`
[[ "$lines" -gt 0 ]] && /usr/bin/mailx -s "${_subject}" "${_list}" < ${_body} ; echo "Email already sent out to ${_list}"
}

# localhost monitor 
local_monitor()
{
TS=` date '+%m-%d-%Y-%H-%M-%S'`
for kpi in $KPI
do 
    echo >> $REPORT
    echo "`date ` - `hostname` - $kpi"  >> $REPORT
    echo >> $REPORT
    CMD_NAME=`echo CMD_$kpi`
    THRESHOLD_NAME=`echo THRESHOLD_$kpi`
    CMD=${!CMD_NAME}
    THRESHOLD=${!THRESHOLD_NAME}
    syslocal "$CMD" "`lowcase $kpi`" "$TS"
    kpi_`lowcase $kpi` "$SERVER" "$THRESHOLD" "$TS" >> $REPORT
done

echo >> $REPORT
    
[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

}

# remote monitor with ssh key
remote_monitor_key()
{
local _server node
_server="$1"

TS=` date '+%m-%d-%Y-%H-%M-%S'`
if [ -n "$FILE" ];then # node list file
    cat ${_server} | while read node;
    do
        for kpi in $KPI
        do 
            echo >> $REPORT
            echo "`date ` - $node - $kpi"  >> $REPORT
            echo >> $REPORT
            CMD_NAME=`echo CMD_$kpi`
            THRESHOLD_NAME=`echo THRESHOLD_$kpi`
            CMD=${!CMD_NAME}
            THRESHOLD=${!THRESHOLD_NAME}
            ssh_run_key "$node" "$USERNAME" "$SSHKEY" "$CMD" "`lowcase $kpi`" "$TS"
            kpi_`lowcase $kpi` "$node" "$THRESHOLD" "$TS" >> $REPORT
        done 
    done
else # node list string
    for node in ${_server}
    do
        for kpi in $KPI
        do 
            echo >> $REPORT
            echo "`date ` - $node - $kpi"  >> $REPORT
            echo >> $REPORT
            CMD_NAME=`echo CMD_$kpi`
            THRESHOLD_NAME=`echo THRESHOLD_$kpi`
            CMD=${!CMD_NAME}
            THRESHOLD=${!THRESHOLD_NAME}
            ssh_run_key "$node" "$USERNAME" "$SSHKEY" "$CMD" "`lowcase $kpi`" "$TS"
            kpi_`lowcase $kpi` "$node" "$THRESHOLD" "$TS" >> $REPORT
        done 
    done
fi

echo >> $REPORT

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

}

# remote monitor with user/pass
remote_monitor_pass()
{
local _server node
_server="$1"

TS=` date '+%m-%d-%Y-%H-%M-%S'`

if [ -n "$FILE" ];then  # node list file
    cat ${_server} | while read node;
    do
        for kpi in $KPI
        do 
            echo >> $REPORT
            echo "`date ` - $node - $kpi"  >> $REPORT
            echo >> $REPORT
            CMD_NAME=`echo CMD_$kpi`
            THRESHOLD_NAME=`echo THRESHOLD_$kpi`
            CMD=${!CMD_NAME}
            THRESHOLD=${!THRESHOLD_NAME}
            ssh_run_pass "$node" "$USERNAME" "$PASSWORD" "$CMD" "`lowcase $kpi`" "$TS"
            kpi_`lowcase $kpi` "$node" "$THRESHOLD" "$TS" >> $REPORT
        done 
    done
else # node list string
    for node in ${_server}
    do
        for kpi in $KPI
        do 
            echo >> $REPORT
            echo "`date ` - $node - $kpi"  >> $REPORT
            echo >> $REPORT
            CMD_NAME=`echo CMD_$kpi`
            THRESHOLD_NAME=`echo THRESHOLD_$kpi`
            CMD=${!CMD_NAME}
            THRESHOLD=${!THRESHOLD_NAME}
            ssh_run_pass "$node" "$USERNAME" "$PASSWORD" "$CMD" "`lowcase $kpi`" "$TS"
            kpi_`lowcase $kpi` "$node" "$THRESHOLD" "$TS" >> $REPORT
        done 
    done
fi

echo >> $REPORT

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

}

host_ping()
{
local _server node
_server="$1"

TS=` date '+%m-%d-%Y-%H-%M-%S'`

if [ -n "$FILE" ];then  # node list file
    cat ${_server} | while read node;
    do 
        ping -c 3 $node > /dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo "Server $node : down" >> $LOGFOLDER/ping_$node_$TS.log
            alarm $TS $node "ping" "high" "Server $node : down"
        else
            echo "Server $node : up" >> $LOGFOLDER/ping_$node_$TS.log
            echo $TS " " $node " ping - [ Server " $node " : up  ]" 
        fi
    done
else  # node list string
    for node in ${_server}
    do
        ping -c 3 $node > /dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo "Server $node : down" >> $LOGFOLDER/ping_$node_$TS.log
            alarm $TS $node "ping" "high" "Server $node : down"
        else
            echo "Server $node : up" >> $LOGFOLDER/ping_$node_$TS.log
            echo $TS " " $node " ping - [ Server " $node " : up  ]" 
        fi
    done
fi
}

## main loop 

unset SERVER FILE KPI MODE 

PING=0

usage()
{
    echo "Usage: $0 [-s localhost|server] [-f serverfile] [-k all|kpi] [-m key|pass] [-p] [-l] [-h]"
    echo "-s server string, localhost needs -k option; remote server needs -k -m options for system monitor or needs -p for ping test"
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


## host ping test
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

# send report by email 

echo
cat $REPORT
echo
echo The system monitoring report saved at $REPORT
echo

[[ $EMAILYES -eq 1 ]] && send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"
















    


#!/bin/bash
# system monitoring solution
# https://github.com/robertluwang
# v1.1 kpi for FS space usage  Feb 20, 2020 
# v1.2 supports kpi loop  Feb 22, 2020 
# v1.3 add alarm, email functions  Feb 22, 2020 
# v1.4 add sqlite3 alarmdb Feb 23, 2020 
# v1.5 add getopts for cli  Feb 29, 2020 

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

ssh -i ${_key} -o StrictHostKeyChecking=no ${_username}@${_server} -C "${_cmd}" > $LOGFOLDER/${_kpi}_${_server}_${_ts}.log

}

kpi_fs()
{
local _server _threshold _ts usep partition

_server="$1"
_threshold="$2"
_ts="$3"

cat $LOGFOLDER/fs_${_server}_${_ts}.log | while read output;
do
    usep=$(echo $output | awk '{ print $5}' | cut -d'%' -f1  )
    partition=$(echo $output | awk '{ print $6 }' )
    # echo $usep ${_threshold} 
    [[ $usep -ge ${_threshold} ]] && alarm ${_ts} ${_server} "fs" "high" "$output"
done

}

kpi_mem()
{
local _server _threshold _ts mem_total mem_used mem_free mem_usedp

_server="$1"
_threshold="$2"
_ts="$3"

cat $LOGFOLDER/mem_${_server}_${_ts}.log | while read output;
do
    mem_total=$(echo $output | awk '{printf("%.0f", $2/1024)}')
    mem_used=$(echo $output | awk '{printf("%.0f", $3/1024)}')
    mem_free=$(echo $output | awk '{printf("%.0f", $4/1024)}')
    mem_usedp=$(echo $output | awk '{printf("%.0f", $3*100/$2)}')
    [[ "$mem_usedp" > "${_threshold}" ]] && alarm ${_ts} ${_server} "mem" "high" "memory total: ${mem_total}GB memory used: ${mem_used}GB memory free: ${mem_free}GB memory usage: ${mem_usedp}%"
done

}

kpi_cpu()
{
local _server _threshold _ts cpu_usedp

_server="$1"
_threshold="$2"
_ts="$3"

cat $LOGFOLDER/cpu_${_server}_${_ts}.log | while read output;
do
    cpu_usedp=$(echo $output | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf ("%.0f\n", usage)}')
    [[ "$cpu_usedp" > "${_threshold}" ]] && alarm ${_ts} ${_server} "cpu" "high" "cpu usage(>${_threshold}%): ${cpu_usedp}%"
done

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

## common setting

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

# kpi common setting
KPIFULL="FS MEM CPU"
readonly CMD_FS="df -H | grep -vE '^Filesystem|tmpfs|cdrom|boot'|grep %"
readonly CMD_MEM="free -m|grep Mem"
readonly CMD_CPU="grep '^cpu ' /proc/stat"
THRESHOLD_FS=50
THRESHOLD_MEM=20
THRESHOLD_CPU=5

# alarm db setting
readonly DBPATH="."
readonly ALARMDB="alarm.db"
readonly DBDUMP="alarmdb_dump.txt-$REPORT_TS"
ALARMID=1000000
readonly SQLITECONN="sqlite3 $DBPATH/$ALARMDB"

## loop body to process kpi monitor and alarm per pki on servers 

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

remote_monitor_key()
{
local _server
_server="$1"

TS=` date '+%m-%d-%Y-%H-%M-%S'`
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

echo >> $REPORT

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

}

remote_monitor_pass()
{
local _server
_server="$1"

TS=` date '+%m-%d-%Y-%H-%M-%S'`

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

echo >> $REPORT

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

}

## main loop 

#SERVER=`cat /etc/hosts|grep localhost|grep -v ip6|awk '{print $2}'|sort`

unset SERVER KPI MODE

usage()
{
    echo "Usage: $0 -s [localhost|server] -k [all|kpi] [-m key|pass] [-l] [-h]"
    echo "-s server name, localhost needs -k option; remote server needs -k -m options"
    echo "-k kpi name, all or valid kpi name like fs, mem and cpu etc"
    echo "-m access mode, ssh remote access with key or user/password"
    echo "-l list available kpi list"
    echo "-h help"
    exit
}

if [ $# -eq 0 ]; then
    usage
fi

while getopts ":s:k:m:lh" opt; do
case $opt in
    s) SERVER="$OPTARG"
    if [[ -z "$SERVER" ]];then 
        echo Cannot be empty for server
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

if [[ -z $SERVER ]];then
    echo "-s is must option"
    usage
fi

if [[ -z $KPI ]];then
    echo "-k is must option"
    usage
fi

if [[ $SERVER != "localhost" ]] && [[ -z $MODE ]]
then
    echo "-m is must option for remote server"
    usage
fi

if [[ $SERVER == "localhost" ]] && [[ -n $MODE ]]
then
    echo "Don't need -m for localhost"
    usage
fi

if [[ $SERVER == "localhost" ]];then
    local_monitor
elif [[ $MODE == "KEY" ]]; then
    remote_monitor_key "$SERVER"
elif [[ $MODE == "PASS" ]]; then 
    remote_monitor_pass "$SERVER"
fi

# send report by email 

echo
cat $REPORT
echo
echo The system monitoring report saved at $REPORT
echo

[[ $EMAILYES -eq 1 ]] && send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"













    


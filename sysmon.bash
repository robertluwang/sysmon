#!/bin/bash
# system monitoring solution
# https://github.com/robertluwang
# v1.1 kpi for FS space usage  Feb 20, 2020 
# v1.2 supports kpi loop  Feb 22, 2020 
# v1.3 add alarm, email functions  Feb 22, 2020 
# 

lowcase()
{
local _str
_str="$1"

echo ${_str} | tr 'A-Z' 'a-z'
}

upcase()
{
local _str
_str="$1"

echo ${_str} | tr 'a-z' 'A-Z'
}

syslocal()
{
local _cmd _logfolder _kpi _ts
_cmd="$1"
_logfolder="$2"
_kpi="$3"
_ts="$4" 

eval ${_cmd} > ${_logfolder}/${_kpi}/localhost@${_ts}.log 
}

ssh_run_pass()
{
local _servers _username _password _cmd _logfolder _kpi _ts node

_servers="$1"
_username="$2"
_password="$3" 
_cmd="$4"
_logfolder="$5"
_kpi="$6"
_ts="$7" 

for node in ${_servers}
do 
    expect << EOF
log_user 0
spawn sudo ssh ${_username}@$node
expect "${_username}: "
send "${_password}\r"
expect "password: "
send "${_password}\r"
expect "$ "
send "${_cmd} > ${_logfolder}/${_kpi}/$node@${_ts}.log\r"
expect "$ "
send "exit\r"
EOF
done
}

ssh_run_key()
{
local _servers _username _key _cmd _logfolder _kpi _ts node
_servers="$1"
_username="$2"
_key="$3" 
_cmd="$4"
_logfolder="$5"
_kpi="$6"
_ts="$7"

for node in ${_servers}
do 
    ssh -i ${_key} -o StrictHostKeyChecking=no ${_username}@$node -C "${_cmd}" > ${_logfolder}/${_kpi}/$node@${_ts}.log
done
}

kpi_fs()
{
local _servers _threshold _logfolder _ts node

_servers="$1"
_threshold="$2"
_logfolder="$3"
_ts="$4"

for node in ${_servers}
do
    cat ${_logfolder}/fs/$node@${_ts}.log | while read output;
    do
        usep=$(echo $output | awk '{ print $5}' | cut -d'%' -f1  )
        partition=$(echo $output | awk '{ print $6 }' )
        # echo $usep ${_threshold} 
        #[[ $usep -ge ${_threshold} ]] && echo $node: $output
        [[ $usep -ge ${_threshold} ]] && alarm ${_ts} $node "fs" "high" "$output"
    done
done
}

kpi_mem()
{
local _servers _threshold _logfolder _ts node mem_total mem_used mem_free mem_usedp

_servers="$1"
_threshold="$2"
_logfolder="$3"
_ts="$4"

for node in ${_servers}
do
    cat ${_logfolder}/mem/$node@${_ts}.log | while read output;
    do
        mem_total=$(echo $output | awk '{printf("%.0f", $2/1024)}')
        mem_used=$(echo $output | awk '{printf("%.0f", $3/1024)}')
        mem_free=$(echo $output | awk '{printf("%.0f", $4/1024)}')
        mem_usedp=$(echo $output | awk '{printf("%.0f", $3/$2*100)}')
        [[ "$mem_usedp" > "${_threshold}" ]] && alarm ${_ts} $node "mem" "low" "memory total: ${mem_total}GB memory used: ${mem_used}GB memory free: ${mem_free}GB memory usage: ${mem_usedp}%"
    done
done
}

alarm()
{
local _ts _node _kpi _severity _alarm

_ts="$1"
_node="$2"
_kpi="$3"
_severity="$4"
_alarm="$5"

echo ${_ts} " " ${_node} " " ${_kpi} " " `upcase ${_severity}` "[ " ${_alarm} " ]" 

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

## main loop

# common setting
DEBUG=1  # 1 - keep outlog    0 - remove outlog 
LOGFOLDER=`pwd`/.sysmon/outlog

# email setting
EMAILYES=0 # 1 - send email  0 - not send email 

EMAIL_LIST="demo@gmail.com"
EMAIL_FILTER="HIGH"
REPORT_TS=` date '+%m-%d-%Y-%H-%M-%S'`
EMAIL_SUB="System monitoring report - ${REPORT_TS}"
REPORT=$LOGFOLDER/report-${REPORT_TS}.log

# node access 
USERNAME='user'
PASSWORD='pass'
SSHKEY="~/.ssh/id_rsa"

# kpi common setting
KPI="fs mem"
CMD_FS="df -H | grep -vE '^Filesystem|tmpfs|cdrom|boot'|grep %"
CMD_MEM="free -m|grep Mem"
THRESHOLD_FS=50
THRESHOLD_MEM=20

echo The system monitoring report is in progress ......

for kpi in $KPI
do 

    echo >> $REPORT
    date >> $REPORT
    echo >> $REPORT

    [ ! -d "$LOGFOLDER/$kpi" ] && sudo mkdir -p $LOGFOLDER/$kpi
    sudo chmod 666 $LOGFOLDER/$kpi

    KPIU=`upcase $kpi`
    CMD_NAME=`echo CMD_$KPIU`
    THRESHOLD_NAME=`echo THRESHOLD_$KPIU`
    CMD=${!CMD_NAME}
    THRESHOLD=${!THRESHOLD_NAME}

    # localhost
    TS=` date '+%m-%d-%Y-%H-%M-%S'`
    SERVER='localhost'
    echo >> $REPORT
    echo kpi $kpi - localhost - threshold:$THRESHOLD >> $REPORT
    echo >> $REPORT
    syslocal "$CMD" "$LOGFOLDER" "$kpi" "$TS"
    kpi_$kpi "$SERVER" "$THRESHOLD" "$LOGFOLDER" "$TS" >> $REPORT

    [[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/$kpi/*@$TS.log || echo "Please see detail log at ""$LOGFOLDER/$kpi/<node>@$TS.log" >> $REPORT

    # remote host with key
    TS=` date '+%m-%d-%Y-%H-%M-%S'`
    SERVER=`cat /etc/hosts|grep localhost|grep -v ip6|awk '{print $2}'|sort`
    echo >> $REPORT
    echo kpi $kpi - remote host with key - threshold:$THRESHOLD >> $REPORT
    echo >> $REPORT
    ssh_run_key "$SERVER" "$USERNAME" "$SSHKEY" "$CMD" "$LOGFOLDER" "$kpi" "$TS"
    kpi_$kpi "$SERVER" "$THRESHOLD" "$LOGFOLDER" "$TS" >> $REPORT

    [[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/$kpi/*@$TS.log || echo "Please see detail log at ""$LOGFOLDER/$kpi/<node>@$TS.log" >> $REPORT

    # remote host with password
    TS=` date '+%m-%d-%Y-%H-%M-%S'`
    SERVER=`cat /etc/hosts|grep localhost|grep -v ip6|awk '{print $2}'|sort`
    echo >> $REPORT
    echo kpi $kpi - remote host with password - threshold:$THRESHOLD >> $REPORT
    echo >> $REPORT
    ssh_run_pass "$SERVER" "$USERNAME" "$PASSWORD" "$CMD" "$LOGFOLDER" "$kpi" "$TS"
    kpi_$kpi "$SERVER" "$THRESHOLD" "$LOGFOLDER" "$TS" >> $REPORT

    [[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/$kpi/*@$TS.log || echo "Please see detail log at ""$LOGFOLDER/$kpi/<node>@$TS.log" >> $REPORT

done

# send report by email 

echo
cat $REPORT
echo
echo The system monitoring report saved at $REPORT
echo

[[ $EMAILYES -eq 1 ]] && send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"







    


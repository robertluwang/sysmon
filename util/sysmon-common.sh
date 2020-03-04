#!/bin/bash
# system monitoring solution common functions
# https://github.com/robertluwang

## common setting

DEBUG=0  # 1 - keep outlog    0 - remove outlog 
readonly LOGFOLDER=`pwd`/outlog  # it must be at shared FS , accessable by all nodes
readonly REPFOLDER=`pwd`/report  # it must be at shared FS , accessable by all nodes

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
readonly REPORT=$REPFOLDER/sysmon_report_${REPORT_TS}.log

# node access 
USERNAME='sysmon'
PASSWORD='sysmon'
readonly SSHKEY="~/.ssh/id_rsa"

pause(){
   read -p "$*"
}

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

belongset()
{
# check if sub set string belong to full set string
# sample: belongset "a c" "a b c d"
# return 1 if belonged; o/w 0 
local _subsetstr _fullsetstr belong
_subsetstr="$1"
_fullsetstr="$2"

belong=0

for k in ${_subsetstr}
do
    if [[ ${_fullsetstr} != *"$k"* ]];then
        belong=0
        break
    else
        belong=1
    fi
done
echo $belong
}

localsys()
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
    CMD_NAME=`echo CMD_$kpi`
    THRESHOLD_NAME=`echo THRESHOLD_$kpi`
    CMD=${!CMD_NAME}
    THRESHOLD=${!THRESHOLD_NAME}
    localsys "$CMD" "`lowcase $kpi`" "$TS"
    kpi_`lowcase $kpi` "$SERVER" "$THRESHOLD" "$TS" >> $REPORT
done

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

# send report by email 

cat $REPORT

[[ $DEBUG -eq 1 ]] && echo The system monitoring report saved at $REPORT

[[ $EMAILYES -eq 1 ]] && echo send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"

exit

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
            CMD_NAME=`echo CMD_$kpi`
            THRESHOLD_NAME=`echo THRESHOLD_$kpi`
            CMD=${!CMD_NAME}
            THRESHOLD=${!THRESHOLD_NAME}
            ssh_run_key "$node" "$USERNAME" "$SSHKEY" "$CMD" "`lowcase $kpi`" "$TS"
            kpi_`lowcase $kpi` "$node" "$THRESHOLD" "$TS" >> $REPORT
        done 
    done
fi

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

# send report by email 


cat $REPORT

[[ $DEBUG -eq 1 ]] && echo The system monitoring report saved at $REPORT

[[ $EMAILYES -eq 1 ]] && echo send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"

exit
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
            CMD_NAME=`echo CMD_$kpi`
            THRESHOLD_NAME=`echo THRESHOLD_$kpi`
            CMD=${!CMD_NAME}
            THRESHOLD=${!THRESHOLD_NAME}
            ssh_run_pass "$node" "$USERNAME" "$PASSWORD" "$CMD" "`lowcase $kpi`" "$TS"
            kpi_`lowcase $kpi` "$node" "$THRESHOLD" "$TS" >> $REPORT
        done 
    done
fi

[[ $DEBUG -ne 1 ]] && rm -f $LOGFOLDER/*_$TS.log || echo "Please see detail log at ""$LOGFOLDER/<kpi>_<node>_$TS.log" >> $REPORT

# send report by email 

cat $REPORT

[[ $DEBUG -eq 1 ]] && echo The system monitoring report saved at $REPORT

[[ $EMAILYES -eq 1 ]] && echo send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"

exit
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
            echo Server $node : down > $LOGFOLDER/ping_${node}_${TS}.log
            alarm $TS $node "ping" "high" "Server $node : down" >> $REPORT
        else
            echo Server $node : up > $LOGFOLDER/ping_${node}_${TS}.log
            echo $TS $node ping - [ Server $node : up ] >> $REPORT
        fi
    done
else  # node list string
    for node in ${_server}
    do
        ping -c 3 $node > /dev/null 2>&1
        if [[ $? -ne 0 ]];then
            echo Server $node : down > $LOGFOLDER/ping_${node}_${TS}.log
            alarm $TS $node "ping" "high" "Server $node : down" >> $REPORT
        else
            echo Server $node : up > $LOGFOLDER/ping_${node}_${TS}.log
            echo $TS $node ping - [ Server $node : up ] >> $REPORT
        fi
    done
fi

# send report by email 

cat $REPORT

[[ $DEBUG -eq 1 ]] && echo The system monitoring report saved at $REPORT

[[ $EMAILYES -eq 1 ]] && echo send_email "${EMAIL_SUB}" "$REPORT" "${EMAIL_FILTER}" "${EMAIL_LIST}"

exit
}

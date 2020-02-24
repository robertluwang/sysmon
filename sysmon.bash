#!/bin/bash
# system monitoring solution
# https://github.com/robertluwang
# v1.1 kpi for FS space usage  Feb 20, 2020 
# v1.2 supports kpi loop  Feb 22, 2020 
# 
syslocal()
{
local _cmd
local _logfolder
local _kpi
local _ts
[[ ! -z "$1" ]] && _cmd="$1"
[[ ! -z "$2" ]] && _logfolder="$2"
[[ ! -z "$3" ]] && _kpi="$3"
[[ ! -z "$4" ]] && _ts="$4" 

eval ${_cmd} > ${_logfolder}/${_kpi}/localhost@${_ts}.log 
}

ssh_run_pass()
{
local _servers
local _username
local _password
local _cmd
local _logfolder
local _kpi
local _ts

[[ ! -z "$1" ]] && _servers="$1"
[[ ! -z "$2" ]] && _username="$2"
[[ ! -z "$3" ]] && _password="$3" 
[[ ! -z "$4" ]] && _cmd="$4"
[[ ! -z "$5" ]] && _logfolder="$5"
[[ ! -z "$6" ]] && _kpi="$6"
[[ ! -z "$7" ]] && _ts="$7" 

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
local _servers
local _username
local _key
local _cmd
local _logfolder
local _kpi
local _ts

[[ ! -z "$1" ]] && _servers="$1"
[[ ! -z "$2" ]] && _username="$2"
[[ ! -z "$3" ]] && _key="$3" 
[[ ! -z "$4" ]] && _cmd="$4"
[[ ! -z "$5" ]] && _logfolder="$5"
[[ ! -z "$6" ]] && _kpi="$6"
[[ ! -z "$7" ]] && _ts="$7"

for node in ${_servers}
do 
    ssh -i /home/${_username}/.ssh/${_key} -o StrictHostKeyChecking=no ${_username}@$node -C "${_cmd}" > ${_logfolder}/${_kpi}/$node@${_ts}.log
done
}

kpi_fs()
{
local _servers
local _threshold
local _logfolder
local _ts

[[ ! -z "$1" ]] && _servers="$1"
[[ ! -z "$2" ]] && _threshold="$2"
[[ ! -z "$3" ]] && _logfolder="$3"
[[ ! -z "$4" ]] && _ts="$4"

echo
echo "Node: Size  Used Avail Use% FS"
echo
for node in ${_servers}
do
    cat ${_logfolder}/fs/$node@${_ts}.log | while read output;
    do
        usep=$(echo $output | awk '{ print $5}' | cut -d'%' -f1  )
        partition=$(echo $output | awk '{ print $6 }' )
        # echo $usep ${_threshold} 
        [[ $usep -ge ${_threshold} ]] && echo $node: $output
    done
done
}

kpi_mem()
{
local _servers
local _threshold
local _logfolder
local _ts

[[ ! -z "$1" ]] && _servers="$1"
[[ ! -z "$2" ]] && _threshold="$2"
[[ ! -z "$3" ]] && _logfolder="$3"
[[ ! -z "$4" ]] && _ts="$4"

echo
echo "Node: total  used  free  Used%"
echo
for node in ${_servers}
do
    cat ${_logfolder}/mem/$node@${_ts}.log | while read output;
    do
        mem_total=$(echo $output | awk '{ print $2}')
        mem_used=$(echo $output | awk '{ print $3}')
        mem_free=$(echo $output | awk '{ print $4}')
        mem_usedp=$(echo "scale=2;$mem_used/$mem_total*100" | bc)
        # echo $mem_usedp ${_threshold} 
        [[ "$mem_usedp" > "${_threshold}" ]] && echo $node: $mem_total $mem_used $mem_free $mem_usedp
    done
done
}

lowcase()
{
local _str
[[ ! -z "$1" ]] && _str="$1"

echo ${_str} | tr 'A-Z' 'a-z'
}

upcase()
{
local _str
[[ ! -z "$1" ]] && _str="$1"

echo ${_str} | tr 'a-z' 'A-Z'
}

## main loop

DEBUG=0  # 1 - keep outlog    0 - remove outlog 
LOGFOLDER=`pwd`/.sysmon/outlog

USERNAME='user'
PASSWORD='pass'

KPI="fs mem"
CMD_FS="df -H | grep -vE '^Filesystem|tmpfs|cdrom|boot'|grep %"
CMD_MEM="free -m|grep Mem"
THRESHOLD_FS=50
THRESHOLD_MEM=30

for kpi in $KPI
do 

    echo
    date
    echo

    [ ! -d "$LOGFOLDER/$kpi" ] && sudo mkdir -p $LOGFOLDER/$kpi
    sudo chmod 666 $LOGFOLDER/$kpi

    KPIU=`upcase $kpi`
    CMD_NAME=`echo CMD_$KPIU`
    THRESHOLD_NAME=`echo THRESHOLD_$KPIU`
    CMD=${!CMD_NAME}
    THRESHOLD=${!THRESHOLD_NAME}

    # localhost
    TS=` date '+%m%d%y%H%M%S'`
    SERVER='localhost'
    echo
    echo kpi $kpi - localhost - threshold:$THRESHOLD
    echo
    syslocal "$CMD" "$LOGFOLDER" "$kpi" "$TS"
    kpi_$kpi "$SERVER" "$THRESHOLD" "$LOGFOLDER" "$TS"

    [[ DEBUG -ne 1 ]] && rm -f $LOGFOLDER/$kpi/*@$TS.log || echo "Please see detail log at ""$LOGFOLDER/$kpi/<node>@$TS.log"

    # remote host with key
    TS=` date '+%m%d%y%H%M%S'`
    SERVER=`cat /etc/hosts|grep localhost|grep -v ip6|awk '{print $2}'|sort`
    KEY='id_rsa'
    echo
    echo kpi $kpi - remote host with key - threshold:$THRESHOLD
    echo
    ssh_run_key "$SERVER" "$USERNAME" "$KEY" "$CMD" "$LOGFOLDER" "$kpi" "$TS"
    kpi_$kpi "$SERVER" "$THRESHOLD" "$LOGFOLDER" "$TS"

    [[ DEBUG -ne 1 ]] && rm -f $LOGFOLDER/$kpi/*@$TS.log || echo "Please see detail log at ""$LOGFOLDER/$kpi/<node>@$TS.log"

    # remote host with password
    TS=` date '+%m%d%y%H%M%S'`
    SERVER=`cat /etc/hosts|grep localhost|grep -v ip6|awk '{print $2}'|sort`
    echo
    echo kpi $kpi - remote host with password - threshold:$THRESHOLD
    echo 
    ssh_run_pass "$SERVER" "$USERNAME" "$PASSWORD" "$CMD" "$LOGFOLDER" "$kpi" "$TS"
    kpi_$kpi "$SERVER" "$THRESHOLD" "$LOGFOLDER" "$TS"

    [[ DEBUG -ne 1 ]] && rm -f $LOGFOLDER/$kpi/*@$TS.log || echo "Please see detail log at ""$LOGFOLDER/$kpi/<node>@$TS.log"


done




    


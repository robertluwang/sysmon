#!/bin/bash
# sysmon common functions for alarm
# https://github.com/robertluwang

# alarm db setting
readonly DBPATH=`pwd`/db
readonly ALARMDB="alarm.db"
readonly DBDUMP="alarmdb_dump.txt-$REPORT_TS"
ALARMID=1000000
readonly SQLITECONN="sqlite3 $DBPATH/$ALARMDB"

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

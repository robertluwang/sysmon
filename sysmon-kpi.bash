#!/bin/bash
# KPI customization for sysmon
# https://github.com/robertluwang
# March 2nd, 2020 
# extend new kpi:
# KPIFULL="FS MEM CPU NEW"
# CMD_NEW="..."  kpi data collection command
# THRESHOLD_NEW=x
# kpi_new()  parsing kpi 

# kpi full list
KPIFULL="FS MEM CPU"

# kpi data collection command 
readonly CMD_FS="df -H | grep -vE '^Filesystem|tmpfs|cdrom|boot'|grep %"
readonly CMD_MEM="free -m|grep Mem"
readonly CMD_CPU="grep '^cpu ' /proc/stat"

# kpi threshold setting
THRESHOLD_FS=50
THRESHOLD_MEM=20
THRESHOLD_CPU=5

# kpi parsing function 

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
    [[ $mem_usedp -ge ${_threshold} ]] && alarm ${_ts} ${_server} "mem" "high" "memory total: ${mem_total}GB memory used: ${mem_used}GB memory free: ${mem_free}GB memory usage: ${mem_usedp}%"
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
    [[ $cpu_usedp -ge ${_threshold} ]] && alarm ${_ts} ${_server} "cpu" "high" "cpu usage(>${_threshold}%): ${cpu_usedp}%"
done

}

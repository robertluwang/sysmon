#!/bin/bash
# sysmon.sh test case

pause(){
   read -p "$*"
}

echo cli help 
./sysmon.sh 

pause 'next test ...'

echo list available kpi
./sysmon.sh -l 

pause 'next test ...'

echo ping localhost
./sysmon.sh -p -s localhost

pause 'next test ...'

echo ping remote wsl1
./sysmon.sh -p -s wsl1

pause 'next test ...'

echo ping remote servers list 
./sysmon.sh -p -s "wsl1 wsl2"

pause 'next test ...'

echo ping remote servers from nodelist file
./sysmon.sh -p -f config/nodelist

pause 'next test ...'

echo localhost monitor 
./sysmon.sh -k all -s localhost

pause 'next test ...'

echo remote monitor with key 
./sysmon.sh -k all -m key -f config/nodelist

pause 'next test ...'

echo remote monitor with pass
./sysmon.sh -k all -m pass -f config/nodelist 

pause 'next test ...'

echo turn on debug
./sysmon.sh -d -k all -m pass -f config/nodelist 

echo enable email, using default email list  
./sysmon.sh -d -e '' -k cpu -m key -s wsl2 

pause 'next test ...'

echo enable email, using new email list  
./sysmon.sh -d -e "info@sysmon.com" -k cpu -m key -s wsl2 


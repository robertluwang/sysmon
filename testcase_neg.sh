#!/bin/bash
# negative test case

pause(){
   read -p "$*"
}

echo "invalid kpi" 
./sysmon.sh -k "cpu xkpi" -m key -s wsl1

pause 'next test ...'

echo "invalid access mode"
./sysmon.sh -k cpu -m xmode -s wsl1

pause 'next test ...'

echo "1 No -k and -m needed for ping test"
./sysmon.sh -p -k cpu -m key -s localhost

pause 'next test ...'

echo "2 -s|-f needed for ping test"
./sysmon.sh -p

pause 'next test ...'

echo "3 Cannot have -s and -f at sametime"
./sysmon.sh -p -s localhost -f config/nodelist

pause 'next test ...'

echo "4 -s|-f needed for system monitor"
./sysmon.sh -k mem -m key 

pause 'next test ...'

echo "5 -m needed for remote access"
./sysmon.sh -k mem -s wsl1

pause 'next test ...'

echo "6 no -m needed for localhost monitor"
./sysmon.sh -k cpu -m key -s localhost

pause 'next test ...'

echo "7 Cannot have -f with -s at sametime"
./sysmon.sh -k cpu -m key -s localhost -f config/nodelist

pause 'next test ...'

echo "8 -k needed for localhost monitor"
./sysmon.sh -s localhost 

pause 'next test ...'

echo "9 -k needed for system monitor"
./sysmon.sh -s wsl1 -m pass 

pause 'next test ...'

echo "10 -k and -m needed for system monitor"
./sysmon.sh -s wsl1 

pause 'next test ...'

echo "11 -m or -s|-f needed for system monitor"
./sysmon.sh -k all

pause 'next test ...'

echo "12 -k or -s|-f needed for system monitor"
./sysmon.sh -m key 

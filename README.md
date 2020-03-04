# sysmon
A lightweight system monitoring solution

## Features
- implemented in bash + sqlite3
- KPI based customzation
- support local host, remote host with ssh key and remote host with user/pass
- alarm db to track history alarms 
- support cli: sysmon, localmon, remotemon, hostping

## test env
```
wsl ubuntu on win10
127.0.0.1 localhost wsl1 wsl2 
```
add wslx as remote server just for test, it enabled user/password login and ssh key

## Usages
```
/mnt/c/shared/sysmon$ ./sysmon.sh
Usage: ./sysmon.sh [-s localhost|server] [-f serverfile] [-k all|kpi] [-m key|pass] [-p] [-d] [-e emailist] [-l] [-h]
-s server string, localhost need -k option; remote server need -k -m options for system monitor or needs -p for ping test
-f server filename, cannot exist with -s at sametime; need -k -m options for system monitor or need -p for ping test
-k kpi name, all or valid kpi name like fs, mem and cpu etc
-m access mode, ssh remote access with key or user/password
-p ping flag, need to work with -s or -f option
-d debug flag
-e email list
-l list available kpi list
-h help
```

## check available kpi 
```
/mnt/c/shared/sysmon$ ./sysmon.sh -l
fs mem cpu
```
## host ping scan 
```
/shared/sysmon$./sysmon.sh -p -s localhost
03-02-2020-13-21-48   localhost  ping - [ Server  localhost  : up  ]

/shared/sysmon$ ./sysmon.sh -p -s "wsl1 wsl2"
03-02-2020-13-22-51   wsl1  ping - [ Server  wsl1  : up  ]
03-02-2020-13-22-51   wsl2  ping - [ Server  wsl2  : up  ]

/shared/sysmon$ ./sysmon.sh -p -f nodelist
03-02-2020-13-23-03   wsl1  ping - [ Server  wsl1  : up  ]
03-02-2020-13-23-03   wsl2  ping - [ Server  wsl2  : up  ]

/shared/sysmon$ ./sysmon.sh -p -s wsl3  
03-02-2020-13-29-55   wsl3   ping   HIGH [  Server wsl3 : down  ]
```
## monitor for localhost, all KPI
```
/shared/sysmon$ ./sysmon.sh -s localhost -k all
02-29-2020-18-18-05   localhost   fs   HIGH [  rootfs 511G 444G 67G 87% /  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /dev  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run/lock  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run/shm  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run/user  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  C: 511G 444G 67G 87% /mnt/c  ]
02-29-2020-18-18-05   localhost   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 18GB memory usage: 42%  ]
02-29-2020-18-18-05   localhost   cpu   HIGH [  cpu usage(>5%): 8%  ]
```

## monitor for remote server with key on selected kpi
```
/shared/sysmon$ ./sysmon.sh -s wsl -k "mem cpu" -m key
02-29-2020-18-21-57   wsl   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 18GB memory usage: 42%  ]
02-29-2020-18-21-57   wsl   cpu   HIGH [  cpu usage(>5%): 8%  ]
```

## monitor for remote server with user/pass on selected kpi 
```
/shared/sysmon$ ./sysmon.sh -s wsl -k "cpu fs" -m pass
02-29-2020-18-24-03   wsl   cpu   HIGH [  cpu usage(>5%): 8%  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  rootfs 511G 444G 67G 87% /  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /dev  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run/lock  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run/shm  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run/user  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  C: 511G 444G 67G 87% /mnt/c  ]
```
## monitor for remote server with ssh key for server list file
```
/shared/sysmon$ ./sysmon.sh -f config/nodelist -k cpu -m key
03-02-2020-13-24-58   wsl1   cpu   HIGH [  cpu usage(>5%): 8%  ]
03-02-2020-13-24-58   wsl2   cpu   HIGH [  cpu usage(>5%): 8%  ]
```
## monitor for remote server with user/pass for server list file
```
/shared/sysmon$ ./sysmon.sh -f config/nodelist -k mem -m pass
03-02-2020-13-25-20   wsl1   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 19GB memory usage: 41%  ]
03-02-2020-13-25-20   wsl2   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 19GB memory usage: 41%  ]
```
## hostping cli 
```
/shared/sysmon$ ./hostping.sh -p -s wsl2
03-03-2020-18-38-04 wsl2 ping - [ Server wsl2 : up ]

/shared/sysmon$ ./hostping.sh -p -f config/nodelist
03-03-2020-18-38-13 wsl1 ping - [ Server wsl1 : up ]
03-03-2020-18-38-13 wsl2 ping - [ Server wsl2 : up ]
```
## remotemon cli 
```
/shared/sysmon$ ./remotemon.sh -k cpu -m key -s wsl1
03-03-2020-18-42-27   wsl1   cpu   HIGH [  cpu usage(>5%): 9%  ]

/shared/sysmon$ ./remotemon.sh -k cpu -m key -f config/nodelist
03-03-2020-18-42-36   wsl1   cpu   HIGH [  cpu usage(>5%): 9%  ]
03-03-2020-18-42-36   wsl2   cpu   HIGH [  cpu usage(>5%): 9%  ]
```
## localmon cli 
```
/shared/sysmon$ ./localmon.sh -k all
03-03-2020-19-30-39   localhost   fs   HIGH [  rootfs 511G 446G 65G 88% /  ]
03-03-2020-19-30-39   localhost   fs   HIGH [  none 511G 446G 65G 88% /dev  ]
03-03-2020-19-30-39   localhost   fs   HIGH [  none 511G 446G 65G 88% /run  ]
03-03-2020-19-30-39   localhost   fs   HIGH [  none 511G 446G 65G 88% /run/lock  ]
03-03-2020-19-30-39   localhost   fs   HIGH [  none 511G 446G 65G 88% /run/shm  ]
03-03-2020-19-30-39   localhost   fs   HIGH [  none 511G 446G 65G 88% /run/user  ]
03-03-2020-19-30-39   localhost   fs   HIGH [  C: 511G 446G 65G 88% /mnt/c  ]
Tue Mar  3 19:30:40 STD 2020 - localhost - MEM
03-03-2020-19-30-39   localhost   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 18GB memory usage: 42%  ]
03-03-2020-19-30-39   localhost   cpu   HIGH [  cpu usage(>5%): 9%  ]
```

## turn on debug mode
```
/shared/sysmon$ ./sysmon.sh -d -k mem -s localhost
03-04-2020-14-38-45   localhost   mem   HIGH [  memory total: 32GB memory used: 14GB memory free: 18GB memory usage: 42%  ]
Please see detail log at /shared/sysmon/outlog/<kpi>_<node>_03-04-2020-14-38-45.log
The system monitoring report saved at /shared/sysmon/report/sysmon_report_03-04-2020-14-38-45.log
```

## enable email 
```
/shared/sysmon$ ./sysmon.sh -d -e "info@sysmon.com" -k mem -m key -s wsl2
03-04-2020-14-38-19   wsl2   mem   HIGH [  memory total: 32GB memory used: 14GB memory free: 18GB memory usage: 43%  ]
Please see detail log at /shared/sysmon/outlog/<kpi>_<node>_03-04-2020-14-38-19.log
The system monitoring report saved at /shared/sysmon/report/sysmon_report_03-04-2020-14-38-19.log
send_email System monitoring report - 03-04-2020-14-38-19 /shared/sysmon/report/sysmon_report_03-04-2020-14-38-19.log HIGH info@sysmon.com
```
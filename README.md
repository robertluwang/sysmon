# sysmon
A lightweight system monitoring solution in bash

## Features
- implemented in bash + sqlite3
- KPI based customzation
- support local host, remote host with ssh key and remote host with user/pass
- alarm db to track history alarms 
- support cli: sysmon, remotemon, hostping

## test env
```
wsl ubuntu on win10
127.0.0.1 localhost wsl1 wsl2 
```
add wslx as remote server just for test, it enabled user/password login and ssh key

## Usages
```
/mnt/c/shared/sysmon$ ./sysmon.sh
Usage: ./sysmon.sh [-s localhost|server] [-f serverfile] [-k all|kpi] [-m key|pass] [-p] [-l] [-h]
-s server string, localhost need -k option; remote server need -k -m options for system monitor or needs -p for ping test
-f server filename, cannot exist with -s at sametime; need -k -m options for system monitor or need -p for ping test
-k kpi name, all or valid kpi name like fs, mem and cpu etc
-m access mode, ssh remote access with key or user/password
-p ping host, need to work with -s or -f option
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
/mnt/c/shared/sysmon$./sysmon.sh -p -s localhost
03-02-2020-13-21-48   localhost  ping - [ Server  localhost  : up  ]

/mnt/c/shared/sysmon$ ./sysmon.sh -p -s "wsl1 wsl2"
03-02-2020-13-22-51   wsl1  ping - [ Server  wsl1  : up  ]
03-02-2020-13-22-51   wsl2  ping - [ Server  wsl2  : up  ]

/mnt/c/shared/sysmon$ ./sysmon.sh -p -f nodelist
03-02-2020-13-23-03   wsl1  ping - [ Server  wsl1  : up  ]
03-02-2020-13-23-03   wsl2  ping - [ Server  wsl2  : up  ]

/mnt/c/shared/sysmon$ ./sysmon.sh -p -s wsl3  
03-02-2020-13-29-55   wsl3   ping   HIGH [  Server wsl3 : down  ]
```
## monitor for localhost, all KPI
```
/mnt/c/shared/sysmon$ ./sysmon.sh -s localhost -k all

Sat Feb 29 18:18:05 STD 2020 - localhost - FS

02-29-2020-18-18-05   localhost   fs   HIGH [  rootfs 511G 444G 67G 87% /  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /dev  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run/lock  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run/shm  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  none 511G 444G 67G 87% /run/user  ]
02-29-2020-18-18-05   localhost   fs   HIGH [  C: 511G 444G 67G 87% /mnt/c  ]

Sat Feb 29 18:18:06 STD 2020 - localhost - MEM

02-29-2020-18-18-05   localhost   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 18GB memory usage: 42%  ]

Sat Feb 29 18:18:07 STD 2020 - localhost - CPU

02-29-2020-18-18-05   localhost   cpu   HIGH [  cpu usage(>5%): 8%  ]

Please see detail log at /mnt/c/shared/sysmon/outlog/<kpi>_<node>_02-29-2020-18-18-05.log

The system monitoring report saved at /mnt/c/shared/sysmon/report/report_02-29-2020-18-18-05.log
```

## monitor for remote server with key on selected kpi
```
/mnt/c/shared/sysmon$ ./sysmon.sh -s wsl -k "mem cpu" -m key

Sat Feb 29 18:21:57 STD 2020 - wsl - MEM

02-29-2020-18-21-57   wsl   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 18GB memory usage: 42%  ]

Sat Feb 29 18:22:00 STD 2020 - wsl - CPU

02-29-2020-18-21-57   wsl   cpu   HIGH [  cpu usage(>5%): 8%  ]

Please see detail log at /mnt/c/shared/sysmon/outlog/<kpi>_<node>_02-29-2020-18-21-57.log

The system monitoring report saved at /mnt/c/shared/sysmon/report/report_02-29-2020-18-21-57.log
```

## monitor for remote server with user/pass on selected kpi 
```
/mnt/c/shared/sysmon$ ./sysmon.sh -s wsl -k "cpu fs" -m pass

Sat Feb 29 18:24:03 STD 2020 - wsl - CPU

02-29-2020-18-24-03   wsl   cpu   HIGH [  cpu usage(>5%): 8%  ]

Sat Feb 29 18:24:06 STD 2020 - wsl - FS

02-29-2020-18-24-03   wsl   fs   HIGH [  rootfs 511G 444G 67G 87% /  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /dev  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run/lock  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run/shm  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  none 511G 444G 67G 87% /run/user  ]
02-29-2020-18-24-03   wsl   fs   HIGH [  C: 511G 444G 67G 87% /mnt/c  ]

Please see detail log at /mnt/c/shared/sysmon/outlog/<kpi>_<node>_02-29-2020-18-24-03.log

The system monitoring report saved at /mnt/c/shared/sysmon/report/report_02-29-2020-18-24-03.log
```
## monitor for remote server with ssh key for server list file
```
/mnt/c/shared/sysmon$ ./sysmon.sh -f config/nodelist -k cpu -m key

Mon Mar  2 13:24:58 STD 2020 - wsl1 - CPU

03-02-2020-13-24-58   wsl1   cpu   HIGH [  cpu usage(>5%): 8%  ]

Mon Mar  2 13:25:01 STD 2020 - wsl2 - CPU

03-02-2020-13-24-58   wsl2   cpu   HIGH [  cpu usage(>5%): 8%  ]

Please see detail log at /mnt/c/shared/sysmon/outlog/<kpi>_<node>_03-02-2020-13-24-58.log

The system monitoring report saved at /mnt/c/shared/sysmon/report/report_03-02-2020-13-24-58.log
```
## monitor for remote server with user/pass for server list file
```
/mnt/c/shared/sysmon$ ./sysmon.sh -f config/nodelist -k mem -m pass

Mon Mar  2 13:25:20 STD 2020 - wsl1 - MEM

03-02-2020-13-25-20   wsl1   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 19GB memory usage: 41%  ]

Mon Mar  2 13:25:24 STD 2020 - wsl2 - MEM

03-02-2020-13-25-20   wsl2   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 19GB memory usage: 41%  ]

Please see detail log at /mnt/c/shared/sysmon/.sysmon/outlog/<kpi>_<node>_03-02-2020-13-25-20.log

The system monitoring report saved at /mnt/c/shared/sysmon/report/report_03-02-2020-13-25-20.log
```
## hostping cli 
```
/mnt/c/shared/sysmon$ ./hostping.sh -p -s wsl2

03-03-2020-18-38-04 wsl2 ping - [ Server wsl2 : up ]

The system monitoring report saved at /mnt/c/shared/sysmon/report/sysmon_report_03-03-2020-18-38-04.log

/mnt/c/shared/sysmon$ ./hostping.sh -p -f config/nodelist

03-03-2020-18-38-13 wsl1 ping - [ Server wsl1 : up ]
03-03-2020-18-38-13 wsl2 ping - [ Server wsl2 : up ]

The system monitoring report saved at /mnt/c/shared/sysmon/report/sysmon_report_03-03-2020-18-38-13.log
```
## remotemon cli 
/mnt/c/shared/sysmon$ ./remotemon.sh -k cpu -m key -s wsl1

Tue Mar  3 18:42:27 STD 2020 - wsl1 - CPU

03-03-2020-18-42-27   wsl1   cpu   HIGH [  cpu usage(>5%): 9%  ]

Please see detail log at /mnt/c/shared/sysmon/outlog/<kpi>_<node>_03-03-2020-18-42-27.log

The system monitoring report saved at /mnt/c/shared/sysmon/report/sysmon_report_03-03-2020-18-42-27.log

/mnt/c/shared/sysmon$ ./remotemon.sh -k cpu -m key -f config/nodelist

Tue Mar  3 18:42:36 STD 2020 - wsl1 - CPU

03-03-2020-18-42-36   wsl1   cpu   HIGH [  cpu usage(>5%): 9%  ]

Tue Mar  3 18:42:38 STD 2020 - wsl2 - CPU

03-03-2020-18-42-36   wsl2   cpu   HIGH [  cpu usage(>5%): 9%  ]

Please see detail log at /mnt/c/shared/sysmon/outlog/<kpi>_<node>_03-03-2020-18-42-36.log
```

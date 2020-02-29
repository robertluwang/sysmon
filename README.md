# sysmon
A lightweight system monitoring solution in bash

## Features
- implemented in bash + sqlite3
- KPI based customzation
- support local host, remote host with ssh key and remote host with user/pass
- alarm db to track history alarms 
- support cli 

## Usages
```
/mnt/c/shared/sysmon$ ./sysmon.sh
Usage: ./sysmon.sh -s [localhost|server] -k [all|kpi] [-m key|pass] [-l] [-h]
-s server name, localhost need -k option; remote server need -k -m options
-k kpi name, all or valid kpi name like fs, mem and cpu etc
-m access mode, ssh remote access with key or user/password
-l list available kpi list
-h help
```

## check available kpi 
```
/mnt/c/shared/sysmon$ ./sysmon.sh -l
fs mem cpu
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

Please see detail log at /mnt/c/shared/sysmon/.sysmon/outlog/<kpi>_<node>_02-29-2020-18-18-05.log

The system monitoring report saved at /mnt/c/shared/sysmon/.sysmon/report/report_02-29-2020-18-18-05.log
```

## monitor for remote server with key on selected kpi
/mnt/c/shared/sysmon$ ./sysmon.sh -s wsl -k "mem cpu" -m key

Sat Feb 29 18:21:57 STD 2020 - wsl - MEM

02-29-2020-18-21-57   wsl   mem   HIGH [  memory total: 32GB memory used: 13GB memory free: 18GB memory usage: 42%  ]

Sat Feb 29 18:22:00 STD 2020 - wsl - CPU

02-29-2020-18-21-57   wsl   cpu   HIGH [  cpu usage(>5%): 8%  ]

Please see detail log at /mnt/c/shared/sysmon/.sysmon/outlog/<kpi>_<node>_02-29-2020-18-21-57.log

The system monitoring report saved at /mnt/c/shared/sysmon/.sysmon/report/report_02-29-2020-18-21-57.log

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

Please see detail log at /mnt/c/shared/sysmon/.sysmon/outlog/<kpi>_<node>_02-29-2020-18-24-03.log

The system monitoring report saved at /mnt/c/shared/sysmon/.sysmon/report/report_02-29-2020-18-24-03.log
```

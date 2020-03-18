# OraFile Script

The main purpose of this script is to get and look to files (trace, logs, dumps etc.) from an oracle instance (AWS  RDS)

Also I would like to notice that the actions  List and View currently able only on AWS RDS instances.

I have not handled any Oracle RDBMS errors. In my opinion, they are so good understandable.
## usage

```
Usage:
   orafile.rb [-h] [-v] -u username [-p password] -b database -a (List|View|Load) -d directory [-f filename] [-n number [-o (Head|Tail)]] [-s (M|A|N)] [-P path] [-t (RDS)]

Parameters:
   -h, --help       Show this help.
   -v, --version    Show the version number
   -u, --user       User name to connect to the database
   -p, --password   Password for connection to the database
   -b, --database   Connection string to the database It might a TNS alias (see tnsnames.ora)or easy connect string (//server:port/service_name)
   -d, --directory  The oracle directory (see ALL_DIRTORIES view)
   -a, --action     It might take the following values:
                 List - give the list of files from the directory
                 View - show the file content
                 Load - load file to the local disk
   -f, --file      For Load and View actions it sets the file name
   -n, --number    For List and View actions it is number of demonstrated rows
   -o, --order     For List and View actions and if number option is set it determines which number of lines to show from the beginning or the end.
                 Head - top lines (default)
                 Tail - bottom lines
   -s, --sort      For List action it specifies the sort order. It might be the following
                  M - data modification file
                  A - file name
                  N - without sort (default)
   -P, --path      For Load option  it sets the path to save loaded file
   -t, --type RDS TODO
```
## Dependencies
* Ruby 2.6
* oci8 gem
* io/console gem
* Oracle Client 12.2 and higher
### The needed DB permission
To use this script the connected to DB user (in  -u|--user parameters) has to the following permission
* Read in Directory (-d|--directory)
* Execute _rdsadmin.rds_file_util_ package (for AWS RDS instance)

## Usage cases

### Action Load

```
>ruby ./orafile.rb -u dbauser -p "derParol" -b testdb -d BDUMP -a Load -f TESTDB_ora_16387.trc
Load file TESTDB_ora_16387.trc ---- to TESTDB_ora_16387.trc

>ls
TESTDB_ora_16387.trc  orafile.rb
```

with _Path_ parameter

```
>ruby ./orafile.rb -u dbauser -p "derParol" -b testdb -d BDUMP -a Load -f TESTDB_ora_16387.trc --path ./Download
Load file TESTDB_ora_16387.trc ---- to ./Download/TESTDB_ora_16387.trc

>ls ./Download
TESTDB_ora_16387.trc
```

### Action view

View all file content
```
>ruby ./orafile.rb -u dbauser -b testdb -d BDUMP -f TESTDB_ora_897.trm -a View
Enter Password:

@3|3|X5R2HMyG2"897|TESTDB|1|1|1|1|9|
M/X5R2HMyG2~B1X2
W2kx+R2$krbmursr_osb*KRB*krbm.c*tQ1sAyX1UYQ2HMyG2~
i400+B$0yX1ZA82UG1~
!0yX1qBJMTG1~
!0yX17m5CUG1~
!0yX1h-SuUG1~

```
View the first two lines

```
>ruby ./orafile.rb -u dbauser -b testdb -d BDUMP -f TESTDB_ora_897.trm -a View -o Head -n 2
Enter Password:

@3|3|X5R2HMyG2"897|XRDS2|1|1|1|1|9|
M/X5R2HMyG2~B1X2

```

View the last line of file

```
>ruby ./orafile.rb -u dbauser -b testdb -d BDUMP -f TESTDB_ora_897.trm -a View -o Tail -n 1
Enter Password:

!0yX1h-SuUG1~

```


### Action List

List 15th first files by data modification
```
>ruby ./orafile.rb -u dbauser -p "derParol" -b testdb -d BDUMP -a list -s M --order Head --number 15

directory 782336 2020-03-18 05:40:00 +0300      trace/
directory  36864 2020-02-29 12:35:00 +0300      cdmp_20200222123424
directory  36864 2020-02-29 12:35:00 +0300      cdmp_20200222123419
directory  90112 2020-02-29 12:30:00 +0300      cdmp_20200222122849
directory  69632 2020-02-29 09:45:00 +0300      cdmp_20200222094304
directory  61440 2020-02-29 09:40:00 +0300      cdmp_20200222093845
directory  61440 2020-02-29 09:40:00 +0300      cdmp_20200222093855
directory  61440 2020-02-29 09:40:00 +0300      cdmp_20200222093904
directory  61440 2020-02-29 09:40:00 +0300      cdmp_20200222093852
file       42134 2020-03-18 05:52:44 +0300      TESTDB_mmon_17316.trm
file      387182 2020-03-18 05:52:44 +0300      TESTDB_mmon_17316.trc
file      128504 2020-03-18 05:49:54 +0300      TESTDB_tt01_17876.trc
file       29054 2020-03-18 05:49:54 +0300      alert_XRDS2.log
file       20711 2020-03-18 05:49:54 +0300      TESTDB_tt01_17876.trm
file         166 2020-03-18 01:49:52 +0300      TESTDB_ora_897.trm
```

The 10th the oldest files
```
>ruby ./orafile.rb -u dbauser -p "derParol" -b testdb -d BDUMP -a list -s M --order Tail --number 10

file  697324 2020-02-26 23:58:16 +0300  alert_TESTDB.log.2020-02-26
file  378463 2020-02-25 23:58:04 +0300  alert_TESTDB.log.2020-02-25
file  114086 2020-02-24 23:54:29 +0300  alert_TESTDB.log.2020-02-24
file  114086 2020-02-23 23:54:36 +0300  alert_TESTDB.log.2020-02-23
file  865414 2020-02-22 23:56:36 +0300  alert_TESTDB.log.2020-02-22
file 1379159 2020-02-21 23:58:04 +0300  alert_TESTDB.log.2020-02-21
file  119032 2020-02-20 23:56:54 +0300  alert_TESTDB.log.2020-02-20
file  118050 2020-02-19 23:56:46 +0300  alert_TESTDB.log.2020-02-19
file  116485 2020-02-18 23:58:04 +0300  alert_TESTDB.log.2020-02-18
file  119975 2020-02-17 23:54:30 +0300  alert_TESTDB.log.2020-02-17

```

The sort file by name

```
>ruby ./orafile.rb  -u dbauser -p "derParol" -b testdb -d DATA_PUMP_DIR -a list -s A

directory         4096 2020-03-04 14:09:19 +0300        datapump/
file      144192569344 2020-03-04 14:39:41 +0300        USER.dmp
file              9766 2017-11-12 02:21:09 +0300        USER10nov2017_IMP.log
file             21457 2017-11-11 16:37:08 +0300        USER_SUPP10nov2017_IMP.log
file             23802 2020-03-04 14:39:41 +0300        USER_exp.log

```

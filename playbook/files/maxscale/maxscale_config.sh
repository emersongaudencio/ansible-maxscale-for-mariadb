#!/bin/bash
# Parameters configuration
MX_MODE=${1}
MAXSCALE_USER=${2}
MAXSCALE_PASS=${3}
MONITOR_USER=${4}
MONITOR_PASS=${5}
PRIMARY=${6}
BACKUP=${7}

MASTER="db1-live.a"
MASTER_ADDRESS=${PRIMARY}

if [ "$PRIMARY" == "$BACKUP" ]; then
  BACKUP=""
fi

total_backup=`echo $BACKUP | wc -w`

if [ $total_backup -gt 0 ]; then
counter=$total_backup
cnt=1
echo "" > /tmp/SERVERS
while [ $counter -gt 0 ]
 do
   for SERVERS in $BACKUP; do
    SERVER_LIST_REPL="$SERVER_LIST_REPL,db$(( $cnt + 1 ))-live.a"
    echo $"[db$(( $cnt + 1 ))-live.a]
type=server
address=$SERVERS
port=3306
protocol=MariaDBBackend
" >> /tmp/SERVERS; ec=$?
    if [ $ec -ne 0 ]; then
         echo "Script execution failed - `date +"%Y-%m-%d_%T"`"
         exit 1
    else
    cnt=$(( $cnt + 1 ))
    counter=$(( $counter - 1 ))
    fi
   done;
 done;

REPLICAS_SERVERS=$(cat /tmp/SERVERS)
rm -rf /tmp/SERVERS

fi

if [ "$SERVER_LIST_REPL" == "" ]; then
  SERVER_LIST="$MASTER"
else
  SERVER_LIST="$MASTER$SERVER_LIST_REPL"
fi

echo $SERVER_LIST
echo $REPLICAS_SERVERS

if [ "$MX_MODE" == "0" ]; then

TYPE="Standby-RW-Split"
MONITOR_NAME="Standby-RW-Split-Monitor"
SERVICE_RW="[RW-Service]
servers=$SERVER_LIST
type=service
router=readwritesplit
user=$MAXSCALE_USER
password=$MAXSCALE_PASS
use_sql_variables_in=master
slave_selection_criteria=LEAST_CURRENT_OPERATIONS
max_slave_connections=100%

[RW-Listener]
type=listener
service=RW-Service
protocol=MariaDBClient
port=33306
address=0.0.0.0"

elif [[ "$MX_MODE" == "1" ]]; then

TYPE="Standby"
MONITOR_NAME="Standby-Monitor"
SERVICE_RW="[Write-Service]
servers=$SERVER_LIST
type=service
router=readconnroute
user=$MAXSCALE_USER
password=$MAXSCALE_PASS
router_options=master

[Write-Listener]
type=listener
service=Write-Service
protocol=MariaDBClient
port=33306
address=0.0.0.0"

fi

echo "### MaxScale $TYPE ###
[maxscale]
threads                     = auto
log_augmentation            = 1
log_info                    = false
ms_timestamp                = 1
admin_host                  = 0.0.0.0
admin_port                  = 8989

[db1-live.a]
type=server
address=$MASTER_ADDRESS
port=3306
protocol=MariaDBBackend

$REPLICAS_SERVERS
[$MONITOR_NAME]
type=monitor
module=mariadbmon
servers=$SERVER_LIST
events=master_down,slave_down,master_up,slave_up,new_master,new_slave
user=$MONITOR_USER
password=$MONITOR_PASS
auto_failover=true
auto_rejoin=true
monitor_interval=1000
detect_replication_lag=true
enforce_read_only_slaves=true

[RO-Service]
servers=$SERVER_LIST
type=service
router=readconnroute
user=$MAXSCALE_USER
password=$MAXSCALE_PASS
router_options=slave

[RO-Listener]
type=listener
service=RO-Service
protocol=MariaDBClient
port=33307
address=0.0.0.0

$SERVICE_RW
" > /etc/maxscale.cnf

systemctl enable maxscale
systemctl restart maxscale

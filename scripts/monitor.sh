#!/usr/bin/env bash

LOG_DIR="$HOME/techflow/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/monitor.log"

counter=1

#loop exactly 10 times 

while [ $counter -le 10 ]
do
	timestamp=$(date "+%Y-%m-%d %H:%M:%S")
	load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
	free_mem=$(free -h | awk 'NR==2 {print $5}')
	echo "[$timestamp] Load Avg: $load_avg | Free Mem: $free_mem | Disk use: $disk_usege" >> "$LOG_FILE"
	counter=$((counter + 1))
	if [ $counter -le 10 ]; then
		sleep 5
	fi
done

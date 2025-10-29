#!/usr/bin/env bash
LOGFILE="/var/log/system_report.log"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %z')

UPTIME=$(uptime -p)

PREV_TOTAL=0
PREV_IDLE=0
CPU=($(head -n1 /proc/stat))
unset CPU[0]
IDLE=${CPU[4]}
TOTAL=0
for VALUE in "${CPU[@]}"; do
  ((TOTAL+=VALUE))
done
DIFF_IDLE=$((IDLE-PREV_IDLE))
DIFF_TOTAL=$((TOTAL-PREV_TOTAL))
DIFF_USAGE=$(( (1000*(DIFF_TOTAL-DIFF_IDLE)/DIFF_TOTAL + 5)/10 ))
CPU_USAGE=$(printf "%.2f" "$DIFF_USAGE")

MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')

MEM_PERC=$(awk -v u=$MEM_USED -v t=$MEM_TOTAL 'BEGIN{printf("%.2f",(u/t)*100)}')


DISK_PERC=$(df -h / | awk 'NR==2 {print $5}')

TOP3=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 4 | tail -n 3)

{
  echo "TIMESTAMP of THE SYSTEMS"
  echo "Uptime: $UPTIME"
  echo "CPU Usage (%): $CPU_USAGE"
  echo "Memory Usage (%): $MEM_PERC"
  echo "Disk Usage (%): $DISK_PERC"
  echo "Top 3 Processes by CPU:"
  echo "$TOP3"
  echo ""
} >> "$LOGFILE"

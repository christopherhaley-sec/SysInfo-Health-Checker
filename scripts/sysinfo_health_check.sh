#!/bin/bash
# ==============================================================================
# Linux Endpoint System Health Checker
# Author: Christopher Haley
# ==============================================================================

LOG_FILE="./HealthCheck_Log.txt"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

log_message() {
    echo -e "$1"
    # Strip ANSI color codes for raw log file saving
    echo -e "$1" | sed 'r;s/\x1B\[[0-9;]*m//g' >> "$LOG_FILE"
}

echo " " >> "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"
echo " System Health Check - $TIMESTAMP" >> "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"

log_message "\e[36m==========================================\e[0m"
log_message "\e[36m   LINUX SYSTEM HEALTH DIAGNOSTIC REPORT  \e[0m"
log_message "\e[36m   Executed: $TIMESTAMP                  \e[0m"
log_message "\e[36m==========================================\e[0m"

# 1. System Info
log_message "\n\e[33m[+] SYSTEM OVERVIEW\e[0m"
log_message "  Hostname      : $(hostname)"
log_message "  OS Kernel     : $(uname -r)"
log_message "  Uptime        : $(uptime -p)"

# 2. CPU & RAM
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_FREE=$(free -m | awk '/Mem:/ {print $4}')
RAM_PERC=$(( RAM_USED * 100 / RAM_TOTAL ))

log_message "\n\e[33m[+] HARDWARE RESOURCE UTILIZATION\e[0m"
log_message "  RAM Usage     : ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERC}%)"
log_message "  CPU Load Avg  : $(uptime | awk -F'load average:' '{ print $2 }')"

# 3. Disk Usage
log_message "\n\e[33m[+] DISK STORAGE\e[0m"
df -h --output=source,target,fstype,size,avail,pcent -x tmpfs -x devtmpfs | while read line; do
    log_message "  $line"
done

# 4. Network Info
log_message "\n\e[33m[+] NETWORK CONFIGURATION\e[0m"
IP_ADDR=$(hostname -I | awk '{print $1}')
log_message "  Primary IP    : ${IP_ADDR:-No IP Assigned}"

# 5. Essential Systemd Services
log_message "\n\e[33m[+] CRITICAL SERVICES CHECK\e[0m"
SERVICES=("sshd" "cron" "ufw" "NetworkManager")

for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        log_message "  Service: $svc -> \e[32m[RUNNING]\e[0m"
    else
        log_message "  Service: $svc -> \e[31m[INACTIVE / NOT FOUND]\e[0m"
    fi
done

log_message "\n\e[36m==========================================\e[0m"
log_message "\e[32m Diagnostic log updated at: $LOG_FILE\e[0m"
log_message "\e[36m==========================================\e[0m"

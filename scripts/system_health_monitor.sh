#!/usr/bin/env bash
#
# system_health_monitor.sh
#
# Monitors CPU, memory, disk usage, and running process count on a Linux
# system. Logs an alert to console and a log file if any metric exceeds
# its threshold.
#
# Usage: ./system_health_monitor.sh

set -euo pipefail

LOGFILE="/var/log/system_health_monitor.log"
CPU_THRESHOLD=80      # percent
MEM_THRESHOLD=80       # percent
DISK_THRESHOLD=80      # percent
PROCESS_THRESHOLD=500  # number of running processes

timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_alert() {
  local message="$1"
  local line="[$(timestamp)] ALERT: $message"
  echo "$line"
  # Fall back to a local file if we don't have permission to write to /var/log
  if ! echo "$line" >> "$LOGFILE" 2>/dev/null; then
    echo "$line" >> "./system_health_monitor.log"
  fi
}

check_cpu() {
  # Average CPU usage over 1 second, using /proc/stat deltas.
  read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
  local total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
  local idle1=$idle
  sleep 1
  read -r cpu user nice system idle iowait irq softirq steal _ < /proc/stat
  local total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
  local idle2=$idle

  local total_delta=$((total2 - total1))
  local idle_delta=$((idle2 - idle1))
  local cpu_usage=$(( (100 * (total_delta - idle_delta)) / total_delta ))

  echo "CPU Usage: ${cpu_usage}%"
  if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
    log_alert "CPU usage is at ${cpu_usage}%, exceeding threshold of ${CPU_THRESHOLD}%"
  fi
}

check_memory() {
  local mem_total mem_available mem_usage
  mem_total=$(grep -i '^MemTotal' /proc/meminfo | awk '{print $2}')
  mem_available=$(grep -i '^MemAvailable' /proc/meminfo | awk '{print $2}')
  mem_usage=$(( 100 * (mem_total - mem_available) / mem_total ))

  echo "Memory Usage: ${mem_usage}%"
  if [ "$mem_usage" -gt "$MEM_THRESHOLD" ]; then
    log_alert "Memory usage is at ${mem_usage}%, exceeding threshold of ${MEM_THRESHOLD}%"
  fi
}

check_disk() {
  # Check root filesystem usage.
  local disk_usage
  disk_usage=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

  echo "Disk Usage (/): ${disk_usage}%"
  if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
    log_alert "Disk usage on / is at ${disk_usage}%, exceeding threshold of ${DISK_THRESHOLD}%"
  fi
}

check_processes() {
  local process_count
  process_count=$(ps -e | wc -l)

  echo "Running Processes: ${process_count}"
  if [ "$process_count" -gt "$PROCESS_THRESHOLD" ]; then
    log_alert "Running process count is ${process_count}, exceeding threshold of ${PROCESS_THRESHOLD}"
  fi
}

main() {
  echo "=== System Health Check: $(timestamp) ==="
  check_cpu
  check_memory
  check_disk
  check_processes
  echo "=== Check complete ==="
}

main

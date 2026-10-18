
#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$HOME/projects/server-health-monitor"
CONFIG_FILE="$PROJECT_DIR/config/monitor.conf"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/health_monitor.log"

mkdir -p "$LOG_DIR"
source "$CONFIG_FILE"

log() {
    local level="$1"
    shift
    printf '[%s] [%-8s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$level" "$*" | tee -a "$LOG_FILE"
}

check_threshold() {
    local name="$1"
    local value="$2"
    local warning="$3"
    local critical="$4"

    if (( value >= critical )); then
        log "CRITICAL" "$name usage is ${value}% (threshold: ${critical}%)"
    elif (( value >= warning )); then
        log "WARNING" "$name usage is ${value}% (threshold: ${warning}%)"
    else
        log "OK" "$name usage is ${value}%"
    fi
}

log "INFO" "========== Health Check Started =========="

# CPU usage (sampled over one second)
read -r cpu user nice system idle iowait irq softirq steal rest \
    < /proc/stat
idle_before=$((idle + iowait))
total_before=$((user + nice + system + idle + iowait + irq + softirq + steal))

sleep 1

read -r cpu user nice system idle iowait irq softirq steal rest \
    < /proc/stat
idle_after=$((idle + iowait))
total_after=$((user + nice + system + idle + iowait + irq + softirq + steal))

total_delta=$((total_after - total_before))
idle_delta=$((idle_after - idle_before))

if (( total_delta > 0 )); then
    cpu_usage=$(( (total_delta - idle_delta) * 100 / total_delta ))
    check_threshold "CPU" "$cpu_usage" "$CPU_WARNING" "$CPU_CRITICAL"
else
    log "WARNING" "Unable to calculate CPU usage"
fi

# Memory usage
mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
memory_usage=$(( (mem_total - mem_available) * 100 / mem_total ))
check_threshold "Memory" "$memory_usage" "$MEMORY_WARNING" "$MEMORY_CRITICAL"

# Root filesystem usage
disk_usage=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')
check_threshold "Root disk" "$disk_usage" "$DISK_WARNING" "$DISK_CRITICAL"

# TCP port checks
for port in $MONITOR_PORTS; do
    if ss -H -lnt "sport = :$port" | grep -q .; then
        log "OK" "TCP port $port is LISTENING"
    else
        log "WARNING" "TCP port $port is NOT LISTENING"
    fi
done

log "INFO" "========== Health Check Completed =========="

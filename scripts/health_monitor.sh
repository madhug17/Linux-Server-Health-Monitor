
#!/usr/bin/env bash
set -Eeuo pipefail

# Project configuration
PROJECT_DIR="$HOME/projects/server-health-monitor"
CONFIG_FILE="$PROJECT_DIR/config/monitor.conf"
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/health_monitor.log"

mkdir -p "$LOG_DIR"

# Load configuration
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE" >&2
    exit 1
fi

source "$CONFIG_FILE"

# Logging function
log() {
    local level="$1"
    shift

    printf '[%s] [%-8s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$level" "$*" | tee -a "$LOG_FILE"
}

# Email alert function
send_alert() {
    local subject="$1"
    local body="$2"

    if [[ "${EMAIL_ALERTS:-false}" != "true" ]]; then
        return 0
    fi

    if [[ -z "${ALERT_EMAIL:-}" ]]; then
        log "ERROR" "ALERT_EMAIL is not configured"
        return 1
    fi

    if ! command -v mail >/dev/null 2>&1; then
        log "ERROR" "mail command is not installed"
        return 1
    fi

    if printf '%s\n' "$body" | mail -s "$subject" "$ALERT_EMAIL"; then
        log "INFO" "Alert email submitted to $ALERT_EMAIL"
    else
        log "ERROR" "Failed to submit alert email"
        return 1
    fi
}

# Load threshold checking function
THRESHOLD_FILE="$PROJECT_DIR/scripts/thresholds.sh"

if [[ ! -f "$THRESHOLD_FILE" ]]; then
    log "ERROR" "Threshold script not found: $THRESHOLD_FILE"
    exit 1
fi

source "$THRESHOLD_FILE"

log "INFO" "========== Health Check Started =========="
log "INFO" "Host: $(hostname)"

# CPU usage: compare two samples one second apart
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

if (( mem_total > 0 )); then
    memory_usage=$(( (mem_total - mem_available) * 100 / mem_total ))
    check_threshold "Memory" "$memory_usage" "$MEMORY_WARNING" "$MEMORY_CRITICAL"
else
    log "WARNING" "Unable to calculate memory usage"
fi

# Root filesystem usage
disk_usage=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

if [[ "$disk_usage" =~ ^[0-9]+$ ]]; then
    check_threshold "Root disk" "$disk_usage" "$DISK_WARNING" "$DISK_CRITICAL"
else
    log "WARNING" "Unable to calculate root disk usage"
fi

# TCP port monitoring
for port in ${MONITOR_PORTS:-}; do
    if ss -H -lnt "sport = :$port" | grep -q .; then
        log "OK" "TCP port $port is LISTENING"
    else
        log "WARNING" "TCP port $port is NOT LISTENING"
    fi
done

log "INFO" "========== Health Check Completed =========="

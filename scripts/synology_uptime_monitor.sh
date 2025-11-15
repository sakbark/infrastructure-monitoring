#!/bin/bash
###############################################################################
# Synology DSM Uptime Monitor with Metrics
# Sends comprehensive system metrics to Uptime.com heartbeat endpoint
###############################################################################

set -e

# Configuration
HEARTBEAT_URL=""  # Will be configured after deployment
LOG_FILE="/tmp/uptime_monitor.log"
METRICS_FILE="/tmp/synology_metrics.json"
MAX_LOG_SIZE=512000  # 500KB

# Logging function
log_message() {
  local LEVEL="$1"
  local MESSAGE="$2"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" >> "$LOG_FILE"

  # Rotate log if too large
  if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
    if [ "$LOG_SIZE" -gt "$MAX_LOG_SIZE" ]; then
      tail -500 "$LOG_FILE" > "${LOG_FILE}.tmp"
      mv "${LOG_FILE}.tmp" "$LOG_FILE"
      log_message "INFO" "Log rotated (was ${LOG_SIZE} bytes)"
    fi
  fi
}

log_message "INFO" "=== Starting Synology monitoring cycle ==="

###############################################################################
# System Information
###############################################################################

HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
KERNEL=$(uname -r 2>/dev/null || echo "unknown")
UPTIME_DAYS=$(awk '{print int($1/86400)}' /proc/uptime 2>/dev/null || echo 0)

log_message "INFO" "System: $HOSTNAME, Kernel: $KERNEL, Uptime: ${UPTIME_DAYS}d"

###############################################################################
# CPU Metrics
###############################################################################

CPU_COUNT=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 1)

# CPU usage from /proc/stat
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | sed 's/%id,//' | awk '{print int($1)}' 2>/dev/null || echo 95)
if [ -n "$CPU_IDLE" ] && [ "$CPU_IDLE" -ge 0 ] 2>/dev/null; then
    CPU_USAGE=$((100 - CPU_IDLE))
else
    CPU_USAGE=0
fi

# CPU load
CPU_LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' 2>/dev/null || echo "0.00")

log_message "INFO" "CPU: ${CPU_COUNT} cores, ${CPU_USAGE}% usage, load: ${CPU_LOAD_1MIN}"

###############################################################################
# Memory Metrics
###############################################################################

MEM_TOTAL_MB=$(free -m | grep Mem: | awk '{print $2}' 2>/dev/null || echo 0)
MEM_USED_MB=$(free -m | grep Mem: | awk '{print $3}' 2>/dev/null || echo 0)
MEM_FREE_MB=$(free -m | grep Mem: | awk '{print $4}' 2>/dev/null || echo 0)

if [ "$MEM_TOTAL_MB" -gt 0 ]; then
    MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($MEM_USED_MB / $MEM_TOTAL_MB) * 100}")
else
    MEM_PERCENT=0
fi

log_message "INFO" "Memory: ${MEM_USED_MB}MB used / ${MEM_TOTAL_MB}MB total (${MEM_PERCENT}%)"

###############################################################################
# Disk Metrics
###############################################################################

# Primary volume
DISK_USAGE=$(df -h /volume7 2>/dev/null | tail -1 | awk '{print $5}' | sed 's/%//' || echo 0)
DISK_SIZE=$(df -h /volume7 2>/dev/null | tail -1 | awk '{print $2}' || echo "0")
DISK_USED=$(df -h /volume7 2>/dev/null | tail -1 | awk '{print $3}' || echo "0")
DISK_FREE=$(df -h /volume7 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")

log_message "INFO" "Disk (/volume7): ${DISK_USED} used / ${DISK_SIZE} total (${DISK_USAGE}%)"

###############################################################################
# Network Metrics
###############################################################################

# Get primary network interface (eth0 or bond0 for Synology)
NET_IFACE=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \K\S+' || echo "eth0")

# Network traffic
if [ -f "/sys/class/net/$NET_IFACE/statistics/rx_bytes" ]; then
    NET_RX_BYTES=$(cat /sys/class/net/$NET_IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
    NET_TX_BYTES=$(cat /sys/class/net/$NET_IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
    NET_RX_MB=$(awk "BEGIN {printf \"%.2f\", $NET_RX_BYTES / 1048576}")
    NET_TX_MB=$(awk "BEGIN {printf \"%.2f\", $NET_TX_BYTES / 1048576}")
else
    NET_RX_MB="0.00"
    NET_TX_MB="0.00"
fi

log_message "INFO" "Network ($NET_IFACE): RX ${NET_RX_MB}MB, TX ${NET_TX_MB}MB"

###############################################################################
# WAN Connectivity Check
###############################################################################

WAN_STATUS="unknown"
WAN_STATE_UP="false"
RESPONSE_TIME="1.0"
WAN_LATENCY_MS="0"
PUBLIC_IP="unknown"

# Use curl for WAN check (ping requires elevated privileges on Synology)
START_TIME=$(date +%s%3N)
PUBLIC_IP=$(curl -s --max-time 5 https://api.ipify.org 2>/dev/null)
END_TIME=$(date +%s%3N)

if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "unknown" ]; then
    WAN_STATUS="up"
    WAN_STATE_UP="true"

    # Calculate response time in seconds
    ELAPSED_MS=$((END_TIME - START_TIME))
    if [ "$ELAPSED_MS" -gt 0 ]; then
        RESPONSE_TIME=$(awk "BEGIN {printf \"%.4f\", $ELAPSED_MS / 1000}")
        WAN_LATENCY_MS="$ELAPSED_MS"
    else
        RESPONSE_TIME="0.050"
        WAN_LATENCY_MS="50"
    fi

    # Test DNS resolution as secondary check
    if nslookup google.com >/dev/null 2>&1; then
        DNS_STATUS="ok"
    else
        DNS_STATUS="failed"
    fi
else
    WAN_STATUS="down"
    WAN_STATE_UP="false"
    RESPONSE_TIME="1.0"
    WAN_LATENCY_MS="0"
    PUBLIC_IP="unknown"
    DNS_STATUS="failed"
fi

log_message "INFO" "WAN: $WAN_STATUS, latency: ${RESPONSE_TIME}s (${WAN_LATENCY_MS}ms), DNS: $DNS_STATUS, public IP: $PUBLIC_IP"

###############################################################################
# Temperature
###############################################################################

# Try to get CPU temperature (varies by Synology model)
TEMP_C=$(sensors 2>/dev/null | grep -i "core 0" | awk '{print $3}' | sed 's/+//;s/°C//' || echo "0")
if [ -z "$TEMP_C" ] || [ "$TEMP_C" = "0" ]; then
    # Alternative method for DSM
    TEMP_C=$(cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -1 | awk '{print int($1/1000)}' || echo "0")
fi

log_message "INFO" "Temperature: ${TEMP_C}°C"

###############################################################################
# Tailscale Status (if available)
###############################################################################

TAILSCALE_IP="unknown"
TAILSCALE_STATUS="unknown"

# Try to find tailscale binary
TAILSCALE_BIN=$(which tailscale 2>/dev/null || echo "")
if [ -z "$TAILSCALE_BIN" ]; then
    # Try common Synology package locations
    for path in /var/packages/Tailscale/target/bin/tailscale /usr/local/bin/tailscale; do
        if [ -f "$path" ]; then
            TAILSCALE_BIN="$path"
            break
        fi
    done
fi

if [ -n "$TAILSCALE_BIN" ] && [ -f "$TAILSCALE_BIN" ]; then
    TAILSCALE_IP=$($TAILSCALE_BIN ip -4 2>/dev/null || echo "unknown")
    TAILSCALE_STATUS=$($TAILSCALE_BIN status --json 2>/dev/null | grep -oP '"BackendState":"\K[^"]+' || echo "unknown")
    log_message "INFO" "Tailscale: $TAILSCALE_STATUS, IP: $TAILSCALE_IP"
else
    log_message "WARN" "Tailscale binary not found"
fi

###############################################################################
# Build JSON Metrics
###############################################################################

cat > "$METRICS_FILE" <<EOFMETRICS
{
  "device": "Synology-NAS",
  "hostname": "$HOSTNAME",
  "location": "Home",
  "kernel": "$KERNEL",
  "uptime_days": $UPTIME_DAYS,
  "cpu": {
    "count": $CPU_COUNT,
    "usage_percent": $CPU_USAGE,
    "load_1min": $CPU_LOAD_1MIN
  },
  "memory": {
    "total_mb": $MEM_TOTAL_MB,
    "used_mb": $MEM_USED_MB,
    "free_mb": $MEM_FREE_MB,
    "usage_percent": $MEM_PERCENT
  },
  "disk": {
    "volume": "/volume7",
    "size": "$DISK_SIZE",
    "used": "$DISK_USED",
    "free": "$DISK_FREE",
    "usage_percent": $DISK_USAGE
  },
  "network": {
    "interface": "$NET_IFACE",
    "rx_mb": $NET_RX_MB,
    "tx_mb": $NET_TX_MB
  },
  "wan": {
    "status": "$WAN_STATUS",
    "up": $WAN_STATE_UP,
    "latency_ms": "$WAN_LATENCY_MS",
    "dns_status": "$DNS_STATUS",
    "public_ip": "$PUBLIC_IP"
  },
  "tailscale": {
    "status": "$TAILSCALE_STATUS",
    "ip": "$TAILSCALE_IP"
  },
  "temperature_c": "$TEMP_C",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOFMETRICS

log_message "INFO" "Metrics file created: $METRICS_FILE"

###############################################################################
# Send Heartbeat to Uptime.com
###############################################################################

send_to_uptime_heartbeat() {
  if [ -z "$HEARTBEAT_URL" ]; then
    log_message "WARN" "Heartbeat URL not configured - skipping"
    return 1
  fi

  HTTP_CODE=$(curl -X POST "$HEARTBEAT_URL" \
    -H "Content-Type: application/json" \
    -d "{\"response_time\": $RESPONSE_TIME}" \
    --max-time 10 \
    -s -o /dev/null -w "%{http_code}")

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
    log_message "INFO" "Heartbeat sent successfully (HTTP $HTTP_CODE) - response_time: ${RESPONSE_TIME}s"
    return 0
  else
    log_message "ERROR" "Heartbeat failed (HTTP $HTTP_CODE)"
    return 1
  fi
}

# Send heartbeat
if [ -n "$HEARTBEAT_URL" ]; then
    send_to_uptime_heartbeat
else
    log_message "WARN" "Heartbeat URL not configured yet - run configure_heartbeat.sh first"
fi

log_message "INFO" "=== Monitoring cycle completed ===
"

exit 0

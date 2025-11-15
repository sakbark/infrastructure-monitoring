#!/bin/sh
################################################################################
# GL-MT6000 Router Monitoring Script for Uptime.com
# Location: /root/router_uptime_monitor.sh on router
#
# This script collects extensive router metrics and pushes to uptime.com
# Supports both Heartbeat and Incoming Webhook check types
#
# Setup Instructions:
# 1. Create a Heartbeat check in uptime.com dashboard:
#    - Login to uptime.com → Monitoring → Checks → Add New
#    - Select "Heartbeat" from Check Type dropdown
#    - Set interval to 2 minutes
#    - Save and copy the Heartbeat URL
# 2. Update HEARTBEAT_URL below with your unique URL
# 3. Optional: Create an Incoming Webhook for richer metrics
# 4. Deploy to router and set up cron job
################################################################################

# CONFIGURATION - Update these values
HEARTBEAT_URL="https://uptime.com/api/v1/checks/XXXXX/heartbeat"
WEBHOOK_URL=""  # Optional: for state_is_up + response_time
UPTIME_API_KEY="78c0730a9c1c200ecddadf965c1a357483b06ca4"

# Router identification
ROUTER_NAME="GL-MT6000-Office"
ROUTER_LOCATION="89 Shepperton Road"

# Logging
LOG_FILE="/tmp/uptime_monitor.log"
METRICS_FILE="/tmp/router_metrics.json"
MAX_LOG_LINES=200

################################################################################
# METRIC COLLECTION FUNCTIONS
################################################################################

collect_system_metrics() {
  # System uptime
  UPTIME_SECS=$(awk '{print int($1)}' /proc/uptime)
  UPTIME_DAYS=$((UPTIME_SECS / 86400))

  # Hostname
  HOSTNAME=$(cat /proc/sys/kernel/hostname)

  # Kernel version
  KERNEL=$(uname -r)
}

collect_cpu_metrics() {
  # Load averages
  read LOAD_1MIN LOAD_5MIN LOAD_15MIN REST < /proc/loadavg

  # CPU usage from top
  CPU_IDLE=$(top -bn1 | grep "CPU:" | awk '{print $8}' | sed 's/%//')
  if [ -n "$CPU_IDLE" ]; then
    CPU_USAGE=$((100 - CPU_IDLE))
  else
    CPU_USAGE=0
  fi

  # CPU count
  CPU_COUNT=$(grep -c ^processor /proc/cpuinfo)
}

collect_memory_metrics() {
  # All values in KB
  MEM_TOTAL=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  MEM_FREE=$(awk '/MemFree/ {print $2}' /proc/meminfo)
  MEM_AVAILABLE=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  MEM_BUFFERS=$(awk '/Buffers/ {print $2}' /proc/meminfo)
  MEM_CACHED=$(awk '/^Cached/ {print $2}' /proc/meminfo)

  # Calculate used memory
  MEM_USED=$((MEM_TOTAL - MEM_FREE - MEM_BUFFERS - MEM_CACHED))

  # Percentage
  if [ "$MEM_TOTAL" -gt 0 ]; then
    MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))
  else
    MEM_PERCENT=0
  fi

  # Convert to MB for readability
  MEM_TOTAL_MB=$((MEM_TOTAL / 1024))
  MEM_USED_MB=$((MEM_USED / 1024))
  MEM_FREE_MB=$((MEM_FREE / 1024))
}

collect_network_metrics() {
  # WAN interface stats (try multiple interface names)
  for iface in wan eth1 eth0; do
    if [ -d "/sys/class/net/$iface" ]; then
      WAN_IFACE=$iface
      RX_BYTES=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
      TX_BYTES=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0)
      RX_PACKETS=$(cat /sys/class/net/$iface/statistics/rx_packets 2>/dev/null || echo 0)
      TX_PACKETS=$(cat /sys/class/net/$iface/statistics/tx_packets 2>/dev/null || echo 0)
      RX_ERRORS=$(cat /sys/class/net/$iface/statistics/rx_errors 2>/dev/null || echo 0)
      TX_ERRORS=$(cat /sys/class/net/$iface/statistics/tx_errors 2>/dev/null || echo 0)
      RX_DROPPED=$(cat /sys/class/net/$iface/statistics/rx_dropped 2>/dev/null || echo 0)
      TX_DROPPED=$(cat /sys/class/net/$iface/statistics/tx_dropped 2>/dev/null || echo 0)
      break
    fi
  done

  # Convert bytes to MB
  RX_MB=$((RX_BYTES / 1048576))
  TX_MB=$((TX_BYTES / 1048576))

  # Get WAN IP address
  WAN_IP=$(ip -4 addr show $WAN_IFACE 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)
  [ -z "$WAN_IP" ] && WAN_IP="N/A"

  # Get public IP (cached for 5 minutes to avoid rate limits)
  PUBLIC_IP_CACHE="/tmp/public_ip_cache"
  if [ ! -f "$PUBLIC_IP_CACHE" ] || [ $(($(date +%s) - $(stat -c %Y "$PUBLIC_IP_CACHE" 2>/dev/null || echo 0))) -gt 300 ]; then
    PUBLIC_IP=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null || echo "N/A")
    echo "$PUBLIC_IP" > "$PUBLIC_IP_CACHE"
  else
    PUBLIC_IP=$(cat "$PUBLIC_IP_CACHE")
  fi
}

collect_wan_metrics() {
  # Test WAN connectivity with ping to Google DNS
  if ping -c 2 -W 3 8.8.8.8 > /tmp/ping_result.txt 2>&1; then
    WAN_STATUS="up"
    WAN_STATE_UP="true"

    # Extract latency stats
    WAN_LATENCY_AVG=$(grep "avg" /tmp/ping_result.txt | awk -F'/' '{print $5}')
    WAN_LATENCY_MIN=$(grep "avg" /tmp/ping_result.txt | awk -F'/' '{print $4}')
    WAN_LATENCY_MAX=$(grep "avg" /tmp/ping_result.txt | awk -F'/' '{print $6}')

    # Packet loss
    WAN_PACKET_LOSS=$(grep "packet loss" /tmp/ping_result.txt | awk -F',' '{print $3}' | awk '{print $1}')

    # Use average latency for response_time (in seconds)
    if [ -n "$WAN_LATENCY_AVG" ]; then
      RESPONSE_TIME=$(echo "scale=4; $WAN_LATENCY_AVG / 1000" | bc 2>/dev/null || echo "0.001")
    else
      RESPONSE_TIME="0.001"
    fi
  else
    WAN_STATUS="down"
    WAN_STATE_UP="false"
    WAN_LATENCY_AVG="999"
    WAN_LATENCY_MIN="999"
    WAN_LATENCY_MAX="999"
    WAN_PACKET_LOSS="100%"
    RESPONSE_TIME="1.0"
  fi

  # DNS test
  if nslookup google.com > /dev/null 2>&1; then
    DNS_STATUS="ok"
    DNS_LATENCY=$(time -p nslookup google.com 2>&1 | grep real | awk '{print $2}')
  else
    DNS_STATUS="failed"
    DNS_LATENCY="N/A"
  fi
}

collect_wifi_metrics() {
  # Count WiFi clients across all interfaces
  WIFI_CLIENTS_TOTAL=0
  WIFI_CLIENTS_2G=0
  WIFI_CLIENTS_5G=0
  WIFI_CLIENTS_6G=0

  # Check each wireless interface
  for wiface in wlan0 wlan1 wlan2 ra0 rai0; do
    if [ -d "/sys/class/net/$wiface" ]; then
      CLIENT_COUNT=$(iw dev $wiface station dump 2>/dev/null | grep -c "^Station" || echo 0)
      WIFI_CLIENTS_TOTAL=$((WIFI_CLIENTS_TOTAL + CLIENT_COUNT))

      # Try to identify band
      FREQ=$(iw dev $wiface info 2>/dev/null | grep "channel" | awk '{print $2}')
      case "$FREQ" in
        1|2|3|4|5|6|7|8|9|10|11|12|13|14)
          WIFI_CLIENTS_2G=$((WIFI_CLIENTS_2G + CLIENT_COUNT))
          ;;
        36|40|44|48|52|56|60|64|100|104|108|112|116|120|124|128|132|136|140|144|149|153|157|161|165)
          WIFI_CLIENTS_5G=$((WIFI_CLIENTS_5G + CLIENT_COUNT))
          ;;
        *)
          if [ "$FREQ" -gt 200 ]; then
            WIFI_CLIENTS_6G=$((WIFI_CLIENTS_6G + CLIENT_COUNT))
          fi
          ;;
      esac
    fi
  done
}

collect_temperature_metrics() {
  # Temperature sensors (multiple sources)
  TEMP_C="N/A"

  # Method 1: thermal_zone
  if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP_RAW=$(cat /sys/class/thermal/thermal_zone0/temp)
    TEMP_C=$((TEMP_RAW / 1000))
  fi

  # Method 2: hwmon
  if [ "$TEMP_C" = "N/A" ] && [ -f /sys/class/hwmon/hwmon0/temp1_input ]; then
    TEMP_RAW=$(cat /sys/class/hwmon/hwmon0/temp1_input)
    TEMP_C=$((TEMP_RAW / 1000))
  fi
}

collect_storage_metrics() {
  # Root filesystem usage
  DISK_INFO=$(df -h / | tail -1)
  DISK_TOTAL=$(echo "$DISK_INFO" | awk '{print $2}')
  DISK_USED=$(echo "$DISK_INFO" | awk '{print $3}')
  DISK_FREE=$(echo "$DISK_INFO" | awk '{print $4}')
  DISK_PERCENT=$(echo "$DISK_INFO" | awk '{print $5}' | sed 's/%//')

  # /tmp usage (in-memory)
  TMP_INFO=$(df -h /tmp | tail -1)
  TMP_USED=$(echo "$TMP_INFO" | awk '{print $3}')
  TMP_FREE=$(echo "$TMP_INFO" | awk '{print $4}')
  TMP_PERCENT=$(echo "$TMP_INFO" | awk '{print $5}' | sed 's/%//')
}

collect_process_metrics() {
  # Process count
  PROCESS_TOTAL=$(ps | wc -l)
  PROCESS_RUNNING=$(ps | grep -c " R ")

  # Top CPU processes
  TOP_CPU_PROC=$(ps aux | sort -rn -k 3 | head -3 | awk '{print $11}' | tr '\n' ',' | sed 's/,$//')
}

################################################################################
# DATA EXPORT FUNCTIONS
################################################################################

build_json_metrics() {
  cat > "$METRICS_FILE" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "router": {
    "name": "$ROUTER_NAME",
    "location": "$ROUTER_LOCATION",
    "hostname": "$HOSTNAME",
    "kernel": "$KERNEL",
    "uptime_seconds": $UPTIME_SECS,
    "uptime_days": $UPTIME_DAYS
  },
  "cpu": {
    "count": $CPU_COUNT,
    "usage_percent": $CPU_USAGE,
    "load_1min": $LOAD_1MIN,
    "load_5min": $LOAD_5MIN,
    "load_15min": $LOAD_15MIN
  },
  "memory": {
    "total_mb": $MEM_TOTAL_MB,
    "used_mb": $MEM_USED_MB,
    "free_mb": $MEM_FREE_MB,
    "usage_percent": $MEM_PERCENT
  },
  "network": {
    "wan_interface": "$WAN_IFACE",
    "wan_ip": "$WAN_IP",
    "public_ip": "$PUBLIC_IP",
    "rx_mb": $RX_MB,
    "tx_mb": $TX_MB,
    "rx_packets": $RX_PACKETS,
    "tx_packets": $TX_PACKETS,
    "rx_errors": $RX_ERRORS,
    "tx_errors": $TX_ERRORS,
    "rx_dropped": $RX_DROPPED,
    "tx_dropped": $TX_DROPPED
  },
  "wan": {
    "status": "$WAN_STATUS",
    "state_is_up": $WAN_STATE_UP,
    "latency_avg_ms": "$WAN_LATENCY_AVG",
    "latency_min_ms": "$WAN_LATENCY_MIN",
    "latency_max_ms": "$WAN_LATENCY_MAX",
    "packet_loss": "$WAN_PACKET_LOSS",
    "dns_status": "$DNS_STATUS"
  },
  "wifi": {
    "clients_total": $WIFI_CLIENTS_TOTAL,
    "clients_2ghz": $WIFI_CLIENTS_2G,
    "clients_5ghz": $WIFI_CLIENTS_5G,
    "clients_6ghz": $WIFI_CLIENTS_6G
  },
  "storage": {
    "root_total": "$DISK_TOTAL",
    "root_used": "$DISK_USED",
    "root_free": "$DISK_FREE",
    "root_percent": $DISK_PERCENT,
    "tmp_used": "$TMP_USED",
    "tmp_percent": $TMP_PERCENT
  },
  "system": {
    "temperature_c": "$TEMP_C",
    "process_count": $PROCESS_TOTAL,
    "top_cpu_processes": "$TOP_CPU_PROC"
  },
  "uptime_metrics": {
    "response_time": $RESPONSE_TIME,
    "state_is_up": $WAN_STATE_UP
  }
}
EOF
}

send_to_uptime_heartbeat() {
  if [ "$HEARTBEAT_URL" = "https://uptime.com/api/v1/checks/XXXXX/heartbeat" ]; then
    log_message "WARN" "Heartbeat URL not configured - skipping heartbeat send"
    return 1
  fi

  # Send simple heartbeat with response_time
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

send_to_uptime_webhook() {
  if [ -z "$WEBHOOK_URL" ]; then
    return 0
  fi

  # Send incoming webhook with state_is_up + response_time
  HTTP_CODE=$(curl -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "{\"state_is_up\": $WAN_STATE_UP, \"response_time\": $RESPONSE_TIME}" \
    --max-time 10 \
    -s -o /dev/null -w "%{http_code}")

  if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "204" ]; then
    log_message "INFO" "Webhook sent successfully (HTTP $HTTP_CODE)"
    return 0
  else
    log_message "ERROR" "Webhook failed (HTTP $HTTP_CODE)"
    return 1
  fi
}

################################################################################
# UTILITY FUNCTIONS
################################################################################

log_message() {
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

  # Also log to syslog
  logger -t router_monitor "[$level] $message"

  # Trim log file
  if [ -f "$LOG_FILE" ]; then
    tail -n $MAX_LOG_LINES "$LOG_FILE" > "${LOG_FILE}.tmp"
    mv "${LOG_FILE}.tmp" "$LOG_FILE"
  fi
}

print_summary() {
  cat <<SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Router Monitoring Summary - $(date)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 System:    $HOSTNAME | Uptime: ${UPTIME_DAYS}d | Temp: ${TEMP_C}°C
 CPU:       ${CPU_USAGE}% used | Load: ${LOAD_1MIN} ${LOAD_5MIN} ${LOAD_15MIN}
 Memory:    ${MEM_USED_MB}MB / ${MEM_TOTAL_MB}MB (${MEM_PERCENT}%)
 Storage:   ${DISK_USED} / ${DISK_TOTAL} (${DISK_PERCENT}%)
 Network:   RX: ${RX_MB}MB | TX: ${TX_MB}MB | Errors: $((RX_ERRORS + TX_ERRORS))
 WAN:       Status: $WAN_STATUS | Latency: ${WAN_LATENCY_AVG}ms | Loss: $WAN_PACKET_LOSS
 IP:        Local: $WAN_IP | Public: $PUBLIC_IP
 WiFi:      $WIFI_CLIENTS_TOTAL clients (2G:$WIFI_CLIENTS_2G 5G:$WIFI_CLIENTS_5G 6G:$WIFI_CLIENTS_6G)
 DNS:       $DNS_STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SUMMARY
}

################################################################################
# MAIN EXECUTION
################################################################################

main() {
  local start_time=$(date +%s)

  log_message "INFO" "Starting router monitoring cycle"

  # Collect all metrics
  collect_system_metrics
  collect_cpu_metrics
  collect_memory_metrics
  collect_network_metrics
  collect_wan_metrics
  collect_wifi_metrics
  collect_temperature_metrics
  collect_storage_metrics
  collect_process_metrics

  # Build JSON
  build_json_metrics

  # Send to Uptime.com
  send_to_uptime_heartbeat
  send_to_uptime_webhook

  # Log summary
  log_message "INFO" "WAN:$WAN_STATUS CPU:${CPU_USAGE}% MEM:${MEM_PERCENT}% Disk:${DISK_PERCENT}% Latency:${WAN_LATENCY_AVG}ms WiFi:${WIFI_CLIENTS_TOTAL} Temp:${TEMP_C}°C"

  # Print summary (optional - comment out for cron)
  # print_summary

  local end_time=$(date +%s)
  local duration=$((end_time - start_time))
  log_message "INFO" "Monitoring cycle completed in ${duration}s"
}

# Run main function
main

exit 0

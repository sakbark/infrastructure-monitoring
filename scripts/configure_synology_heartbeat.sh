#!/bin/bash
# Helper script to configure heartbeat URL

if [ -z "$1" ]; then
    echo "Usage: $0 <heartbeat_url>"
    echo "Example: $0 https://metrics.uptime.com/metrics/heartbeat/YOUR-ID-HERE"
    exit 1
fi

HEARTBEAT_URL="$1"
SCRIPT_PATH="$HOME/scripts/synology_uptime_monitor.sh"

echo "Configuring heartbeat URL..."
sed -i "s|HEARTBEAT_URL=\"\"|HEARTBEAT_URL=\"$HEARTBEAT_URL\"|" "$SCRIPT_PATH"

echo "Testing monitoring script..."
"$SCRIPT_PATH"

echo ""
echo "Last 5 log entries:"
tail -5 /tmp/uptime_monitor.log

echo ""
echo "✅ Configuration complete!"
echo "Script will run automatically via cron every 2 minutes"

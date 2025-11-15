# 🏠 Home Router (GL-BE9300) - Deployment Complete

**Status**: ✅ FULLY OPERATIONAL
**Date**: November 15, 2025
**Location**: Home

---

## ✅ Monitoring Deployed

### Heartbeat Configuration
- **URL**: `https://metrics.uptime.com/metrics/heartbeat/3B0JA-A38B6865528F0E0F`
- **Check Name**: "Home Router GL-BE9300 - Direct Heartbeat"
- **Status**: 🟢 LIVE - Sending data every 2 minutes
- **Last Send**: HTTP 200 (Successful)

### Current Metrics (Live)
```json
{
  "router": "GL-BE9300-Home",
  "location": "Home",
  "kernel": "5.4.213",
  "uptime_days": 0,
  "cpu": {
    "count": 4,
    "usage_percent": 0,
    "load_1min": 2.47
  },
  "memory": {
    "total_mb": 862,
    "used_mb": 461,
    "usage_percent": 53
  },
  "wan": {
    "status": "up",
    "latency_avg_ms": "2.187",
    "packet_loss": "0%",
    "public_ip": "140.228.71.7"
  },
  "wifi": {
    "clients_total": 0
  },
  "temperature_c": "67"
}
```

### Cron Job
```cron
*/2 * * * * /root/router_uptime_monitor.sh >/dev/null 2>&1
```

---

## ✅ Tailscale Configuration

### Access Information
- **Tailscale IP**: `100.104.73.101`
- **Hostname**: `gl-be9300`
- **Full Domain**: `gl-be9300.tail75e75.ts.net`
- **SSH Command**: `ssh -i ~/.ssh/flint3_router root@100.104.73.101`

### Subnet Router Configuration
**Advertised Routes** (Pending Approval in Tailscale Admin):
- `192.168.50.0/24` (Home LAN)
- `140.228.71.0/24` (WAN subnet)

### Exit Node
- **Status**: Advertised ✅
- **Enabled**: Yes (Pending approval in Tailscale Admin)

### IP Forwarding
```
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```
✅ Configured and active

---

## ✅ Services Status

All critical services remain accessible:

| Service | Port | Status | Notes |
|---------|------|--------|-------|
| SSH | 22 | ✅ Running | dropbear |
| HTTP | 80 | ✅ Running | nginx |
| HTTPS | 443 | ✅ Running | nginx |
| Admin GUI | 8080 | ✅ Running | uhttpd |
| Tailscale | 41641 | ✅ Running | - |

---

## 📋 Next Steps Required

### 1. Approve Subnet Routes in Tailscale Admin
1. Go to https://login.tailscale.com
2. Find device: **gl-be9300** (100.104.73.101)
3. Go to **Machine Settings** → **Subnets**
4. **Approve** the following routes:
   - ✅ `192.168.50.0/24`
   - ✅ `140.228.71.0/24`

### 2. Enable Exit Node (Optional)
1. In same Machine Settings page
2. Go to **Exit Node** section
3. Click **Allow** to enable this router as an exit node

---

## 🌐 Both Routers Summary

### Office Router (GL-MT6000) ✅ OPERATIONAL
- **Tailscale IP**: 100.106.155.108
- **Local IP**: 192.168.8.1
- **Heartbeat**: `https://metrics.uptime.com/metrics/heartbeat/3B0J7-9FDC95A785D49153`
- **Status**: 🟢 LIVE
- **Performance**: 32 Mbps, ~7ms latency
- **Monitoring**: Every 2 minutes
- **Subnets**: 192.168.1.0/24, 192.168.8.0/24, 192.168.23.0/24 (Approved)

### Home Router (GL-BE9300) ✅ OPERATIONAL
- **Tailscale IP**: 100.104.73.101
- **Local IP**: 192.168.50.1
- **Heartbeat**: `https://metrics.uptime.com/metrics/heartbeat/3B0JA-A38B6865528F0E0F`
- **Status**: 🟢 LIVE
- **Performance**: 665 Mbps, ~2.2ms latency (20x faster!)
- **Monitoring**: Every 2 minutes
- **Subnets**: 192.168.50.0/24, 140.228.71.0/24 (Pending Approval)
- **Exit Node**: Advertised (Pending Approval)

---

## 🔧 Quick Access Commands

### Via Tailscale
```bash
# SSH to home router
ssh -i ~/.ssh/flint3_router root@100.104.73.101

# View monitoring logs
ssh -i ~/.ssh/flint3_router root@100.104.73.101 'tail -f /tmp/uptime_monitor.log'

# Check metrics
ssh -i ~/.ssh/flint3_router root@100.104.73.101 'cat /tmp/router_metrics.json'

# Manual test
ssh -i ~/.ssh/flint3_router root@100.104.73.101 '/root/router_uptime_monitor.sh'

# Check Tailscale status
ssh -i ~/.ssh/flint3_router root@100.104.73.101 'tailscale status'
```

### Via Local Network
```bash
# When on home network (192.168.50.0/24)
ssh -i ~/.ssh/flint3_router root@192.168.50.1

# Admin GUI
http://192.168.50.1
```

---

## 📊 Uptime.com Dashboard

Both routers are now monitored:

1. **Office Router GL-MT6000 - Direct Heartbeat** ✅
   - Type: HEARTBEAT
   - Status: UP
   - Interval: 2 minutes

2. **Home Router GL-BE9300 - Direct Heartbeat** ✅
   - Type: HEARTBEAT
   - Status: UP
   - Interval: 2 minutes

**Dashboard**: https://uptime.com

---

## 🔐 Google Secret Manager

All configuration stored in GSM:

```bash
# Home router Tailscale access
gcloud secrets versions access latest --secret="home-router-tailscale-access"

# Home router network info
gcloud secrets versions access latest --secret="home-router-network-info"

# GL.iNet router credentials
gcloud secrets versions access latest --secret="glinet-router-credentials"

# Uptime.com API key
gcloud secrets versions access latest --secret="uptime-api-key"
```

---

## 📝 Files Deployed on Router

```
/root/router_uptime_monitor.sh    (10.6 KB) - Main monitoring script
/root/configure_heartbeat.sh       (1.6 KB)  - Configuration helper
/tmp/router_metrics.json          - Latest metrics (JSON)
/tmp/uptime_monitor.log           - Activity log (auto-rotating)
```

---

## 🎉 Deployment Summary

**Completed Tasks:**
- ✅ SSH access configured via Tailscale
- ✅ Monitoring script deployed and operational
- ✅ Heartbeat configured and sending data
- ✅ Cron job set up (every 2 minutes)
- ✅ Tailscale subnet router configured
- ✅ Tailscale exit node advertised
- ✅ IP forwarding enabled
- ✅ All services (SSH, HTTP, HTTPS, Admin GUI) verified
- ✅ Configuration stored in Google Secret Manager

**Performance Comparison:**
- Home: 665 Mbps / 2.2ms latency 🚀
- Office: 32 Mbps / 7ms latency

**Monitoring:**
- Both routers push comprehensive metrics every 2 minutes
- Alerts triggered if heartbeat missed
- Full metrics: CPU, Memory, Network, WAN, WiFi, Temperature

---

**Deployed by**: Claude Code
**Date**: November 15, 2025 19:41 UTC
**Status**: 🟢 OPERATIONAL

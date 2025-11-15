# 🌐 Infrastructure Monitoring

Network monitoring deployment for routers and NAS devices with automated heartbeat reporting to Uptime.com.

**Last Updated**: November 15, 2025
**Status**: 2/3 Devices Operational, 1/3 Awaiting Activation

---

## 📊 Monitored Devices

| Device | Type | Status | Monitoring | Location |
|--------|------|--------|------------|----------|
| GL-MT6000 | Router | 🟢 LIVE | Every 2min | Office |
| GL-BE9300 | Router | 🟢 LIVE | Every 2min | Home |
| Synology DS218+ | NAS | 🟡 READY | Deployed | Home |

---

## 📁 Repository Structure

```
infrastructure-monitoring/
├── README.md                    # This file
├── docs/                        # Documentation
│   ├── DEPLOYMENT_ISSUES_AND_OUTSTANDING_TASKS.md  # Issues & troubleshooting
│   ├── NETWORK_MONITORING_COMPLETE_SUMMARY.md      # Overall summary
│   ├── HOME_ROUTER_DEPLOYMENT_COMPLETE.md          # Home router details
│   ├── SYNOLOGY_NAS_DEPLOYMENT.md                  # Synology NAS details
│   └── GSM_SECRETS_SUMMARY.md                      # Google Secret Manager reference
├── scripts/                     # Monitoring scripts
│   ├── router_uptime_monitor.sh           # Router monitoring script
│   ├── synology_uptime_monitor.sh         # Synology monitoring script
│   └── configure_synology_heartbeat.sh    # Config helper
└── configs/                     # Device configurations
    ├── home_router_complete_config.json
    ├── office_router_complete_config.json
    ├── synology_nas_complete_config.json
    └── uptime_config.json
```

---

## 🚀 Quick Start

### View Device Configurations

```bash
# All secrets stored in Google Secret Manager
gcloud secrets list --filter="name~'router|synology|uptime'"

# Retrieve specific config
gcloud secrets versions access latest --secret="synology-nas-saadz-config" | python3 -m json.tool
```

### Access Devices

```bash
# Office Router (GL-MT6000)
ssh -i ~/.ssh/glinet_mt6000 root@100.106.155.108  # Tailscale
ssh -i ~/.ssh/glinet_mt6000 root@192.168.8.1      # Local

# Home Router (GL-BE9300)
ssh -i ~/.ssh/flint3_router root@100.104.73.101  # Tailscale
ssh -i ~/.ssh/flint3_router root@192.168.50.1    # Local

# Synology NAS (DS218+)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23  # Local (PREFERRED)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@100.115.78.45  # Tailscale (may hang)
```

### Check Monitoring Status

```bash
# Routers
ssh -i ~/.ssh/glinet_mt6000 root@100.106.155.108 'tail -10 /tmp/uptime_monitor.log'
ssh -i ~/.ssh/flint3_router root@100.104.73.101 'tail -10 /tmp/uptime_monitor.log'

# Synology
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 'tail -10 /tmp/uptime_monitor.log'
```

---

## 📈 Metrics Collected

Each device reports every 2 minutes:
- **System**: CPU usage, memory, temperature, uptime
- **Network**: WAN status, latency, packet loss, public IP
- **Device-specific**: WiFi clients (routers), disk usage (NAS)

---

## ⏳ Outstanding Tasks

1. **Synology NAS Monitoring Activation**:
   - Create heartbeat check at https://uptime.com
   - Configure heartbeat URL
   - Setup DSM Task Scheduler

2. **Tailscale Configuration**:
   - Approve subnet routes for home router (192.168.50.0/24, 140.228.71.0/24)
   - Approve exit node (optional)

3. **Synology SSH Issue**:
   - Investigate Tailscale SSH hanging issue
   - Currently works via local IP only

See [`docs/DEPLOYMENT_ISSUES_AND_OUTSTANDING_TASKS.md`](docs/DEPLOYMENT_ISSUES_AND_OUTSTANDING_TASKS.md) for detailed information.

---

## 🔐 Security

- All credentials stored in Google Secret Manager (encrypted)
- SSH key-based authentication
- Tailscale mesh VPN for secure remote access
- No exposed SSH ports on public internet
- HTTPS-only monitoring endpoints

---

## 📚 Documentation

- **[Deployment Issues & Tasks](docs/DEPLOYMENT_ISSUES_AND_OUTSTANDING_TASKS.md)** - Troubleshooting & outstanding work
- **[Network Monitoring Summary](docs/NETWORK_MONITORING_COMPLETE_SUMMARY.md)** - Complete deployment overview
- **[Home Router Deployment](docs/HOME_ROUTER_DEPLOYMENT_COMPLETE.md)** - GL-BE9300 details
- **[Synology NAS Deployment](docs/SYNOLOGY_NAS_DEPLOYMENT.md)** - DS218+ details
- **[GSM Secrets Reference](docs/GSM_SECRETS_SUMMARY.md)** - All secrets documentation

---

## 🛠️ Technologies

- **Monitoring**: Uptime.com (Heartbeat checks)
- **Secrets**: Google Secret Manager
- **VPN**: Tailscale mesh network
- **Routers**: OpenWRT (GL.iNet)
- **NAS**: Synology DSM 7.1.1
- **Scripts**: Bash (BusyBox compatible)

---

## 📊 Network Topology

```
Internet
   │
   ├─── Office (GL-MT6000)
   │    └── 100.106.155.108 (Tailscale)
   │        └── 192.168.8.1 (Local)
   │
   └─── Home (GL-BE9300)
        └── 100.104.73.101 (Tailscale)
            └── 192.168.50.1 (Local)
                └── Synology DS218+ (192.168.50.23)
                    └── 100.115.78.45 (Tailscale)
```

---

## 🔗 Links

- **Uptime.com Dashboard**: https://uptime.com
- **Tailscale Admin**: https://login.tailscale.com/admin/machines
- **Synology QuickConnect**: https://sakbark.quickconnect.to
- **Synology Local**: https://192.168.50.23:5001

---

## 📝 Notes

- Synology SSH via Tailscale currently has connection issues - use local IP when possible
- Home router subnet routes need manual approval in Tailscale admin
- All configurations are version-controlled in Google Secret Manager
- Monitoring scripts are deployed on each device with cron jobs

---

**Deployed by**: Claude Code
**Date**: November 15, 2025
**Version**: 1.0

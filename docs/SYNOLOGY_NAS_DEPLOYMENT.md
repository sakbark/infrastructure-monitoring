# 🖥️ Synology NAS (SaadZ) - Deployment Summary

**Status**: ⚠️ PARTIALLY COMPLETE - Monitoring Ready, Awaiting Heartbeat Configuration
**Date**: November 15, 2025
**Location**: Home (192.168.50.23) - Behind GL-BE9300 Router

---

## ✅ Completed Tasks

### 1. SSH Access Configured
- **Tailscale IP**: 100.115.78.45 (port 77)
- **Local IP**: 192.168.50.23 (port 77) ✅ PREFERRED
- **SSH Key**: ~/.ssh/synology_nas
- **Username**: saadmin
- **Note**: Tailscale SSH may hang - use local IP when on home network

**SSH Commands**:
```bash
# Via Local Network (Preferred)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23

# Via Tailscale (May hang)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@100.115.78.45
```

### 2. Monitoring Script Deployed
- **Location**: ~/scripts/synology_uptime_monitor.sh (9.3 KB)
- **Config Helper**: ~/scripts/configure_heartbeat.sh (629 bytes)
- **Status**: ✅ Deployed and tested
- **Metrics**: CPU, memory, disk, network, WAN, Tailscale, temperature

**Test Script**:
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 '~/scripts/synology_uptime_monitor.sh'
```

### 3. Current System Metrics
```json
{
  "hostname": "SaadZ",
  "model": "DS218+ (apollolake)",
  "dsm_version": "7.1.1-42962 Update 9",
  "uptime_days": 65,
  "cpu": {
    "cores": 2,
    "usage_percent": 0,
    "load": 0.21
  },
  "memory": {
    "total_mb": 9806,
    "used_mb": 1145,
    "usage_percent": 12
  },
  "disk": {
    "volume": "/volume7",
    "size": "3.5T",
    "used": "2.0T (58%)"
  },
  "temperature_c": 34,
  "public_ip": "140.228.71.7"
}
```

### 4. Configuration Stored in GSM
```bash
# Retrieve Synology configuration
gcloud secrets versions access latest --secret="synology-nas-saadz-config"

# View formatted
gcloud secrets versions access latest --secret="synology-nas-saadz-config" | python3 -m json.tool
```

---

## ⏳ Pending Manual Steps

### 1. Create Heartbeat Check in Uptime.com
**You need to**:
1. Log in to https://uptime.com
2. Go to **Monitoring** → **Add New Check**
3. Select **Heartbeat** check type
4. Configure:
   - **Name**: "Synology NAS SaadZ - Direct Heartbeat"
   - **Interval**: 2 minutes
   - **Tags**: synology, nas, home
5. Save and **copy the heartbeat URL**

### 2. Configure Heartbeat URL
After creating the check, run:
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 \
  '~/scripts/configure_heartbeat.sh https://metrics.uptime.com/metrics/heartbeat/YOUR-ID-HERE'
```

### 3. Setup Cron Job or Task Scheduler
**Option A: Via Cron (SSH)**:
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 \
  'crontab -l 2>/dev/null | { cat; echo "*/2 * * * * ~/scripts/synology_uptime_monitor.sh >/dev/null 2>&1"; } | crontab -'
```

**Option B: Via DSM UI (Recommended)**:
1. Open DSM at https://192.168.50.23:5001
2. Go to **Control Panel** → **Task Scheduler**
3. Create → **Scheduled Task** → **User-defined script**
4. General:
   - Task name: "Synology Uptime Monitor"
   - User: saadmin
   - Enabled: ✅
5. Schedule:
   - Run on the following days: Daily
   - Frequency: Every 2 minutes
   - First run time: 00:00
6. Task Settings:
   - User-defined script: `/volume7/homes/saadmin/scripts/synology_uptime_monitor.sh`
7. Save

### 4. Add SSH Key for Passwordless Access
Generate and add a dedicated SSH key:
```bash
# On your Mac
ssh-keygen -t ed25519 -f ~/.ssh/synology_dedicated -C "saad@macbook-synology"

# Add to Synology
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys" < ~/.ssh/synology_dedicated.pub
```

---

## 🌐 Access Methods

### Web Interfaces
- **Local HTTPS**: https://192.168.50.23:5001
- **QuickConnect**: https://sakbark.quickconnect.to
- **DDNS**: https://sakbark.synology.me:5001

### SSH Access
```bash
# Current (with existing key)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23

# After adding new key
ssh -i ~/.ssh/synology_dedicated -p 77 saadmin@192.168.50.23
```

### Tailscale
```bash
# Check status
tailscale status | grep saadz

# Should show:
# 100.115.78.45   saadz   tagged-devices linux   active; offers exit node
```

---

## 🔧 Synology DSM API Integration

### API Availability
The Synology DSM provides a comprehensive Web API for automation:

**Base URLs**:
- Local HTTP: `http://192.168.50.23:5000/webapi`
- Local HTTPS: `https://192.168.50.23:5001/webapi`
- QuickConnect: `https://sakbark.quickconnect.to/webapi`

**API Info Endpoint**:
```bash
curl -k "https://192.168.50.23:5001/webapi/query.cgi?api=SYNO.API.Info&version=1&method=query"
```

**Authentication**:
```bash
curl -k "https://192.168.50.23:5001/webapi/auth.cgi?api=SYNO.API.Auth&version=3&method=login&account=saadmin&passwd=YOUR_PASSWORD&session=FileStation&format=sid"
```

**Common APIs**:
- `SYNO.API.Info` - List available APIs
- `SYNO.API.Auth` - Authentication
- `SYNO.Core.System` - System information
- `SYNO.Storage.CGI.Storage` - Storage info
- `SYNO.FileStation.*` - File operations
- `SYNO.DownloadStation.*` - Download management

**Enable Web API** (if needed):
1. DSM → **Control Panel** → **Terminal & SNMP**
2. Enable **Web API**
3. Save

**Documentation**:
- Available in DSM UI under Developer Tools
- Official guide: https://global.download.synology.com/download/Document/Software/DeveloperGuide/

---

## 📊 Integration with Calendar GPT

### Future Integration Options

**1. Direct API Access**:
Calendar GPT could access the Synology DSM API to:
- Retrieve file information
- Upload/download files
- Monitor system status
- Manage downloads
- Query storage usage

**2. Monitoring Data Access**:
Since monitoring metrics are stored at `/tmp/synology_metrics.json`:
```bash
# Calendar GPT could SSH and retrieve:
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 'cat /tmp/synology_metrics.json'
```

**3. Via Google Secret Manager**:
All configuration already stored in GSM:
```bash
gcloud secrets versions access latest --secret="synology-nas-saadz-config"
```

---

## 📝 Quick Commands

### Check Monitoring Status
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 'tail -10 /tmp/uptime_monitor.log'
```

### View Current Metrics
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 'cat /tmp/synology_metrics.json' | python3 -m json.tool
```

### Manual Test Run
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 '~/scripts/synology_uptime_monitor.sh && tail -5 /tmp/uptime_monitor.log'
```

### Check Disk Usage
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 'df -h | grep volume'
```

### System Information
```bash
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 'cat /etc/VERSION && free -m && uptime'
```

---

## 🔐 Credentials Reference

**SSH Access**:
- Username: `saadmin`
- Password: `fP3OaK!ky0LzQC`
- SSH Key: `~/.ssh/synology_nas`
- Port: `77`

**Stored in GSM**:
```bash
gcloud secrets versions access latest --secret="synology-nas-saadz-config"
```

---

## 📋 Summary

**What's Working**:
- ✅ SSH access (local IP preferred)
- ✅ Monitoring script deployed
- ✅ Metrics collection tested
- ✅ Configuration stored in GSM
- ✅ Tailscale connectivity (ping/services)
- ✅ DSM Web API available

**What's Pending**:
- ⏳ Create heartbeat check in Uptime.com dashboard
- ⏳ Configure heartbeat URL in monitoring script
- ⏳ Setup cron job or DSM Task Scheduler
- ⏳ Fix Tailscale SSH hanging issue
- ⏳ Add additional SSH key for passwordless access
- ⏳ Optional: Enable DSM Web API for Calendar GPT integration

**Next Action**:
1. Create heartbeat check at https://uptime.com (manual)
2. Configure the heartbeat URL
3. Setup the task scheduler
4. Monitoring will be fully operational

---

**Deployed by**: Claude Code
**Date**: November 15, 2025 20:00 UTC
**Status**: 🟡 READY FOR ACTIVATION (Awaiting Heartbeat Configuration)

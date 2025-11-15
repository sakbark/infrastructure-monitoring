# Google Secret Manager - Router Configuration Summary

**Updated**: November 15, 2025
**Project**: new-fps-gpt

---

## 🔐 Updated Secrets

### 1. `home-router-network-info` ✅ UPDATED
**Version**: 2 (Latest)
**Content**: Complete home router (GL-BE9300) configuration including:
- Tailscale access (100.104.73.101)
- Local network access (192.168.50.1)
- DDNS configuration
- Monitoring setup and current metrics
- Performance metrics
- Subnet router configuration
- Exit node configuration
- All services status

**Access**:
```bash
gcloud secrets versions access latest --secret="home-router-network-info"
```

### 2. `office-router-network-info` ✅ UPDATED
**Version**: 2 (Latest)
**Content**: Complete office router (GL-MT6000) configuration including:
- Tailscale access (100.106.155.108)
- Local network access (192.168.8.1)
- Multi-WAN setup details
- Monitoring setup and current metrics
- Performance metrics
- Subnet router configuration (approved routes)
- All services status

**Access**:
```bash
gcloud secrets versions access latest --secret="office-router-network-info"
```

### 3. `home-router-tailscale-access` ✅ NEW
**Version**: 1 (Latest)
**Content**: Tailscale-specific access information for home router:
- Tailscale IP and hostname
- SSH commands
- Service endpoints
- Subnet configuration
- Exit node status
- Latency metrics

**Access**:
```bash
gcloud secrets versions access latest --secret="home-router-tailscale-access"
```

### 4. `uptime-api-key` ✅ UPDATED
**Version**: 2 (Latest)
**Content**: Uptime.com API configuration:
```json
{
  "api_key": "78c0730a9c1c200ecddadf965c1a357483b06ca4",
  "tier": "paid",
  "features": {
    "api_access": true,
    "create_checks": true,
    "browsable_api": true,
    "heartbeat_checks": true,
    "webhook_checks": true
  },
  "rate_limits": {
    "api_calls_per_hour": 500,
    "api_calls_per_minute": 60
  }
}
```

**Access**:
```bash
gcloud secrets versions access latest --secret="uptime-api-key"
```

### 5. `synology-nas-saadz-config` ✅ NEW
**Version**: 1 (Latest)
**Content**: Complete Synology DS218+ NAS configuration including:
- Tailscale access (100.115.78.45:77)
- Local network access (192.168.50.23:77)
- QuickConnect and DDNS configuration
- DSM Web API documentation and endpoints
- Monitoring setup (deployed, awaiting activation)
- Hardware specifications
- Current metrics snapshot
- All access methods

**Access**:
```bash
gcloud secrets versions access latest --secret="synology-nas-saadz-config"
```

### 6. `glinet-router-credentials` (Existing)
**Content**: Shared credentials for all GL.iNet routers
- Username: root
- Password: Boohoo77!!
- Router list with specifications

**Access**:
```bash
gcloud secrets versions access latest --secret="glinet-router-credentials"
```

---

## 📊 Router Quick Reference

### Home Router (GL-BE9300)
```bash
# Via Tailscale
ssh -i ~/.ssh/flint3_router root@100.104.73.101

# Via Local Network
ssh -i ~/.ssh/flint3_router root@192.168.50.1

# View Configuration
gcloud secrets versions access latest --secret="home-router-network-info" | python3 -m json.tool
```

### Office Router (GL-MT6000)
```bash
# Via Tailscale
ssh -i ~/.ssh/glinet_mt6000 root@100.106.155.108

# Via Local Network
ssh -i ~/.ssh/glinet_mt6000 root@192.168.8.1

# View Configuration
gcloud secrets versions access latest --secret="office-router-network-info" | python3 -m json.tool
```

### Synology NAS (DS218+)
```bash
# Via Tailscale (may hang - use local IP)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@100.115.78.45

# Via Local Network (PREFERRED)
ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23

# DSM Web Interface
open https://192.168.50.23:5001
# Or: https://sakbark.quickconnect.to

# View Configuration
gcloud secrets versions access latest --secret="synology-nas-saadz-config" | python3 -m json.tool
```

---

## 🔍 Secret Contents Summary

### Home Router Network Info
- **Tailscale IP**: 100.104.73.101
- **Local IP**: 192.168.50.1
- **Heartbeat URL**: https://metrics.uptime.com/metrics/heartbeat/3B0JA-A38B6865528F0E0F
- **Subnet Routes**: 192.168.50.0/24, 140.228.71.0/24 (Pending Approval)
- **Exit Node**: Advertised (Pending Approval)
- **Performance**: 665 Mbps, 2.2ms latency
- **Current Metrics**: CPU 0%, Memory 53%, Temp 67°C

### Office Router Network Info
- **Tailscale IP**: 100.106.155.108
- **Local IP**: 192.168.8.1
- **Heartbeat URL**: https://metrics.uptime.com/metrics/heartbeat/3B0J7-9FDC95A785D49153
- **Subnet Routes**: 192.168.1.0/24, 192.168.8.0/24, 192.168.23.0/24 (Approved)
- **Performance**: 32 Mbps, 7ms latency
- **Current Metrics**: CPU 0%, Memory 23%, Temp 45°C

### Synology NAS (SaadZ)
- **Tailscale IP**: 100.115.78.45:77 (SSH may hang - use local IP)
- **Local IP**: 192.168.50.23:77 (PREFERRED)
- **QuickConnect**: sakbark.quickconnect.to
- **DDNS**: sakbark.synology.me:5001
- **Monitoring**: Deployed, awaiting heartbeat configuration
- **Performance**: 665 Mbps WAN (via home router), 144ms latency
- **Current Metrics**: CPU 0%, Memory 12%, Disk 58%, Temp 34°C
- **Uptime**: 65 days

---

## 📝 Common Commands

### List All Secrets
```bash
gcloud secrets list --format="table(name,createTime)"
```

### View Secret Content
```bash
# Home router
gcloud secrets versions access latest --secret="home-router-network-info"

# Office router
gcloud secrets versions access latest --secret="office-router-network-info"

# Tailscale access
gcloud secrets versions access latest --secret="home-router-tailscale-access"

# Uptime.com API
gcloud secrets versions access latest --secret="uptime-api-key"

# Router credentials
gcloud secrets versions access latest --secret="glinet-router-credentials"

# Synology NAS
gcloud secrets versions access latest --secret="synology-nas-saadz-config"
```

### Update Secret
```bash
echo '{"new":"data"}' | gcloud secrets versions add SECRET_NAME --data-file=-
```

---

## 🎯 What's Stored

Each router configuration secret includes:

✅ **Access Information**
- Tailscale IP and SSH commands
- Local network IP and SSH commands
- DDNS hostname
- SSH keys used
- Admin GUI URLs

✅ **Network Configuration**
- WAN setup (single or multi-WAN)
- Public IP addresses
- DNS servers
- Subnet information
- Tailscale subnet routes
- Exit node status

✅ **Monitoring Details**
- Uptime.com heartbeat URL
- Check ID and name
- Monitoring interval
- Script locations
- Current metrics snapshot
- Last heartbeat status

✅ **Performance Metrics**
- Download/upload speeds
- Latency measurements
- Packet loss
- Current resource usage (CPU, Memory, Temperature)

✅ **Services Status**
- SSH, HTTP, HTTPS availability
- Admin GUI accessibility
- Tailscale status
- Monitoring script status

✅ **Credentials**
- Username and password
- SSH key references
- Service authentication

---

## 🔒 Security Notes

- All secrets are stored encrypted in Google Secret Manager
- Access requires `gcloud` authentication
- SSH keys are stored locally at `~/.ssh/`
- Passwords are shared across all GL.iNet routers
- Tailscale provides secure remote access without exposing SSH ports

---

**Last Updated**: November 15, 2025 20:10 UTC
**Secrets Modified**: 5 (2 updated, 2 new, 1 existing)

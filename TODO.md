# 📋 TODO - Outstanding Tasks

**Last Updated**: November 15, 2025

---

## 🔴 Critical (Required for Full Operation)

### 1. Activate Synology NAS Monitoring
**Estimated Time**: 10 minutes
**Priority**: High

- [ ] Create heartbeat check in Uptime.com
  - Go to https://uptime.com
  - Monitoring → Add New Check → Heartbeat
  - Name: "Synology NAS SaadZ - Direct Heartbeat"
  - Interval: 2 minutes
  - Copy heartbeat URL

- [ ] Configure heartbeat URL
  ```bash
  ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 \
    '~/scripts/configure_heartbeat.sh <HEARTBEAT_URL>'
  ```

- [ ] Setup DSM Task Scheduler
  - Open https://192.168.50.23:5001
  - Control Panel → Task Scheduler
  - Create scheduled task (every 2 minutes)
  - Script: `/volume7/homes/saadmin/scripts/synology_uptime_monitor.sh`

- [ ] Verify operation
  ```bash
  ssh -i ~/.ssh/synology_nas -p 77 saadmin@192.168.50.23 \
    'tail -20 /tmp/uptime_monitor.log'
  ```

### 2. Approve Tailscale Subnet Routes
**Estimated Time**: 2 minutes
**Priority**: High

- [ ] Go to https://login.tailscale.com/admin/machines
- [ ] Find device: gl-be9300 (100.104.73.101)
- [ ] Approve routes:
  - [ ] 192.168.50.0/24 (Home LAN)
  - [ ] 140.228.71.0/24 (WAN subnet - optional)

### 3. Investigate Synology Tailscale SSH Issue
**Estimated Time**: 30-60 minutes
**Priority**: Medium

- [ ] SSH to Synology via local IP
- [ ] Check SSH configuration
  ```bash
  cat /etc/ssh/sshd_config | grep -E "ListenAddress|AllowUsers|DenyUsers"
  ```
- [ ] Check DSM firewall rules
- [ ] Verify SSH listening on all interfaces
  ```bash
  netstat -tlnp | grep :77
  ```
- [ ] Review Tailscale logs
- [ ] Document findings in GitHub issue

---

## 🟡 Optional (Nice to Have)

### 4. Approve Home Router as Exit Node
**Estimated Time**: 1 minute
**Priority**: Low

- [ ] Go to https://login.tailscale.com/admin/machines
- [ ] Find device: gl-be9300 (100.104.73.101)
- [ ] Enable "Exit node" feature

### 5. Add Additional SSH Key to Synology
**Estimated Time**: 2 minutes
**Priority**: Low

- [ ] Open DSM at https://192.168.50.23:5001
- [ ] Control Panel → Terminal & SNMP
- [ ] Add public key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGfzOS892+Y90w6CUwhwC+bUwlGJ6cBw8R4tSAa1381t saad@macbook-flint3-router`

### 6. Fix Synology DNS Resolution
**Estimated Time**: 10 minutes
**Priority**: Low

- [ ] Investigate why `nslookup` is failing
- [ ] Check DNS server configuration
- [ ] Test DNS resolution with different servers
- [ ] Update monitoring script if needed

---

## 🔵 Future Enhancements

### 7. Implement Prometheus Exporters
**Estimated Time**: 2-4 hours
**Priority**: Low

- [ ] Install node_exporter on routers
- [ ] Setup Prometheus server
- [ ] Create Grafana dashboards
- [ ] Migrate from Uptime.com to self-hosted monitoring

### 8. Create Ansible Playbooks
**Estimated Time**: 4-6 hours
**Priority**: Low

- [ ] Write playbook for router configuration
- [ ] Write playbook for NAS configuration
- [ ] Setup inventory file
- [ ] Test deployment automation

### 9. Implement Calendar GPT Integration
**Estimated Time**: 2-3 hours
**Priority**: Medium

- [ ] Create Synology DSM API wrapper
- [ ] Add API credentials to GSM
- [ ] Implement file operations
- [ ] Add system status queries
- [ ] Test integration with Calendar GPT

### 10. Setup Backup & DR Procedures
**Estimated Time**: 1-2 hours
**Priority**: Medium

- [ ] Document backup procedures
- [ ] Create automated GSM secret backups
- [ ] Test restoration procedures
- [ ] Document disaster recovery scenarios

---

## 📊 Progress Tracking

- **Total Tasks**: 10
- **Critical**: 3
- **Optional**: 3
- **Future**: 4

### Completion Status
- ✅ Completed: 0/10 (0%)
- 🔄 In Progress: 0/10 (0%)
- ⏳ Pending: 10/10 (100%)

---

## 🔗 Related Documentation

- [Deployment Issues & Tasks](docs/DEPLOYMENT_ISSUES_AND_OUTSTANDING_TASKS.md)
- [Network Monitoring Summary](docs/NETWORK_MONITORING_COMPLETE_SUMMARY.md)
- [Synology Deployment](docs/SYNOLOGY_NAS_DEPLOYMENT.md)
- [Final Session Summary](docs/FINAL_SESSION_SUMMARY.md)

---

**Created**: November 15, 2025
**Last Updated**: November 15, 2025

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-15

### Added
- Initial deployment of network monitoring infrastructure
- Monitoring scripts for GL.iNet routers (OpenWRT)
- Monitoring script for Synology DSM (NAS)
- Uptime.com heartbeat integration
- Google Secret Manager integration for secure credential storage
- Tailscale mesh VPN configuration
- Comprehensive documentation suite:
  - Deployment summary
  - Issues and troubleshooting guide
  - Device-specific deployment guides
  - GSM secrets reference
  - Session summary
- Configuration files for all 3 devices (JSON)
- GitHub repository with MIT license
- TODO list for outstanding tasks

### Operational
- Office Router (GL-MT6000): ✅ Fully operational, monitoring every 2 minutes
- Home Router (GL-BE9300): ✅ Fully operational, monitoring every 2 minutes, Tailscale subnet router configured
- Synology NAS (DS218+): 🟡 Scripts deployed, awaiting manual activation

### Fixed
- Arithmetic syntax errors in router monitoring scripts (decimal to integer conversion)
- Synology ping permission issue (replaced with curl-based WAN check)
- CLIENT_COUNT newline handling in monitoring scripts
- Missing bc package on home router

### Known Issues
- Synology SSH via Tailscale hangs (workaround: use local IP)
- Uptime.com API doesn't support programmatic heartbeat creation (manual creation required)
- Tailscale subnet routes for home router pending approval
- Synology DNS resolution failing (nslookup)

### Security
- All credentials stored encrypted in Google Secret Manager
- SSH key-based authentication for all devices
- Tailscale mesh VPN for secure remote access
- No exposed SSH ports on public internet
- HTTPS-only monitoring endpoints

### Documentation
- 5 comprehensive documentation files
- Device configuration files (JSON)
- Monitoring scripts with inline comments
- Quick start guide
- Troubleshooting guide

### Infrastructure
- 3 devices configured
- 2 devices operational (67%)
- 1 device ready for activation (33%)
- 6 GSM secrets created/updated
- ~800 lines of monitoring script code
- ~2,300 lines of documentation

---

## [Unreleased]

### To Do
- Activate Synology NAS monitoring (create heartbeat, configure, schedule)
- Approve Tailscale subnet routes for home router
- Investigate Synology Tailscale SSH connectivity issue
- Optional: Approve home router as Tailscale exit node
- Future: Implement Prometheus/Grafana monitoring
- Future: Create Ansible playbooks for automation
- Future: Integrate Synology DSM API with Calendar GPT

---

**Format**: [Keep a Changelog](https://keepachangelog.com/)
**Versioning**: [Semantic Versioning](https://semver.org/)

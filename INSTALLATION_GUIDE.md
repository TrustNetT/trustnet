# TrustNet Installation & v1.1.0 Deployment Workflow

## Current Status
- ✅ **v1.0.0 base installer**: Working (core branch)
- ✅ **v1.1.0 components**: Ready in `core/versions/v1.1.0/`
- ✅ **v1.1.0 deployment script**: Ready at `tools/deploy-v1.1.0-components.sh`

---

## Installation Workflow

### Phase 1: Base v1.0.0 Installation (First Time Only)

**Command:**
```bash
curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh | bash -s -- --auto
```

**What happens:**
1. Downloads Alpine Linux ISO (cached in `~/.trustnet/cache/`)
2. Creates VM at `~/vms/trustnet/`
3. Installs Cosmos SDK blockchain node
4. Starts Caddy reverse proxy
5. VM ready at `trustnet.local`

**Cache behavior:**
- ISO downloaded once, reused on subsequent installs
- Cache persists across reboots
- Do NOT delete `~/.trustnet/` unless fresh install needed

**Verify success:**
```bash
curl https://trustnet.local/status
```

---

### Phase 2: v1.1.0 Component Deployment (After Phase 1 Complete)

**Prerequisites:**
- Base v1.0.0 installation completed
- VM running and accessible at `trustnet.local:2223`

**Command:**
```bash
cd ~/GitProjects/TrustNet/trustnet-wip
bash tools/deploy-v1.1.0-components.sh
```

**What happens:**
1. Copies v1.1.0 components from repository:
   - `setup.py` (FastAPI server for QR codes)
   - `first-setup.html` (Setup UI)
   - `setup-requirements.txt` (Python dependencies)
2. Deploys to VM via SSH
3. Installs FastAPI on the VM
4. Creates systemd service for Setup API (port 8001)
5. Configures Caddy routing for `/setup` endpoint

**Verify success:**
```bash
# Check Setup API running
curl http://trustnet.local:8001/api/setup/info

# Access setup UI
curl https://trustnet.local/setup

# Check service status
ssh -p 2223 warden@trustnet.local "systemctl status trustnet-setup"
```

---

## Component Details

### v1.0.0 Components (Base)
| Component | File | Purpose |
|-----------|------|---------|
| VM Bootstrap | `tools/lib/vm-bootstrap.sh` | Alpine Linux setup |
| VM Lifecycle | `tools/lib/vm-lifecycle.sh` | QEMU management |
| Caddy Config | `tools/lib/install-caddy.sh` | HTTPS reverse proxy |
| Cosmos SDK | `tools/lib/install-cosmos-sdk.sh` | Blockchain node |
| Certificates | `tools/lib/install-certificates.sh` | SSL/TLS setup |

### v1.1.0 Components (Added by deploy script)
| Component | Location | Port | Purpose |
|-----------|----------|------|---------|
| setup.py | `core/versions/v1.1.0/api/setup_api.py` | 8001 | FastAPI server (QR codes, PIN verification) |
| Setup UI | `core/versions/v1.1.0/web/templates/first-setup.html` | 1317 | Mobile-friendly setup interface |
| Requirements | `core/versions/v1.1.0/setup-requirements.txt` | - | Python dependencies (FastAPI, qrcode, etc.) |

---

## Complete Installation Example

```bash
# Step 1: Fresh installation (first time only)
curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh \
  | bash -s -- --auto

# Wait for installation to complete (takes 5-10 minutes)
# Installation is done when you see:
#   ✅ TrustNet v1.0.0 Setup Complete

# Step 2: Deploy v1.1.0 features
cd ~/GitProjects/TrustNet/trustnet-wip
bash tools/deploy-v1.1.0-components.sh

# Wait for deployment (takes 2-3 minutes)
# Deployment is done when you see:
#   ✅ v1.1.0 Component Deployment Complete

# Step 3: Verify everything works
echo "=== Testing Base Installation ==="
curl https://trustnet.local/status

echo "=== Testing v1.1.0 Features ==="
curl http://trustnet.local:8001/api/setup/info
```

---

## File Locations & Persistence

### Local Host
```
~/.trustnet/
├── cache/              # ISO cache (PERSISTENT)
├── logs/              # Installation logs
└── data/              # Node data

~/vms/trustnet/
├── trustnet.qcow2     # System disk
├── api/               # v1.1.0 files (copied by deploy script)
└── web/               # v1.1.0 UI files
```

### VM Filesystem
```
/opt/trustnet/
├── api/               # FastAPI server
├── web/               # Setup UI
└── blockchain/        # Cosmos SDK data
```

---

## Key Points

1. **Never delete `~/.trustnet/`** except for fresh installation - it contains the ISO cache
2. **Base installer is immutable** - no modifications to `core` branch scripts
3. **v1.1.0 deployment is separate** - runs only after base installation completes
4. **Cache is persistent** - ISO only downloaded once, then reused
5. **VM persists** - survives reboots unless `~/vms/trustnet/` is deleted

---

## Troubleshooting

### Base Installation Hangs
- Check network: `ping -c1 dl-cdn.alpinelinux.org`
- Check disk space: `df -h ~/.trustnet/`
- Check VM logs: `cat ~/.trustnet/logs/install-*.log`

### v1.1.0 Deployment Fails
- VM must be running: `ssh -p 2223 warden@trustnet.local "echo OK"`
- Check base installation completed: `curl https://trustnet.local/status` (should return 200)
- Check SSH key: `ls ~/.ssh/factory-foreman`

### Setup API Not Responding
- Check service: `ssh -p 2223 warden@trustnet.local "systemctl status trustnet-setup"`
- Check port: `ssh -p 2223 warden@trustnet.local "ss -tlnp | grep 8001"`
- View logs: `ssh -p 2223 warden@trustnet.local "journalctl -u trustnet-setup -n 20"`

---

## Environment Variables

Optional configuration (in `~/.bashrc` or before running):
```bash
# Use specific branch (default: main)
export TRUSTNET_BRANCH=main

# Fresh installation (delete existing)
export TRUSTNET_FRESH=1

# Alpine architecture (default: x86_64)
export TRUSTNET_ARCH=x86_64
```

---

**Status**: ✅ Production Ready  
**Last Updated**: March 20, 2026  
**Maintainer**: TrustNet Core Team

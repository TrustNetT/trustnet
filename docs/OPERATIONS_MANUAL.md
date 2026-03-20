# TrustNet Operations Manual

**Version**: 1.0  
**Date**: February 2, 2026  
**Status**: Living Document

---

## Table of Contents

1. [The Warden - Understanding Your Role](#the-warden---understanding-your-role)
2. [Node Architecture](#node-architecture)
3. [Accessing Your Node](#accessing-your-node)
4. [Daily Operations](#daily-operations)
5. [Disk Management](#disk-management)
6. [Module Management](#module-management)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)
10. [Emergency Procedures](#emergency-procedures)

---

## The Warden - Understanding Your Role

### Etymology & Meaning

The TrustNet user is called **"warden"** for a reason deeply connected to the project's mission.

**Warden** (noun):
- A custodian, defender, or guardian
- A watchman or protector
- A chief or head official responsible for security and order

**Etymology**: 
- Derived from Old French *garder* (to guard, watch, keep)
- Germanic root: *wartēn* (to watch or protect)
- Etymologically identical to "guardian"
- Related to Anglo-Saxon "ward" (to guard, protect)

**Historical Usage**:
- Prison Warden - Guardian of inmates
- Game Warden - Protector of wildlife
- Church Warden - Guardian of sacred spaces
- Warden of the Mint - Chief custodian of currency

### Why "Warden" for TrustNet?

In the context of TrustNet, a **warden** is:

1. **Guardian of Identity**: You protect the integrity of digital identities on the blockchain
2. **Custodian of Trust**: Your node validates transactions and maintains the trust network
3. **Defender of Truth**: You ensure the blockchain remains honest and tamper-proof
4. **Watchman of Keys**: You safeguard cryptographic keys and credentials
5. **Protector of Reputation**: Your node maintains the reputation scoring system

**You are not just a "user" - you are a warden of the TrustNet.**

Your responsibilities:
- ✅ Maintain node uptime and security
- ✅ Validate transactions honestly
- ✅ Protect private keys and sensitive data
- ✅ Monitor node health and performance
- ✅ Update software to patch vulnerabilities
- ✅ Participate in network consensus

**Think of yourself as a guardian in a watchtower**, maintaining the integrity of a decentralized network of trust.

---

## Node Architecture

### Disk Structure

TrustNet uses a **dual-disk architecture**:

```
┌─────────────────────────────────────────┐
│ MAIN DISK (trustnet.qcow2 - 5GB)       │
│ Production OS - Always Clean            │
├─────────────────────────────────────────┤
│ /dev/vda1 - Alpine Linux 3.21          │
│ ├── /etc/         System configs       │
│ ├── /usr/         System binaries      │
│ ├── /var/www/html/ Web UI + modules    │
│ ├── /opt/trustnet/ Blockchain node     │
│ └── /home/warden/  Your data           │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DEV DISK (trustnet-dev-tools.qcow2)    │
│ Development Tools - Optional            │
├─────────────────────────────────────────┤
│ /dev/vdb1 - 10GB Development Tools     │
│ └── /opt/dev-tools/                    │
│     ├── bin/      Go, Git, Make, GCC   │
│     ├── lib/      Development libs     │
│     ├── src/      Go source cache      │
│     └── pkg/      Go packages          │
└─────────────────────────────────────────┘
```

### Network Configuration

**IPv6 Addressing**: TrustNet uses IPv6 exclusively for modern, secure networking.

**Services**:
| Service | Access | Description |
|---------|--------|-------------|
| SSH | `ssh trustnet` | Admin access (key-based auth) |
| Web UI | `https://trustnet.local` | Caddy web server (HTTPS) |
| API | Internal | Cosmos SDK REST API |
| P2P | Automatic | Tendermint P2P network |
| RPC | Internal | Tendermint RPC |

**Note**: The installer configured all networking automatically. You don't need to manage ports or IP addresses.

### Services

Running services on your TrustNet node:

```bash
# Check all services
doas rc-status

# Key services:
- sshd          SSH access
- caddy         Web server (HTTPS)
- trustnetd     Blockchain node
- networking    Network configuration
```

---

## Accessing Your Node

### SSH Access

The installer has configured everything for you. Simply use:

```bash
# Access your TrustNet node
ssh trustnet

# That's it! No passwords, ports, or IP addresses needed.
```

The installer set up:
- SSH key authentication (stored in `~/.ssh/trustnet-warden`)
- Hostname resolution (`trustnet.local`)
- SSH config entry (in `~/.ssh/config`)
- IPv6 networking

**First Time**: The installer already created a secure password for the `warden` user. If you want to change it:

```bash
ssh trustnet
passwd
# Enter current password: [provided by installer]
# Enter new password: [your-secure-password]
```

### Web UI Access

Open your browser and go to:

```
https://trustnet.local
```

**That's it!** The installer has already:
- Configured the hostname (`trustnet.local`)
- Installed proper SSL certificates
- Set up IPv6 networking
- Configured Caddy web server

**No port numbers, no IP addresses, no certificate warnings.**

### Privilege Escalation

TrustNet uses **`doas`** (OpenBSD's secure alternative to `sudo`):

```bash
# Run command as root
doas apk update

# Edit system file
doas vi /etc/caddy/Caddyfile

# Restart service
doas rc-service caddy restart

# Get root shell (use sparingly!)
doas sh
```

**Why `doas` instead of `sudo`?**
- Simpler configuration (fewer security holes)
- Smaller codebase (easier to audit)
- Alpine Linux standard
- More secure by default

### File System Navigation

**Important Directories**:

```bash
# Web UI and modules
cd /var/www/html/
ls modules/                    # Installed modules
ls static/                     # Static assets

# Blockchain data
cd /opt/trustnet/
ls data/                       # Blockchain database
ls config/                     # Node configuration

# System configs
cd /etc/
cat caddy/Caddyfile           # Web server config
cat trustnet/config.toml      # Node config

# Logs
cd /var/log/
tail -f caddy/access.log      # Web access
tail -f trustnet/node.log     # Blockchain logs

# Your home
cd ~
cd /home/warden/
```

---

## Daily Operations

### Starting the Node

**Production Mode** (minimal, 5GB):
```bash
cd ~/TrustNet/  # Or wherever VM disk is
./start-trustnet.sh

# VM starts with main disk only
# No development tools loaded
```

**Development Mode** (with dev tools, 15GB):
```bash
./start-trustnet.sh --dev

# VM starts with both disks
# /opt/dev-tools/ auto-mounted
# Go, Git, Make, GCC available
```

### Stopping the Node

**Graceful Shutdown** (recommended):
```bash
# From host machine
ssh trustnet doas poweroff

# Node saves state and shuts down cleanly
```

**From Host** (if VM is unresponsive):
```bash
# Find QEMU process
ps aux | grep qemu

# Send shutdown signal
kill -TERM [qemu-pid]

# Force kill (last resort)
kill -9 [qemu-pid]
```

### Checking Node Status

**Check Node Status**:
```bash
# SSH to node and check services
ssh trustnet doas rc-status

# Check specific service
ssh trustnet doas rc-service trustnetd status
ssh trustnet doas rc-service caddy status

# Check blockchain sync
ssh trustnet trustnetd status

# Check uptime
ssh trustnet uptime
```

**From Host Browser**:
```bash
# Open web UI to see status dashboard
https://trustnet.local
```

### Viewing Logs

**Real-time Monitoring**:
```bash
# Caddy web server
ssh trustnet doas tail -f /var/log/caddy/access.log

# Blockchain node
ssh trustnet doas tail -f /var/log/trustnet/node.log

# System messages
ssh trustnet doas tail -f /var/log/messages

# All logs simultaneously
ssh trustnet doas tail -f /var/log/*.log
```

**Historical Logs**:
```bash
# Search logs
doas grep "ERROR" /var/log/trustnet/node.log

# Last 100 lines
doas tail -n 100 /var/log/caddy/access.log

# Logs from last hour
doas journalctl --since "1 hour ago"
```

---

## Disk Management

### Understanding Your Disks

**Main Disk** (`trustnet.qcow2`):
- Size: 5GB
- Purpose: Production OS and blockchain
- **Never contains dev tools**
- Always production-ready
- Used in all modes

**Dev Disk** (`trustnet-dev-tools.qcow2`):
- Size: 10GB
- Purpose: Development tools (Go, Ignite, etc.)
- Optional - attach when needed
- Can be shared across multiple VMs
- Not needed for running modules

### Creating a Dev Disk

**First Time Setup**:
```bash
cd ~/TrustNet/  # Or wherever your VM disks are

# Create dev tools disk
./tools/create-dev-disk.sh

# Output:
Creating dev tools disk (10G)...
Formatting disk...
Installing Go 1.25.6...
Installing Ignite CLI...
Installing build tools...
✅ Dev disk created: trustnet-dev-tools.qcow2
Attach to VM with: ./start-trustnet.sh --dev
```

### Attaching/Detaching Dev Disk

**Start with Dev Disk**:
```bash
# Start VM in development mode
./start-trustnet.sh --dev

# Verify dev tools mounted
ssh trustnet ls /opt/dev-tools/    # Should see bin/, lib/, etc.
ssh trustnet which go                # /opt/dev-tools/go/bin/go
ssh trustnet go version              # go version go1.25.6 linux/amd64
```

**Start without Dev Disk**:
```bash
# Start VM in production mode
./start-trustnet.sh

# Verify no dev tools
ssh trustnet ls /opt/dev-tools/     # Directory doesn't exist
ssh trustnet which go                # go: not found
```

**Switching Modes**:
```bash
# Currently running with dev disk, want production:
ssh trustnet doas poweroff           # Stop VM
./start-trustnet.sh                  # Start without dev disk

# Currently running production, want dev tools:
ssh trustnet doas poweroff           # Stop VM
./start-trustnet.sh --dev            # Start with dev disk
```

### Disk Space Management

**Check Disk Usage**:
```bash
# Inside VM
df -h

# Expected output (production mode):
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda1       4.9G  2.1G  2.6G  45% /

# With dev disk attached:
/dev/vda1       4.9G  2.1G  2.6G  45% /
/dev/vdb1       9.8G  3.2G  6.1G  35% /opt/dev-tools
```

**Clean Up Space**:
```bash
# Remove old logs
doas rm -f /var/log/*.log.old

# Clean package cache
doas apk cache clean

# Remove temporary files
doas rm -rf /tmp/*

# Vacuum blockchain database (if needed)
cd /opt/trustnet/
doas trustnetd unsafe-reset-all  # ⚠️ DESTRUCTIVE - removes all blockchain data!
```

### Backup & Restore

**Backup Main Disk**:
```bash
# Stop VM first
ssh trustnet doas poweroff

# Compress and backup
cd ~/TrustNet/
tar -czf trustnet-backup-$(date +%Y%m%d).tar.gz trustnet.qcow2

# Or use qemu-img
qemu-img convert -O qcow2 -c trustnet.qcow2 trustnet-backup.qcow2
```

**Restore from Backup**:
```bash
# Stop VM
ssh trustnet doas poweroff

# Restore
cd ~/TrustNet/
cp trustnet.qcow2 trustnet-broken.qcow2  # Save broken version
cp trustnet-backup.qcow2 trustnet.qcow2

# Start VM
./start-trustnet.sh
```

---

## Module Management

### Viewing Installed Modules

**List Modules**:
```bash
# Inside VM
ls /var/www/html/modules/

# Expected output:
identity/       # Identity registration
transactions/   # Transaction viewer
keys/           # Key management
```

**Check Module Status**:
```bash
# Module info
cat /var/www/html/modules/identity/module.json

# Module service status
doas rc-service identity-service status

# Module logs
doas tail -f /var/log/modules/identity.log
```

### Installing a Module

**From Host** (recommended):
```bash
cd ~/GitProjects/TrustNet/trustnet-wip/

# Install module
./tools/module-install.sh identity

# Process:
1. Builds module on host (if needed)
2. Syncs files to VM via rsync
3. Registers module in VM
4. Starts module service
5. Updates Caddy routes
```

**From VM** (if module already built):
```bash
# Download module
cd /tmp/
wget https://trustnet.example.com/modules/identity-v1.0.tar.gz
tar -xzf identity-v1.0.tar.gz

# Install
doas /opt/trustnet/tools/install-module.sh identity/

# Verify
ls /var/www/html/modules/identity/
doas rc-service identity-service status
```

### Removing a Module

**Safe Removal**:
```bash
# From host
./tools/module-remove.sh identity

# Or from VM
doas /opt/trustnet/tools/remove-module.sh identity

# Process:
1. Stops module service
2. Removes files from /var/www/html/modules/
3. Removes Caddy routes
4. Unregisters from module registry
```

**Force Removal** (if broken):
```bash
# Inside VM
doas rc-service identity-service stop
doas rm -rf /var/www/html/modules/identity/
doas rc-update del identity-service
doas rc-service caddy restart
```

### Updating a Module

```bash
# From host
cd ~/GitProjects/TrustNet/trustnet-wip/

# Pull latest module code
git pull origin main

# Rebuild and deploy
./tools/module-update.sh identity

# Or manually:
./tools/module-remove.sh identity
./tools/module-install.sh identity
```

---

## Monitoring & Maintenance

### Health Checks

**Automated Health Check Script**:
```bash
#!/bin/bash
# Save as: check-health.sh

echo "=== TrustNet Health Check ==="
echo

# SSH accessible?
echo -n "SSH: "
ssh -o ConnectTimeout=5 trustnet 'echo OK' 2>/dev/null || echo "FAILED"

# Web UI accessible?
echo -n "Web UI: "
curl -s -o /dev/null -w "%{http_code}" https://trustnet.local | grep -q 200 && echo "OK" || echo "FAILED"

# Blockchain sync status
echo -n "Blockchain: "
ssh trustnet 'curl -s http://localhost:26657/status | jq -r .result.sync_info.catching_up' 2>/dev/null | grep -q false && echo "SYNCED" || echo "SYNCING"

# Disk space
echo -n "Disk Space: "
ssh trustnet "df -h / | tail -1 | awk '{print \$5}'" 2>/dev/null

echo
echo "=== End Health Check ==="
```

**Run Health Check**:
```bash
chmod +x check-health.sh
./check-health.sh

# Expected output:
=== TrustNet Health Check ===

SSH: OK
Web UI: OK
Blockchain: SYNCED
Disk Space: 45%

=== End Health Check ===
```

### Performance Monitoring

**Inside VM**:
```bash
# CPU and memory
top

# Disk I/O
doas iostat -x 1

# Network
doas iftop

# Blockchain stats
curl http://localhost:26657/status | jq '.result.sync_info'
```

**From Host**:
```bash
# QEMU process resources
ps aux | grep qemu

# VM disk I/O
iostat -x 1 | grep qemu

# Network usage
iftop -i [bridge-interface]
```

### Regular Maintenance Tasks

**Daily**:
- [ ] Check node is synced: `curl http://localhost:26657/status | jq .result.sync_info.catching_up`
- [ ] Check disk space: `df -h /`
- [ ] Review logs for errors: `doas grep ERROR /var/log/trustnet/node.log`

**Weekly**:
- [ ] Update packages: `doas apk update && doas apk upgrade`
- [ ] Backup main disk: `tar -czf backup.tar.gz trustnet.qcow2`
- [ ] Check module updates: `git pull origin main`
- [ ] Review web access logs: `doas tail -100 /var/log/caddy/access.log`

**Monthly**:
- [ ] Rotate logs: `doas logrotate /etc/logrotate.conf`
- [ ] Verify backups: Test restore from backup
- [ ] Security audit: Check for unauthorized SSH keys
- [ ] Performance review: Analyze metrics, optimize if needed

---

## Troubleshooting

### Node Won't Start

**Symptoms**: VM doesn't boot or hangs

**Diagnosis**:
```bash
# Check if disk image corrupted
qemu-img check trustnet.qcow2

# Check if port already in use
lsof -i :2223  # SSH port
lsof -i :8443  # HTTPS port

# Check QEMU logs
journalctl -u qemu-trustnet  # If running as service
```

**Solutions**:
```bash
# Repair disk
qemu-img check -r all trustnet.qcow2

# Kill process using port
kill [pid-from-lsof]

# Restore from backup
cp trustnet-backup.qcow2 trustnet.qcow2
./start-trustnet.sh
```

### Can't SSH to Node

**Symptoms**: Connection refused or timeout

**Diagnosis**:
```bash
# Is VM running?
ps aux | grep qemu

# Is port forwarded correctly?
netstat -tuln | grep 2223

# Is sshd running in VM?
# (need console access or boot in debug mode)
```

**Solutions**:
```bash
# Restart VM
./stop-trustnet.sh
./start-trustnet.sh

# Check SSH config in VM (via console)
# Boot with -nographic, login, check:
doas rc-service sshd status
doas rc-service sshd restart
```

### Web UI Not Loading

**Symptoms**: Browser can't connect to https://127.0.0.1:8443

**Diagnosis**:
```bash
# Is Caddy running?
ssh warden@127.0.0.1 -p 2223 'doas rc-service caddy status'

# Check Caddy logs
ssh warden@127.0.0.1 -p 2223 'doas tail -50 /var/log/caddy/error.log'

# Test from inside VM
ssh warden@127.0.0.1 -p 2223 'curl -k https://localhost'
```

**Solutions**:
```bash
# Restart Caddy
ssh warden@127.0.0.1 -p 2223 'doas rc-service caddy restart'

# Check Caddyfile syntax
ssh warden@127.0.0.1 -p 2223 'doas caddy validate --config /etc/caddy/Caddyfile'

# Rebuild Caddy config
ssh warden@127.0.0.1 -p 2223 'doas caddy reload --config /etc/caddy/Caddyfile'
```

### Dev Disk Won't Mount

**Symptoms**: Started with `--dev` but no `/opt/dev-tools/`

**Diagnosis**:
```bash
# Inside VM
doas fdisk -l  # Check if /dev/vdb exists

# Check mount status
mount | grep dev-tools

# Check dmesg for errors
dmesg | tail -50
```

**Solutions**:
```bash
# Manual mount
doas mkdir -p /opt/dev-tools
doas mount /dev/vdb /opt/dev-tools

# If filesystem corrupted
doas fsck.ext4 /dev/vdb

# Recreate dev disk
./tools/create-dev-disk.sh
./start-trustnet.sh --dev
```

### Blockchain Not Syncing

**Symptoms**: Node stuck, not catching up

**Diagnosis**:
```bash
# Check sync status
curl http://localhost:26657/status | jq '.result.sync_info'

# Check peers
curl http://localhost:26657/net_info | jq '.result.n_peers'

# Check logs
doas tail -f /var/log/trustnet/node.log
```

**Solutions**:
```bash
# Restart node
doas rc-service trustnetd restart

# Reset if corrupted (⚠️ DESTRUCTIVE)
doas trustnetd unsafe-reset-all
doas rc-service trustnetd start

# Check network connectivity
ping 8.8.8.8
curl http://google.com
```

---

## Security Best Practices

### SSH Security

**Change Default Password** (Critical):
```bash
# First login
ssh warden@127.0.0.1 -p 2223
passwd
# Old: warden
# New: [strong-password]
```

**Use SSH Keys** (Recommended):
```bash
# Generate key on host
ssh-keygen -t ed25519 -f ~/.ssh/trustnet-warden

# Copy to VM
ssh-copy-id -i ~/.ssh/trustnet-warden.pub warden@127.0.0.1 -p 2223

# Disable password auth in VM
ssh warden@127.0.0.1 -p 2223
doas vi /etc/ssh/sshd_config
# Set: PasswordAuthentication no
doas rc-service sshd restart
```

**Limit SSH Access**:
```bash
# Only allow from specific IPs
doas vi /etc/ssh/sshd_config
# Add: AllowUsers warden@127.0.0.1 warden@192.168.1.0/24

# Disable root login
# Set: PermitRootLogin no

doas rc-service sshd restart
```

### Firewall Configuration

**Inside VM**:
```bash
# Install firewall
doas apk add iptables iptables-openrc

# Basic rules
doas iptables -A INPUT -i lo -j ACCEPT
doas iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
doas iptables -A INPUT -p tcp --dport 22 -j ACCEPT
doas iptables -A INPUT -p tcp --dport 443 -j ACCEPT
doas iptables -A INPUT -p tcp --dport 26656 -j ACCEPT
doas iptables -A INPUT -j DROP

# Save rules
doas rc-update add iptables
doas /etc/init.d/iptables save
```

### File Permissions

**Protect Sensitive Files**:
```bash
# Private keys
chmod 600 ~/.ssh/*
chmod 700 ~/.ssh/

# Config files with secrets
doas chmod 600 /etc/trustnet/priv_validator_key.json
doas chmod 600 /etc/trustnet/node_key.json

# Web directory
doas chown -R warden:warden /var/www/html/
chmod 755 /var/www/html/
```

### Audit Logging

**Enable Audit Logs**:
```bash
# Install auditd
doas apk add audit

# Configure audit rules
doas vi /etc/audit/audit.rules
# Add:
-w /etc/trustnet/ -p wa -k trustnet-config
-w /var/www/html/ -p wa -k web-changes
-w /home/warden/.ssh/ -p wa -k ssh-keys

# Start auditd
doas rc-service auditd start
doas rc-update add auditd
```

---

## Emergency Procedures

### Node Compromised

**If you suspect unauthorized access**:

1. **Immediate Actions**:
   ```bash
   # Disconnect from network
   ssh warden@127.0.0.1 -p 2223 'doas ip link set eth0 down'
   
   # Or stop VM entirely
   kill [qemu-pid]
   ```

2. **Investigation**:
   ```bash
   # Check recent logins
   last -20
   
   # Check unauthorized SSH keys
   cat ~/.ssh/authorized_keys
   
   # Check running processes
   ps aux
   
   # Check network connections
   doas netstat -tulpn
   
   # Check recent file modifications
   find / -mtime -1 -type f
   ```

3. **Recovery**:
   ```bash
   # Restore from clean backup
   cp trustnet-backup-[date].qcow2 trustnet.qcow2
   
   # Regenerate all keys
   ./tools/regenerate-keys.sh
   
   # Change all passwords
   passwd
   
   # Review and harden security
   # (see Security Best Practices section)
   ```

### Disk Full

**Immediate Recovery**:
```bash
# Free up space quickly
doas rm -f /var/log/*.log.old
doas rm -rf /tmp/*
doas apk cache clean

# Check what's using space
doas du -sh /* | sort -h

# If blockchain data too large
cd /opt/trustnet/
doas trustnetd unsafe-reset-all  # ⚠️ Deletes all blockchain data
```

### Corrupted Blockchain

**Symptoms**: Node errors, can't sync, database errors

**Recovery**:
```bash
# Stop node
doas rc-service trustnetd stop

# Backup current state
doas tar -czf ~/blockchain-backup.tar.gz /opt/trustnet/data/

# Reset blockchain
doas trustnetd unsafe-reset-all

# Or restore from snapshot
wget https://trustnet.example.com/snapshots/latest.tar.gz
doas tar -xzf latest.tar.gz -C /opt/trustnet/data/

# Restart node
doas rc-service trustnetd start

# Monitor sync
curl http://localhost:26657/status | jq '.result.sync_info'
```

### Lost Access (Forgot Password)

**Recovery via Console**:
```bash
# Start VM with console access
./start-trustnet.sh --console

# At boot, press 'e' in GRUB
# Add to kernel line: single
# Boot into single-user mode

# Reset password
passwd warden

# Reboot normally
reboot
```

---

## Appendix

### Quick Reference Commands

```bash
# === Access ===
ssh trustnet                           # SSH to node
https://trustnet.local                 # Web UI

# === Start/Stop ===
./start-trustnet.sh                    # Production mode
./start-trustnet.sh --dev              # Development mode
ssh trustnet doas poweroff             # Stop node

# === Status ===
ssh trustnet doas rc-status            # All services
ssh trustnet trustnetd status          # Blockchain status
ssh trustnet uptime                    # How long running

# === Logs ===
ssh trustnet doas tail -f /var/log/trustnet/node.log   # Blockchain
ssh trustnet doas tail -f /var/log/caddy/access.log    # Web access
ssh trustnet doas tail -f /var/log/messages            # System

# === Disk ===
ssh trustnet df -h                     # Disk usage
qemu-img check trustnet.qcow2          # Check disk health (from host)

# === Modules ===
ssh trustnet ls /var/www/html/modules/ # List installed
./tools/module-install.sh [name]       # Install module
./tools/module-remove.sh [name]        # Remove module
```

### Useful Aliases

Add to `~/.bashrc` inside VM:

```bash
# Logs
alias logs-node='doas tail -f /var/log/trustnet/node.log'
alias logs-web='doas tail -f /var/log/caddy/access.log'
alias logs-all='doas tail -f /var/log/*.log'

# Status
alias status='doas rc-status'
alias node-status='trustnetd status'
alias sync-status='curl -s http://localhost:26657/status | jq .result.sync_info'

# Services
alias restart-node='doas rc-service trustnetd restart'
alias restart-web='doas rc-service caddy restart'

# Disk
alias disk='df -h'
alias diskusage='doas du -sh /* | sort -h'
```

### Environment Variables

```bash
# Add to ~/.profile inside VM
export TRUSTNET_HOME="/opt/trustnet"
export TRUSTNET_CONFIG="$TRUSTNET_HOME/config/config.toml"
export TRUSTNET_DATA="$TRUSTNET_HOME/data"
export PATH="$PATH:$TRUSTNET_HOME/bin"

# If dev disk mounted
if [ -d /opt/dev-tools ]; then
    source /opt/dev-tools/setup-env.sh
fi
```

---

**End of Operations Manual**

*This is a living document. Update as new features are added or procedures change.*

**Last Updated**: February 2, 2026  
**Version**: 1.0  
**Maintainer**: TrustNet Warden (you!)

# TrustNet Registry Operations Manual

**Version**: 1.0  
**Date**: February 2, 2026  
**Status**: Living Document  
**Node Type**: Registry Node

---

## Table of Contents

1. [The Keeper - Understanding Your Role](#the-keeper---understanding-your-role)
2. [Registry Node Architecture](#registry-node-architecture)
3. [Accessing Your Registry Node](#accessing-your-registry-node)
4. [Daily Operations](#daily-operations)
5. [Registry Management](#registry-management)
6. [Data Synchronization](#data-synchronization)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)
10. [Emergency Procedures](#emergency-procedures)

---

## The Keeper - Understanding Your Role

### Etymology & Meaning

The TrustNet registry operator is called **"keeper"** - a role with deep historical significance.

**Keeper** (noun):
- One who maintains, preserves, or guards something
- A custodian or caretaker
- One who keeps records or maintains order
- A protector or guardian of important resources

**Etymology**:
- From Middle English *kepen* (to observe, guard, take care of)
- Old English *cēpan* (to keep, guard, look out for)
- Related to Germanic *kōpōn* (to look, watch)

**Historical Usage**:
- **Bookkeeper** - Keeper of financial records
- **Shopkeeper** - Keeper of goods and commerce
- **Gatekeeper** - Keeper of entry points, controller of access
- **Timekeeper** - Keeper of accurate time
- **Recordkeeper** - Keeper of historical documentation
- **Zookeeper** - Keeper of animals and habitats
- **Lighthouse Keeper** - Keeper of navigational safety

### Why "Keeper" for TrustNet Registry?

In the context of TrustNet, a **keeper** is:

1. **Keeper of Records**: You maintain the authoritative registry of all identities
2. **Keeper of History**: Your node preserves the complete transaction history
3. **Keeper of Truth**: You provide verified lookups and validation services
4. **Keeper of Access**: You control who can query and access registry data
5. **Keeper of Continuity**: You ensure the registry remains available and consistent

**You are not just running a server - you are a keeper of the TrustNet registry.**

Your responsibilities:
- ✅ Maintain registry uptime and availability
- ✅ Preserve complete historical records
- ✅ Provide fast, accurate lookup services
- ✅ Synchronize with other registry nodes
- ✅ Validate registration requests
- ✅ Archive and backup critical data
- ✅ Protect registry integrity from corruption

**Think of yourself as a librarian**, maintaining a vast catalog of identities, ensuring every record is preserved, accessible, and accurate.

### Keeper vs Warden: Understanding the Difference

**Warden** (Regular TrustNet Node):
- Participates in blockchain consensus
- Validates transactions locally
- Protects the integrity of the network
- Runs blockchain node software

**Keeper** (Registry Node):
- Maintains centralized registry database
- Provides lookup and query services
- Archives complete transaction history
- Serves API requests for identity resolution
- Does not participate in blockchain consensus (reads only)

**Key Distinction**: Wardens **validate and create** blocks. Keepers **record and serve** information.

---

## Registry Node Architecture

### Disk Structure

Registry nodes use a **dual-disk architecture** similar to TrustNet nodes:

```
┌─────────────────────────────────────────┐
│ MAIN DISK (registry.qcow2 - 10GB)      │
│ Production OS - Registry Database       │
├─────────────────────────────────────────┤
│ /dev/vda1 - Alpine Linux 3.21          │
│ ├── /etc/           System configs     │
│ ├── /usr/           System binaries    │
│ ├── /var/www/html/  Web UI + API       │
│ ├── /opt/registry/  Registry database  │
│ └── /home/keeper/   Your data          │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DATA DISK (registry-data.qcow2 - 50GB) │
│ Registry Data - Expandable              │
├─────────────────────────────────────────┤
│ /dev/vdb1 - Registry Storage            │
│ └── /opt/registry/data/                │
│     ├── identities/  Identity records  │
│     ├── transactions/ TX history       │
│     ├── snapshots/   Periodic backups  │
│     └── indices/     Search indices    │
└─────────────────────────────────────────┘
```

**Why Separate Data Disk?**
- Registry grows over time (identities + transactions)
- Easy to expand storage without rebuilding node
- Backup data disk independently
- Faster disk I/O (dedicated disk for database)

### Network Configuration

**IPv6 Addressing**: Registry nodes use IPv6 exclusively.

**Services**:
| Service | Access | Description |
|---------|--------|-------------|
| SSH | `ssh registry` | Admin access (key-based auth) |
| Web UI | `https://registry.local` | Registry dashboard |
| API | `https://registry.local/api` | REST API for queries |
| Metrics | Internal | Prometheus metrics |
| Sync | Automatic | Inter-registry replication |

**Note**: The installer configured all networking automatically.

### Services

Running services on your Registry node:

```bash
# Check all services
doas rc-status

# Key services:
- sshd          SSH access
- caddy         Web server (HTTPS)
- registryd     Registry daemon
- postgres      Database (if using PostgreSQL)
- redis         Cache layer (optional)
- sync-daemon   Inter-registry sync
```

---

## Accessing Your Registry Node

### SSH Access

The installer has configured everything for you. Simply use:

```bash
# Access your Registry node
ssh registry

# That's it! No passwords, ports, or IP addresses needed.
```

The installer set up:
- SSH key authentication (stored in `~/.ssh/registry-keeper`)
- Hostname resolution (`registry.local`)
- SSH config entry (in `~/.ssh/config`)
- IPv6 networking

**First Time**: The installer created a secure password for the `keeper` user. If you want to change it:

```bash
ssh registry
passwd
# Enter current password: [provided by installer]
# Enter new password: [your-secure-password]
```

### Web UI Access

Open your browser and go to:

```
https://registry.local
```

**That's it!** The installer has already:
- Configured the hostname (`registry.local`)
- Installed proper SSL certificates
- Set up IPv6 networking
- Configured Caddy web server

**No port numbers, no IP addresses, no certificate warnings.**

### API Access

**REST API Endpoint**:
```bash
# From host machine or any network client
curl https://registry.local/api/v1/identities

# Query specific identity
curl https://registry.local/api/v1/identity/did:trust:abc123

# Search identities
curl https://registry.local/api/v1/search?name=alice

# Get registry statistics
curl https://registry.local/api/v1/stats
```

**API Authentication** (if enabled):
```bash
# Use API key
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://registry.local/api/v1/identities

# Or use client certificate (mTLS)
curl --cert client.crt --key client.key \
  https://registry.local/api/v1/identities
```

### Privilege Escalation

Registry nodes use **`doas`** (OpenBSD's secure alternative to `sudo`):

```bash
# Run command as root
doas apk update

# Edit system file
doas vi /etc/caddy/Caddyfile

# Restart service
doas rc-service registryd restart

# Get root shell (use sparingly!)
doas sh
```

### File System Navigation

**Important Directories**:

```bash
# Registry database and data
cd /opt/registry/
ls data/identities/           # Identity records
ls data/transactions/         # Transaction history
ls data/snapshots/            # Periodic backups

# Web UI and API
cd /var/www/html/
ls api/                       # API endpoints
ls dashboard/                 # Web dashboard

# System configs
cd /etc/
cat caddy/Caddyfile          # Web server config
cat registry/config.toml     # Registry config

# Logs
cd /var/log/
tail -f caddy/access.log     # Web access
tail -f registry/registry.log # Registry operations
tail -f registry/sync.log    # Sync activity

# Your home
cd ~
cd /home/keeper/
```

---

## Daily Operations

### Starting the Registry Node

**Production Mode** (standard):
```bash
cd ~/Registry/  # Or wherever VM disk is
./start-registry.sh

# Registry starts with both disks
# Main disk: OS and services
# Data disk: Registry database
```

**Maintenance Mode** (read-only):
```bash
./start-registry.sh --read-only

# Registry serves queries but rejects writes
# Use for maintenance or when syncing
```

### Stopping the Registry Node

**Graceful Shutdown** (recommended):
```bash
# From host machine
ssh registry doas poweroff

# Registry saves state and shuts down cleanly
# Flushes all pending writes to disk
```

**Emergency Stop** (if unresponsive):
```bash
# Find QEMU process
ps aux | grep registry

# Send shutdown signal
kill -TERM [qemu-pid]

# Force kill (last resort - may corrupt data)
kill -9 [qemu-pid]
```

### Checking Registry Status

**Check Services**:
```bash
# SSH to node and check all services
ssh registry doas rc-status

# Check registry daemon
ssh registry doas rc-service registryd status

# Check database
ssh registry doas rc-service postgres status  # If using PostgreSQL

# Check uptime
ssh registry uptime
```

**Check Registry Health**:
```bash
# Registry statistics
ssh registry registryd stats

# Database size
ssh registry du -sh /opt/registry/data/

# Number of identities
ssh registry "ls /opt/registry/data/identities/ | wc -l"

# Check sync status
ssh registry registryd sync status
```

**From Web Dashboard**:
```bash
# Open dashboard to see real-time stats
https://registry.local

# Shows:
- Total identities registered
- Total transactions processed
- Sync status with other registries
- Disk usage
- API request rate
- Uptime
```

### Viewing Logs

**Real-time Monitoring**:
```bash
# Registry operations
ssh registry doas tail -f /var/log/registry/registry.log

# Sync activity
ssh registry doas tail -f /var/log/registry/sync.log

# API access
ssh registry doas tail -f /var/log/caddy/access.log

# Database queries (if enabled)
ssh registry doas tail -f /var/log/postgres/postgresql.log

# All logs simultaneously
ssh registry doas tail -f /var/log/registry/*.log
```

**Historical Logs**:
```bash
# Search logs
ssh registry doas grep "ERROR" /var/log/registry/registry.log

# Last 100 lines
ssh registry doas tail -n 100 /var/log/registry/registry.log

# Logs from last hour
ssh registry doas journalctl --since "1 hour ago"

# Logs for specific identity
ssh registry doas grep "did:trust:abc123" /var/log/registry/registry.log
```

---

## Registry Management

### Understanding Registry Data

**Identity Records**:
```bash
# Inside registry node
ssh registry
cd /opt/registry/data/identities/

# List all identities
ls -la

# View specific identity
cat did:trust:abc123.json

# Example identity record:
{
  "did": "did:trust:abc123",
  "name": "Alice",
  "email": "alice@example.com",
  "public_key": "04a1b2c3...",
  "created_at": "2026-02-01T10:30:00Z",
  "updated_at": "2026-02-01T10:30:00Z",
  "reputation_score": 100,
  "verified": true,
  "metadata": {...}
}
```

**Transaction History**:
```bash
# Transaction logs
cd /opt/registry/data/transactions/

# Organized by date
ls 2026/
ls 2026/02/
ls 2026/02/01/

# View transaction
cat 2026/02/01/tx-abc123.json

# Example transaction:
{
  "tx_id": "tx-abc123",
  "type": "identity_registration",
  "identity": "did:trust:abc123",
  "timestamp": "2026-02-01T10:30:00Z",
  "block_height": 12345,
  "gas_used": 50000,
  "status": "confirmed"
}
```

### Registry Queries

**Command-Line Queries**:
```bash
# Find identity by DID
ssh registry registryd query identity did:trust:abc123

# Search by name
ssh registry registryd query name alice

# Search by email
ssh registry registryd query email alice@example.com

# Get identity count
ssh registry registryd stats --identities

# Get transaction count
ssh registry registryd stats --transactions
```

**API Queries** (from host or remote):
```bash
# Get all identities (paginated)
curl https://registry.local/api/v1/identities?page=1&limit=100

# Get specific identity
curl https://registry.local/api/v1/identity/did:trust:abc123

# Search
curl https://registry.local/api/v1/search?q=alice

# Get statistics
curl https://registry.local/api/v1/stats
```

### Adding Identity Records

**Manual Registration** (rare - usually automated):
```bash
# SSH to registry
ssh registry

# Register new identity
doas registryd register \
  --name "Alice" \
  --email "alice@example.com" \
  --public-key "04a1b2c3..." \
  --did "did:trust:abc123"

# Verify registration
registryd query identity did:trust:abc123
```

**Bulk Import**:
```bash
# Import from JSON file
ssh registry doas registryd import --file identities.json

# Import from CSV
ssh registry doas registryd import --csv identities.csv

# Progress
ssh registry doas tail -f /var/log/registry/import.log
```

### Updating Identity Records

**Update Existing Identity**:
```bash
# Update reputation score
ssh registry doas registryd update did:trust:abc123 \
  --reputation-score 150

# Update verification status
ssh registry doas registryd update did:trust:abc123 \
  --verified true

# Update metadata
ssh registry doas registryd update did:trust:abc123 \
  --metadata '{"kyc_verified": true}'
```

### Removing Identity Records

**Soft Delete** (mark as inactive):
```bash
# Deactivate identity (preserves history)
ssh registry doas registryd deactivate did:trust:abc123

# Verify
ssh registry registryd query identity did:trust:abc123
# Shows: "status": "inactive"
```

**Hard Delete** (permanent removal):
```bash
# ⚠️ DESTRUCTIVE - removes all traces
ssh registry doas registryd delete did:trust:abc123 --force

# Cannot be undone!
```

---

## Data Synchronization

### Understanding Registry Sync

Registry nodes synchronize with each other to maintain consistency:

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Registry A  │ ←─────→ │  Registry B  │ ←─────→ │  Registry C  │
│  (Keeper 1)  │  sync   │  (Keeper 2)  │  sync   │  (Keeper 3)  │
└──────────────┘         └──────────────┘         └──────────────┘
       ↓                        ↓                        ↓
   All have same             All have same           All have same
   identity records          identity records        identity records
```

**Sync Protocol**:
1. New identity registered on Registry A
2. Registry A broadcasts to Registry B and C
3. Registries B and C validate and store
4. All three registries now have the record
5. Consensus achieved

### Checking Sync Status

**Status Overview**:
```bash
# Check sync status
ssh registry registryd sync status

# Example output:
Sync Status: ACTIVE
Connected Peers: 5
Last Sync: 2 minutes ago
Pending Records: 0
Sync Lag: 0 seconds
```

**Peer Information**:
```bash
# List connected registry peers
ssh registry registryd sync peers

# Example output:
Registry Peers:
- registry-us-1.trustnet.org (last seen: 1m ago)
- registry-eu-1.trustnet.org (last seen: 30s ago)
- registry-asia-1.trustnet.org (last seen: 2m ago)
```

**Sync Metrics**:
```bash
# Detailed sync metrics
ssh registry registryd sync metrics

# Shows:
- Records synced today
- Sync errors (if any)
- Average sync latency
- Bandwidth usage
```

### Manual Sync Operations

**Force Sync** (if behind):
```bash
# Trigger manual sync
ssh registry doas registryd sync force

# Watch progress
ssh registry doas tail -f /var/log/registry/sync.log
```

**Sync from Specific Peer**:
```bash
# Sync from trusted registry
ssh registry doas registryd sync from registry-us-1.trustnet.org

# Useful if local data is corrupted
```

**Disable Sync** (maintenance mode):
```bash
# Stop accepting sync updates
ssh registry doas registryd sync disable

# Re-enable when ready
ssh registry doas registryd sync enable
```

### Resolving Sync Conflicts

**If Registries Diverge**:
```bash
# Compare with peer
ssh registry registryd sync compare registry-us-1.trustnet.org

# Shows differences:
Local has: 1523 identities
Peer has: 1525 identities
Missing records: 2
Conflicting records: 0

# Resolve conflicts
ssh registry doas registryd sync resolve \
  --strategy latest  # Use most recent record
```

**Sync Strategies**:
- `latest` - Use most recently updated record
- `highest-reputation` - Use record with highest reputation
- `manual` - Manual review and selection
- `peer` - Trust peer's version

---

## Monitoring & Maintenance

### Health Checks

**Automated Health Check Script**:
```bash
#!/bin/bash
# Save as: check-registry-health.sh

echo "=== Registry Health Check ==="
echo

# SSH accessible?
echo -n "SSH: "
ssh -o ConnectTimeout=5 registry 'echo OK' 2>/dev/null || echo "FAILED"

# Web UI accessible?
echo -n "Web UI: "
curl -s -o /dev/null -w "%{http_code}" https://registry.local | grep -q 200 && echo "OK" || echo "FAILED"

# API accessible?
echo -n "API: "
curl -s -o /dev/null -w "%{http_code}" https://registry.local/api/v1/stats | grep -q 200 && echo "OK" || echo "FAILED"

# Registry daemon running?
echo -n "Registry Daemon: "
ssh registry 'doas rc-service registryd status' 2>/dev/null | grep -q running && echo "RUNNING" || echo "STOPPED"

# Sync status
echo -n "Sync Status: "
ssh registry 'registryd sync status' 2>/dev/null | grep -q ACTIVE && echo "ACTIVE" || echo "INACTIVE"

# Disk space
echo -n "Disk Space (Data): "
ssh registry "df -h /opt/registry/data/ | tail -1 | awk '{print \$5}'" 2>/dev/null

# Identity count
echo -n "Total Identities: "
ssh registry 'registryd stats --identities' 2>/dev/null

# Connected peers
echo -n "Connected Peers: "
ssh registry 'registryd sync peers | wc -l' 2>/dev/null

echo
echo "=== End Health Check ==="
```

**Run Health Check**:
```bash
chmod +x check-registry-health.sh
./check-registry-health.sh

# Expected output:
=== Registry Health Check ===

SSH: OK
Web UI: OK
API: OK
Registry Daemon: RUNNING
Sync Status: ACTIVE
Disk Space (Data): 42%
Total Identities: 1523
Connected Peers: 5

=== End Health Check ===
```

### Performance Monitoring

**Inside Registry Node**:
```bash
# CPU and memory
ssh registry top

# Disk I/O
ssh registry doas iostat -x 1

# Network
ssh registry doas iftop

# Database performance (PostgreSQL)
ssh registry doas psql -U registry -c "SELECT * FROM pg_stat_activity;"

# Cache hit rate (Redis)
ssh registry redis-cli info stats
```

**Registry Metrics**:
```bash
# Request rate
ssh registry registryd metrics --requests

# Response time
ssh registry registryd metrics --latency

# Database query time
ssh registry registryd metrics --db-latency

# Sync throughput
ssh registry registryd metrics --sync-throughput
```

### Regular Maintenance Tasks

**Daily**:
- [ ] Check sync status: `ssh registry registryd sync status`
- [ ] Check disk space: `ssh registry df -h /opt/registry/data/`
- [ ] Review logs for errors: `ssh registry doas grep ERROR /var/log/registry/registry.log`
- [ ] Check peer connections: `ssh registry registryd sync peers`

**Weekly**:
- [ ] Update packages: `ssh registry doas apk update && doas apk upgrade`
- [ ] Backup data disk: `tar -czf backup.tar.gz registry-data.qcow2`
- [ ] Review sync metrics: `ssh registry registryd sync metrics`
- [ ] Check API usage: `ssh registry doas tail -1000 /var/log/caddy/access.log | grep /api/`
- [ ] Vacuum database: `ssh registry doas registryd vacuum`

**Monthly**:
- [ ] Rotate logs: `ssh registry doas logrotate /etc/logrotate.conf`
- [ ] Verify backups: Test restore from backup
- [ ] Security audit: Check for unauthorized access
- [ ] Performance review: Analyze metrics, optimize if needed
- [ ] Prune old snapshots: `ssh registry doas registryd prune-snapshots --older-than 90d`

---

## Troubleshooting

### Registry Daemon Won't Start

**Symptoms**: Service fails to start

**Diagnosis**:
```bash
# Check service status
ssh registry doas rc-service registryd status

# Check logs
ssh registry doas tail -50 /var/log/registry/registry.log

# Check config file
ssh registry doas cat /etc/registry/config.toml

# Check database connectivity
ssh registry doas registryd test-db
```

**Solutions**:
```bash
# Restart service
ssh registry doas rc-service registryd restart

# Verify config syntax
ssh registry doas registryd validate-config

# Reset database connection
ssh registry doas rc-service postgres restart
ssh registry doas rc-service registryd restart

# If corrupted, restore from backup
# (see Emergency Procedures)
```

### Sync Not Working

**Symptoms**: Registries out of sync, missing records

**Diagnosis**:
```bash
# Check sync status
ssh registry registryd sync status

# Check peers
ssh registry registryd sync peers

# Check firewall
ssh registry doas iptables -L

# Check network connectivity
ssh registry ping6 registry-us-1.trustnet.org
```

**Solutions**:
```bash
# Force sync
ssh registry doas registryd sync force

# Reset sync state
ssh registry doas registryd sync reset

# Add peer manually
ssh registry doas registryd sync add-peer registry-us-1.trustnet.org

# Check logs
ssh registry doas tail -f /var/log/registry/sync.log
```

### API Returning Errors

**Symptoms**: 500 errors, timeouts, slow responses

**Diagnosis**:
```bash
# Test API directly
curl -v https://registry.local/api/v1/stats

# Check registry daemon
ssh registry doas rc-service registryd status

# Check database
ssh registry doas rc-service postgres status

# Check logs
ssh registry doas tail -50 /var/log/registry/registry.log
```

**Solutions**:
```bash
# Restart services
ssh registry doas rc-service registryd restart
ssh registry doas rc-service caddy restart

# Clear cache (if using Redis)
ssh registry redis-cli FLUSHALL

# Rebuild indices
ssh registry doas registryd rebuild-indices
```

### Data Disk Full

**Symptoms**: Registry stops accepting new records

**Diagnosis**:
```bash
# Check disk usage
ssh registry df -h /opt/registry/data/

# Find what's using space
ssh registry doas du -sh /opt/registry/data/*/ | sort -h
```

**Solutions**:
```bash
# Prune old snapshots
ssh registry doas registryd prune-snapshots --older-than 30d

# Compress transaction logs
ssh registry doas registryd compress-transactions --older-than 90d

# Expand data disk (from host)
qemu-img resize registry-data.qcow2 +20G

# Resize filesystem (in VM)
ssh registry doas resize2fs /dev/vdb
```

### Registry Out of Sync with Blockchain

**Symptoms**: Registry has records not on blockchain

**Diagnosis**:
```bash
# Check sync lag
ssh registry registryd sync status

# Compare with blockchain
ssh registry registryd validate --blockchain

# Check logs
ssh registry doas grep "validation" /var/log/registry/registry.log
```

**Solutions**:
```bash
# Re-sync from blockchain
ssh registry doas registryd resync-blockchain

# Validate all records
ssh registry doas registryd validate-all

# Purge invalid records
ssh registry doas registryd purge-invalid
```

---

## Security Best Practices

### SSH Security

**Change Default Password** (Critical):
```bash
# First login
ssh registry
passwd
# Old: [provided by installer]
# New: [strong-password]
```

**Use SSH Keys** (Already configured by installer):
```bash
# Verify key authentication working
ssh registry 'echo "Key auth works"'

# Disable password auth (extra security)
ssh registry doas vi /etc/ssh/sshd_config
# Set: PasswordAuthentication no
ssh registry doas rc-service sshd restart
```

### API Security

**Enable API Authentication**:
```bash
# Generate API key
ssh registry doas registryd generate-api-key --name "admin-key"

# Output: API_KEY=abc123...

# Require API key for all requests
ssh registry doas vi /etc/registry/config.toml
# Set: require_api_key = true

# Restart registry
ssh registry doas rc-service registryd restart

# Test with key
curl -H "Authorization: Bearer abc123..." \
  https://registry.local/api/v1/identities
```

**Rate Limiting**:
```bash
# Configure rate limits
ssh registry doas vi /etc/registry/config.toml

# Add:
[rate_limit]
enabled = true
requests_per_minute = 60
burst = 100

ssh registry doas rc-service registryd restart
```

**IP Whitelisting** (if needed):
```bash
# Allow only specific IPs
ssh registry doas vi /etc/registry/config.toml

# Add:
[access_control]
allowed_ips = ["2001:db8::1", "2001:db8::2"]

ssh registry doas rc-service registryd restart
```

### Database Security

**Encrypt Data at Rest**:
```bash
# Enable database encryption
ssh registry doas vi /etc/postgres/postgresql.conf

# Add:
ssl = on
ssl_cert_file = '/etc/ssl/certs/postgres.crt'
ssl_key_file = '/etc/ssl/private/postgres.key'

ssh registry doas rc-service postgres restart
```

**Regular Backups** (encrypted):
```bash
# Backup with encryption
ssh registry doas registryd backup --encrypt --output /tmp/backup.enc

# Copy to secure location
scp registry:/tmp/backup.enc ~/registry-backups/

# Cleanup
ssh registry doas rm /tmp/backup.enc
```

### Audit Logging

**Enable Comprehensive Logging**:
```bash
# Configure audit logs
ssh registry doas vi /etc/registry/config.toml

# Add:
[audit]
enabled = true
log_all_queries = true
log_all_writes = true
log_api_access = true

ssh registry doas rc-service registryd restart
```

**Review Audit Logs**:
```bash
# Who accessed what
ssh registry doas grep "API_ACCESS" /var/log/registry/audit.log

# Who modified records
ssh registry doas grep "WRITE" /var/log/registry/audit.log

# Failed authentication attempts
ssh registry doas grep "AUTH_FAILED" /var/log/registry/audit.log
```

---

## Emergency Procedures

### Registry Node Compromised

**If you suspect unauthorized access**:

1. **Immediate Actions**:
   ```bash
   # Disconnect from network
   ssh registry doas ip link set eth0 down
   
   # Or stop VM entirely
   ./stop-registry.sh
   ```

2. **Investigation**:
   ```bash
   # Check recent logins
   ssh registry last -20
   
   # Check unauthorized SSH keys
   ssh registry cat ~/.ssh/authorized_keys
   
   # Check running processes
   ssh registry ps aux
   
   # Check unauthorized API keys
   ssh registry doas registryd list-api-keys
   
   # Check recent registry modifications
   ssh registry doas grep "UPDATE\|DELETE" /var/log/registry/audit.log
   ```

3. **Recovery**:
   ```bash
   # Restore from clean backup
   cp registry-backup-[date].qcow2 registry.qcow2
   cp registry-data-backup-[date].qcow2 registry-data.qcow2
   
   # Revoke all API keys
   ssh registry doas registryd revoke-all-api-keys
   
   # Regenerate credentials
   ./tools/regenerate-registry-keys.sh
   
   # Change keeper password
   ssh registry passwd
   
   # Review and harden security
   ```

### Data Corruption

**Symptoms**: Registry errors, database errors, corrupt records

**Recovery**:
```bash
# Stop registry
ssh registry doas rc-service registryd stop

# Check database integrity
ssh registry doas registryd check-database

# If corrupt, restore from backup
ssh registry doas registryd restore --backup /opt/registry/snapshots/latest.db

# Or restore entire data disk
./stop-registry.sh
cp registry-data-backup.qcow2 registry-data.qcow2
./start-registry.sh

# Verify integrity
ssh registry doas registryd validate-all
```

### Data Disk Full (Emergency)

**Immediate Recovery**:
```bash
# Delete old snapshots
ssh registry doas rm -rf /opt/registry/data/snapshots/2025-*

# Compress old transactions
ssh registry doas registryd compress-transactions --older-than 30d

# Emergency: Delete transaction history (⚠️ DESTRUCTIVE)
ssh registry doas rm -rf /opt/registry/data/transactions/2025-*

# Expand disk
qemu-img resize registry-data.qcow2 +50G
ssh registry doas resize2fs /dev/vdb
```

### Lost Keeper Access (Forgot Password)

**Recovery via Console**:
```bash
# Start VM with console access
./start-registry.sh --console

# At boot, press 'e' in GRUB
# Add to kernel line: single
# Boot into single-user mode

# Reset password
passwd keeper

# Reboot normally
reboot
```

### Complete Registry Rebuild

**If all else fails**:
```bash
# 1. Backup data disk
cp registry-data.qcow2 registry-data-backup.qcow2

# 2. Rebuild main disk
./install-registry.sh

# 3. Attach old data disk
./start-registry.sh --attach-data registry-data-backup.qcow2

# 4. Verify data intact
ssh registry registryd stats
```

---

## Appendix

### Quick Reference Commands

```bash
# === Access ===
ssh registry                           # SSH to registry
https://registry.local                 # Web UI
https://registry.local/api/v1/stats    # API stats

# === Start/Stop ===
./start-registry.sh                    # Start node
./start-registry.sh --read-only        # Maintenance mode
ssh registry doas poweroff             # Stop node

# === Status ===
ssh registry doas rc-status            # All services
ssh registry registryd sync status     # Sync status
ssh registry registryd stats           # Registry stats

# === Logs ===
ssh registry doas tail -f /var/log/registry/registry.log  # Registry
ssh registry doas tail -f /var/log/registry/sync.log      # Sync
ssh registry doas tail -f /var/log/caddy/access.log       # API access

# === Data Management ===
ssh registry registryd query identity did:trust:abc123    # Query
ssh registry registryd sync force                         # Force sync
ssh registry registryd backup --output /tmp/backup.db     # Backup

# === Maintenance ===
ssh registry registryd vacuum                             # Optimize DB
ssh registry registryd prune-snapshots --older-than 90d   # Cleanup
ssh registry registryd rebuild-indices                    # Rebuild indices
```

### Useful Aliases

Add to `~/.bashrc` inside registry node:

```bash
# Logs
alias logs-registry='doas tail -f /var/log/registry/registry.log'
alias logs-sync='doas tail -f /var/log/registry/sync.log'
alias logs-api='doas tail -f /var/log/caddy/access.log'

# Status
alias status='doas rc-status'
alias registry-status='registryd stats'
alias sync-status='registryd sync status'

# Services
alias restart-registry='doas rc-service registryd restart'
alias restart-web='doas rc-service caddy restart'

# Queries
alias count-identities='registryd stats --identities'
alias count-transactions='registryd stats --transactions'
alias list-peers='registryd sync peers'
```

### Environment Variables

```bash
# Add to ~/.profile inside registry node
export REGISTRY_HOME="/opt/registry"
export REGISTRY_CONFIG="$REGISTRY_HOME/config/config.toml"
export REGISTRY_DATA="$REGISTRY_HOME/data"
export PATH="$PATH:$REGISTRY_HOME/bin"
```

### API Endpoints Reference

```bash
# Identity Management
GET    /api/v1/identities              # List all (paginated)
GET    /api/v1/identity/{did}          # Get specific identity
POST   /api/v1/identity                # Create identity
PUT    /api/v1/identity/{did}          # Update identity
DELETE /api/v1/identity/{did}          # Delete identity

# Search
GET    /api/v1/search?q={query}        # Search identities
GET    /api/v1/search?name={name}      # Search by name
GET    /api/v1/search?email={email}    # Search by email

# Statistics
GET    /api/v1/stats                   # General statistics
GET    /api/v1/stats/identities        # Identity stats
GET    /api/v1/stats/transactions      # Transaction stats
GET    /api/v1/stats/sync              # Sync stats

# Health
GET    /api/v1/health                  # Health check
GET    /api/v1/status                  # Detailed status
```

---

**End of Registry Operations Manual**

*This is a living document. Update as new features are added or procedures change.*

**Last Updated**: February 2, 2026  
**Version**: 1.0  
**Maintainer**: TrustNet Keeper (you!)

---

## See Also

- [TrustNet Operations Manual](OPERATIONS_MANUAL.md) - For regular TrustNet nodes (Wardens)
- [Production vs Development Nodes](PRODUCTION_VS_DEVELOPMENT_NODES.md) - Architecture decisions
- [Modular Development Plan](MODULAR_DEVELOPMENT_PLAN.md) - Development workflow

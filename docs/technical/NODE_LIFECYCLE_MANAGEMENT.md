# TrustNet: Node & Registry Lifecycle Management

**Date**: January 31, 2026  
**Topic**: Node/Registry lifecycle, health tracking, auto-cleanup  
**Scope**: Handling transient VMs, health checks, state management

---

## Problem Statement

In VM-based environments, nodes and registries are **transient**:
- ✅ Nodes/registries start and run (ONLINE)
- ⏸️ VMs are paused or suspended (OFFLINE - temporary)
- 🛑 VMs are shut down or destroyed (INACTIVE - longer absence)
- ☠️ VMs are never restarted (DEAD - permanently gone)
- 🧹 Stale entries pollute registry (need cleanup)

**Without lifecycle management**:
- Registry has stale entries pointing to dead nodes
- Discovery tries dead nodes (timeout delays)
- Manual cleanup required
- No visibility into node health
- Resource waste on unreachable peers

---

## Node Lifecycle States

```
┌──────────────────────────────────────────────────────────────────────┐
│                       NODE LIFECYCLE STATES                           │
└──────────────────────────────────────────────────────────────────────┘

1. ONLINE (Active, Healthy)
   ├─ Node is running
   ├─ Heartbeat received (< 30 seconds)
   ├─ Health checks passing
   ├─ Actively accepting connections
   │
   └─ Transition to OFFLINE: No heartbeat for 30 seconds

2. OFFLINE (Temporarily Down, Can Recover)
   ├─ Node not responding
   ├─ Heartbeat timeout (30s - 10 min)
   ├─ Might be: paused VM, network issue, restart
   ├─ Still in registry (might come back)
   │
   └─ Transition to INACTIVE: No heartbeat for > 10 minutes

3. INACTIVE (Long Gone, Unlikely to Return)
   ├─ Node missing for 10+ minutes
   ├─ Treat as potentially dead
   ├─ Remove from active peer lists
   ├─ Keep in registry (for re-registration)
   │
   └─ Transition to DEAD: No heartbeat for > 1 hour

4. DEAD (Permanent, Auto-Cleanup)
   ├─ Node missing for 1+ hour
   ├─ Assume VM destroyed/never returning
   ├─ Remove from registry completely
   ├─ Can re-register as new node
   │
   └─ Transition to ONLINE: New node registration

5. REMOVED (Manually Deleted)
   ├─ Admin explicitly removed node
   ├─ Cannot auto-restore
   ├─ Requires manual re-registration
```

---

## State Transitions

```
START (New Node)
  │
  ▼
┌────────────────────────────────────┐
│      1. ONLINE (Healthy)           │
│  ✓ Heartbeat < 30s                 │
│  ✓ Health checks passing           │
│  ✓ Actively used by peers          │
└────────────────────────────────────┘
  ▲                                  ▼
  │    No heartbeat 30-600s          ▲
  │    ┌──────────────────────────┐  │
  │    │ 2. OFFLINE (Temporary)   │  │
  │    │ ⏸️ Paused/restarting      │  │
  │    │ ⏳ Can recover             │  │
  │    └──────────────────────────┘  │
  │    │          ▼                  │
  │    │    Heartbeat restored       │
  │    └──────────────────────────────┘
  │
  │    No heartbeat 600s - 3600s
  │    ┌──────────────────────────┐
  │    │ 3. INACTIVE (Long gone)  │
  │    │ 🛑 Unlikely to return     │
  │    │ 🧹 Cleaned from peers     │
  │    └──────────────────────────┘
  │    │          ▼
  │    │    Heartbeat restored
  │    └──────────────────────────────┘
  │
  │    No heartbeat > 3600s
  │    ┌──────────────────────────┐
  │    │ 4. DEAD (Permanent)      │
  │    │ ☠️ Assume VM destroyed    │
  │    │ 🗑️ Auto-remove from DB    │
  │    └──────────────────────────┘
  │
  └──────────────────────────────────────── MANUAL REMOVE
                                           (DELETED)

Legend:
⏳ Temporary (can recover)
🛑 Long-term absence (unlikely)
☠️ Permanent (auto-cleanup)
🧹 Cleaned from active use
🗑️ Removed from registry
```

---

## Timeout Strategy

| State | Transition | Timeout | Action |
|-------|-----------|---------|--------|
| ONLINE → OFFLINE | No heartbeat for 30 sec | `HEARTBEAT_TIMEOUT = 30s` | Mark offline, warn clients |
| OFFLINE → INACTIVE | No heartbeat for 10 min | `INACTIVE_THRESHOLD = 600s` | Remove from active peers |
| INACTIVE → DEAD | No heartbeat for 1 hour | `DEAD_THRESHOLD = 3600s` | Auto-cleanup, remove from registry |
| DEAD | Auto-cleanup triggers | `CLEANUP_INTERVAL = 60s` | Delete stale entries |

---

## Heartbeat Mechanism

### What is Heartbeat?

A periodic signal that proves the node is still alive.

```
Node (every 30 seconds):
  POST /registry/heartbeat
  {
    "node_id": "node-1",
    "node_ipv6": "fd10:1234::1",
    "internal_registry": "fd10:1234::101",
    "timestamp": "2026-01-31T15:30:00Z",
    "status": "healthy|degraded|recovering",
    "peers_known": 5,
    "storage_usage": "45%"
  }

Registry (receives heartbeat):
  ✓ Node is ONLINE
  ✓ Update last_heartbeat timestamp
  ✓ Update node status fields
  ✓ Broadcast alive status to other peers
```

### Heartbeat Intervals

```bash
# Node sends heartbeat every 30 seconds
HEARTBEAT_INTERVAL=30s

# Registry expects heartbeat within 30 seconds
HEARTBEAT_TIMEOUT=30s

# If no heartbeat for 30s → OFFLINE
# If no heartbeat for 10min → INACTIVE  
# If no heartbeat for 1hour → DEAD (cleanup)
```

### Failed Heartbeat Handling

```bash
Heartbeat fails? (POST timeout, 5xx error)
├─ Retry count < 3? → Retry after 5 seconds
├─ Retry count >= 3? → Mark node OFFLINE
│
Connection timeout specific?
├─ Network issue (not node down)?
│  └─ Increase next timeout (backoff)
│
Keep trying periodically:
├─ OFFLINE: Retry every 10 seconds
├─ INACTIVE: Retry every 60 seconds  
├─ DEAD: Don't retry (will be cleaned)
```

---

## Health Check Strategy

### Passive Health Check (Heartbeat-based)

Node sends heartbeat → Registry receives → Node is ONLINE

**Pros**:
- Simple, node initiates
- Works through most firewalls
- Low overhead

**Cons**:
- Detects death after timeout (delayed)
- No visibility into node health beyond "alive"

### Active Health Check (Registry probes node)

Registry periodically checks node health.

```bash
Registry (every 60 seconds):
  GET /health HTTP/1.1
  Host: [node_ipv6]:8053
  
Node responds:
  {
    "status": "healthy",
    "registry_status": "synced",
    "peers": 5,
    "storage": "45%",
    "timestamp": "2026-01-31T15:30:00Z"
  }

Registry evaluates:
├─ Status healthy? → ONLINE
├─ Status degraded? → ONLINE (but flag for attention)
├─ Timeout/error? → OFFLINE
```

**Pros**:
- Registry knows detailed health
- Detects "zombie" nodes (running but broken)
- Can collect metrics

**Cons**:
- More traffic
- Needs outbound access from registry to node
- Might not work behind NAT

### Combined Strategy (Recommended)

```
Node → Registry (active heartbeat)  [Every 30s]
Registry → Node (active health)     [Every 60s]

If heartbeat missing for 30s:
├─ Node is likely OFFLINE

If health check fails for 60s:
├─ Node appears unhealthy
├─ Might still be running but broken
```

---

## Cleanup Strategy

### Auto-Cleanup Daemon

```bash
Registry runs cleanup task every 60 seconds:

1. Check each node's last_heartbeat timestamp
2. Calculate time_since_heartbeat = now - last_heartbeat

3. For each node:
   ├─ time_since_heartbeat < 30s?
   │  └─ State = ONLINE ✓
   │
   ├─ 30s < time_since_heartbeat < 600s?
   │  └─ State = OFFLINE (can recover)
   │
   ├─ 600s < time_since_heartbeat < 3600s?
   │  └─ State = INACTIVE (remove from active peers)
   │
   └─ time_since_heartbeat > 3600s?
      └─ State = DEAD (DELETE from registry)
         └─ Log removal for audit

4. Update peer lists:
   ├─ Remove INACTIVE from "active_peers"
   ├─ Remove DEAD from entire registry
   ├─ Keep OFFLINE in registry (for potential recovery)

5. Report cleanup stats:
   ├─ Nodes removed: X
   ├─ Nodes marked inactive: Y
   ├─ Nodes brought back online: Z
```

### Cleanup Configuration

```bash
# In registry configuration:

# Timeouts
HEARTBEAT_TIMEOUT=30s         # Mark OFFLINE after
INACTIVE_THRESHOLD=600s       # Mark INACTIVE after (10 min)
DEAD_THRESHOLD=3600s          # Auto-delete after (1 hour)

# Cleanup timing
CLEANUP_INTERVAL=60s          # Run cleanup every minute
CLEANUP_BATCH_SIZE=100        # Clean up to 100 nodes per run

# Logging
CLEANUP_LOG_FILE=/var/log/trustnet/cleanup.log
CLEANUP_ENABLE_AUDIT=true     # Log all removals for audit

# Grace periods (before final deletion)
GRACE_PERIOD_BEFORE_DELETE=300s  # Wait 5 min before deleting (in case of clock skew)
```

---

## Data Model Changes

### Node Record (Enhanced)

```json
{
  "node_id": "node-1",
  "node_ipv6": "fd10:1234::1",
  "internal_registry": "fd10:1234::101",
  
  // Basic info (unchanged)
  "created_at": "2026-01-31T10:00:00Z",
  "name": "lab-node-1",
  
  // NEW: Lifecycle tracking
  "state": "online|offline|inactive|dead|removed",
  "last_heartbeat": "2026-01-31T15:30:42Z",
  "last_health_check": "2026-01-31T15:30:45Z",
  "state_changed_at": "2026-01-31T15:20:00Z",
  
  // NEW: Health metrics
  "health_status": "healthy|degraded|unknown",
  "last_error": "timeout connecting to internal registry",
  "error_count": 2,
  
  // NEW: Cleanup tracking
  "marked_for_deletion_at": "2026-01-31T16:30:00Z",  // if DEAD
  "deletion_reason": "heartbeat timeout 1 hour",
  "reactivation_count": 3,  // times brought back online
}
```

### Registry Record (Enhanced)

```json
{
  "registry_id": "root",
  "registry_ipv6": "fd10:1234::253",
  
  // Basic info
  "created_at": "2026-01-31T10:00:00Z",
  "type": "root|internal",
  
  // NEW: Lifecycle tracking
  "state": "online|offline|inactive|dead",
  "last_heartbeat": "2026-01-31T15:30:42Z",
  
  // NEW: Cleanup stats
  "nodes_online": 8,
  "nodes_offline": 2,
  "nodes_inactive": 1,
  "nodes_dead": 0,
  "last_cleanup": "2026-01-31T15:30:00Z",
  "last_cleanup_removed": 0,
}
```

---

## API Endpoints (New/Modified)

### Heartbeat Endpoint

```
POST /registry/heartbeat

Request:
{
  "node_id": "node-1",
  "node_ipv6": "fd10:1234::1",
  "internal_registry": "fd10:1234::101",
  "timestamp": "2026-01-31T15:30:00Z",
  "status": "healthy|degraded",
  "metrics": {
    "peers_known": 5,
    "storage_usage_percent": 45,
    "uptime_seconds": 86400
  }
}

Response (200 OK):
{
  "status": "ack",
  "registry_state": "healthy",
  "node_state": "online",
  "next_heartbeat_expected": "2026-01-31T15:30:30Z"
}
```

### Health Check Endpoint

```
GET /health

Response (200 OK):
{
  "status": "healthy|degraded|unhealthy",
  "registry": {
    "state": "online",
    "nodes_online": 8,
    "nodes_offline": 2,
    "last_cleanup": "2026-01-31T15:30:00Z"
  },
  "storage": {
    "available_percent": 55,
    "last_replication": "2026-01-31T15:29:00Z"
  }
}
```

### Node Status Endpoint

```
GET /registry/nodes?state=online|offline|inactive|dead

Response (200 OK):
{
  "nodes": [
    {
      "node_id": "node-1",
      "state": "online",
      "last_heartbeat": "2026-01-31T15:30:42Z",
      "health": "healthy"
    },
    {
      "node_id": "node-2",
      "state": "offline",
      "last_heartbeat": "2026-01-31T15:20:00Z",
      "health": "unknown"
    }
  ]
}
```

### Cleanup Status Endpoint

```
GET /registry/cleanup-status

Response (200 OK):
{
  "enabled": true,
  "last_run": "2026-01-31T15:30:00Z",
  "last_run_removed": 5,
  "last_run_marked_inactive": 2,
  "configuration": {
    "heartbeat_timeout": 30,
    "inactive_threshold": 600,
    "dead_threshold": 3600,
    "cleanup_interval": 60
  }
}
```

---

## Operational Guide

### Monitoring Node Health

```bash
# Check overall status
curl -k https://[registry]:8053/health

# List all nodes by state
curl -k https://[registry]:8053/registry/nodes?state=online
curl -k https://[registry]:8053/registry/nodes?state=offline
curl -k https://[registry]:8053/registry/nodes?state=inactive

# Watch cleanup progress
watch 'curl -k https://[registry]:8053/registry/cleanup-status | jq'

# View logs
tail -f /var/log/trustnet/cleanup.log
```

### Manual Node Management

```bash
# Remove a node permanently
DELETE /registry/nodes/node-1

# Reactivate an offline node
POST /registry/nodes/node-1/reactivate

# Force cleanup
POST /registry/cleanup-now

# Disable auto-cleanup (for maintenance)
POST /registry/cleanup-disable
```

### Scenarios

#### VM Paused (Expected Offline)

```
Time 0:00 - Node goes offline (VM paused)
  └─ Last heartbeat: 0:00

Time 0:30 - Registry checks heartbeat
  └─ No new heartbeat for 30s
  └─ State = OFFLINE
  └─ Alert (optional): Node offline

Time 10:00 - VM resumed
  └─ Node sends heartbeat
  └─ State = ONLINE
  └─ All good, re-join peers

Result: ✅ No cleanup needed, transparent recovery
```

#### VM Destroyed (Permanent)

```
Time 0:00 - Node crashes (VM destroyed)
  └─ Last heartbeat: 0:00

Time 0:30 - Registry notices no heartbeat
  └─ State = OFFLINE
  └─ Retry attempts every 10s

Time 10:00 - Still no heartbeat for 10 minutes
  └─ State = INACTIVE
  └─ Remove from active peer lists
  └─ Stop retrying active health checks

Time 1:00 - No heartbeat for 1 hour
  └─ State = DEAD
  └─ Auto-cleanup triggers
  └─ Node removed from registry
  └─ Cleanup log: "node-1 removed after 1 hour timeout"

Result: ✅ Stale entry cleaned, registry remains healthy
```

#### Registry Goes Down

```
Node A (affected by registry down):
  ├─ Can't heartbeat (registry not responding)
  ├─ Keeps retrying for 30s
  ├─ After 30s: Node marks registry as OFFLINE
  ├─ Uses backup registry if available

Registry comes back online:
  ├─ Nodes resume heartbeating
  ├─ State = ONLINE
  ├─ Replication catches up
  ├─ All good

Result: ✅ Transparent failover to backup registry
```

---

## Implementation Checklist

### Phase 1: Data Model (Week 1)
- [ ] Add state field to node records
- [ ] Add last_heartbeat timestamp
- [ ] Add health_status field
- [ ] Add marked_for_deletion field
- [ ] Create migration for existing nodes

### Phase 2: Heartbeat System (Week 1-2)
- [ ] Node sends heartbeat every 30s
- [ ] Registry receives and updates state
- [ ] Implement state transitions (ONLINE → OFFLINE)
- [ ] Implement retry logic for failed heartbeats
- [ ] Add heartbeat logging

### Phase 3: Health Checks (Week 2)
- [ ] Registry probes node health every 60s
- [ ] Parse health response
- [ ] Update health_status field
- [ ] Implement health-based state transitions
- [ ] Add health metrics collection

### Phase 4: Cleanup System (Week 2-3)
- [ ] Implement cleanup daemon
- [ ] Add state transition logic (OFFLINE → INACTIVE → DEAD)
- [ ] Implement auto-delete for DEAD nodes
- [ ] Add cleanup logging and audit trail
- [ ] Add configuration options

### Phase 5: API & Monitoring (Week 3)
- [ ] Add heartbeat endpoint
- [ ] Add health check endpoint
- [ ] Add node status query endpoint
- [ ] Add cleanup status endpoint
- [ ] Add manual node management endpoints

### Phase 6: Testing & Documentation (Week 3-4)
- [ ] Write tests for state transitions
- [ ] Test cleanup in various scenarios
- [ ] Write operational guides
- [ ] Create monitoring dashboard
- [ ] Document troubleshooting procedures

---

## Configuration Example

```bash
# ~/.trustnet/registry-config.yaml

lifecycle:
  # Heartbeat and timeout settings
  heartbeat_timeout: 30s        # Mark OFFLINE after 30s no heartbeat
  inactive_threshold: 10m       # Mark INACTIVE after 10 min
  dead_threshold: 1h            # Auto-delete after 1 hour
  grace_period_before_delete: 5m  # Wait 5 min after marking DEAD
  
  # Retry strategy
  offline_retry_interval: 10s   # Retry every 10s while OFFLINE
  inactive_retry_interval: 60s  # Retry every 60s while INACTIVE
  
  # Health checking
  active_health_check_enabled: true
  health_check_interval: 60s
  health_check_timeout: 5s
  
  # Cleanup
  cleanup_enabled: true
  cleanup_interval: 60s
  cleanup_batch_size: 100
  cleanup_log_file: /var/log/trustnet/cleanup.log
  cleanup_enable_audit: true
  
  # Notifications
  offline_alert_enabled: true
  inactive_alert_enabled: false
  cleanup_alert_enabled: true
```

---

## Monitoring & Alerts

### Key Metrics to Track

1. **Node Health**
   - Nodes ONLINE (target: > 90%)
   - Nodes OFFLINE (temporary, < 5%)
   - Nodes INACTIVE (cleanup candidate)
   - Nodes DEAD (should be zero after cleanup)

2. **Cleanup Metrics**
   - Nodes cleaned per hour
   - Average time to cleanup
   - Cleanup errors
   - Stale entries in registry

3. **Heartbeat Quality**
   - Heartbeat success rate (target: > 99%)
   - Heartbeat latency (target: < 1 sec)
   - Failed heartbeat causes

### Alert Thresholds

```
WARNING:  > 10% nodes offline for > 5 minutes
CRITICAL: > 30% nodes offline
WARNING:  Registry not reachable for heartbeat
WARNING:  Cleanup daemon not running
CRITICAL: Registry corrupted with stale entries
```

---

## Summary

**Node Lifecycle Management** provides:

✅ **Automatic offline detection** - Heartbeat timeout marks nodes offline  
✅ **Graceful recovery** - Nodes return to ONLINE when back  
✅ **Stale cleanup** - Auto-delete after 1 hour of inactivity  
✅ **VM-friendly** - Handles pause/resume/destroy scenarios  
✅ **Health visibility** - Know what's online, offline, or dead  
✅ **Zero manual intervention** - Fully automatic with logging  
✅ **Production-ready** - Handles all edge cases  

**Result**: Registry stays healthy even with VMs constantly coming and going.


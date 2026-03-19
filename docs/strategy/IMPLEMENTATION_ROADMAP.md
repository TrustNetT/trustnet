# TrustNet Implementation Roadmap: Lifecycle Management

**Status**: Design Complete → Ready for Implementation  
**Estimated Timeline**: 4 weeks  
**Start Date**: February 2026  
**Architecture**: Unified Hybrid (single codebase, multiple deployment modes)  

---

## Architecture Strategy (CRITICAL)

**Single Codebase, Multiple Modes** (see [UNIFIED_HYBRID_ARCHITECTURE.md](UNIFIED_HYBRID_ARCHITECTURE.md)):

1. **Development Mode** (Internal Registries)
   - Each node has internal registry
   - Discovery via multicast + gossip
   - Fast iteration, no external services
   - All features tested before production

2. **Production Mode** (Independent Registries)
   - Separate registry nodes (replicated)
   - Discovery via multicast → DNS
   - Heartbeat-based state tracking
   - Enterprise-grade reliability

**Implementation principle**: Every feature must work in BOTH modes.
- Same code, different config files
- Same tests, run in both modes
- Development = fast testing, Production = proven code

---

## Overview

You now have complete design documentation for:
1. ✅ **Network topology** (Full vs Isolated networks)
2. ✅ **Node lifecycle** (5-state machine)
3. ✅ **Heartbeat mechanism** (protocol, retry logic, metrics)
4. ✅ **Auto-cleanup** (timers, daemon, logging)
5. ✅ **VM scenarios** (pause, destroy, crash, recovery)
6. ✅ **Unified hybrid** (single codebase, both modes)

This roadmap tells you **exactly what to code**, in **what order**, with **clear success criteria**.

---

## Phase 1: Data Model Migration (Days 1-3)

### What: Update node records in registry (Works in both modes)

**Key principle**: Build internal registry first (used in both dev and prod modes).
- Development: Each node uses its own internal registry
- Production: Separate registry nodes also use same internal registry code

#### Current Model
```go
type Node struct {
    ID         string
    IPv6       string
    Port       int
    LastSeen   time.Time
}
```

#### New Model (Add These Fields)
```go
type Node struct {
    // Existing fields (keep as-is)
    ID         string
    IPv6       string
    Port       int
    
    // NEW: Lifecycle fields
    State           string    // "online" | "offline" | "inactive" | "dead" | "removed"
    LastHeartbeat   time.Time // When last heartbeat received
    LastStateChange time.Time // When state last changed
    StateChanges    []StateTransition // Audit trail
    
    // NEW: Health fields
    HealthStatus    string    // "healthy" | "degraded" | "unknown"
    LastHealthCheck time.Time
    HealthErrors    int       // Counter for failed checks
    
    // NEW: Cleanup fields
    MarkedForDeletion bool      // True after DEAD timeout
    MarkedAt          time.Time // When marked for deletion
    DeletionReason    string    // Why (timeout, manual, error)
    ReactivationCount int       // How many times came back ONLINE
    
    // NEW: Metrics (for monitoring)
    Uptime            time.Duration
    HeartbeatLatency  int // milliseconds
    PeerCount         int
    LastMetrics       map[string]interface{}
}

// NEW: Audit trail
type StateTransition struct {
    From      string    // Previous state
    To        string    // New state
    Timestamp time.Time
    Reason    string
}
```

#### Implementation
- [ ] Update registry node storage (in-memory or database)
- [ ] Create migration function for existing nodes (set `State = "online"`)
- [ ] Write tests for state field
- [ ] Verify backward compatibility (existing nodes still discoverable)

**Success Criteria**:
- Registry stores all new fields
- Old nodes converted to new model
- State queries work: `GET /registry/nodes?state=online`
- No data loss on migration

---

## Phase 2: Heartbeat Endpoint (Days 4-6)

### What: Registry endpoint to receive heartbeat updates

#### Endpoint: `POST /registry/heartbeat`

**Request**:
```json
{
  "node_id": "node-1",
  "node_ipv6": "fd10:1234::1",
  "timestamp": "2026-02-01T10:30:00Z",
  "status": "healthy",
  "metrics": {
    "uptime": 3600,
    "peer_count": 4,
    "storage_used_gb": 5.2,
    "latency_ms": 12
  }
}
```

**Response**:
```json
{
  "status": "ack",
  "node_state": "online",
  "next_heartbeat_in": 30,
  "registry_state": "healthy"
}
```

#### Implementation
```bash
POST /registry/heartbeat

1. Extract node_id from request
2. Find node in registry
3. If node not found:
   - Create new node record
   - Set State = "online"
   
4. If node found:
   - Update LastHeartbeat = request.timestamp
   - Store Metrics = request.metrics
   
5. Check current state:
   - If state == "offline":
     - Change to "online"
     - Log transition: OFFLINE → ONLINE
     - Emit alert (recovered)
   
   - If state == "inactive" or "dead":
     - Change to "online"
     - Increment ReactivationCount
     - Log transition: INACTIVE/DEAD → ONLINE
     - Emit alert (node recovered)
   
   - If state == "online":
     - Just update LastHeartbeat
     - No state change needed
   
   - If state == "removed":
     - Reject: "node previously removed"
     - (can re-register with new node_id)

6. Return "ack" with current state

7. Log: "node-1 heartbeat received (state=online, latency=12ms)"
```

**Tests**:
- [ ] New node sends first heartbeat → created with state=online
- [ ] Existing online node sends heartbeat → state unchanged
- [ ] Offline node sends heartbeat → state changes to online, alert emitted
- [ ] Dead node sends heartbeat → state changes to online, reactivation logged
- [ ] Removed node sends heartbeat → rejected with error

**Success Criteria**:
- Heartbeat endpoint receives updates
- Node states update correctly
- State transitions logged
- Recovery alerts emitted
- Metrics stored for monitoring

---

## Phase 3: State Transition Logic (Days 7-9)

### What: Automatic state changes based on time since heartbeat

#### Timeout Rules
```
ONLINE (< 30 seconds since heartbeat)
  ├─ Actively in peer lists
  └─ No health checks needed

OFFLINE (30 seconds - 10 minutes)
  ├─ No longer in peer lists (to new discoverers)
  ├─ Active health checks every 10 seconds
  └─ Still in registry (can recover)

INACTIVE (10 minutes - 1 hour)
  ├─ Removed from active peer lists
  ├─ Passive health checks only (when requested)
  └─ Still in registry (for re-registration)

DEAD (> 1 hour, marked for deletion)
  ├─ Not in any peer lists
  ├─ Not health-checked
  └─ Scheduled for deletion by cleanup daemon

REMOVED (manually deleted or after DEAD cleanup)
  ├─ Completely deleted from registry
  └─ No recovery possible (requires re-registration)
```

#### Checking State (Every 30-60 seconds)

**Pseudocode**:
```bash
function check_node_states():
    for each node in registry:
        time_since_heartbeat = now - node.last_heartbeat
        
        if time_since_heartbeat < 30s:
            # Still receiving heartbeats
            if node.state != "online":
                transition(node, "online", "heartbeat received")
                emit_alert("node recovered", node.id)
        
        elif time_since_heartbeat < 600s:  # 10 minutes
            # No recent heartbeat
            if node.state == "online":
                transition(node, "offline", "heartbeat timeout")
                emit_alert("node offline", node.id)
            
            # Active health check
            if time_since_heartbeat > 30s and time_since_heartbeat % 10s == 0:
                send_health_check(node)
        
        elif time_since_heartbeat < 3600s:  # 1 hour
            # Long absence
            if node.state != "inactive" and node.state != "dead":
                transition(node, "inactive", "offline for 10+ minutes")
                emit_alert("node inactive", node.id)
            
            # Passive health checks only (if requested)
            # Don't actively probe
        
        else:  # > 1 hour
            # Dead node
            if node.state != "dead" and node.state != "removed":
                transition(node, "dead", "offline for 1+ hour")
                node.marked_for_deletion = true
                node.marked_at = now
                emit_alert("node dead", node.id)
```

#### Implementation
- [ ] Add state checking function to registry
- [ ] Call every 30-60 seconds (background goroutine or scheduler)
- [ ] Transition nodes based on timeout rules
- [ ] Log all state transitions
- [ ] Update peer lists (remove offline/inactive/dead)
- [ ] Emit alerts for important transitions

**Tests**:
- [ ] Node online, then heartbeat stops → transitions to offline after 30s
- [ ] Offline node, then heartbeat resumes → transitions back to online
- [ ] Offline node stays offline for 10min → transitions to inactive
- [ ] Inactive node stays inactive for 1hr → transitions to dead
- [ ] Multiple transitions in sequence (online → offline → inactive → dead)

**Success Criteria**:
- State transitions happen at correct times
- Transitions are logged with timestamps
- Peer lists updated automatically
- Alerts emitted for important events

---

## Phase 4: Cleanup Daemon (Days 10-12)

### What: Automatic removal of DEAD nodes

#### Cleanup Process (Runs every 60 seconds)

```bash
function cleanup_dead_nodes():
    # Find all nodes marked as DEAD
    dead_nodes = filter_nodes(state == "dead")
    
    for each dead_node in dead_nodes:
        time_since_marked = now - dead_node.marked_at
        grace_period = 5 minutes  # Wait 5 min before final delete
        
        if time_since_marked > grace_period:
            # Remove completely
            log("Removing dead node", dead_node.id, "reason:", dead_node.deletion_reason)
            
            # Clean up all references
            remove_from_peer_lists(dead_node.id)
            delete_node_record(dead_node.id)
            
            # Emit event
            emit_event("node_removed", {
                "node_id": dead_node.id,
                "reason": dead_node.deletion_reason,
                "offline_duration": time_since_marked
            })
            
            # Metrics
            increment_counter("nodes_removed_total")
            observe_gauge("cleanup_batch_size", 1)
```

#### Implementation
- [ ] Create cleanup daemon (background task)
- [ ] Run every 60 seconds
- [ ] Remove DEAD nodes after grace period (5-10 minutes)
- [ ] Log removals with details
- [ ] Emit events/alerts
- [ ] Track metrics (nodes removed per hour, etc.)

**Tests**:
- [ ] Dead node with grace period expired → deleted
- [ ] Dead node with grace period not expired → not deleted yet
- [ ] Multiple dead nodes → batch deleted
- [ ] Log shows removal reason and timestamp
- [ ] Cleanup happens even if no heartbeats coming in

**Success Criteria**:
- Dead nodes automatically removed
- Cleanup logs detailed information
- No orphaned node references
- Cleanup metrics tracked
- Graceful handling (respects grace period)

---

## Phase 5: Health Check Endpoint (Days 13-15)

### What: Registry endpoint to check node health actively

#### Endpoint: `GET /registry/health/{node_id}`

**Request**:
```
GET /registry/health/node-1?timeout=5
```

**Response** (from node):
```json
{
  "node_id": "node-1",
  "status": "healthy",
  "timestamp": "2026-02-01T10:30:00Z",
  "metrics": {
    "uptime": 3600,
    "peer_count": 4,
    "storage": "5.2GB"
  }
}
```

**Registry Logic**:
```bash
# For OFFLINE nodes (30s - 10min)
# Registry probes every 10 seconds:
GET http://[node_ipv6]:8053/health?timeout=5s

# Update health status:
if response received within 5s:
    node.health_status = "healthy"
    node.health_errors = 0
else:
    node.health_errors++
    node.health_status = "unknown"
    if node.health_errors > 5:
        node.health_status = "degraded"

# For INACTIVE/DEAD nodes
# No active probing, only respond if requested
```

#### Implementation
- [ ] Add health check endpoint to nodes (`GET /health`)
- [ ] Registry calls health endpoint for OFFLINE nodes
- [ ] Parse health response and update health_status
- [ ] Track health check latency
- [ ] Move nodes to OFFLINE state if repeated health failures

**Tests**:
- [ ] Registry health checks offline node
- [ ] Offline node responds → health_status = healthy
- [ ] Offline node doesn't respond → health_status = degraded
- [ ] Multiple health failures → move to inactive earlier
- [ ] Health latency tracked

**Success Criteria**:
- Registry can probe node health
- Health status updated correctly
- Metrics tracked (latency, success rate)
- Works for both active and passive scenarios

---

## Phase 6: Monitoring & Dashboards (Days 16-20)

### What: Monitor node states and cleanup activity

#### Metrics to Track

```
# State distribution
trustnet_nodes_total{state="online"} 15
trustnet_nodes_total{state="offline"} 2
trustnet_nodes_total{state="inactive"} 0
trustnet_nodes_total{state="dead"} 1

# Transition events
trustnet_state_transitions_total{from="online",to="offline"} 5
trustnet_state_transitions_total{from="offline",to="online"} 4
trustnet_state_transitions_total{from="offline",to="inactive"} 1

# Cleanup activity
trustnet_nodes_removed_total 3
trustnet_cleanup_batches_total 12
trustnet_cleanup_batch_size{quantile="0.5"} 0
trustnet_cleanup_batch_size{quantile="0.99"} 5

# Health checks
trustnet_health_checks_total{status="success"} 1000
trustnet_health_checks_total{status="timeout"} 5
trustnet_health_checks_total{status="error"} 2

# Heartbeat latency
trustnet_heartbeat_latency_ms{quantile="0.5"} 12
trustnet_heartbeat_latency_ms{quantile="0.99"} 45
```

#### Alerts

```
# WARNING: Many nodes offline
if (nodes_offline / nodes_total) > 0.1 for 5min
  alert: "More than 10% of nodes offline"

# CRITICAL: Most nodes offline (network issue?)
if (nodes_offline / nodes_total) > 0.3 for 1min
  alert: "Critical: 30%+ nodes offline"

# INFO: Cleanup activity
if nodes_removed_this_hour > 0
  log: "Cleaned up N nodes this hour"
```

#### Dashboard

- [ ] Node state pie chart (online/offline/inactive/dead)
- [ ] Node state timeline (how many in each state over time)
- [ ] Heartbeat latency histogram
- [ ] State transition frequency
- [ ] Cleanup activity (nodes removed per hour)
- [ ] Health check success rate
- [ ] Alert history

#### Implementation
- [ ] Add metrics collection to registry
- [ ] Export metrics in Prometheus format: `GET /metrics`
- [ ] Create Grafana dashboard
- [ ] Configure alerts in Prometheus
- [ ] Document alert thresholds

**Tests**:
- [ ] Metrics endpoint returns correct format
- [ ] Counters increment correctly
- [ ] Gauges reflect current state
- [ ] Histograms have reasonable buckets

**Success Criteria**:
- All metrics tracked
- Dashboard shows real-time state
- Alerts trigger correctly
- Historical data available
- Easy to troubleshoot issues

---

## Testing Strategy

### Unit Tests (Week 3-4)
```bash
# Test heartbeat endpoint
test_new_node_heartbeat()
test_existing_node_heartbeat()
test_offline_node_recovery()
test_invalid_heartbeat()

# Test state transitions
test_online_to_offline_timeout()
test_offline_to_inactive_timeout()
test_inactive_to_dead_timeout()
test_dead_recovery()

# Test cleanup
test_dead_node_removal()
test_grace_period_respected()
test_cleanup_logging()
```

### Integration Tests (Week 3-4)
```bash
# End-to-end scenarios
test_scenario_vm_pause_resume()
test_scenario_vm_destroyed()
test_scenario_registry_crash()
test_scenario_network_partition()
```

### Load Tests (Week 4)
```bash
# Simulate 100+ nodes
test_100_nodes_steady_state()
test_100_nodes_all_offline()
test_cleanup_performance()
test_metrics_overhead()
```

---

## Implementation Checklist

### Week 1: Data Model
- [ ] Update Node struct with new fields
- [ ] Create migration for existing nodes
- [ ] Write data model tests
- [ ] Verify backward compatibility

### Week 2: Heartbeat + State Transitions
- [ ] Implement POST /registry/heartbeat endpoint
- [ ] Implement state checking logic
- [ ] Add state transition logging
- [ ] Write heartbeat tests
- [ ] Write state transition tests

### Week 3: Health Checks + Cleanup
- [ ] Implement health check probing for OFFLINE nodes
- [ ] Implement cleanup daemon
- [ ] Add cleanup logging
- [ ] Write health check tests
- [ ] Write cleanup tests

### Week 4: Monitoring + Docs
- [ ] Add metrics collection
- [ ] Export /metrics endpoint
- [ ] Create Grafana dashboard
- [ ] Configure Prometheus alerts
- [ ] Write operational documentation
- [ ] Write troubleshooting guide
- [ ] Run end-to-end tests

---

## Node Heartbeat Client Integration

**Parallel Work** (Can start Week 1):
```bash
# Location: tools/heartbeat-client.sh
# Systemd: /etc/systemd/system/trustnet-heartbeat.service
# Config: /etc/trustnet/heartbeat.env

# Script design:
- Read config from /etc/trustnet/heartbeat.env
- Every 30 seconds: POST to /registry/heartbeat
- Collect metrics (uptime, peer count, storage)
- Retry logic (3x with 2s backoff)
- Logging to /var/log/trustnet/heartbeat.log
```

See: **HEARTBEAT_IMPLEMENTATION.md** for complete script.

---

## Success Metrics

By end of implementation:

✅ Nodes automatically track ONLINE/OFFLINE/INACTIVE/DEAD/REMOVED states  
✅ Heartbeat failures detected within 30 seconds  
✅ VMs pause/resume without manual intervention  
✅ Dead nodes auto-removed after 1 hour  
✅ No stale registry entries  
✅ Clear visibility into node health  
✅ Automatic recovery when VMs restart  
✅ Comprehensive logging and auditing  
✅ Monitoring dashboard shows all state transitions  
✅ Production-ready with configurable timeouts  

---

## Configuration File

Create `trustnet/config/lifecycle.yaml`:

```yaml
# Heartbeat configuration
heartbeat:
  interval_seconds: 30       # How often nodes send heartbeat
  timeout_seconds: 5         # How long to wait for heartbeat response
  retry_count: 3             # Retry attempts on failure
  retry_delay_seconds: 2     # Delay between retries

# State transition timeouts
state_transitions:
  online_to_offline_seconds: 30      # No heartbeat for 30s → OFFLINE
  offline_to_inactive_seconds: 600   # No heartbeat for 10min → INACTIVE
  inactive_to_dead_seconds: 3600     # No heartbeat for 1hr → DEAD
  grace_period_before_delete_seconds: 300  # Wait 5min after DEAD → DELETE

# Health checking
health_check:
  enabled: true
  interval_seconds: 60       # Recheck every minute
  timeout_seconds: 5
  probe_offline_nodes: true  # Actively probe OFFLINE nodes

# Cleanup daemon
cleanup:
  enabled: true
  interval_seconds: 60       # Run every minute
  batch_size: 100            # Delete up to 100 nodes per batch
  logging: true              # Log all deletions
  dry_run: false             # Set true to test without deleting

# Alerts
alerts:
  enabled: true
  offline_threshold_percent: 10    # Alert when 10%+ offline
  offline_threshold_duration: 300  # For 5+ minutes
  critical_threshold_percent: 30   # Critical when 30%+ offline
  recovery_notification: true      # Alert on node recovery
```

---

## Summary

**You now have**:
1. ✅ Complete design documentation
2. ✅ Real-world examples and scenarios
3. ✅ Phase-by-phase implementation guide
4. ✅ Clear success criteria for each phase
5. ✅ Testing strategy
6. ✅ Configuration framework
7. ✅ Heartbeat client design

**Next**: Pick Phase 1 (data model) and start coding!

**Questions to answer before coding**:
- Where's your registry backend code? (Go? Node? Rust?)
- Do you use a database or in-memory storage?
- What monitoring system? (Prometheus, CloudWatch, custom?)
- What alerting? (PagerDuty, Slack, email?)

**Once you start**: Keep this document open and work through phases sequentially.


# TrustNet: Node Heartbeat Implementation Guide

**Date**: January 31, 2026  
**Topic**: Implementing heartbeat client on nodes  
**Purpose**: Send periodic heartbeats to registry for lifecycle management

---

## Overview

Every TrustNet node sends a **heartbeat** to the registry every 30 seconds to prove it's alive. The registry uses this to track node state (ONLINE/OFFLINE/INACTIVE/DEAD).

---

## Heartbeat Client Design

### What Happens

```bash
Every 30 seconds, the node sends:

POST https://[registry_ipv6]:8053/registry/heartbeat
{
  "node_id": "node-1",
  "node_ipv6": "fd10:1234::1",
  "internal_registry": "fd10:1234::101",
  "timestamp": "2026-01-31T15:30:00Z",
  "status": "healthy",
  "metrics": {
    "peers_known": 5,
    "storage_usage_percent": 45,
    "uptime_seconds": 3600
  }
}

Registry responds:
{
  "status": "ack",
  "node_state": "online",
  "registry_state": "healthy"
}
```

---

## Implementation: Heartbeat Service

### 1. Create Heartbeat Script

Create `tools/heartbeat-client.sh`:

```bash
#!/bin/bash
#
# TrustNet Node Heartbeat Client
# Sends periodic heartbeats to registry to maintain ONLINE state
#

set -euo pipefail

# Configuration
HEARTBEAT_INTERVAL=${HEARTBEAT_INTERVAL:-30}
HEARTBEAT_TIMEOUT=${HEARTBEAT_TIMEOUT:-5}
HEARTBEAT_RETRY_COUNT=${HEARTBEAT_RETRY_COUNT:-3}
HEARTBEAT_RETRY_DELAY=${HEARTBEAT_RETRY_DELAY:-2}

# State
NODE_ID="${1:-}"
NODE_IPV6="${2:-}"
INTERNAL_REGISTRY="${3:-}"
REGISTRY_IPV6="${4:-}"

# Validation
if [[ -z "$NODE_ID" ]] || [[ -z "$NODE_IPV6" ]] || [[ -z "$INTERNAL_REGISTRY" ]] || [[ -z "$REGISTRY_IPV6" ]]; then
    echo "Usage: $0 <node_id> <node_ipv6> <internal_registry> <registry_ipv6>"
    exit 1
fi

# Logging
log_info()    { echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO:  $*" >> /var/log/trustnet/heartbeat.log; }
log_error()   { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $*" >> /var/log/trustnet/heartbeat.log; }
log_debug()   { echo "[$(date +'%Y-%m-%d %H:%M:%S')] DEBUG: $*" >> /var/log/trustnet/heartbeat.log; }

# Send heartbeat with retry logic
send_heartbeat() {
    local attempt=1
    local status="healthy"
    
    # Determine node status
    if ! check_node_health; then
        status="degraded"
    fi
    
    # Collect metrics
    local uptime=$(get_uptime)
    local storage=$(get_storage_usage)
    local peers=$(count_known_peers)
    
    # Build heartbeat payload
    local payload=$(cat <<EOF
{
  "node_id": "$NODE_ID",
  "node_ipv6": "$NODE_IPV6",
  "internal_registry": "$INTERNAL_REGISTRY",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "status": "$status",
  "metrics": {
    "peers_known": $peers,
    "storage_usage_percent": $storage,
    "uptime_seconds": $uptime
  }
}
EOF
)
    
    # Retry loop
    while [[ $attempt -le $HEARTBEAT_RETRY_COUNT ]]; do
        log_debug "Heartbeat attempt $attempt/$HEARTBEAT_RETRY_COUNT"
        
        # Send heartbeat
        local response=$(
            timeout "$HEARTBEAT_TIMEOUT" curl -k -s \
                -X POST \
                -H "Content-Type: application/json" \
                -d "$payload" \
                "https://[$REGISTRY_IPV6]:8053/registry/heartbeat" \
                2>&1 || echo "TIMEOUT"
        )
        
        # Check response
        if [[ "$response" == "TIMEOUT" ]]; then
            log_error "Heartbeat timeout (attempt $attempt)"
            ((attempt++))
            if [[ $attempt -le $HEARTBEAT_RETRY_COUNT ]]; then
                sleep "$HEARTBEAT_RETRY_DELAY"
            fi
        elif echo "$response" | grep -q '"status".*"ack"'; then
            log_info "Heartbeat sent successfully (node_state: online)"
            return 0
        else
            log_error "Heartbeat failed: $response"
            ((attempt++))
            if [[ $attempt -le $HEARTBEAT_RETRY_COUNT ]]; then
                sleep "$HEARTBEAT_RETRY_DELAY"
            fi
        fi
    done
    
    log_error "Heartbeat failed after $HEARTBEAT_RETRY_COUNT attempts - marking registry as OFFLINE"
    return 1
}

# Health checks
check_node_health() {
    # TODO: Implement actual health checks
    # - Check internal registry connectivity
    # - Check peer connectivity
    # - Check storage availability
    return 0
}

# Metrics collection
get_uptime() {
    # Get node uptime in seconds
    cat /proc/uptime | awk '{print int($1)}'
}

get_storage_usage() {
    # Get registry storage usage percentage
    # TODO: Get from actual registry storage path
    df /var/lib/trustnet-registry | tail -1 | awk '{print $5}' | sed 's/%//'
}

count_known_peers() {
    # Count known peer nodes
    # TODO: Query registry for peer count
    # Placeholder: return 0
    echo 0
}

# Main loop
main() {
    log_info "Starting heartbeat client for $NODE_ID"
    log_info "Registry: [$REGISTRY_IPV6]:8053"
    log_info "Heartbeat interval: ${HEARTBEAT_INTERVAL}s"
    
    while true; do
        send_heartbeat
        sleep "$HEARTBEAT_INTERVAL"
    done
}

# Run
main "$@"
```

### 2. Systemd Service Unit

Create `/etc/systemd/system/trustnet-heartbeat.service`:

```ini
[Unit]
Description=TrustNet Node Heartbeat Client
Documentation=https://trustnet.local/docs
After=network-online.target trustnet-registry.service
Wants=network-online.target

[Service]
Type=simple
User=trustnet
Group=trustnet
WorkingDirectory=/opt/trustnet

# Get configuration from node config
EnvironmentFile=/etc/trustnet/heartbeat.env

# Run heartbeat service
ExecStart=/opt/trustnet/tools/heartbeat-client.sh \
    ${NODE_ID} \
    ${NODE_IPV6} \
    ${INTERNAL_REGISTRY_IPV6} \
    ${REGISTRY_IPV6}

# Restart on failure
Restart=always
RestartSec=10

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=trustnet-heartbeat

# Security
ProtectSystem=strict
ProtectHome=yes
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

### 3. Configuration File

Create `/etc/trustnet/heartbeat.env`:

```bash
# Node identification
NODE_ID=node-1
NODE_IPV6=fd10:1234::1
INTERNAL_REGISTRY_IPV6=fd10:1234::101

# Registry location
REGISTRY_IPV6=fd10:1234::253

# Heartbeat settings
HEARTBEAT_INTERVAL=30        # Send heartbeat every 30 seconds
HEARTBEAT_TIMEOUT=5          # Wait 5 seconds for response
HEARTBEAT_RETRY_COUNT=3      # Retry 3 times on failure
HEARTBEAT_RETRY_DELAY=2      # Wait 2 seconds between retries
```

---

## Integration with Installation

### When Node is Created

```bash
# In install.sh or setup-node.sh:

# 1. Create node
setup_node "node-1" "fd10:1234::1"

# 2. Configure heartbeat
configure_heartbeat "node-1" "fd10:1234::1" "fd10:1234::101" "fd10:1234::253"

# 3. Start heartbeat service
systemctl enable trustnet-heartbeat.service
systemctl start trustnet-heartbeat.service

# 4. Verify heartbeat is running
sleep 30
systemctl status trustnet-heartbeat.service
```

### Function to Configure Heartbeat

Add to `tools/lib/common.sh`:

```bash
# Configure and start heartbeat service for a node
configure_heartbeat() {
    local node_id="$1"
    local node_ipv6="$2"
    local internal_registry="$3"
    local registry_ipv6="$4"
    
    log_info "Configuring heartbeat for $node_id..."
    
    # Create heartbeat environment file
    sudo tee /etc/trustnet/heartbeat.env > /dev/null << EOF
NODE_ID=$node_id
NODE_IPV6=$node_ipv6
INTERNAL_REGISTRY_IPV6=$internal_registry
REGISTRY_IPV6=$registry_ipv6

HEARTBEAT_INTERVAL=30
HEARTBEAT_TIMEOUT=5
HEARTBEAT_RETRY_COUNT=3
HEARTBEAT_RETRY_DELAY=2
EOF
    
    # Create log directory
    sudo mkdir -p /var/log/trustnet
    sudo chown trustnet:trustnet /var/log/trustnet
    sudo chmod 755 /var/log/trustnet
    
    # Enable heartbeat service
    sudo systemctl daemon-reload
    sudo systemctl enable trustnet-heartbeat.service
    sudo systemctl start trustnet-heartbeat.service
    
    log_success "Heartbeat configured for $node_id"
}
```

---

## Monitoring Heartbeat

### Check Heartbeat Status

```bash
# Is the heartbeat service running?
systemctl status trustnet-heartbeat.service

# Watch heartbeat logs in real-time
journalctl -u trustnet-heartbeat.service -f

# View heartbeat log file
tail -f /var/log/trustnet/heartbeat.log

# Count successful heartbeats in the last hour
grep "sent successfully" /var/log/trustnet/heartbeat.log | wc -l
```

### Verify Registry Sees Heartbeat

```bash
# Check node state on registry
curl -k https://[registry]:8053/registry/nodes/node-1

# Expected response:
{
  "node_id": "node-1",
  "state": "online",
  "last_heartbeat": "2026-01-31T15:30:42Z",
  "health": "healthy"
}
```

---

## Troubleshooting Heartbeat

### Problem: Heartbeat Connection Refused

```
ERROR: Failed to connect to registry
```

**Diagnosis**:
```bash
# Test connectivity to registry
curl -k https://[registry]:8053/health

# Test DNS resolution
dig [registry_name] AAAA

# Test IPv6 routing
ping6 fd10:1234::253
```

**Solutions**:
- Ensure registry is running: `systemctl status trustnet-registry.service`
- Check firewall allows port 8053: `sudo iptables -L -n | grep 8053`
- Verify IPv6 routing: `ip -6 route`

### Problem: Heartbeat Timeout

```
ERROR: Heartbeat timeout (attempt 1/3)
```

**Diagnosis**:
```bash
# Check registry latency
time curl -k https://[registry]:8053/health

# Check network latency
ping6 -c 5 fd10:1234::253
```

**Solutions**:
- Increase HEARTBEAT_TIMEOUT if latency is high
- Check for network congestion
- Verify registry isn't overloaded

### Problem: Node Marked as OFFLINE in Registry

```
curl https://[registry]:8053/registry/nodes/node-1
→ state: "offline"
```

**Diagnosis**:
```bash
# Check if heartbeat service is running
systemctl status trustnet-heartbeat.service

# Check heartbeat logs
journalctl -u trustnet-heartbeat.service -n 50

# Verify registry is reachable
timeout 5 curl -k https://[registry]:8053/health
```

**Solutions**:
- Start heartbeat service: `systemctl start trustnet-heartbeat.service`
- Check if registry crashed
- Verify network connectivity
- Once fixed, node will return to ONLINE automatically (1-2 heartbeats)

---

## Metrics & Monitoring

### Heartbeat Success Rate

```bash
# Calculate success rate in the last hour
total=$(grep "Heartbeat" /var/log/trustnet/heartbeat.log | \
        grep "$(date -d '1 hour ago' '+%Y-%m-%d %H')" | wc -l)

success=$(grep "sent successfully" /var/log/trustnet/heartbeat.log | \
          grep "$(date -d '1 hour ago' '+%Y-%m-%d %H')" | wc -l)

echo "Success rate: $((success * 100 / total))%"
```

### Average Heartbeat Latency

```bash
# Extract heartbeat latencies from response times
# (requires enhanced logging with response time)
grep "response_time_ms:" /var/log/trustnet/heartbeat.log | \
  awk '{sum+=$NF; count++} END {print "Avg latency: " sum/count " ms"}'
```

---

## Configuration Tuning

### For Fast Networks (LAN, < 5ms latency)

```bash
HEARTBEAT_INTERVAL=30      # 30 second heartbeat
HEARTBEAT_TIMEOUT=2        # Quick timeout
HEARTBEAT_RETRY_COUNT=2    # Fewer retries
```

### For Slow Networks (WAN, > 50ms latency)

```bash
HEARTBEAT_INTERVAL=60      # 60 second heartbeat
HEARTBEAT_TIMEOUT=10       # Longer timeout
HEARTBEAT_RETRY_COUNT=5    # More retries
```

### For Unreliable Networks

```bash
HEARTBEAT_INTERVAL=20      # More frequent
HEARTBEAT_TIMEOUT=8        # Reasonable timeout
HEARTBEAT_RETRY_COUNT=5    # More attempts
HEARTBEAT_RETRY_DELAY=3    # Longer between retries
```

---

## Summary

The heartbeat client:

✅ Runs as systemd service on every node  
✅ Sends heartbeat every 30 seconds (configurable)  
✅ Automatically retries on failure  
✅ Collects and reports node metrics  
✅ Integrates with node lifecycle management  
✅ Enables automatic online/offline detection  
✅ Allows graceful recovery when nodes restart  

**Result**: Registry always knows which nodes are alive and healthy!


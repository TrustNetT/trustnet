# TrustNet: Network Topology Concepts

**Date**: January 31, 2026  
**Topic**: Full Network vs Isolated Network - Discovery Strategy

---

## Overview

TrustNet nodes can operate in different network environments. Understanding these environments is critical for proper discovery strategy and fallback behavior.

---

## Network Types

### 1. Full Network (Internet-Connected)

**Definition**: Node can reach both:
- ✅ Local network peers (multicast ff02::1)
- ✅ Remote registries (DNS, internet)

**Characteristics**:
- IPv6 multicast enabled on local segment
- Internet connectivity to root registry
- Can reach DNS TNR record
- Can establish HTTPS connections to remote registries

**Discovery Priority** (Hybrid Mode):
```
1. Try Multicast ff02::1 (instant discovery, local only)
2. Try DNS TNR record (reliable fallback, global reach)
3. Try Static peer (if explicitly configured)
```

**Example Scenarios**:
- Cloud deployment with internet access
- Corporate network with internet gateway
- Home lab with router connectivity
- Multi-site network with WAN link

---

### 2. Isolated Network (No Internet)

**Definition**: Node can reach:
- ✅ Local network peers (multicast ff02::1)
- ❌ Remote registries (no internet access)

**Characteristics**:
- IPv6 multicast enabled locally
- NO internet connectivity
- DNS might work (internal DNS) but can't reach external registries
- Firewall blocks outbound to remote networks
- Air-gapped or offline environment

**Discovery Implications**:

**Case 2a: Isolated with Registry Running Locally** ✅
```
1. Try Multicast ff02::1 → FOUND (registry broadcasting)
2. Use local registry
3. Network works perfectly (isolated but complete)
```

**Case 2b: Isolated with Registry NOT Running** ❌
```
1. Try Multicast ff02::1 → TIMEOUT (no registry advertising)
2. Try DNS TNR record → Returns address but...
3. Try Connect to TNR registry → TIMEOUT (unreachable)
4. Try Static peer (if configured) → May or may not work

Problem: We know registry address but can't reach it
Reason: Network is isolated, registry is down, or both
```

**Case 2c: Isolated with Only Static Peer** ✅
```
1. Try Multicast ff02::1 → TIMEOUT (no registry)
2. Try DNS TNR record → TIMEOUT (no internet)
3. Try Static peer → SUCCESS (explicitly configured)
4. Network works (if peer is reachable)
```

**Example Scenarios**:
- Factory/manufacturing network (air-gapped)
- Military/secure network (isolated)
- Development lab without internet
- Disaster recovery (temporary isolation)

---

### 3. Degraded Network (Partial Connectivity)

**Definition**: Node can reach some but not all resources

**Characteristics**:
- Multicast available locally
- DNS available locally but points to unreachable registries
- Some peers reachable, others not
- Intermittent connectivity

**Discovery Strategy**:
```
1. Try Multicast ff02::1 → FOUND or TIMEOUT (best guess)
2. If timeout: Try DNS (but expect timeouts)
3. If DNS fails: Fall back to static peer
4. If all fail: Report isolated status, suggest:
   - Wait for multicast discovery
   - Configure --peer with reachable node
   - Check network connectivity
```

---

## Discovery Strategy by Network Type

### Full Network (Hybrid Mode - Default)

```
┌─────────────────────────────────────┐
│  Full Network (Internet Connected)  │
└────────────────────┬────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   Multicast              DNS TNR Record
   ff02::1                (fallback)
   │                      │
   ├─ Found ──────┐      ├─ Success ─┐
   │              │      │           │
   └─ Timeout ────┼──────┤           │
                  │      │           │
            ┌─────┴──────┴─────┐     │
            │   Use Registry   │◄────┘
            │ (local or remote)│
            └──────────────────┘

Result: ✅ Node discovers and connects
Time: 0-5 seconds (multicast) or 1-3 seconds (DNS)
```

---

### Isolated Network (No Internet)

#### Scenario A: Isolated with Local Registry

```
┌─────────────────────────────────────┐
│ Isolated Network (Local Registry)   │
│ fd10:1234::253 running on multicast │
└────────────────────┬────────────────┘
                     │
                     ▼
              Multicast ff02::1
              │
              ├─ Found ──────┐
              │              │
              └─ Timeout ────X (shouldn't happen)
                             
         ┌────────────────────┐
         │  Use Local Registry│
         │ fd10:1234::253     │
         └────────────────────┘

Result: ✅ Node discovers locally
Time: 0-5 seconds (multicast)
Note: Registry MUST be broadcasting on multicast
```

#### Scenario B: Isolated with Registry Down

```
┌──────────────────────────────────────┐
│ Isolated Network (Registry Down)     │
│ No registry broadcasting on multicast│
└────────────────────┬─────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
   Multicast              DNS TNR Record
   ff02::1                (if configured)
   │                      │
   └─ TIMEOUT ───┐        └─ Returns: fd10:1234::253
                 │           │
                 │    ┌──────┘ (local DNS has entry)
                 │    │
                 │    ▼
                 │  Try Connect
                 │  │
                 │  └─ TIMEOUT ─────┐
                 │ (no internet)    │
                 │                  │
         ┌───────┴──────────────────┘
         │
         ▼
    Static Peer?
    │
    ├─ Provided? ─┐
    │             │
    │    ┌────────▼─────┐
    │    │ Try Connect  │
    │    │ --peer addr  │
    │    └────┬──────┬──┘
    │         │      │
    │     SUCCESS  FAIL
    │         │      │
    │    ┌────┘      └─► ❌ ERROR
    │    │
    │    ▼
    │ ✅ Use static peer
    │
    └─ Not Provided?
       │
       └─► ❌ ERROR: Cannot discover registry
           Recommendations:
           1. Start local registry on multicast
           2. Provide --peer fd10:1234::X
           3. Check network connectivity

Result: ❌ Node cannot discover
Reason: Isolated + no running registry + no peer configured
Solution: Requires manual intervention (--peer or start registry)
```

---

## Detection: Is This an Isolated Network?

### Detection Method 1: Multicast Timeout
```bash
# If multicast times out (5 seconds) and no response
→ Likely isolated (no registry broadcasting)
→ Fall back to DNS or static peer
```

### Detection Method 2: DNS Reachable but Registry Unreachable
```bash
# DNS lookup succeeds: fd10:1234::253
# But curl -k https://[fd10:1234::253]:8053/health → TIMEOUT (5+ seconds)
→ Network is ISOLATED or registry is DOWN
→ We need to distinguish:
  - Option A: Use multicast for local discovery
  - Option B: Use static peer if configured
  - Option C: Error - cannot reach remote registry
```

### Detection Method 3: Explicit Configuration
```bash
# User specifies: --discovery static-only
→ Treating as isolated network
→ Only try configured peer
```

---

## Improved Discovery Algorithm

### Current: Simple Fallback Chain
```
Multicast → DNS → Static → Error
```

### Proposed: Network-Aware Fallback

```
1. Try Multicast ff02::1 (5 second timeout)
   │
   ├─ FOUND ──────────────────────────► Use multicast registry
   │
   └─ TIMEOUT (no response)
       │
       ├─ DNS TNR record configured?
       │  │
       │  ├─ YES: Try DNS lookup
       │  │   │
       │  │   ├─ Lookup successful, get IP
       │  │   │  │
       │  │   │  └─ Try connect to IP (5 sec timeout)
       │  │   │     │
       │  │   │     ├─ SUCCESS ──────► Use remote registry
       │  │   │     │
       │  │   │     └─ TIMEOUT/FAIL
       │  │   │         │
       │  │   │         └─ Check status (see below)
       │  │   │
       │  │   └─ Lookup failed (no internet)
       │  │       │
       │  │       └─ Network is ISOLATED
       │  │           → Try static peer
       │  │
       │  └─ NO: DNS not configured
       │      │
       │      └─ Try static peer (if provided)
       │
       └─ Multicast timeout + No DNS
           → Network is ISOLATED
           → MUST have static peer or fail

Status Detection:
├─ Full Network: Multicast found OR DNS worked
├─ Isolated Network: Multicast timeout + DNS failed/unreachable
└─ Degraded: Some mechanisms work, others fail
```

---

## Implementation: Network Status Indicators

### Add Network Status to Configuration

```bash
# In ~/.trustnet/node-*.conf, track:

# Network connectivity status
NETWORK_STATUS=full|isolated|degraded|unknown

# Last successful discovery method
LAST_DISCOVERY_METHOD=multicast|dns|static|none

# Available mechanisms
AVAILABLE_MECHANISMS=multicast,dns,static
# Example: AVAILABLE_MECHANISMS=multicast,dns (isolated has only multicast)

# Timestamps for troubleshooting
DISCOVERY_TIME_MULTICAST=2026-01-31T10:00:00Z
DISCOVERY_TIME_DNS=<timeout>
DISCOVERY_TIME_STATIC=2026-01-31T10:00:05Z
```

---

## Handling Each Case

### Case 1: Full Network + Registry Running ✅

```bash
bash install.sh --auto

# Node discovers via fastest method (usually multicast)
# Status: NETWORK_STATUS=full
# All mechanisms available
# SUCCESS
```

### Case 2: Full Network + Registry Down ⚠️

```bash
bash install.sh --auto

# Multicast fails (no broadcaster)
# DNS falls back and works
# Status: NETWORK_STATUS=full (DNS confirmed internet)
# SUCCESS (via DNS)
```

### Case 3: Isolated + Local Registry Running ✅

```bash
bash install.sh --auto

# Multicast finds registry (broadcasting locally)
# Status: NETWORK_STATUS=isolated (inferred from no DNS)
# SUCCESS
```

### Case 4: Isolated + Local Registry Down + Static Peer ✅

```bash
bash install.sh --auto --discovery static-only --peer fd10:1234::1

# Multicast fails (no broadcaster)
# DNS fails (no internet)
# Static peer succeeds
# Status: NETWORK_STATUS=isolated
# SUCCESS (via static peer)
```

### Case 5: Isolated + Local Registry Down + No Static Peer ❌

```bash
bash install.sh --auto

# Multicast fails (no broadcaster)
# DNS fails (no internet)
# No static peer
# Status: NETWORK_STATUS=isolated
# ERROR: Cannot discover registry

# Suggested recovery:
# 1. Start registry locally: bootstrap must start first
# 2. Or provide static peer: --peer fd10:1234::X
# 3. Check multicast connectivity: ping6 ff02::1
```

---

## Updated Fallback Logic

### Pseudo-Code for Discovery

```bash
function discover_registries(mode, peer, domain)
    
    # Mode: hybrid|multicast-only|dns-only|static-only
    
    if mode == "multicast-only"
        try_multicast()
        return
    fi
    
    if mode == "dns-only"
        try_dns()
        return
    fi
    
    if mode == "static-only"
        try_static_peer()
        return
    fi
    
    # HYBRID MODE (default):
    # Network-aware fallback
    
    # Step 1: Try multicast (fastest, local only)
    result = try_multicast()
    if result == SUCCESS
        NETWORK_STATUS = "full or isolated" (unclear)
        return result
    fi
    
    # Step 2: Multicast failed, try DNS (5+ sec timeout means no internet)
    result = try_dns()
    if result == SUCCESS
        NETWORK_STATUS = "full"
        return result
    fi
    
    if result == TIMEOUT or NO_INTERNET
        NETWORK_STATUS = "isolated"
        # Don't retry DNS, move to static peer
    fi
    
    # Step 3: Try static peer (explicit fallback)
    if peer is provided
        result = try_static_peer(peer)
        if result == SUCCESS
            NETWORK_STATUS = "isolated"
            return result
        fi
    fi
    
    # Step 4: All mechanisms failed
    NETWORK_STATUS = "isolated"
    
    if NETWORK_STATUS == "isolated"
        print "ERROR: Isolated network, cannot discover registry"
        print "Options:"
        print "  1. Start local registry (bootstrap must run first)"
        print "  2. Provide static peer: --peer fd10:1234::X"
        print "  3. Check multicast: ping6 ff02::1"
    else
        print "ERROR: Cannot discover registry, check connectivity"
    fi
    
    return FAILURE
end
```

---

## Documentation Updates Needed

### 1. Add to HYBRID_DISCOVERY_GUIDE.md

**New Section**: "Network Topology & Discovery"
- Define Full Network vs Isolated Network
- Show which mechanisms work in each
- Detection strategy

### 2. Add to QUICK_START_TESTING.md

**New Section**: "Isolated Network Testing"
- How to simulate isolated environment
- Test without internet access
- Test with static peer

### 3. Add to troubleshooting

**Scenario**: "Registry address in DNS but can't reach it"
- Diagnosis: Likely isolated network
- Solutions: Start local registry or use --peer

---

## Benefits of This Approach

✅ **Clearer diagnosis**: Know if you're isolated or not  
✅ **Better recovery**: Different solutions for different problems  
✅ **Faster fallback**: Don't keep retrying impossible connections  
✅ **Better error messages**: Tell user what to do based on network type  
✅ **Supports edge cases**: Works in air-gapped environments  
✅ **Still backwards compatible**: Hybrid mode works everywhere  

---

## Summary

| Network Type | Multicast | DNS | Static | Outcome |
|---|---|---|---|---|
| Full, registry running | ✅ Instant | ✅ Fallback | Optional | ✅ Succeeds via multicast |
| Full, registry down | ❌ Timeout | ✅ Works | Optional | ✅ Succeeds via DNS |
| Isolated, local registry | ✅ Works | ❌ Timeout | Optional | ✅ Succeeds via multicast |
| Isolated, no registry | ❌ Timeout | ❌ Timeout | ✅ Required | ✅ Succeeds via static peer |
| Isolated, no registry, no peer | ❌ Timeout | ❌ Timeout | ❌ Missing | ❌ FAILS (need manual intervention) |

**Key insight**: In isolated networks, multicast is the ONLY discovery mechanism that works (registry must be broadcasting). DNS and remote peers are unreachable. This needs to be understood and designed for!


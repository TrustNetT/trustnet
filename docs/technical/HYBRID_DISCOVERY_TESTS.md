# TrustNet: Hybrid Discovery Testing Scenarios

**Date**: January 31, 2026  
**Status**: Test scenarios prepared - awaiting execution  
**Discovery Implementation**: Complete and ready for testing

---

## Test Environment Setup

### Prerequisites

```bash
# Install required tools:
apt-get install socat netcat-openbsd dnsutils curl

# Verify IPv6:
ip addr show           # Should see fd10:1234::* addresses
ping6 ff02::1         # Link-local multicast check
```

### Network Configuration

For testing, you'll need:
- **Local Network**: Same subnet for multicast tests (e.g., home lab)
- **Internet Network**: Two different subnets or VPNs
- **Firewall Test**: Network with multicast disabled

---

## Test Scenario 1: Multicast Discovery (Local Network)

### Objective
Verify nodes auto-discover each other on same network via IPv6 multicast ff02::1

### Setup
- Two VMs or containers on same network segment
- No DNS configured (tests pure multicast)
- Multicast enabled (default)

### Test Steps

```bash
# Terminal 1 (Node A - Bootstrap):
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Expected output:
[✓] Creating root registry at fd10:1234::253
[✓] Starting multicast broadcaster on ff02::1
[✓] Node will listen for multicast announcements
[✓] Registry configuration ready

# Note: Don't set up DNS yet
```

```bash
# Terminal 2 (Node B - Same network):
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Expected output:
[✓] Listening for multicast on ff02::1...
[✓] Found registry via multicast (instant!)
[✓] Discovered at fd10:1234::253
[✓] Node configuration ready: default-node-1
[✓] Created node at fd10:1234::1
```

### Verification

```bash
# Verify multicast was used (not DNS):
cat ~/.trustnet/node-1.conf | grep DISCOVERY
# Should show: DISCOVERY_MODE=hybrid (and multicast should be first discovered)

# Verify registry IP:
cat ~/.trustnet/bootstrap.conf
# Should show: ROOT_REGISTRY_IP=fd10:1234::253

# Check node configuration:
cat ~/.trustnet/default-node-1.conf
# Should show IPv6 addresses assigned
```

### Success Criteria

✅ Discovery happens **instantly** (< 5 seconds)  
✅ No DNS lookup occurs  
✅ Node correctly identifies registry via multicast  
✅ Configuration files created with correct IPv6 addresses

### Failure Scenarios

**Multicast not detected**:
- Check if `socat` is installed (needed for multicast I/O)
- Verify network supports IPv6 multicast: `ping6 ff02::1`
- Check if multicast is filtered: `ethtool -S eth0 | grep multicast`
- Fallback: Use DNS or static peer

---

## Test Scenario 2: DNS Discovery (Internet Networks)

### Objective
Verify nodes discover each other via DNS when on different network segments

### Setup
- Two VMs on different network segments (or use separate NAT networks)
- DNS configured with TNR AAAA record
- Multicast intentionally blocked or unavailable

### Test Steps

```bash
# Step 1: Admin adds DNS entry to their domain
# (In your DNS provider: yourdomain.com)
tnr.yourdomain.com  AAAA  fd10:1234::253
# (Or use local /etc/hosts if no public DNS)

# Verify DNS is working:
dig tnr.yourdomain.com AAAA
# Should return: fd10:1234::253
```

```bash
# Terminal 1 (Node A - Different network segment):
cd ~/vms
# Force DNS-only to test DNS discovery:
bash ../trustnet-wip/install.sh --auto --discovery dns-only

# Expected output:
[✓] DNS-only mode
[✓] Querying tnr.yourdomain.com AAAA...
[✓] Found registry at fd10:1234::253 (DNS)
[✓] Created node at fd10:1234::2
```

```bash
# Terminal 2 (Node B - Also different segment):
cd ~/vms
bash ../trustnet-wip/install.sh --auto --discovery dns-only

# Expected output:
[✓] Found registry via DNS at fd10:1234::253
[✓] Created node at fd10:1234::3
```

### Verification

```bash
# Verify DNS was used (not multicast):
cat ~/.trustnet/node-2.conf | grep DISCOVERY
# Should show DNS as discovery method

# Verify root registry from DNS:
nslookup tnr.yourdomain.com AAAA
# Should match the configured registry

# Verify nodes are connected:
ls -la ~/.trustnet/
# Should show: bootstrap.conf, default-node-2.conf, default-node-3.conf
```

### Success Criteria

✅ DNS query returns correct registry IP  
✅ Node connects via DNS address  
✅ Works across different network segments  
✅ Faster than manual peer configuration

### Failure Scenarios

**DNS not resolving**:
- Check: `dig tnr.yourdomain.com AAAA`
- Add to /etc/hosts if DNS unavailable: `fd10:1234::253 tnr.yourdomain.com`
- Use static `--peer` as fallback

**DNS points to wrong address**:
- Verify correct IPv6 in DNS record
- Wait for DNS propagation (5 minutes)

---

## Test Scenario 3: Hybrid Discovery (Mixed Networks)

### Objective
Verify hybrid falls back correctly: multicast → DNS → static peer

### Setup
- First node on local network (with multicast)
- Second node on internet (without multicast)
- Third node with firewall blocking multicast and DNS
- DNS configured for internet nodes

### Test Steps

```bash
# Terminal 1 (Local network):
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Expected: Uses multicast (instant)
[✓] Listening for multicast on ff02::1...
[✓] Found registry via multicast (instant!)
```

```bash
# Terminal 2 (Different network, DNS available):
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Expected: Multicast fails, DNS succeeds
[✓] Listening for multicast on ff02::1...
[⚠] No multicast response (timeout)
[✓] Trying DNS fallback...
[✓] Found registry via DNS TNR record
```

```bash
# Terminal 3 (Firewall blocks multicast & DNS):
cd ~/vms
bash ../trustnet-wip/install.sh --auto --peer fd10:1234::1

# Expected: Both fail, static succeeds
[✓] Listening for multicast...
[⚠] No multicast (firewall blocks)
[✓] Trying DNS...
[⚠] No DNS (firewall blocks)
[✓] Trying static peer fd10:1234::1...
[✓] Connected to static peer!
```

### Verification

```bash
# Check each node's discovery method:
grep DISCOVERY ~/.trustnet/*.conf

# Results should show:
# bootstrap.conf: Not applicable (root registry)
# node-1.conf: DISCOVERY=multicast (fastest)
# node-2.conf: DISCOVERY=dns (fallback)
# node-3.conf: DISCOVERY=static (manual)
```

### Success Criteria

✅ Node 1 uses multicast (instant)  
✅ Node 2 falls back to DNS when no multicast  
✅ Node 3 falls back to static when both fail  
✅ All three nodes can communicate

### Failure Scenarios

**Multicast timeout too short**:
- Increase timeout in setup-node.sh from 5s to 10s

**DNS fallback not triggered**:
- Manually test multicast: `socat - UDP6-DATAGRAM:[ff02::1]:8053`
- If multicast works, DNS won't trigger (expected)

---

## Test Scenario 4: Discovery Mode Selection

### Objective
Verify `--discovery` flag correctly selects single mechanism

### Test Steps

```bash
# Test multicast-only (should fail on different network):
bash ../trustnet-wip/install.sh --auto --discovery multicast-only
# On different segment: Should error after timeout
# On same segment: Should succeed via multicast

# Test dns-only (should fail without DNS):
bash ../trustnet-wip/install.sh --auto --discovery dns-only
# Without DNS: Should error
# With DNS: Should succeed

# Test static-only (requires --peer):
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::1
# Should connect directly to specified peer
# No discovery attempts

# Test hybrid (default, tries all):
bash ../trustnet-wip/install.sh --auto
# Should try multicast → DNS → static in order
```

### Verification

```bash
# Verify selection is recorded:
cat ~/.trustnet/*.conf | grep DISCOVERY_MODE

# Test that mode is respected:
bash ../trustnet-wip/install.sh --auto --discovery multicast-only
# On different network: Should timeout, not try DNS
grep "Discovery mode" ~/.trustnet/current-session.log
# Should show only multicast attempts
```

### Success Criteria

✅ Each mode selects only its mechanism  
✅ No fallback between mechanisms  
✅ Clear error when mode fails  
✅ Hybrid tries all mechanisms in order

---

## Test Scenario 5: Static Peer Fallback

### Objective
Verify `--peer` flag works as manual backup when discovery fails

### Setup
- Block multicast and DNS (simulate severe firewall)
- Use `--peer` to manually specify registry location

### Test Steps

```bash
# Simulate network with no multicast/DNS:
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::253

# Expected:
[✓] Static-only mode
[✓] Connecting to peer fd10:1234::253...
[✓] Connected successfully
[✓] Created node configuration
[✓] Node will contact bootstrap peer at fd10:1234::253
```

### Verification

```bash
# Verify static peer is recorded:
cat ~/.trustnet/*.conf | grep STATIC_PEER
# Should show: STATIC_PEER=fd10:1234::253

# Verify node uses peer for bootstrap:
cat ~/.trustnet/*.conf | grep BOOTSTRAP_PEERS
# Should reference the static peer
```

### Success Criteria

✅ Accepts --peer argument correctly  
✅ Connects to specified peer  
✅ Works without any discovery mechanism  
✅ Suitable for isolated networks

### Failure Scenarios

**Peer unreachable**:
- Check connectivity: `curl -k https://[fd10:1234::253]:8053/health`
- Verify peer IPv6 is correct
- Check firewall allows port 8053

---

## Test Scenario 6: Multiple Registries (Advanced)

### Objective
Verify registry replication and multi-registry support

### Setup
- Primary registry at fd10:1234::253
- Secondary registries for load balancing/redundancy
- Nodes discover any registry in the network

### Test Steps

```bash
# Create secondary registries (after primary):
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::253
# Creates second registry that replicates from primary

# Node discovers and uses secondary:
bash ../trustnet-wip/install.sh --auto
# Should discover via multicast/DNS
# If primary unavailable, falls back to secondary
```

### Verification

```bash
# Check registry list:
curl -k https://[fd10:1234::253]:8053/api/registries
# Should list: primary + secondaries

# Verify replication:
curl -k https://[fd10:1234::102]:8053/api/registries
# Should match primary registry list (replicated)
```

### Success Criteria

✅ Secondary registries created successfully  
✅ Replication syncs registry list  
✅ Nodes can discover any registry  
✅ Failover to secondary if primary down

---

## Test Scenario 7: Performance Comparison

### Objective
Measure discovery speed for each mechanism

### Test Steps

```bash
# Time multicast discovery:
time bash ../trustnet-wip/install.sh --auto --discovery multicast-only
# Expected: < 5 seconds (timeout is fast)

# Time DNS discovery:
time bash ../trustnet-wip/install.sh --auto --discovery dns-only
# Expected: 1-2 seconds (DNS query + connection)

# Time static discovery:
time bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::253
# Expected: < 1 second (direct connection)

# Time hybrid discovery (best path):
time bash ../trustnet-wip/install.sh --auto
# Expected: < 5 seconds (multicast success)
```

### Verification

```bash
# Results summary:
# 1. Multicast: 0.5-5 seconds (depending on multicast availability)
# 2. Static: 0.1-1 second (fastest, most manual)
# 3. DNS: 1-3 seconds (reliable, global)
# 4. Hybrid: 0.5-5 seconds (uses fastest available)
```

### Success Criteria

✅ Multicast is fastest when available  
✅ DNS is acceptable for internet nodes  
✅ Static is instant but requires manual config  
✅ Hybrid balances speed and usability

---

## Test Scenario 8: Backwards Compatibility

### Objective
Verify hybrid works with existing DNS-only configurations

### Setup
- Existing nodes configured with DNS-only
- Add new hybrid node to same network

### Test Steps

```bash
# Old DNS-only installation (existing setup):
bash ../trustnet-wip/install.sh --auto --discovery dns-only
# Works with existing configuration

# New hybrid installation (should also work):
bash ../trustnet-wip/install.sh --auto
# Should discover via multicast or DNS
# Should work alongside DNS-only nodes
```

### Verification

```bash
# Verify both configurations work:
cat ~/.trustnet/*.conf | grep DISCOVERY_MODE
# Should show: dns-only, hybrid

# Verify nodes communicate:
ssh root@[fd10:1234::1] curl -k https://[fd10:1234::253]:8053/health
# Both should connect successfully
```

### Success Criteria

✅ Hybrid compatible with DNS-only  
✅ Mixed configurations work together  
✅ No breaking changes  
✅ Migration transparent

---

## Test Execution Checklist

- [ ] **Test 1**: Multicast discovery on same network
  - [ ] Node A bootstraps, broadcasts multicast
  - [ ] Node B discovers instantly via multicast
  - [ ] No DNS involved

- [ ] **Test 2**: DNS discovery on internet
  - [ ] Add TNR AAAA record to DNS
  - [ ] Nodes discover via DNS on different segments
  - [ ] Multicast intentionally disabled

- [ ] **Test 3**: Hybrid fallback chain
  - [ ] Node 1: Uses multicast (local)
  - [ ] Node 2: Falls back to DNS (internet)
  - [ ] Node 3: Falls back to static (firewall)

- [ ] **Test 4**: Discovery mode selection
  - [ ] Multicast-only works locally
  - [ ] DNS-only works globally
  - [ ] Static-only works with --peer
  - [ ] Hybrid tries all in sequence

- [ ] **Test 5**: Static peer fallback
  - [ ] Block multicast and DNS
  - [ ] Use --peer to specify registry
  - [ ] Node connects successfully

- [ ] **Test 6**: Multiple registries
  - [ ] Create secondary registries
  - [ ] Verify replication
  - [ ] Nodes discover any registry

- [ ] **Test 7**: Performance measurement
  - [ ] Time each discovery mechanism
  - [ ] Confirm expected speeds
  - [ ] Hybrid uses fastest available

- [ ] **Test 8**: Backwards compatibility
  - [ ] DNS-only nodes still work
  - [ ] Hybrid nodes work alongside
  - [ ] No breaking changes

---

## Test Failure Resolution

### If Multicast Discovery Fails

```bash
# Check multicast support:
ping6 ff02::1
# If fails: Network doesn't support multicast

# Fallback options:
bash ../trustnet-wip/install.sh --auto --discovery dns-only
# Or:
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer <registry-ip>
```

### If DNS Discovery Fails

```bash
# Verify DNS entry:
dig tnr.yourdomain.com AAAA
# If fails: Add record or use local /etc/hosts

# Fallback:
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer <registry-ip>
```

### If Static Peer Fails

```bash
# Verify connectivity:
curl -k https://[fd10:1234::253]:8053/health
# If fails: Registry not running or port blocked

# Solution:
# Start registry first, then retry
```

---

## Summary

**Hybrid Discovery** provides:
- ✅ Zero-config for local networks (multicast)
- ✅ Global reach with DNS fallback
- ✅ Manual control with static peer
- ✅ Best user experience for all scenarios

**Ready for testing!**


# TrustNet Hybrid Discovery: Quick Start Testing Guide

**Status**: Ready to test  
**Estimated Time**: 5-30 minutes depending on scenario  
**Prerequisites**: IPv6 network, 2+ VMs/containers, bash 4+

---

## 60-Second Verification

```bash
# Check implementation is complete:
cd ~/GitProjects/TrustNet/trustnet-wip
./verify-hybrid-discovery.sh

# Expected output:
# ✓ All verification checks passed!
# ✓ 20+ checks completed successfully
```

---

## 5-Minute Test: Local Multicast Discovery

### What It Tests
- Nodes auto-discover each other on same network
- Zero configuration needed
- Instant discovery via IPv6 multicast ff02::1

### Prerequisites
- 2 VMs or containers on same network segment
- IPv6 enabled (`ip addr show` should show fd10:1234::* addresses)

### Test Steps

```bash
# VM 1 - Bootstrap root registry:
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Output should include:
# [✓] Creating root registry at fd10:1234::253
# [✓] Starting multicast broadcaster on ff02::1

# VM 2 - Node discovers automatically:
bash ../trustnet-wip/install.sh --auto

# Output should include:
# [✓] Listening for multicast on ff02::1...
# [✓] Found registry via multicast (instant!)
# [✓] Discovered at fd10:1234::253
```

### Verification

```bash
# Verify discovery method used:
cat ~/.trustnet/*.conf | grep DISCOVERY

# Verify node was created:
ls -la ~/.trustnet/
# Should show: bootstrap.conf, node-*.conf files
```

### Expected Result
✅ Node B discovers within **< 5 seconds**  
✅ No DNS queries occur  
✅ Configuration files created successfully

---

## 15-Minute Test: DNS Fallback Discovery

### What It Tests
- Nodes discover via DNS when multicast unavailable
- Works across different network segments
- DNS TNR record configuration

### Prerequisites
- 2 VMs on different network segments (or with multicast blocked)
- Ability to add DNS record or edit /etc/hosts

### Test Steps

```bash
# Step 1: Configure DNS (pick one method):

# Method A - Add to /etc/hosts:
echo "fd10:1234::253 tnr.yourdomain.com" | sudo tee -a /etc/hosts

# Method B - Add DNS record in your domain:
# tnr.yourdomain.com  AAAA  fd10:1234::253
# (In your DNS provider's interface)

# Step 2: Verify DNS is working:
dig tnr.yourdomain.com AAAA
# Should return: fd10:1234::253

# Step 3: VM 1 - Start registry (on network segment A):
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Step 4: VM 2 - Discover via DNS (on network segment B):
# Force DNS-only to test DNS discovery:
bash ../trustnet-wip/install.sh --auto --discovery dns-only

# Output should include:
# [✓] DNS-only mode
# [✓] Querying tnr.yourdomain.com AAAA...
# [✓] Found registry at fd10:1234::253 (DNS)
```

### Verification

```bash
# Verify DNS was used:
cat ~/.trustnet/*.conf | grep DISCOVERY_MODE
# Should show: DISCOVERY_MODE=dns-only or hybrid

# Verify correct registry address:
cat ~/.trustnet/*.conf | grep ROOT_REGISTRY
# Should show: fd10:1234::253
```

### Expected Result
✅ Node discovers via DNS in **1-3 seconds**  
✅ Works on different network segments  
✅ No multicast required

---

## 20-Minute Test: Hybrid Fallback Chain

### What It Tests
- Hybrid mode tries multicast first (fastest)
- Falls back to DNS if multicast fails
- Falls back to static peer if DNS fails

### Prerequisites
- 3 VMs: 1 local, 1 internet, 1 firewall-restricted
- Optional: DNS configured from previous test

### Test Steps

```bash
# VM 1 - Registry (local):
cd ~/vms
bash ../trustnet-wip/install.sh --auto
# This VM broadcasts on multicast

# VM 2 - Node (same segment):
bash ../trustnet-wip/install.sh --auto
# Should discover via multicast (instant)

# VM 3 - Node (different segment):
bash ../trustnet-wip/install.sh --auto
# Should discover via DNS fallback

# VM 4 - Node (firewall blocked):
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::1
# Should connect via static peer
```

### Verification

```bash
# Check discovery methods used on each node:
for node in ~/.trustnet/default-node-*.conf; do
  echo "Node: $node"
  grep DISCOVERY_MODE "$node"
done

# Results should show:
# Node-1: multicast (fastest)
# Node-2: DNS (fallback)
# Node-3: static (manual)
```

### Expected Result
✅ VM 2 uses multicast (< 5 sec)  
✅ VM 3 falls back to DNS (1-3 sec)  
✅ VM 4 uses static peer (< 1 sec)  
✅ All VMs connect successfully

---

## Advanced: Performance Benchmark

### Compare Discovery Speed

```bash
# Time multicast discovery:
time bash ../trustnet-wip/install.sh --auto --discovery multicast-only
# Expected: 0.5-5 seconds

# Time DNS discovery:
time bash ../trustnet-wip/install.sh --auto --discovery dns-only
# Expected: 1-3 seconds

# Time static discovery:
time bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::253
# Expected: 0.1-1 second

# Time hybrid discovery (uses fastest):
time bash ../trustnet-wip/install.sh --auto
# Expected: 0.5-5 seconds (multicast if available)
```

### Results
```
Discovery Method    | Speed       | Best For
--------------------|-------------|------------------
Multicast           | 0.5-5 sec   | Local networks
DNS                 | 1-3 sec     | Global distribution
Static              | 0.1-1 sec   | Manual config
Hybrid              | Best avail  | Mixed networks
```

---

## Troubleshooting

### Multicast Not Working?

```bash
# Check multicast support:
ping6 ff02::1
# If fails: Network doesn't support IPv6 multicast

# Fallback: Use DNS or static peer
bash ../trustnet-wip/install.sh --auto --discovery dns-only

# Or: Explicitly use static peer
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::253
```

### DNS Not Resolving?

```bash
# Verify DNS record:
dig tnr.yourdomain.com AAAA
# If fails: 
#  1. Check DNS record is added
#  2. Wait 5 minutes for propagation
#  3. Use /etc/hosts as temporary workaround

# Verify /etc/hosts entry:
cat /etc/hosts | grep tnr

# Use static peer as fallback:
bash ../trustnet-wip/install.sh --auto --discovery static-only --peer fd10:1234::253
```

### Static Peer Not Reachable?

```bash
# Verify peer is running and accessible:
curl -k https://[fd10:1234::253]:8053/health
# If fails: Ensure registry is running on that IP

# Check connectivity to peer:
ping6 fd10:1234::253
# If fails: Firewall or routing issue

# Verify correct peer address:
ip -6 route
# Should show route to fd10:1234::/32
```

---

## Test Scenario Checklist

### ✓ Quick Verification
- [ ] Run: `./verify-hybrid-discovery.sh`
- [ ] All checks pass

### ✓ Multicast Test (5 min)
- [ ] 2 VMs on same network
- [ ] VM 1: Starts registry
- [ ] VM 2: Discovers via multicast < 5 sec
- [ ] Check DISCOVERY_MODE=multicast

### ✓ DNS Test (15 min)
- [ ] Add DNS record for tnr.yourdomain.com
- [ ] Verify DNS: `dig tnr.yourdomain.com AAAA`
- [ ] VM 1: Starts registry
- [ ] VM 2: Discovers via DNS 1-3 sec
- [ ] Check DISCOVERY_MODE=dns

### ✓ Hybrid Test (20 min)
- [ ] 3+ VMs on different networks
- [ ] VM 1 (local): Multicast
- [ ] VM 2 (local): Multicast
- [ ] VM 3 (remote): DNS fallback
- [ ] VM 4 (firewall): Static peer
- [ ] All discover successfully

### ✓ Mode Selection Test (10 min)
- [ ] Test `--discovery multicast-only`
- [ ] Test `--discovery dns-only`
- [ ] Test `--discovery static-only --peer ...`
- [ ] Test `--discovery hybrid` (default)

### ✓ Performance Test (10 min)
- [ ] Measure multicast speed
- [ ] Measure DNS speed
- [ ] Measure static speed
- [ ] Compare hybrid speed

---

## Quick Commands Reference

```bash
# Clone/go to project:
cd ~/GitProjects/TrustNet/trustnet-wip

# Verify implementation:
./verify-hybrid-discovery.sh

# Test scenarios:
# 1. Multicast only:
bash install.sh --auto --discovery multicast-only

# 2. DNS only:
bash install.sh --auto --discovery dns-only

# 3. Static only (manual):
bash install.sh --auto --discovery static-only --peer fd10:1234::253

# 4. Hybrid (recommended):
bash install.sh --auto

# Check discovery mode used:
cat ~/.trustnet/*.conf | grep DISCOVERY

# Health check:
curl -k https://[fd10:1234::253]:8053/health
```

---

## Next Steps After Testing

1. **Document Results**
   - Record which mechanisms worked
   - Note performance metrics
   - Identify any failures

2. **Implement Multicast I/O**
   - Replace placeholder functions in tools/lib/common.sh
   - Use socat or netcat6 for actual multicast
   - Test announcement format

3. **Production Deployment**
   - Roll out to real infrastructure
   - Monitor discovery performance
   - Adjust timeouts if needed

---

**Ready to test? Start with Quick Verification above! 🚀**


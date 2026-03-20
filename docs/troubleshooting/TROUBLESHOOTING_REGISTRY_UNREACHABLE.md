# TrustNet Troubleshooting: "Registry Exists But Not Running"

**Scenario**: TNR DNS record exists (points to fd10:1234::253) but the registry is not running or not reachable  
**Network Status**: ISOLATED (cannot reach registry)  
**Solution**: Depends on your situation

---

## Symptoms

You see one of these error messages:

```
✗ Cannot discover registry (all mechanisms failed)
✗ DNS address found but unreachable
✗ Cannot reach [fd10:1234::253] - likely ISOLATED NETWORK
```

And you notice:
- DNS lookup works: `dig tnr.yourdomain.com AAAA` returns `fd10:1234::253`
- But curl fails: `curl -k https://[fd10:1234::253]:8053/health` → TIMEOUT

---

## Diagnosis Flowchart

```
DNS record exists but registry unreachable?
│
├─ On same local network as registry?
│  │
│  ├─ YES → Registry crashed/not running
│  │        └─ START registry (see below)
│  │
│  └─ NO → Different network segment
│         │
│         ├─ Have internet access?
│         │  │
│         │  ├─ YES → Firewall blocking (DNS works, HTTPS blocked)
│         │  │        └─ Check firewall rules
│         │  │
│         │  └─ NO → ISOLATED NETWORK
│         │         └─ Use static peer (see below)
│         │
│         └─ Network is ISOLATED
│            └─ Use static peer on local network
```

---

## Case 1: Registry Crashed/Not Running (Local Network)

### Symptoms
- You're on the same network as the registry
- DNS returns correct IP
- But curl times out
- Multicast also fails

### Diagnosis

```bash
# Check if registry is running:
ps aux | grep -i registry
ps aux | grep -i trustnet

# Check if port 8053 is listening:
netstat -tulpn | grep 8053
ss -tulpn | grep 8053

# Try direct connection:
curl -k https://[fd10:1234::253]:8053/health
# Expected: connection refused or timeout (instead of connection established)

# Check logs (if available):
journalctl -u trustnet-registry -n 50
docker logs trustnet-registry
```

### Solution: Start Registry

**Option A: Bootstrap registry** (if it's the root registry)
```bash
# Go to the bootstrap node
cd /path/to/trustnet
bash tools/setup-root-registry.sh

# This will:
# ✓ Create root registry at fd10:1234::253
# ✓ Start HTTPS on port 8053
# ✓ Begin broadcasting on multicast ff02::1
```

**Option B: Check registry status** (if already created)
```bash
# Check if services are running:
systemctl status trustnet-registry
docker ps | grep registry

# Restart if crashed:
systemctl restart trustnet-registry
docker restart trustnet-registry
```

**Option C: Check HTTPS certificate**
```bash
# Registry needs Let's Encrypt certificate
# Check if certificate is valid:
curl -k -v https://[fd10:1234::253]:8053/health

# Look for certificate issues:
openssl s_client -connect [fd10:1234::253]:8053

# If certificate expired:
# Caddy should auto-renew, or restart Caddy:
systemctl restart caddy
docker restart caddy
```

### After Restarting Registry

```bash
# Verify registry is running:
curl -k https://[fd10:1234::253]:8053/health
# Should return: 200 OK (or similar health response)

# Verify multicast is broadcasting:
# (Once actual multicast I/O is implemented)

# Try node discovery again:
bash install.sh --auto
# Should now discover via multicast (instant) or DNS
```

---

## Case 2: Isolated Network (Different Segment)

### Symptoms
- You're on a different network segment than the registry
- DNS works (returns registry IP)
- But you can't reach it (firewall/no internet)
- Multicast doesn't work (different segment)

### Diagnosis

```bash
# Verify DNS works:
dig tnr.yourdomain.com AAAA
# Should return: fd10:1234::253

# Try to reach registry IP:
curl -k https://[fd10:1234::253]:8053/health
# Will timeout (can't reach, firewall blocks, or no route)

# Check if it's network isolation:
ping6 fd10:1234::253
# If this times out: ISOLATED NETWORK confirmed

# Check local network for available peers:
ping6 ff02::1
# If this fails: No multicast on this segment
```

### Solution: Use Static Peer

**Find a peer on your local network**:
```bash
# Ask network admin or check:
# - Existing node on your segment
# - Another registry on your segment
# Common addresses: fd10:1234::1 (Node-1), fd10:1234::2 (Node-2)
```

**Use static peer discovery**:
```bash
# If you know a peer on your local network:
bash install.sh --auto --discovery static-only --peer fd10:1234::1

# Result:
# ✓ Connects directly to fd10:1234::1
# ✓ Doesn't need DNS or multicast
# ✓ Works in isolated networks
```

**Verify it works**:
```bash
# Check configuration:
cat ~/.trustnet/node-*.conf

# Verify registry was discovered:
curl -k https://[discovered_registry]:8053/health
```

---

## Case 3: Firewall Blocking HTTPS

### Symptoms
- DNS works (returns IP)
- Ping works (can reach IP)
- But curl times out or connection refused
- Likely firewall blocking port 8053

### Diagnosis

```bash
# Check if port 8053 is reachable:
curl -k -v https://[fd10:1234::253]:8053/health
# Look at "Trying fd10:1234::253:8053..."
# Then "Connection refused" or timeout

# Check firewall rules:
sudo iptables -L -n | grep 8053
sudo nft list ruleset | grep 8053

# Check if you're behind a proxy:
echo $http_proxy $https_proxy
```

### Solution: Configure Firewall

**Allow outbound HTTPS (if admin)**:
```bash
# Allow TCP port 8053 to registry:
sudo iptables -A OUTPUT -d fd10:1234::253 -p tcp --dport 8053 -j ACCEPT
```

**Or use different discovery mode**:
```bash
# If multicast available on local segment:
bash install.sh --auto --discovery multicast-only

# If you have a peer on your segment:
bash install.sh --auto --discovery static-only --peer fd10:1234::X
```

---

## Case 4: DNS Points to Wrong Address

### Symptoms
- DNS returns an IP
- But that's not the actual registry
- Connection times out or connects to wrong service

### Diagnosis

```bash
# Verify DNS record:
dig tnr.yourdomain.com AAAA +short
# Should return: fd10:1234::253

# Verify registry is at that address:
curl -k https://[returned_ip]:8053/health
# If this fails, DNS is wrong

# Verify with different DNS:
nslookup tnr.yourdomain.com
getent hosts tnr.yourdomain.com

# Check /etc/hosts doesn't override:
cat /etc/hosts | grep tnr
```

### Solution: Fix DNS Record

```bash
# Update DNS record:
tnr.yourdomain.com  AAAA  fd10:1234::253

# Wait for propagation (5-15 minutes):
sleep 300

# Verify updated record:
dig tnr.yourdomain.com AAAA +nocmd +noall +answer

# Clear local DNS cache (if caching):
sudo systemctl restart systemd-resolved
```

---

## Summary: What To Do

### Quick Decision Tree

```
1. Is registry on same local network?
   YES → Start/restart registry (Case 1)
   NO  → Use static peer (Case 2)

2. Can you reach registry by IP?
   YES → Just need DNS setup, try again
   NO  → Firewall or isolated (Case 2/3)

3. Are you on same network segment?
   YES → Find why registry not responding (Case 1)
   NO  → Use static peer (Case 2)
```

### Commands to Try (In Order)

```bash
# 1. Verify DNS works:
dig tnr.yourdomain.com AAAA

# 2. Verify registry is running:
curl -k https://[fd10:1234::253]:8053/health

# 3. If registry not running, start it:
bash tools/setup-root-registry.sh

# 4. If registry is on different network, use peer:
bash install.sh --auto --discovery static-only --peer fd10:1234::1

# 5. If firewall issue, try multicast (if available):
bash install.sh --auto --discovery multicast-only
```

---

## Prevention: Registry Checklist

- [ ] **Registry Running**: `ps aux | grep registry` shows running process
- [ ] **Port Listening**: `netstat -tulpn | grep 8053` shows port open
- [ ] **Certificate Valid**: `openssl s_client -connect [ip]:8053` shows valid cert
- [ ] **HTTPS Working**: `curl -k https://[ip]:8053/health` returns 200
- [ ] **Multicast Broadcasting**: Registry announces on ff02::1 every 30 seconds
- [ ] **DNS Record**: `dig tnr.* AAAA` returns correct IP
- [ ] **Firewall Allows**: Port 8053 not blocked in firewall rules

---

## Network Topology Reminder

**Full Network**:
```
Node can reach:
├─ Multicast ff02::1 (local)
├─ Internet (DNS)
└─ Remote registries

Discovery: Multicast → DNS → Static
Result: ✅ Works everywhere
```

**Isolated Network**:
```
Node can only reach:
├─ Multicast ff02::1 (local segment only)
└─ Static peers (explicitly configured)

Discovery: Multicast OR Static peer
Result: ✅ Works locally
        ❌ Cannot reach remote registries
```

---

## See Also

- [NETWORK_TOPOLOGY_CONCEPTS.md](NETWORK_TOPOLOGY_CONCEPTS.md) - Full network types explained
- [HYBRID_DISCOVERY_GUIDE.md](HYBRID_DISCOVERY_GUIDE.md) - Discovery mechanisms
- [QUICK_START_TESTING.md](QUICK_START_TESTING.md) - Testing procedures

---

**Still stuck? Check the error message from TrustNet installation - it will tell you which mechanisms failed and suggest next steps.**


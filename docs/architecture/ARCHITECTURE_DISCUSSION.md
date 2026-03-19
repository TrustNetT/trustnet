# TrustNet: Architecture Discussion - IPv6 Discovery Options

**Date**: January 31, 2026  
**Topic**: Bootstrap workflow and automatic node discovery using IPv6

---

## 1. Current Understanding (Clarified)

### What You've Clarified:

✅ **First Installation (No TNR Record)**:
- TNR record doesn't exist in domain
- Must bootstrap by creating the first registry
- This registry is **not special** — it's just the first one
- After creation, we **provide** the IPv6 address to user
- User manually creates AAAA TNR record in their domain

✅ **Subsequent Installations (TNR Exists)**:
- User runs installer, script queries DNS for TNR
- TNR contains list of all registries in network
- Node joins the network, syncs state

✅ **All Registries Are Equal**:
- No "root" registry concept
- Just first-one-created and subsequent-ones
- All participate in consensus/replication equally

---

## 2. The Real Question: Auto-Discovery via IPv6

**Current approach**: DNS-based (TNR AAAA record)

**Question**: Since we're using IPv6 exclusively, can nodes discover each other automatically **without manual DNS setup**?

### Why This Matters:
- **Current friction**: User must manually add TNR record to domain DNS
- **Ideal solution**: Network self-organizes without DNS dependency
- **Network resilience**: Works even if DNS unavailable
- **Isolated networks**: Works in networks with no public DNS

---

## 3. IPv6 Discovery Mechanisms (Options)

### Option A: IPv6 Multicast (ff00::/8)

**How it works**:
- Nodes send multicast queries on `ff02::1` (link-local all nodes)
- Other nodes respond with registry endpoints
- No DNS required, works on same network segment

**Pros**:
- ✅ Zero configuration
- ✅ Automatic peer discovery
- ✅ No manual DNS entry needed
- ✅ Works in isolated networks
- ✅ Self-healing (nodes announce themselves)

**Cons**:
- ❌ Only works on same network segment (local link)
- ❌ Multicast might be filtered by firewalls/switches
- ❌ Doesn't scale across internet (no multicast routing)
- ❌ Less explicit control (harder to exclude bad nodes)

**Use case**: 
- Private networks, clusters, data centers
- All nodes on same LAN

---

### Option B: Link-Local Autoconfiguration (fe80::/10)

**How it works**:
- IPv6 link-local addresses assigned automatically (fe80::1, fe80::2, etc.)
- Nodes discover each other via IPv6 neighbor discovery
- Registry ports discovered via port scanning or service broadcasts

**Pros**:
- ✅ Completely automatic (no configuration)
- ✅ IPv6 native
- ✅ Works without DNS

**Cons**:
- ❌ Only works on same physical link
- ❌ Link-local addresses change when node moves
- ❌ Not suitable for static/stable addressing
- ❌ Hard to know which node is which (no names)

**Use case**: 
- Zero-configuration mesh on local network
- Not suitable for distributed systems with named nodes

---

### Option C: Service Discovery (mDNS + DNS-SD)

**How it works**:
- Nodes broadcast their presence via mDNS (multicast DNS)
- Service names: `node-1._trustnet._tcp.local`
- No central DNS server needed
- Avahi or similar tools

**Pros**:
- ✅ Named discovery (knows node names)
- ✅ No central DNS needed
- ✅ Works on local networks
- ✅ Standard protocol (avahi, systemd-resolved)

**Cons**:
- ❌ Only on local network segments
- ❌ Not reliable for static network membership
- ❌ Requires mDNS service running on all nodes
- ❌ Multicast filtering can block discovery

**Use case**: 
- Local LAN discovery (like Bonjour)
- Short-lived nodes (works in ephemeral clusters)

---

### Option D: DNS-Based (TNR Record) - Current Approach

**How it works**:
- User creates AAAA TNR record in their domain
- TNR contains list of all known registries
- Installer queries DNS for TNR AAAA record
- Nodes fetch registry list, join network

**Pros**:
- ✅ Works across internet
- ✅ Explicit control (admin manages registry list)
- ✅ Firewall-friendly (port 53 usually open)
- ✅ Can include secondary registries for failover
- ✅ Scales globally
- ✅ No special network setup needed

**Cons**:
- ❌ Requires DNS setup (manual TNR record)
- ❌ Depends on DNS availability
- ❌ User must know IPv6 address to add TNR record
- ❌ Additional bootstrap friction

**Use case**: 
- Distributed networks across internet
- Multiple networks, explicit control
- Production deployments

---

### Option E: Hybrid Approach (Multicast + DNS Fallback)

**How it works**:
1. First: Try IPv6 multicast discovery (fastest, no DNS needed)
2. If multicast fails: Fall back to DNS TNR record
3. If DNS fails: Use configured static peers

**Pros**:
- ✅ Best of both worlds
- ✅ Works in isolated networks (multicast)
- ✅ Works across internet (DNS fallback)
- ✅ Resilient (multiple fallbacks)
- ✅ No mandatory DNS setup

**Cons**:
- ❌ More complex implementation
- ❌ Multiple discovery mechanisms to maintain
- ❌ Potential race conditions between methods
- ❌ Harder to debug discovery issues

**Use case**: 
- Private + public hybrid networks
- Maximum resilience requirement

---

## 4. Current Bootstrap Workflow Analysis

### Friction Points:

1. **User doesn't know IPv6 address until after bootstrap**
   - Problem: Can't add TNR record until registry created
   - Solution: Print IPv6 address during bootstrap, wait for user to add DNS record

2. **DNS dependency**
   - Problem: Can't discover nodes without DNS
   - Solution: Use multicast for local networks, DNS for internet

3. **Manual DNS entry**
   - Problem: Requires user to edit their domain DNS
   - Solution: Automatic discovery (multicast) removes need for DNS

---

## 5. Proposed Workflow Improvements

### Scenario 1: Local Network (Isolated - No Internet DNS)

```
Bootstrap on Local IPv6 Network:
1. Run installer: bash install.sh --auto
2. Script creates first registry (no DNS needed!)
3. Script broadcasts multicast on ff02::1
4. Other nodes automatically discover registry
5. No manual DNS setup required!
```

**Requires**: IPv6 multicast enabled on network (usually default)
**Advantage**: Zero configuration, self-organizing

---

### Scenario 2: Internet-Distributed Network (With DNS)

```
Bootstrap with Public Domain:
1. Run installer: bash install.sh --auto
2. Script creates first registry, shows IPv6 address
3. User adds AAAA TNR record to their domain DNS
4. Script polls DNS until TNR record found
5. Other nodes query DNS, join network
```

**Requires**: User access to domain DNS
**Advantage**: Works across internet, explicit control

---

### Scenario 3: Hybrid (Preferred for Production)

```
Bootstrap with Multicast + DNS Fallback:
1. Run installer: bash install.sh --auto
2. Script tries multicast discovery first
3. If multicast found peers: Use them (fast, local)
4. If no multicast: Fall back to DNS TNR record
5. If no DNS: Use static peer list (config file)

Result: Works everywhere, no single point of failure
```

**Advantages**:
- ✅ Local networks work instantly (multicast)
- ✅ Internet networks work (DNS TNR)
- ✅ Resilient (multiple fallbacks)
- ✅ No mandatory configuration

---

## 6. My Recommendations

### For Your Use Case (TrustNet):

I think **Hybrid Approach** makes most sense:

1. **Default (Multicast Discovery)**
   - IPv6 nodes broadcast presence on `ff02::1` multicast
   - No DNS dependency
   - Instant local network discovery
   - Works in isolated environments

2. **Fallback (DNS-Based)**
   - If multicast fails: Query DNS for TNR record
   - User can manually add TNR record for internet distribution
   - Works across WANs

3. **Static Fallback**
   - User can provide `--peer fd10:1234::1` flag
   - For firewalled/filtered networks

### Implementation Steps:

1. **Update bootstrap to multicast-first**:
   - Registry sends multicast announcement: `ff02::1:registry:8053`
   - Format: `TRUSTNET_REGISTRY\n{ipv6_address}:{port}\n{timestamp}`
   - Every 30 seconds (keep-alive)

2. **Update discovery to hybrid**:
   - Script listens for multicast
   - If no multicast: Query DNS TNR record
   - If no DNS: Use `--peer` flag or error

3. **Update installer flow**:
   - First install: Create registry, send multicast (no DNS needed)
   - Subsequent: Discover via multicast or DNS
   - User only needs DNS if network spans internet

---

## 7. Updated Workflow (Proposed)

### First Installation (No Manual DNS!):

```bash
$ cd ~/vms
$ bash ../trustnet-wip/install.sh --auto

[Output]:
✓ Created registry at fd10:1234::253
✓ Broadcasting on IPv6 multicast ff02::1
✓ Waiting for multicast response...

[Next node on same network]:
$ bash ../trustnet-wip/install.sh --auto

[Output]:
✓ Detected registry via multicast: fd10:1234::253
✓ Created node-1 at fd10:1234::1
✓ Joined network automatically!

[Manual DNS Optional]:
If you want internet distribution, add to your domain DNS:
  tnr.yourdomain.com AAAA fd10:1234::253
```

### Benefits:
- ✅ No manual DNS entry for local networks
- ✅ Works instantly (multicast)
- ✅ Still supports DNS for distributed networks
- ✅ Resilient with fallbacks

---

## 8. Questions for You

1. **Network scope**: Will TrustNet be used on:
   - [ ] Single local network (LAN) only?
   - [ ] Multiple LANs across internet?
   - [ ] Both (hybrid)?

2. **User experience**: Do you want:
   - [ ] Zero configuration (multicast only)?
   - [ ] Optional DNS for distribution?
   - [ ] Mandatory DNS for control?

3. **Firewall/Security**: Should nodes:
   - [ ] Trust all multicast peers automatically?
   - [ ] Require DNS verification (more secure)?
   - [ ] Support both with flags?

4. **Scalability**: Expected number of:
   - [ ] Nodes per network (10s, 100s, 1000s)?
   - [ ] Separate networks (1, 10, 100+)?

---

## 9. Decision Matrix

| Approach | Local Only | Internet | Zero Config | Explicit Control |
|----------|-----------|----------|-------------|------------------|
| Multicast Only | ✅ Best | ❌ No | ✅ Yes | ❌ No |
| DNS Only | ❌ Complex | ✅ Best | ❌ No | ✅ Yes |
| Hybrid | ✅ Good | ✅ Good | ✅ Yes | ✅ Yes |

**Recommendation**: **Hybrid approach** balances all concerns

---

## Next Steps (When You Decide)

1. Clarify your use case (local/internet/hybrid)
2. Choose approach (multicast/DNS/hybrid)
3. Update scripts accordingly
4. Test discovery mechanisms
5. Document user workflow

---

## References

- RFC 4291: IPv6 Addressing Architecture
- RFC 4862: IPv6 Stateless Address Autoconfiguration  
- RFC 4944: IPv6 over Low-Power Wireless Personal Area Networks (6LoWPAN)
- RFC 5153: IPv6 Router Advertisement Guard (RA-GUARD)
- RFC 5533: IANA Considerations for IPv6 Multicast Addresses
- mDNS: RFC 6762
- DNS-SD: RFC 6763


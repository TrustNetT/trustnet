# TrustNet: Critical Architecture Decisions - Jan 31 Discussion

## Summary of Your Clarifications

### 1. Bootstrap Process (Workflow Clarification)
```
First Installation:
- TNR record doesn't exist
- Create first registry (not "special" - just the first)
- Print IPv6 address to user
- User MANUALLY creates AAAA TNR record in their domain
- Next installations detect TNR, join network

Key Point: All registries are equal - no master/slave concept
```

### 2. Network Discovery Question
**You raised**: Since we use IPv6 exclusively, can nodes auto-discover without DNS?

This is **the critical decision** that affects the entire architecture.

---

## Discovery Options Compared

| Mechanism | Local | Internet | Config | Multicast |
|-----------|-------|----------|--------|-----------|
| **Multicast (ff02::1)** | ✅ Yes | ❌ No | ✅ Zero | ✅ Yes |
| **DNS TNR (Current)** | ⚠️ Possible | ✅ Yes | ❌ Manual | ❌ No |
| **Hybrid (Recommended)** | ✅ Yes | ✅ Yes | ✅ Auto+Option | ✅ Yes |
| **mDNS/DNS-SD** | ✅ Yes | ⚠️ Partial | ✅ Mostly | ✅ Yes |

---

## The Core Question

### Current Design (DNS-Based):
```
Friction:
1. User must manually add TNR AAAA record
2. Depends on DNS availability
3. Extra setup step after bootstrap

Flow:
$ bash install.sh --auto
[Creates registry]
[User must: Add AAAA record to domain DNS]
[Next install detects TNR, joins]
```

### Alternative (Multicast-Based):
```
Zero-Configuration:
1. No manual DNS entry needed
2. Nodes discover each other automatically
3. Instant network formation on same segment

Flow:
$ bash install.sh --auto
[Creates registry, broadcasts on ff02::1]
$ bash install.sh --auto  [on another node]
[Detects registry via multicast, joins instantly]
```

### Hybrid (Best of Both):
```
Auto-Discovery + Optional DNS:
1. Multicast first (zero-config for local networks)
2. DNS fallback (for internet distribution)
3. Static peer fallback (for firewalled networks)

Flow:
$ bash install.sh --auto
[Creates registry, broadcasts on ff02::1]
[Also shows: "Add to DNS: tnr.yourdomain.com AAAA fd10:1234::253"]
$ bash install.sh --auto  [on another node]
[Tries multicast → found! Joins automatically]
```

---

## Key Design Questions for You

### Question 1: Network Scope
**How will TrustNet be used?**

- [ ] **Local networks only** (single data center, office, private LAN)
  - → Multicast is sufficient
  - → DNS is optional bonus for distribution

- [ ] **Distributed across internet** (multiple cities, cloud, WAN)
  - → DNS is essential
  - → Multicast won't work (no multicast routing on internet)

- [ ] **Both** (private + internet hybrid)
  - → Hybrid approach needed
  - → Multicast for local, DNS for remote

---

### Question 2: User Experience
**What's your priority?**

- [ ] **Zero Configuration** (nodes self-organize)
  - → Multicast auto-discovery
  - → No DNS setup needed
  - → Best for clusters/research

- [ ] **Explicit Control** (admin decides who joins)
  - → DNS-based (TNR record)
  - → Admin controls registry list
  - → Best for enterprise/production

- [ ] **Both** (multi-tenant, different security models)
  - → Hybrid with flags to switch modes
  - → `--auto-discover` (multicast) vs `--dns-mode` (TNR)

---

### Question 3: Firewall/Security
**How should peer verification work?**

- [ ] **Trust all multicast responders** (loose security)
  - → Simple, fast
  - → Risk: Anyone on network can inject registries

- [ ] **DNS-verified only** (strict security)
  - → Admin controls via DNS
  - → Requires DNS setup

- [ ] **Hybrid** (multicast + DNS verification option)
  - → Default: trust multicast
  - → Optional: verify against DNS

---

## My Recommendation

**Hybrid approach** because:

1. ✅ **Works everywhere**
   - Multicast for LANs (instant discovery)
   - DNS for internet distribution
   - Static peers for firewall edge cases

2. ✅ **No mandatory setup**
   - Local networks: just run install script
   - Internet networks: optional DNS setup

3. ✅ **Resilient**
   - Multiple fallback mechanisms
   - Works if one mechanism fails

4. ✅ **Backwards compatible**
   - Can still use DNS-only if preferred
   - Can still use multicast-only if preferred

5. ✅ **Production-ready**
   - Supports enterprise use cases
   - Supports research/experimental use cases

---

## Implementation Impact

### If We Choose Multicast-Only:
- Simpler implementation
- Zero-config experience
- **Limitation**: Doesn't work across internet
- **Suitable for**: Private networks, clusters

### If We Choose DNS-Only (Current):
- Implementation already done
- Explicit control
- **Friction**: Manual DNS setup required
- **Suitable for**: Distributed networks, enterprise

### If We Choose Hybrid:
- More complex implementation
- Best user experience
- Handles all scenarios
- **Time**: ~2-3 more days of work
- **Suitable for**: All use cases (local + distributed)

---

## Timeline Impact

| Approach | Time | Complexity | Testing |
|----------|------|-----------|---------|
| Current (DNS) | Now | ✅ Done | Ready |
| Multicast Only | +1 day | Moderate | Medium |
| Hybrid | +2-3 days | High | Complex |

---

## What I Need from You

Please answer these questions to determine the right direction:

1. **Primary use case**: Local networks, distributed networks, or both?

2. **User preference**: Zero-config (auto-discover) or explicit control (DNS)?

3. **Production readiness**: Must work across internet, or local networks OK?

4. **Timeline**: Are we in a hurry, or is quality > speed?

5. **Scalability**: Expected number of:
   - Nodes per deployment? (10s, 100s, 1000s?)
   - Separate networks? (1, 5, many?)

---

## Options for Now

### Option A: Move Forward with DNS-Only
- Current scripts are ready
- Test bootstrap workflow (TNR manual setup)
- Accept friction of manual DNS entry
- **Time**: Can test today

### Option B: Design Multicast Discovery
- Discuss multicast approach in detail
- Plan implementation
- Update scripts for discovery
- **Time**: Add 1-2 days to timeline

### Option C: Design Full Hybrid Solution
- Plan both multicast + DNS mechanisms
- Design fallback logic
- Implement with feature flags
- **Time**: Add 2-3 days to timeline

---

## My Suggestion

**Let's do Option C (Hybrid)** because:

1. You already asked the question (signals importance)
2. It's the right architectural decision long-term
3. Enables local + distributed use cases
4. Not much more work than Option B
5. Future-proofs the design

**Timeline**: Implement hybrid this week, test both mechanisms.

---

## Next Steps (Awaiting Your Input)

Once you decide:
1. I'll update the architecture documentation
2. Modify scripts to support chosen discovery method
3. Create test scenarios for new mechanism
4. Verify bootstrap works with new approach

Ready to discuss further or implement your preferred approach!


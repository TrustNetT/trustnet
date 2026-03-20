# TrustNet: Discovery Mechanisms - Visual Comparison

## Option 1: DNS-Only (Current Implementation)

```
User runs installer:
┌─────────────────────────────────────────────┐
│ $ bash install.sh --auto                    │
│                                             │
│ [1] Create first registry                   │
│     ✓ Created at fd10:1234::253             │
│     ✓ Config saved to ~/.trustnet/          │
│                                             │
│ [2] Manual step: USER adds to domain DNS    │
│     tnr.example.com AAAA fd10:1234::253     │
│     (user does this themselves)             │
│                                             │
│ [3] Next node discovers via DNS             │
│     ✓ Queries DNS for TNR record            │
│     ✓ Found registry at fd10:1234::253      │
│     ✓ Joins network automatically           │
└─────────────────────────────────────────────┘

Workflow:
┌──────────────┐     ┌──────────────┐     ┌────────────────┐
│ Run install  │ --> │ Create       │ --> │ User manually  │
│              │     │ registry     │     │ adds DNS entry │
└──────────────┘     └──────────────┘     └────────────────┘
                                                    |
                                                    v
                                          ┌─────────────────┐
                                          │ Next nodes can  │
                                          │ discover via    │
                                          │ DNS query       │
                                          └─────────────────┘

Pros:
✅ Works across internet (global distribution)
✅ Explicit control (admin decides registry list)
✅ Firewall friendly (port 53 usually open)
✅ Proven technology (DNS is reliable)
✅ Ready to test today

Cons:
❌ Manual DNS setup required
❌ Friction: user must know IPv6 address
❌ Depends on DNS availability
❌ Extra setup step after bootstrap
```

---

## Option 2: Multicast-Only (IPv6 ff02::1)

```
User runs installer:
┌─────────────────────────────────────────────┐
│ $ bash install.sh --auto                    │
│                                             │
│ [1] Create first registry                   │
│     ✓ Created at fd10:1234::253             │
│     ✓ Broadcasting on ff02::1:8053          │
│     ✓ Multicast advertisement every 30s     │
│                                             │
│ [2] Next node auto-discovers                │
│     ✓ Listens for multicast on ff02::1      │
│     ✓ Detected registry at fd10:1234::253   │
│     ✓ Joins network automatically!          │
│     ✓ NO MANUAL SETUP REQUIRED!             │
└─────────────────────────────────────────────┘

Workflow:
┌──────────────┐     ┌──────────────┐
│ Run install  │ --> │ Create       │
│              │     │ registry     │
│              │     │ + multicast  │
└──────────────┘     └──────────────┘
      |                     |
      v                     v
    Node 1              broadcasts
      |                  ff02::1
      |
      +--- Node 2 (instant discovery!)
      +--- Node 3 (instant discovery!)
      +--- Node 4 (instant discovery!)

Pros:
✅ Zero configuration (automatic discovery)
✅ Instant network formation (no delay)
✅ Self-organizing (no manual steps)
✅ Works in isolated networks (no DNS needed)
✅ IPv6 native (designed for this)
✅ Resilient (no DNS dependency)

Cons:
❌ Only works on same network segment
❌ Doesn't scale across internet (no multicast routing)
❌ Multicast might be filtered (some networks block it)
❌ Less explicit control (harder to exclude bad nodes)
❌ Node discovery happens automatically (could be seen as security risk)

Use Case: Private networks, data centers, research labs
```

---

## Option 3: Hybrid (Recommended)

```
User runs installer:
┌─────────────────────────────────────────────────┐
│ $ bash install.sh --auto                        │
│                                                 │
│ [1] Create first registry                       │
│     ✓ Created at fd10:1234::253                 │
│     ✓ Broadcasting on ff02::1 (multicast)       │
│     ✓ Also shows:                               │
│       "Add to DNS (optional):                   │
│        tnr.example.com AAAA fd10:1234::253"     │
│                                                 │
│ [2] Next node (same network)                    │
│     ✓ Tries multicast first                     │
│     ✓ Found registry on ff02::1                 │
│     ✓ Joins instantly (no DNS needed!)          │
│                                                 │
│ [3] Next node (different network)               │
│     ✓ Tries multicast (no response)             │
│     ✓ Fallback: Query DNS for TNR               │
│     ✓ Found registry via DNS                    │
│     ✓ Joins network                             │
└─────────────────────────────────────────────────┘

Workflow:
                    ┌─────────────┐
                    │ Create      │
                    │ registry +  │
                    │ multicast   │
                    └──────┬──────┘
                           |
                ┌──────────┴──────────┐
                |                     |
                v                     v
    ┌───────────────────────┐  (Optional: User adds DNS)
    │ Nodes on same network │  tnr.example.com AAAA ::253
    │ Discover via          │
    │ multicast ff02::1     │  ┌──────────────────────────┐
    │ Instant!              │  │ Nodes on different       │
    │                       │  │ networks discover via    │
    │ ✅ No DNS needed      │  │ DNS TNR record           │
    │ ✅ Zero config        │  │                          │
    └───────────────────────┘  │ ✅ Works across internet │
                               │ ✅ Explicit control      │
                               └──────────────────────────┘

Pros:
✅ Works everywhere (local + internet)
✅ Zero config for local networks (multicast)
✅ Optional DNS for distribution
✅ Resilient (multiple mechanisms)
✅ Backwards compatible (can use either method)
✅ Enterprise-ready (explicit control option)
✅ Research-friendly (auto-discovery option)

Cons:
⚠️ More complex implementation
⚠️ Multiple mechanisms to maintain
⚠️ Potential race conditions (which discovers first?)
⚠️ Harder to debug (more moving parts)

Use Case: Production systems, hybrid networks, any deployment
Recommended: YES - best balance of all concerns
```

---

## Side-by-Side Comparison Table

```
┌────────────────────┬──────────────┬──────────────┬───────────────┐
│ Characteristic     │ DNS-Only     │ Multicast    │ Hybrid        │
├────────────────────┼──────────────┼──────────────┼───────────────┤
│ Local network      │ Requires DNS │ Instant ✅   │ Instant ✅    │
│ Across internet    │ Works ✅     │ No ❌        │ Works ✅      │
│ Configuration      │ Manual       │ Zero ✅      │ Zero/Optional │
│ Setup friction     │ High         │ None ✅      │ Low ✅        │
│ Explicit control   │ Yes ✅       │ No           │ Yes ✅        │
│ Resilience         │ DNS dep.     │ Local only   │ Multiple ✅   │
│ Complexity         │ Low ✅       │ Moderate     │ High          │
│ Testing effort     │ Easy ✅      │ Moderate     │ Complex       │
│ Production ready   │ Yes ✅       │ Maybe        │ Yes ✅        │
│ Scalability        │ Infinite     │ Segment only │ Infinite ✅   │
└────────────────────┴──────────────┴──────────────┴───────────────┘
```

---

## Discovery Mechanism Comparison

```
DNS-Only Discovery:
┌─────────────────────────────────────────────────────────────┐
│ Installer queries: nslookup tnr.example.com AAAA            │
│ DNS returns:       fd10:1234::253 (root registry)           │
│ Installer connects: https://[fd10:1234::253]:8053/api/peers │
│ Gets registry list: [fd10:1234::253, fd10:1234::254, ...]  │
│ Joins network     ✓                                         │
└─────────────────────────────────────────────────────────────┘

Multicast Discovery:
┌─────────────────────────────────────────────────────────────┐
│ Installer listens: ff02::1 (link-local all nodes)           │
│ Registries announce: "TRUSTNET_REGISTRY:fd10:1234::253:8053"│
│ Installer receives: ff02::1:registry:8053 multicast message │
│ Joins network     ✓                                         │
│ Takes seconds, not minutes!                                 │
└─────────────────────────────────────────────────────────────┘

Hybrid Discovery:
┌──────────────────────────────────────────────────────────────┐
│ Step 1: Try Multicast                                        │
│   Listen on ff02::1 for registries (timeout: 5 seconds)      │
│   If found: Join immediately ✓                               │
│                                                              │
│ Step 2: If multicast failed, try DNS                         │
│   Query: nslookup tnr.example.com AAAA                       │
│   If found: Join via DNS ✓                                   │
│                                                              │
│ Step 3: If both failed, try static peer                      │
│   Use: --peer fd10:1234::1 flag                              │
│   If provided: Join via static peer ✓                        │
│                                                              │
│ Step 4: All failed, error                                    │
│   (No discovery mechanism worked)                            │
└──────────────────────────────────────────────────────────────┘
```

---

## Which Should You Choose?

### Choose DNS-Only if:
- ✅ Network is distributed across internet
- ✅ You have admin access to domain DNS
- ✅ You want explicit control
- ✅ Simplicity is paramount
- ✅ You want to test TODAY

### Choose Multicast-Only if:
- ✅ Network is local (single data center/office)
- ✅ Zero configuration is critical
- ✅ You don't care about internet distribution
- ✅ You're in research/experimental phase

### Choose Hybrid if:
- ✅ Network might be both local AND distributed
- ✅ You want best user experience
- ✅ Enterprise/production deployment
- ✅ You're willing to spend 2-3 more days building
- 🎯 **Recommended**: Best long-term architecture

---

## Current Status

| Aspect | Status |
|--------|--------|
| DNS-Only scripts | ✅ Complete (ready to test) |
| Multicast support | ⏳ Not implemented |
| Hybrid implementation | ⏳ Not implemented |
| Documentation | ✅ Complete |

---

## Next Steps

**I recommend: Let's implement Hybrid approach**

1. It's the right long-term architecture
2. Handles all use cases
3. Not much more work than Multicast-only
4. Future-proofs the design
5. Makes TrustNet suitable for any deployment

**Timeline**: +2-3 days to implement and test

Ready to proceed when you decide!


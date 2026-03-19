# Registry Architecture: Decentralized vs Centralized

**Question**: Do we need external/root registries, or should TrustNet be fully decentralized with only internal registries?

**Date**: January 31, 2026  
**Status**: Architecture decision point

---

## The Two Approaches

### Approach 1: Decentralized (Internal Registries Only)

**Architecture**:
```
Node-1                Node-2                Node-3
├─ Internal Registry  ├─ Internal Registry  ├─ Internal Registry
├─ P2P Engine        ├─ P2P Engine        ├─ P2P Engine
└─ App Data          └─ App Data          └─ App Data
     │                    │                    │
     └────────────────────┴────────────────────┘
           (DHT/Gossip Protocol)
           All nodes talk to each other
           No central authority
```

**How Discovery Works**:
```
Node-1 boots:
  1. Start internal registry
  2. Broadcast multicast on ff02::1: "I'm here!"
  3. Listen for other nodes broadcasting
  4. Find Node-2, Node-3 via multicast
  5. Exchange peer lists
  6. Sync state with peers
  
Result: Pure P2P, like BitTorrent DHT
```

**Pros** ✅:
- No SPOF (Single Point of Failure)
- Truly decentralized
- Each node independent
- Minimal complexity
- Works offline/air-gapped
- No central coordinator

**Cons** ❌:
- Discovery harder (multicast limited to local segment)
- Global peer view difficult (need DHT or gossip)
- Registry spread across nodes (complex to query)
- Harder to monitor overall health
- Scaling (N² peer connections)
- Remote discovery requires DHT (more complex)

**Data Storage**:
- Each node stores its own app data
- Each node stores peers list it knows about
- No global registry (each node has partial view)
- Consensus via gossip protocol

---

### Approach 2: Centralized with Root Registry (Current Design)

**Architecture**:
```
Root Registry (External)
├─ Central peer list
├─ Global view of all nodes
├─ Heartbeat tracking
└─ State synchronization
       ↑
       │ heartbeat
       │ peer discovery
       │ state sync
       ├─ ─ ┬─ ─ ┬─ ─
       │    │    │
   Node-1 Node-2 Node-3
   ├─Internal  ├─Internal  ├─Internal
   │ Registry  │ Registry  │ Registry
   └─App Data  └─App Data  └─App Data
```

**How Discovery Works**:
```
Node-1 boots:
  1. Start internal registry (local state only)
  2. Try discovery: Multicast → DNS → Static peer
  3. Find Root Registry
  4. Register self: "I'm Node-1 at fd10:1234::1"
  5. Get peer list from Root Registry
  6. Connect to peers directly
  7. Send heartbeat every 30s to Root Registry
  
Result: Root Registry is source of truth
```

**Pros** ✅:
- Single source of truth
- Easy discovery (ask Root Registry)
- Easy monitoring (Root Registry has all state)
- Clear global view
- Easier remote discovery (through Root Registry)
- Simpler peer finding (Root Registry knows everyone)
- Heartbeat tracking works well
- State consistency easier

**Cons** ❌:
- Root Registry = SPOF (if down, discovery broken)
- More infrastructure to run
- Single point of monitoring
- Requires external service
- Requires replication for HA (backup registries)

**Data Storage**:
- Root Registry stores: all nodes, peer lists, heartbeats, state
- Nodes store: local app data only
- Global view centralized

---

## Early-Stage Behavior

### Scenario A: Single Registry Starts (No Nodes Yet)

#### Decentralized Approach
```
Registry boots:
1. Registry is just a node with no app data
2. Starts internal registry
3. Broadcasts multicast: "I'm here!"
4. Listens for other nodes
5. Currently alone, so internal registry empty (except itself)
6. Sits waiting for first node to appear

State:
├─ Node count: 1 (itself)
├─ Peer list: empty
├─ Registry status: Running but idle
└─ Discovery: Broadcasting, listening

When Node-1 joins:
├─ Node-1 receives multicast from Registry
├─ Node-1 connects to Registry
├─ Registry gets heartbeat from Node-1
├─ Registry adds Node-1 to its peer list
└─ Node-1 queries Registry for other peers (none yet)
```

**Behavior**: Just idles, broadcasts, waits. Clean.

---

#### Centralized Approach (Current Design)
```
Root Registry boots:
1. Starts as central coordinator
2. Broadcasts multicast: "Root Registry here!"
3. Waits for nodes to heartbeat
4. Internal peer list: empty (no nodes registered)
5. Heartbeat daemon: runs but no nodes to check

State:
├─ Node count: 0
├─ Registered nodes: []
├─ Heartbeat queue: empty
├─ Cleanup daemon: runs but no dead nodes
└─ Discovery: Broadcasting, listening

When Node-1 joins:
├─ Node-1 discovers Root Registry (multicast)
├─ Node-1 POSTs /registry/heartbeat
├─ Root Registry creates node entry
├─ Root Registry responds with peer list: []
├─ Node-1 knows: "I'm alone"
└─ Node-1 waits for other nodes
```

**Behavior**: Waits for first heartbeat, initializes node entry. Clean.

---

### Scenario B: Single Node Starts (No Other Nodes Yet)

#### Decentralized Approach
```
Node-1 boots:
1. Start internal registry
2. Broadcast multicast: "I'm Node-1!"
3. Listen for other nodes broadcasting
4. (silence... nothing else is up)
5. Timeout after 5 seconds
6. Create DHT entry for itself
7. Peer list: [self]
8. Ready to serve app queries locally

State:
├─ Internal registry: contains self only
├─ Peers: [self]
├─ Can answer queries about itself
├─ Cannot find other nodes (multicast times out)
└─ Discovery status: Local only

App behavior:
├─ Queries to own data: ✓ Works
├─ Queries to other nodes: ✗ Not found (alone)
├─ Data replicated: Only on self
├─ Availability: Single point of failure (it's the only copy)
```

**Behavior**: Node operates solo, knows about itself, discovers itself via multicast timeout. Clean.

**But problem**: Node thinks it's alone. How does it bootstrap when joining existing cluster? By re-running discovery? Or does it know "there might be more nodes out there"?

---

#### Centralized Approach (Current Design)
```
Node-1 boots:
1. Start internal registry (local state)
2. Try discovery: 
   - Multicast ff02::1: (silence, no Root Registry up)
   - DNS tnr.example.com: (fails, no DNS entry)
   - Static peer from config: (tries, fails)
3. After 30 seconds: "Registry unreachable"
4. Options:
   a) Error: "Cannot reach registry, cannot start"
   b) Wait: "Waiting for registry to appear"
   c) Degraded: "Operating without registry (local only)"

State:
├─ Internal registry: empty (no heartbeat confirmation)
├─ Heartbeat service: failing (no registry to send to)
├─ Peer list: unknown (cannot query Root Registry)
├─ App status: WAITING_FOR_REGISTRY or OFFLINE
└─ Discovery status: Failed
```

**Behavior**: Node tries to find Root Registry, fails, enters error/wait state.

**Problem**: Single node cannot start if registry is not running. Chicken-and-egg problem.

---

### Scenario C: Registry Starts, Then Node Starts (Normal Flow)

#### Decentralized
```
T=0:00  Root Registry boots
        ├─ Broadcasts multicast "Registry here!"
        └─ Listens for nodes

T=0:05  Node-1 boots
        ├─ Multicast discovery finds Root Registry immediately
        ├─ Adds Root Registry to peer list
        ├─ Queries: "Any other peers?"
        ├─ Root Registry responds: "Peer list: []"
        └─ Node-1 now: peer_list = [Root Registry]

T=0:10  Node-2 boots
        ├─ Multicast discovery finds Root Registry
        ├─ Multicast discovery finds Node-1
        ├─ Adds both to peer list
        ├─ Root Registry now knows about Node-2
        ├─ Node-1 learns about Node-2 via gossip
        └─ Both nodes: peer_list = [Root Registry, Node-1, Node-2]

Result:
├─ Full mesh (all know all)
├─ No central bottleneck for data
├─ Root Registry = just another peer
└─ Pure P2P after discovery
```

**Key insight**: Root Registry is just a seed node, not special!

---

#### Centralized
```
T=0:00  Root Registry boots
        ├─ Broadcasts multicast
        ├─ Waits for heartbeats
        ├─ Node list: []
        └─ Ready for registrations

T=0:05  Node-1 boots
        ├─ Discovery: finds Root Registry via multicast
        ├─ Sends heartbeat: "I'm Node-1"
        ├─ Root Registry creates entry
        ├─ Root Registry responds: "peer_list = []"
        └─ Node-1: I'm registered, no other peers yet

T=0:10  Node-2 boots
        ├─ Discovery: finds Root Registry via multicast
        ├─ Sends heartbeat: "I'm Node-2"
        ├─ Root Registry creates entry
        ├─ Root Registry responds: "peer_list = [Node-1]"
        └─ Node-2: peer_list = [Node-1]

T=0:15  Root Registry heartbeat cycle
        ├─ Checks: Node-1 heartbeat received ✓ (< 30s)
        ├─ Checks: Node-2 heartbeat received ✓ (< 30s)
        ├─ Marks both: state = ONLINE
        └─ Ready to serve queries

Result:
├─ Root Registry is source of truth
├─ Nodes query Root Registry for peer lists
├─ Root Registry is central coordinator
└─ All peer discovery goes through Root Registry
```

**Key insight**: Root Registry is critical for discovery and coordination.

---

## When Do We Need External Registries?

### Scenario: Nodes in Different Networks

```
Network A (Corporate)        Network B (Factory)
├─ Node-1                    ├─ Node-3
├─ Node-2                    └─ Node-4
└─ Local Registry-A

Problem: Nodes in different networks cannot multicast to each other
         (multicast is link-local only)

Solution with Decentralized:
├─ Use DHT with fallback to static peers
├─ Registry-A lists Node-3, Node-4 as static peers
├─ Nodes manually configured with bootstrap peers
├─ Works but requires manual config
└─ Result: Ad-hoc federation

Solution with Centralized:
├─ Both networks register with global Root Registry
├─ Root Registry = cloud instance (globally accessible)
├─ Node-1, Node-2 heartbeat → global registry
├─ Node-3, Node-4 heartbeat → global registry
├─ All nodes can discover all other nodes
├─ Works automatically with DNS (single entry point)
└─ Result: Seamless federation
```

---

## Comparison Table

| Aspect | Decentralized (Internal Only) | Centralized (External) |
|--------|-------------------------------|------------------------|
| **Complexity** | Low to Medium (gossip/DHT) | Medium (heartbeat + state) |
| **SPOF** | No | Yes (Root Registry) |
| **Local discovery** | Excellent (multicast) | Good (multicast) |
| **Remote discovery** | Hard (requires DHT) | Easy (DNS to Root Registry) |
| **Monitoring** | Distributed (hard to get global view) | Centralized (Root Registry has all state) |
| **Scaling** | P2P (N² connections) | Star (N connections per node) |
| **First node startup** | Can start alone | Needs coordination |
| **Cross-network** | Manual peering | Automatic via Root Registry |
| **Bootstrapping** | Static peers + DHT | Root Registry address |
| **Use case** | Local clusters, air-gapped | Multi-site, cloud, federated |

---

## Recommendation by Use Case

### Use Decentralized (Internal Registries Only) If:
- ✅ Cluster runs in single location (LAN/data center)
- ✅ All nodes can multicast to each other
- ✅ Don't need global peer discovery
- ✅ Want pure P2P, no central coordinator
- ✅ Air-gapped networks (no internet needed)
- ✅ Can manually configure static peers for federation
- **Example**: Factory with 50 nodes in one facility

---

### Use Centralized (External Registries) If:
- ✅ Nodes spread across multiple networks
- ✅ Need remote discovery (no multicast between networks)
- ✅ Want single source of truth for all nodes
- ✅ Need monitoring of global cluster state
- ✅ Want automated peer discovery
- ✅ Willing to manage Root Registry infrastructure
- **Example**: Cloud federation (Node-1 in AWS, Node-2 in GCP, Node-3 on-prem)

---

## Hybrid Approach (Best of Both)

### "Internal + External Registries"

**Architecture**:
```
Root Registry (Global, in cloud)
├─ All nodes heartbeat here
├─ Global peer view
├─ Inter-network discovery
└─ Monitoring/alerting

Network A (LAN)              Network B (LAN)
├─ Node-1 ──┐              ├─ Node-3 ──┐
├─ Node-2 ──┼─→ Registry-A├─ Node-4 ──┼─→ Registry-B
└─ (multicast)             └─ (multicast)
      ↑                             ↑
      └─────────────────────────────┘
         Both heartbeat to global Root Registry

Benefits:
✅ Local discovery via multicast (fast, no latency)
✅ Global discovery via Root Registry (works across networks)
✅ Redundancy (if one registry fails, still can use others locally)
✅ Single monitoring point (Root Registry sees all)
✅ Flexibility (nodes find each other locally first, then check global)

Discovery order:
1. Try local multicast (fast)
2. Try local registry (medium)
3. Try global registry (slow but works globally)
```

---

## Implementation Impact

### If We Go Decentralized (Internal Only)

**Changes Needed**:
- Remove concept of "Root Registry"
- Implement gossip protocol or DHT
- Each node maintains peer list
- Static peer config for federation
- Distributed consensus for state
- More complex testing

**Lifecycle Management**:
```
Heartbeat: Node sends to peers (not to central registry)
Cleanup: Each node cleans its own peer list
Health: Gossip protocol spreads health info
```

---

### If We Go Centralized (Current + External)

**Changes Needed** (Already in plan):
- Root Registry as central coordinator
- Heartbeat to Root Registry
- Root Registry maintains global state
- Cleanup daemon on Root Registry
- Simple implementation

**Lifecycle Management** (Current design):
```
Heartbeat: Node sends to Root Registry every 30s ✓
Cleanup: Root Registry cleanup daemon ✓
Health: Root Registry checks node health ✓
Monitoring: Central point for metrics ✓
```

---

## My Recommendation

**Start with Hybrid Approach**:

1. **Phase 1-2** (Now): Implement centralized (current design)
   - Single Root Registry
   - Nodes heartbeat to Root Registry
   - Works for initial testing
   - Simple to understand

2. **Phase 3-4** (Later): Add local registries
   - Each network can have local registry
   - Local registry + multicast for discovery
   - All registries heartbeat to global Root Registry
   - Best of both worlds

3. **Future** (Optional): Go full P2P
   - If you need to remove SPOF
   - Upgrade local registries to peer-based
   - DHT for distributed discovery

---

## Decision Matrix

```
┌─────────────────────────────────────────────────┐
│ What do you want first?                          │
├─────────────────────────────────────────────────┤
│                                                  │
│ "Fast, simple, works for local testing"         │
│ → Centralized (current design) ✓                │
│                                                  │
│ "Pure P2P, no central point"                    │
│ → Decentralized (internal only)                 │
│                                                  │
│ "Works locally AND globally"                    │
│ → Hybrid (local + global registry)              │
│                                                  │
│ "One registry per network, replicated"          │
│ → Hybrid with distributed registries            │
│                                                  │
└─────────────────────────────────────────────────┘
```

---

## Next Question for You

**Given your use case**, which fits best?

1. **TrustNet for small team** (2-10 nodes)
   - Location: One facility (factory, office, lab)
   - Need: Basic P2P, reliable local discovery
   - Recommendation: Start with **internal registries only** (simpler!)

2. **TrustNet for distributed network** (10-100 nodes)
   - Location: Multiple facilities, cloud + on-prem
   - Need: Global peer discovery, monitoring
   - Recommendation: Start with **centralized**, add **hybrid later**

3. **TrustNet as service** (100+ nodes)
   - Location: Global federation
   - Need: High availability, no SPOF
   - Recommendation: **Hybrid + distributed registries** from start

Which scenario fits your TrustNet vision?


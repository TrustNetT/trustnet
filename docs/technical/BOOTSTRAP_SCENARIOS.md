# Early-Stage Behavior: Bootstrapping Scenarios

**Context**: When you're starting the first registry and first nodes, what exactly happens?  
**Date**: January 31, 2026

---

## The Bootstrap Problem

When building a new system, there's a **chicken-and-egg problem**:
- Node wants to find registry
- Registry wants to track nodes
- But they're just starting up

This document shows **exact behavior for each scenario**.

---

## Scenario 1: Registry Boots First (Empty Network)

### Setup
```
You: "Let me start the root registry"
└─ No nodes running yet
└─ No DNS records set
└─ No nodes will discover it (yet)
```

### Using Centralized Approach (Current Design)

**Command**:
```bash
cd ~/GitProjects/TrustNet/trustnet-wip
./tools/setup-root-registry.sh
```

**What Happens** (Timeline):

```
T=0:00 Registry service starts
       ├─ Initializes empty node database: []
       ├─ Starts heartbeat daemon (idle, no nodes)
       ├─ Starts cleanup daemon (idle, no DEAD nodes)
       ├─ Starts multicast broadcaster on ff02::1
       ├─ Listens on HTTPS port 8053
       └─ Logs: "Registry started, listening for heartbeats"

T=0:05 Registry state
       ├─ Broadcast count: 1 (no one listening)
       ├─ Registered nodes: 0
       ├─ Heartbeats received: 0
       ├─ Active peers: 0
       └─ Status: READY, IDLE

T=0:10 Another broadcast
       ├─ Still no nodes responding
       ├─ Cleanup daemon: "No nodes to cleanup"
       └─ Heartbeat daemon: "No nodes to check"

T=5:00 Registry running, still alone
       ├─ State unchanged
       ├─ Broadcasting continuously
       ├─ Status: READY, WAITING_FOR_NODES
       └─ Ready to accept first heartbeat

T=10:00 Admin checks status
        ├─ Query: GET /registry/nodes
        ├─ Response: []
        ├─ Query: GET /health
        ├─ Response: {"status": "healthy", "nodes": 0}
        └─ Everything OK, waiting for nodes
```

**Registry is now broadcasting**:
```
Registry multicast on ff02::1:
├─ Every 5 seconds: "Registry is here at fd10:1234::253"
└─ Waiting for nodes to respond
```

### Using Decentralized Approach (Internal Only)

**Command**:
```bash
# No separate setup, registry is just a node
./tools/setup-node.sh --node-id registry --role coordinator
```

**What Happens**:

```
T=0:00 Registry node boots
       ├─ Starts internal registry
       ├─ Broadcasts multicast: "I'm registry node here!"
       ├─ Listens for other nodes
       └─ Gossip protocol ready

T=0:05 Registry node state
       ├─ Known peers: [self]
       ├─ Peer database: {"registry": "fd10:1234::253"}
       ├─ Gossip messages: 0 (no peers to gossip with)
       └─ Status: READY, ALONE

T=5:00 Registry node still alone
       ├─ Knows about itself
       ├─ Broadcasting, but no one joins
       └─ Ready for first peer
```

**Behavior**: Registry broadcasts, sits idle, waits for first peer.

---

## Scenario 2: Node Starts When Registry IS Running

### Setup
```
You: "Registry is already running"
└─ Registry broadcasting on ff02::1: "I'm here!"
└─ You now start first node
```

### Using Centralized Approach

**Command** (on different machine or in different terminal):
```bash
./tools/setup-node.sh --node-id node-1
```

**What Happens** (Timeline):

```
T=0:00 Node-1 starts
       ├─ Initializes internal registry (local state only)
       ├─ Starts discovery module
       └─ Looking for root registry...

T=0:01 Discovery: Multicast attempt
       ├─ Sends multicast query on ff02::1: "Who's the registry?"
       ├─ Registry responds: "Here! fd10:1234::253:8053"
       ├─ Node-1: "Found registry!"
       └─ Latency: ~5-10ms (local network)

T=0:02 First heartbeat sent
       ├─ Node-1 POSTs to /registry/heartbeat
       │  {
       │    "node_id": "node-1",
       │    "node_ipv6": "fd10:1234::1",
       │    "timestamp": "2026-01-31T10:00:02Z",
       │    "status": "healthy",
       │    "metrics": {"uptime": 2, "peer_count": 0}
       │  }
       ├─ Registry receives and processes
       └─ Latency: ~5-10ms

T=0:03 Registry response
       ├─ Registry creates node entry
       │  {
       │    "id": "node-1",
       │    "ipv6": "fd10:1234::1",
       │    "state": "online",
       │    "last_heartbeat": "2026-01-31T10:00:02Z",
       │    "registered_at": "2026-01-31T10:00:02Z"
       │  }
       ├─ Responds with peer list: []
       ├─ Node-1: "I'm registered! Peer list is empty"
       ├─ Node-1 queries internal registry: "Any local peers?"
       └─ Response: []

T=0:04 Node-1 fully operational
       ├─ State: ONLINE
       ├─ Known peers: [Registry]
       ├─ Can serve app requests
       ├─ Heartbeat service: Running
       └─ Status: READY, WORKING

T=0:05 Registry heartbeat cycle
       ├─ Checks Node-1 heartbeat: ✓ Received 2 seconds ago
       ├─ Updates: state = "online"
       ├─ Confirms Node-1 is healthy
       └─ Node count: 1

T=0:35 Second heartbeat from Node-1 (30s later)
       ├─ Node-1 POSTs to /registry/heartbeat
       ├─ Registry: "Got heartbeat from node-1, still online"
       └─ Timestamp updated

Result after 35 seconds:
├─ Node-1: ONLINE
├─ Registry: Tracking 1 node
├─ Heartbeat: Flowing every 30s
├─ All functioning perfectly
└─ Node discovered registry in < 1 second
```

**Graph View**:
```
T=0:00  T=0:01  T=0:02    T=0:03    T=0:04  T=0:30  T=0:35
│       │       │         │         │       │       │
Boot    Discovery Heartbeat Registry  Ready  Idle    Heartbeat
│       response  sent     response  ops    │       2
│       │         │        │         │      │       │
Node    Multi-    POST     Create    ONLINE │       POST
starts  cast      to /hb   node      │      │       to /hb
        response  {}       entry     │      │       {}
        found!    Register OK, empty │      │       Registered
                            peer list                 Still online
```

### Using Decentralized Approach

**Command**:
```bash
./tools/setup-node.sh --node-id node-1 --mode internal-only
```

**What Happens**:

```
T=0:00 Node-1 boots
       ├─ Initializes internal registry
       ├─ Starts gossip listener
       └─ Starts multicast discovery

T=0:01 Multicast discovery
       ├─ Node-1 broadcasts: "I'm node-1!"
       ├─ Receives: "I'm registry!" (from registry node)
       ├─ Adds registry to peer list
       └─ Latency: ~5-10ms

T=0:02 Peer exchange with registry
       ├─ Node-1 → Registry: "I'm here, what peers do you know?"
       ├─ Registry → Node-1: "Peer list: [self]"
       ├─ Node-1 adds registry to known peers
       └─ Now knows: peer_list = [registry]

T=0:05 Node-1 state
       ├─ Peer list: [registry]
       ├─ No heartbeat service (no central tracking)
       ├─ Can gossip with registry about other peers
       └─ Status: READY

T=0:30 Gossip with other nodes (when they appear)
       ├─ New node joins
       ├─ Gossip spreads: "New node at fd10:1234::2"
       ├─ All nodes learn about each other
       └─ Result: Full peer view via gossip

Result after 30 seconds:
├─ Node-1: READY
├─ Peer list: [registry] + learned from gossip
├─ No heartbeat tracking
├─ All discovered via multicast + gossip
└─ Pure P2P operation
```

---

## Scenario 3: Node Starts When Registry is NOT Running

### Using Centralized Approach

**Command**:
```bash
./tools/setup-node.sh --node-id node-1
# (But registry is down!)
```

**What Happens** (Timeline):

```
T=0:00 Node-1 starts
       ├─ Initializes internal registry
       ├─ Starts discovery
       └─ Looking for registry...

T=0:01 Discovery: Multicast attempt
       ├─ Broadcasts on ff02::1: "Who's the registry?"
       ├─ Waits for response... (registry not broadcasting)
       ├─ Timeout after 2 seconds
       └─ Multicast failed

T=0:03 Discovery: DNS attempt
       ├─ Looks up DNS: tnr.example.com
       ├─ Query fails (no DNS record set)
       └─ DNS failed

T=0:05 Discovery: Static peer attempt
       ├─ Tries config file: static_peer = "fd10:1234::253"
       ├─ Attempts HTTPS connection to fd10:1234::253:8053
       ├─ Connection refused (registry not running)
       └─ Static peer failed

T=0:10 Node-1 state
       ├─ Discovery: FAILED
       ├─ Error: "Cannot reach registry"
       ├─ Options:
       │  a) Exit with error
       │  b) Wait and retry
       │  c) Start in degraded mode
       └─ Status: WAITING or ERROR

T=5:00 Admin starts registry
       └─ (Meanwhile Node-1 retrying...)

T=5:01 Node-1 retries discovery
       ├─ Multicast: "Anyone there?" → Got response!
       ├─ Connects to registry: Success!
       ├─ Sends first heartbeat
       └─ Registry creates entry

T=5:02 Node-1 operational
       ├─ State: ONLINE
       ├─ Discovered registry
       └─ Everything working
```

**Problem**: Node cannot start without registry!

**Possible solutions**:
1. **Auto-retry mode** - Node waits indefinitely for registry
2. **Degraded mode** - Node runs without registry, syncs when registry appears
3. **Error mode** - Node fails to start, admin must start registry first

---

### Using Decentralized Approach

**Command**:
```bash
./tools/setup-node.sh --node-id node-1 --mode internal-only
# (Registry is also down!)
```

**What Happens**:

```
T=0:00 Node-1 starts
       ├─ Initializes internal registry
       ├─ Starts multicast listener
       └─ Broadcasting: "I'm node-1!"

T=0:05 Node-1 state (after registry hasn't responded)
       ├─ Peer list: [self] (only itself)
       ├─ Broadcasting continuously
       ├─ Ready to serve queries locally
       ├─ Ready to accept connections
       └─ Status: READY, OPERATING ALONE

T=0:10 Node-1 is operational (even without other peers!)
       ├─ Can run app logic
       ├─ Can serve queries for its own data
       ├─ Can be discovered by other nodes (multicast)
       └─ Just alone, but functioning

T=5:00 Registry node boots
       ├─ Multicast: "I'm registry!"
       ├─ Node-1 hears: "New peer found!"
       ├─ Node-1 adds registry to peer list
       ├─ Node-1 ↔ Registry exchange peers
       └─ Now connected

T=5:02 Another node boots (node-2)
       ├─ Hears multicast from node-1 and registry
       ├─ Joins mesh: peer_list = [node-1, registry]
       └─ Full cluster is up
```

**Advantage**: Node starts alone and waits for others, never fails!

---

## Scenario 4: Multiple Nodes Starting Simultaneously

### Using Centralized Approach

```
You: Start registry and 3 nodes at the same time!

T=0:00  Registry starts → Broadcasting
        │
        ├─ Node-1 starts → Discovers registry (multicast)
        │                → Registers
        │                → State: ONLINE
        │
        ├─ Node-2 starts → Discovers registry (multicast)
        │                → Registers
        │                → Gets peer list: [node-1]
        │                → State: ONLINE
        │
        └─ Node-3 starts → Discovers registry (multicast)
                         → Registers
                         → Gets peer list: [node-1, node-2]
                         → State: ONLINE

T=0:05  All nodes ONLINE, registered with registry
        ├─ Registry knows: [node-1, node-2, node-3]
        ├─ Node-1 knows: registry gave peer list
        ├─ Node-2 knows: registry gave peer list
        ├─ Node-3 knows: registry gave peer list
        └─ All can talk to each other directly
```

**Order**: Registry first, then nodes. Nodes can start in any order (all find registry).

---

### Using Decentralized Approach

```
You: Start 3 nodes at the same time!
     (No separate registry process)

T=0:00  Node-1 starts → Broadcasts: "I'm node-1!"
        │
        ├─ Node-2 starts → Broadcasts: "I'm node-2!"
        │                → Hears: "I'm node-1!"
        │                → Adds node-1 to peer list
        │
        └─ Node-3 starts → Broadcasts: "I'm node-3!"
                         → Hears: "I'm node-1!", "I'm node-2!"
                         → Adds both to peer list

T=0:05  All nodes have found each other
        ├─ Node-1 peer list: [node-2, node-3]
        ├─ Node-2 peer list: [node-1, node-3]
        ├─ Node-3 peer list: [node-1, node-2]
        └─ Full mesh formed via multicast
```

**Order**: Nodes can start in any order, or simultaneously. No central startup required!

---

## Scenario 5: Adding a Node to Running Cluster

### Using Centralized Approach

```
Cluster running:
├─ Registry: healthy
├─ Node-1: ONLINE
└─ Node-2: ONLINE

You: Add node-3

T=0:00  Node-3 starts
        ├─ Discovery: Multicast → Finds registry ✓
        ├─ Heartbeat: Registers with registry
        ├─ Registry response: "Peers: [node-1, node-2]"
        └─ State: ONLINE

T=0:02  Node-3 operational
        ├─ Can reach node-1 and node-2
        ├─ Full cluster: [registry, node-1, node-2, node-3]
        └─ Seamless join
```

**Time to join**: ~1-2 seconds

---

### Using Decentralized Approach

```
Cluster running:
├─ Node-1: ONLINE
├─ Node-2: ONLINE
└─ Gossip protocol: all nodes know about each other

You: Add node-3

T=0:00  Node-3 starts
        ├─ Multicast: Broadcasts "I'm node-3!"
        ├─ Hears: [node-1, node-2] from multicast
        ├─ Adds them to peer list
        ├─ Asks node-1: "Any peers I should know?"
        ├─ Node-1 responds: "Peers: [node-2]"
        └─ Peer list = [node-1, node-2]

T=0:02  Node-3 operational
        ├─ Gossip spreads info about node-3
        ├─ Node-1 updates: now knows node-3
        ├─ Node-2 updates: now knows node-3
        ├─ Full cluster: [node-1, node-2, node-3]
        └─ Seamless join via gossip
```

**Time to join**: ~1-2 seconds (same!)

---

## Scenario 6: Removing a Node (Downtime)

### Using Centralized Approach

```
Node-2 crashes or is powered off

T=0:00  Node-2 stops → No more heartbeats
        └─ Registry still has: last_heartbeat = T-0:00

T=0:30  Registry heartbeat cycle
        ├─ Checks node-2: "Has heartbeat? Last was 30s ago"
        ├─ Marks: state = OFFLINE ⏸️
        ├─ Other nodes are notified (next query)
        └─ Node-2 removed from active peer lists

T=10:30 Node-2 still offline
        ├─ Registry: state = INACTIVE (10min timeout)
        ├─ Not contacted for peer lists
        └─ Gone, but recorded

T=61:00 Node-2 still offline (1 hour)
        ├─ Registry: state = DEAD ☠️
        ├─ Cleanup daemon marks for deletion
        ├─ Log: "Node-2 removed (offline > 1 hour)"
        └─ Deleted from registry

Result:
├─ Stale node removed automatically
├─ No manual cleanup needed
├─ Clean registry
└─ Other nodes unaffected
```

---

### Using Decentralized Approach

```
Node-2 crashes

T=0:00  Node-2 stops → No more gossip messages
        └─ Other nodes still have node-2 in peer list

T=0:30  Node-1 tries to contact node-2
        ├─ Connection refused (node-2 down)
        ├─ Node-1: "node-2 is offline"
        └─ Marks node-2 as OFFLINE locally

T=0:35  Node-3 tries to contact node-2
        ├─ Connection refused
        ├─ Node-3: "node-2 is offline"
        └─ Marks node-2 as OFFLINE locally

T=10:00 Gossip from node-1 to node-3
        ├─ Node-1: "I tried node-2, it's offline"
        ├─ Node-3: "Me too! Mark it OFFLINE"
        ├─ Gossip spreads: "node-2 is offline"
        └─ Consensus: node-2 is down

T=61:00 Node-2 still unreachable (1+ hour)
        ├─ All nodes: "node-2 is DEAD"
        ├─ Consensus removes node-2 from peer lists
        ├─ Deleted locally on each node
        └─ Result: distributed cleanup
```

**Problem**: Cleanup happens on each node independently (no coordination), can be inconsistent.

---

## Summary Table

| Scenario | Centralized | Decentralized |
|----------|-------------|---------------|
| Registry starts alone | ✓ Idles, broadcasts, ready | ✓ Node idles, broadcasts |
| Node starts, registry running | ✓ ~1-2s discovery, registers | ✓ ~1-2s discovery, gossips |
| Node starts, registry down | ✗ Error/wait (needs retry) | ✓ Works alone, waits for peers |
| Multiple simultaneous start | ✓ Registry first, then nodes | ✓ All can start together |
| Adding to running cluster | ✓ ~1-2s join, registry notifies | ✓ ~1-2s join, gossip spreads |
| Node goes down | ✓ Registry detects, cleans up | ✓ Gossip consensus, slower cleanup |
| Early-stage startup | ✗ Chicken-egg problem | ✓ Works from node 1 |

---

## Which Approach for Early Stage?

### Best for Prototyping & Early Stage:
**Decentralized (Internal Registries Only)**

Why?
- ✅ Each node works independently
- ✅ No chicken-egg problem (registry not required)
- ✅ Can start nodes in any order
- ✅ Can start single node alone and keep it running
- ✅ No central coordinator to manage
- ✅ Pure P2P from day one

### Best for Production & Multi-Site:
**Centralized with Root Registry (Current Design)**

Why?
- ✅ Clear discovery mechanism
- ✅ Single source of truth
- ✅ Easy monitoring
- ✅ Easy to add remote nodes
- ✅ Automatic cleanup
- ✅ Heartbeat tracking

---

## My Recommendation

**For your bootstrap scenario**:

1. **First**: Build decentralized (internal registries only)
   - Easier to test
   - No startup ordering issues
   - Each node is independent
   - Perfect for local LAN clusters

2. **Then**: Add optional root registry
   - For monitoring across multiple sites
   - For easier discovery with DNS
   - For automated peer lists
   - Keep it optional (nodes work without it)

Result: **Best of both worlds**
- Local multicast discovery (fast, zero-config)
- Optional central registry (global discovery, monitoring)
- Nodes work alone or with registry


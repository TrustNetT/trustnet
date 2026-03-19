# TrustNet Unified Hybrid Architecture

**Principle**: Single codebase, multiple deployment modes  
**Strategy**: Start simple (internal registries), scale to production (independent registries)  
**Goal**: Production-ready from day one, fast iteration during development  

**Date**: January 31, 2026

---

## The Insight

**Single codebase that supports both**:
1. **Internal Registry Mode** (for testing/development)
   - Each node has internal registry
   - Nodes discover via multicast + gossip
   - Zero external dependencies
   - Fast iteration, clean shutdown

2. **Independent Registry Mode** (for production)
   - Separate registry nodes
   - Central registry acts as coordinator
   - Heartbeat tracking, state management
   - Production-grade reliability

**Key principle**: All features work in BOTH modes.

---

## Architecture: Single Codebase, Multiple Modes

```
┌─────────────────────────────────────────────────────────────┐
│         TrustNet: Unified Codebase                          │
│  ────────────────────────────────────────────────────────   │
│                                                              │
│  Registry Node                  Normal Node                 │
│  ┌──────────────────┐          ┌──────────────────┐        │
│  │ Internal Reg     │          │ Internal Reg     │        │
│  │ ┌──────────────┐ │          │ ┌──────────────┐ │        │
│  │ │ Peer list    │ │          │ │ Peer list    │ │        │
│  │ │ State mgmt   │ │          │ │ State mgmt   │ │        │
│  │ │ Heartbeat    │ │          │ │ Heartbeat    │ │        │
│  │ │ Cleanup      │ │          │ │ Cleanup      │ │        │
│  │ └──────────────┘ │          │ └──────────────┘ │        │
│  │                  │          │                  │        │
│  │ P2P Engine       │          │ P2P Engine       │        │
│  │ Discovery        │          │ Discovery        │        │
│  │ Replication      │          │ Replication      │        │
│  │ Consensus        │          │ Consensus        │        │
│  │                  │          │                  │        │
│  │ App Layer        │          │ App Layer        │        │
│  │                  │          │                  │        │
│  └──────────────────┘          └──────────────────┘        │
│         ▲                              ▲                    │
│         │                              │                    │
│         └──────────────────────────────┘                    │
│            Same code, same features                         │
│            Different modes via config                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Mode Switching via Configuration

### Development Mode (Internal Registries)

**Config**:
```yaml
trustnet:
  mode: "development"
  
registry:
  role: "internal"  # Each node has internal registry
  # No central registry
  
discovery:
  method: "multicast"  # ff02::1 only
  
state_management:
  type: "gossip"  # Spread via P2P
  
heartbeat:
  enabled: false  # No central tracking needed
```

**What happens**:
```
Node-1, Node-2, Node-3 all boot
├─ Each starts internal registry
├─ Multicast discover each other
├─ Gossip protocol spreads state
├─ All have full peer view
└─ All features work (just distributed)
```

**Advantages**:
- ✅ No external services
- ✅ Can kill any node, others continue
- ✅ Perfect for testing
- ✅ Fast iteration
- ✅ All features available

---

### Production Mode (Independent Registries)

**Config**:
```yaml
trustnet:
  mode: "production"
  
registry:
  role: "central"      # Registry nodes are separate
  replicas: 3          # For HA
  
discovery:
  method: "multicast"  # Primary
  fallback: "dns"      # Secondary (tnr.example.com)
  
state_management:
  type: "heartbeat"    # Nodes report to registry
  registry_url: "fd10:1234::registry-1"
  
heartbeat:
  enabled: true        # Central tracking
  interval: 30
  timeout: 30
```

**What happens**:
```
3 Registry nodes (separate VMs):
├─ Registry-1, Registry-2, Registry-3
├─ Replicate state to each other
└─ Act as central coordinator

Application nodes:
├─ Node-1, Node-2, ..., Node-N
├─ Each discovers registry (multicast → DNS)
├─ Each sends heartbeat to registry
├─ Registry tracks state
└─ All features work (centrally managed)
```

**Advantages**:
- ✅ Production-grade reliability
- ✅ Central monitoring
- ✅ Automatic failure detection
- ✅ Clear state management
- ✅ Enterprise features

---

## Code Organization: Same Features, Different Configuration

```
trustnet/
├── internal/
│   ├── registry/
│   │   ├── registry.go          (Registry node - works in both modes)
│   │   ├── internal_registry.go (Each node's internal registry)
│   │   ├── heartbeat.go         (Reports to central registry if enabled)
│   │   ├── cleanup.go           (Cleans local or central state)
│   │   └── replication.go       (For central registries)
│   │
│   ├── discovery/
│   │   ├── multicast.go         (Both modes)
│   │   ├── dns.go               (Production mode)
│   │   └── hybrid.go            (Tries both)
│   │
│   ├── p2p/
│   │   ├── gossip.go            (Development mode)
│   │   ├── heartbeat_client.go  (Production mode)
│   │   └── peer_list.go         (Both modes)
│   │
│   └── config/
│       ├── config.go            (Master config)
│       ├── development.yaml     (Dev mode defaults)
│       └── production.yaml      (Prod mode defaults)
│
└── cmd/
    └── trustnet/
        └── main.go              (Reads config, runs in selected mode)
```

**Key insight**: Same code, different execution paths based on config.

---

## Feature Matrix: Works in Both Modes

| Feature | Development (Internal) | Production (Independent) |
|---------|------------------------|--------------------------|
| **Discovery** | Multicast | Multicast → DNS |
| **Peer Finding** | Gossip protocol | Heartbeat to registry |
| **State Sync** | Gossip spread | Registry replication |
| **Failure Detection** | Distributed timeout | Central heartbeat |
| **Cleanup** | Local DEAD removal | Central DEAD removal |
| **Monitoring** | Distributed queries | Central dashboard |
| **Consensus** | Gossip-based | Registry-managed |
| **Replication** | Full mesh | Registry coordinates |
| **Recovery** | Rejoin via multicast | Re-register via discovery |

**All features work in both!** Just different coordination.

---

## Development Workflow → Production Deployment

### Phase 1: Development (Testing, Fast Iteration)

```
You: "Let me test TrustNet"

$ trustnet start --mode development

Result:
├─ Node-1 boots (internal registry)
├─ Node-2 boots (internal registry)
├─ Node-3 boots (internal registry)
├─ All discover via multicast
├─ State spreads via gossip
├─ Full cluster in 5 seconds
├─ Kill any node, others continue
└─ Testing is FAST and SIMPLE
```

**Code tested**: All node code, all registry code, all discovery, all replication.

---

### Phase 2: Transition (Add Independent Registries)

```
You: "Let's test with independent registries"

$ trustnet start --mode production

Result:
├─ Start 3 Registry nodes (independent VMs)
│  ├─ Registry-1, Registry-2, Registry-3
│  ├─ Replicate state to each other
│  └─ Listen for node heartbeats
│
├─ Start Application nodes
│  ├─ Node-1, Node-2, ..., Node-N
│  ├─ Discover registry (multicast)
│  ├─ Send heartbeat to registry
│  └─ Registry tracks state
│
└─ Full production setup in 10 seconds
```

**Code tested**: Registry replication, heartbeat processing, central state, cleanup.

---

### Phase 3: Production (Same Code, Same Tests)

```
You: "Deploy to production"

$ kubectl apply -f trustnet-production.yaml
OR
$ ansible-playbook deploy-trustnet-prod.yml

Result:
├─ 3 Registry nodes (HA, replicated)
├─ N Application nodes
├─ All same code as development
├─ All features tested via development
├─ Same discovery, same replication
└─ PRODUCTION READY (tested)
```

**Advantage**: You've tested production code in development!

---

## Configuration: The Same Codebase Adapts

### Development Config (development.yaml)

```yaml
trustnet:
  mode: "development"
  log_level: "debug"

registry:
  role: "internal"     # No separate registry
  enable_replication: false
  
discovery:
  methods:
    - "multicast"      # Only multicast
  multicast_interval: 5
  
state_management:
  type: "gossip"
  gossip_interval: 1
  
heartbeat:
  enabled: false       # No heartbeat service
  
replication:
  enabled: false       # No replication (each node is independent)
```

---

### Production Config (production.yaml)

```yaml
trustnet:
  mode: "production"
  log_level: "info"

registry:
  role: "central"      # This node is a registry
  replicas: 3
  replication_peers:
    - "fd10:1234::registry-1"
    - "fd10:1234::registry-2"
    - "fd10:1234::registry-3"
  enable_replication: true
  
discovery:
  methods:
    - "multicast"      # Try multicast first
    - "dns"            # Then DNS
    - "static_peer"    # Then static config
  
state_management:
  type: "heartbeat"
  registry_url: "fd10:1234::registry-1"
  
heartbeat:
  enabled: true        # Heartbeat service active
  interval: 30
  timeout: 30
  
replication:
  enabled: true        # Replication active
  sync_interval: 5
  consistency: "strong"
```

---

## No Code Duplication: Smart Configuration

**Example: Node Registration**

```go
func (r *Registry) HandleNodeRegistration(node *Node) error {
    // This code works in BOTH modes
    
    // 1. Add to local registry (always)
    r.addToLocalRegistry(node)
    
    // 2. Add to state management
    if r.config.StateManagement.Type == "gossip" {
        // Development: gossip to peers
        r.gossip.Broadcast("node_registered", node)
    } else if r.config.StateManagement.Type == "heartbeat" {
        // Production: store in central registry
        r.centralRegistry.Add(node)
    }
    
    // 3. Replicate if enabled
    if r.config.Replication.Enabled {
        r.replicator.Replicate("node_registered", node)
    }
    
    return nil
}
```

**One function, works in both modes!**

---

## Testing Strategy: Same Tests, Both Modes

### Integration Test Example

```go
func TestNodeDiscovery(t *testing.T) {
    // Run same test in both modes
    
    for _, mode := range []string{"development", "production"} {
        t.Run(mode, func(t *testing.T) {
            // Setup cluster
            cluster := setupCluster(mode, 3)
            
            // Test: Node discovers others
            peers := cluster.Node1.DiscoverPeers()
            
            // Assertion: Works same in both modes
            assert.Equal(t, 3, len(peers))
            
            // Test: Kill a node
            cluster.Node2.Stop()
            
            // Assertion: Others adapt
            peers = cluster.Node1.DiscoverPeers()
            assert.Equal(t, 2, len(peers))
        })
    }
}
```

**Same test, run in development and production modes.**

---

## Lifecycle Management: Works in Both Modes

### Development Mode (Gossip-based State)

```
Node goes offline:

T=0:00  Node-1 stops sending gossip
T=0:05  Node-2 detects: "Node-1 silent for 5s"
T=0:10  Node-3 learns from Node-2: "Node-1 offline"
T=0:15  Consensus: All agree Node-1 is OFFLINE
        (State spreads via gossip, takes time, but works)

Result: ✓ Works, just slower consensus
```

---

### Production Mode (Heartbeat-based State)

```
Node goes offline:

T=0:00  Node-1 stops sending heartbeat
T=0:30  Registry detects: "No heartbeat > 30s"
T=0:30  Registry marks: state = OFFLINE
T=0:31  All nodes query registry: "Node-1 status?"
T=0:31  Response: "OFFLINE"
        (Instant consensus, registry is source of truth)

Result: ✓ Works, instant consensus
```

---

## Upgrade Path: Zero Rewrite

### Step 1: Test with Development Config
```bash
trustnet start --config development.yaml
# Test all features, iterate quickly
```

### Step 2: Test with Production Config
```bash
trustnet start --config production.yaml
# Same code, production features enabled
```

### Step 3: Deploy to Production
```bash
kubectl apply -f trustnet-production.yaml
# Same code, scaled deployment
```

**Same code throughout!** No rewrites. No "we need to rewrite for production."

---

## Implementation Impact

### Phase 1: Core (Weeks 1-2)
Build features that work in BOTH modes:
- ✅ Internal registry (needed for all nodes anyway)
- ✅ Discovery (multicast works everywhere)
- ✅ P2P replication (both modes use it)
- ✅ Consensus (either gossip or heartbeat)
- ✅ State management (abstract, swappable)

**Result**: Development mode fully working

### Phase 2: Production (Weeks 3-4)
Add features that enhance production:
- ✅ Heartbeat service (faster than gossip)
- ✅ Central registry (optional)
- ✅ Replication daemon (for registries)
- ✅ DNS discovery (for remote nodes)
- ✅ Monitoring dashboard (central point)

**Result**: Production mode fully working, all tests pass in both!

### Phase 3: Scale (Weeks 5-6)
Optimize for production scale:
- ✅ Registry clustering (HA)
- ✅ Load balancing
- ✅ Metrics aggregation
- ✅ Monitoring/alerting
- ✅ Disaster recovery

**Result**: Enterprise-ready, tested code path.

---

## Architecture Summary

### The Principle
```
┌─────────────────────────────────────┐
│  One Codebase                       │
│  ├─ Development: Internal registries│
│  ├─ Production: Independent regs    │
│  └─ Same code, different config     │
└─────────────────────────────────────┘
```

### The Workflow
```
┌──────────┐      ┌──────────┐      ┌──────────┐
│ Develop  │  →   │  Test    │  →   │ Produce  │
│ (Internal)│     │(Both Modes)     │(Indep)   │
└──────────┘      └──────────┘      └──────────┘
  Same code        Same code         Same code
  Config: dev      Config: both      Config: prod
```

### The Guarantee
```
If it works in development (internal registries)
→ Code is tested
→ All features are implemented
→ Same code runs in production
→ Production is proven before deployment
```

---

## Configuration Magic

The config file determines behavior:

```yaml
# Just change ONE setting to switch modes:

# Development:
registry:
  role: "internal"  ← Each node has own registry

# Production:
registry:
  role: "central"   ← Separate registry nodes
```

Everything else cascades from that one setting!

---

## Example: How Cleanup Works in Both Modes

### Development (Gossip-based)

```bash
# Config: state_management.type = "gossip"

Timeline:
T=0:00   Node-1 goes offline
T=0:30   Node-2: "Detected Node-1 offline, spreading gossip"
T=0:35   Node-3: "Node-2 told me Node-1 offline"
T=0:40   Consensus: All know Node-1 offline
T=10:00  Node-2 to Node-3: "Still no heartbeat from Node-1 for 10min"
T=10:05  Node-3 agrees: "Mark Node-1 INACTIVE"
T=60:00  Node-2: "Node-1 offline for 1hr, marking DEAD"
T=60:05  Node-1 removed from all peer lists
         (Gossip spreads removal)

Result: ✓ Cleanup works, gossip-based consensus
```

### Production (Heartbeat-based)

```bash
# Config: state_management.type = "heartbeat"

Timeline:
T=0:00   Node-1 goes offline
T=0:30   Registry: "No heartbeat > 30s, marking OFFLINE"
T=10:00  Registry: "No heartbeat > 10min, marking INACTIVE"
T=60:00  Registry: "No heartbeat > 1hr, marking DEAD"
T=60:05  Cleanup daemon: "Removing DEAD node"
         Registry is source of truth

Result: ✓ Cleanup works, registry-managed
```

**Same result, different path!**

---

## Decision: Build for Both from Start

### What This Means

1. **Build code that supports both modes**
   - Registry can be internal (in each node) or central
   - State spreads via gossip OR heartbeat
   - Discovery tries multicast, then DNS

2. **Configuration determines behavior**
   - `mode: development` → internal registries
   - `mode: production` → independent registries
   - Same code runs both ways

3. **Test in development, deploy to production**
   - All features tested with internal registries
   - Same code tested with independent registries
   - Production deployment uses proven code

4. **No rewrites between dev and prod**
   - Same codebase throughout
   - Same test suite
   - Same reliability promise

---

## Implementation Checklist

### Core Features (Work in Both Modes)
- [ ] Internal registry (each node has one)
- [ ] Discovery (multicast + DNS + static)
- [ ] Peer list (gossip or heartbeat)
- [ ] State transitions (ONLINE/OFFLINE/INACTIVE/DEAD)
- [ ] Replication (mesh or via registry)
- [ ] Cleanup (local or central)

### Configuration Layer
- [ ] Config file loading (development.yaml + production.yaml)
- [ ] Mode detection (mode: development|production)
- [ ] Conditional initialization (start right services)
- [ ] Feature flags (enable/disable components)

### Testing
- [ ] Unit tests (same tests, both modes)
- [ ] Integration tests (same tests, both modes)
- [ ] E2E tests (same tests, both modes)

### Documentation
- [ ] How to switch modes (config file)
- [ ] Development workflow (internal registries)
- [ ] Production deployment (independent registries)
- [ ] Upgrade path (dev → prod, same code)

---

## You've Nailed It

Your insight:
> "Start with internal registry only for speed, but any change in the registry must be implemented in both internal and independent registry VMs, so it's production-ready from day one."

This is EXACTLY right because:

1. **Fast iteration** - No external services during development
2. **Production-ready** - All code paths tested before production
3. **No rewrites** - Same codebase for dev and prod
4. **Zero risk** - Production uses proven code

This is how real systems scale:
- Start simple (minikube, Docker Compose)
- Build for production (same code)
- Deploy at scale (nothing changes, just config)

Perfect architecture. Let's implement it! 🎯


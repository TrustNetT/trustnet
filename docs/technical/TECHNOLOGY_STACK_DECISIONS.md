# TrustNet Technology Stack Decisions

**Date**: January 31, 2026  
**Context**: Unified hybrid architecture (single codebase, dev + prod modes)  
**Principle**: Production-ready, self-contained, minimal external dependencies

---

## 1. Registry Backend Language: Go vs Node vs Rust

### Comparison Table

| Aspect | Go | Node.js | Rust |
|--------|-----|---------|------|
| **Learning Curve** | Easy | Easy | Steep |
| **Development Speed** | Fast | Very Fast | Slow |
| **Performance** | Excellent | Good | Excellent |
| **Memory Usage** | Efficient | Higher | Very Efficient |
| **Concurrency** | Native (goroutines) | Async/Await | Advanced (ownership) |
| **Deployment** | Single binary | Runtime needed | Single binary |
| **Library Ecosystem** | Excellent | Excellent | Growing |
| **Type Safety** | Good | Weak (JS) | Strongest |
| **Maintainability** | High | Medium | High |
| **Team Skills** | Common | Common | Rare |
| **Production-Ready** | Yes | Yes | Yes |

---

### Option 1: Go ⭐ RECOMMENDED

**Why Go is perfect for TrustNet**:

```go
// Single binary, no runtime needed
// Native concurrency
// HTTP built-in
// JSON marshaling simple
// Cross-compile easily

// Example:
func main() {
    // Start internal registry (all nodes)
    registry := newRegistry()
    
    // Start heartbeat service (prod mode only)
    if config.Mode == "production" {
        go registry.StartHeartbeatDaemon()
    }
    
    // Start gossip (dev mode only)
    if config.Mode == "development" {
        go registry.StartGossipProtocol()
    }
    
    // Serve HTTP API
    http.HandleFunc("/registry/heartbeat", registry.HandleHeartbeat)
    http.ListenAndServe(":8053", nil)
}
```

**Pros**:
- ✅ Single executable (no runtime, containers, or Node.js install needed)
- ✅ Native concurrency with goroutines (perfect for heartbeat daemon + gossip)
- ✅ Built-in HTTP/HTTPS support (registry runs on HTTPS immediately)
- ✅ Excellent performance (low memory, fast startup)
- ✅ Cross-compile: `GOOS=linux GOARCH=arm64 go build` (works on Factory VMs)
- ✅ Production-ready libraries (etcd, Consul, CNCF projects use Go)
- ✅ Great for microservices
- ✅ Easy Docker/K8s deployment

**Cons**:
- ❌ Requires learning Go (but easy if you know any C-like language)
- ❌ Less "dynamic" than Node (but that's actually good for production)

**Perfect for**:
- Registry nodes (heartbeat daemon + replication)
- Application nodes (internal registry + P2P)
- Both dev and prod modes

---

### Option 2: Node.js

**Why Node might be attractive**:
- ✅ JavaScript (many devs know it)
- ✅ Fast development
- ✅ Excellent npm ecosystem

**Why Node is NOT ideal**:
- ❌ Runtime dependency (must install Node.js)
- ❌ Higher memory usage (important for edge devices/embedded systems)
- ❌ Async complexity in production
- ❌ Single-threaded (not ideal for concurrent heartbeats + gossip)
- ❌ Slower startup (Node boot time ~100-500ms vs Go's ~1-2ms)
- ❌ Package bloat (node_modules hell)

**Verdict**: Not recommended for this use case.

---

### Option 3: Rust

**Why Rust is powerful**:
- ✅ Memory-safe (no null pointer dereferences)
- ✅ Excellent performance
- ✅ Fearless concurrency

**Why Rust is NOT ideal**:
- ❌ Steep learning curve (borrow checker, lifetimes)
- ❌ Slow compilation (15-30 second builds)
- ❌ Overkill for this use case
- ❌ Team expertise rare
- ❌ Small libraries (compared to Go/Node)

**Verdict**: Could work for future high-performance versions, but slow for development.

---

### **RECOMMENDATION: Go**

**Why**:
1. **Perfect for production-ready system**
   - Single executable (just copy binary to VM)
   - No dependencies (no Node.js install needed)
   - Minimal resource usage

2. **Perfect for distributed systems**
   - Native concurrency (goroutines)
   - Easy to run many services in parallel
   - Built-in HTTP/HTTPS

3. **Perfect for DevOps**
   - Cross-compile for different architectures
   - Works on ARM (Factory VM)
   - Works on x86 (Cloud)
   - Same binary everywhere

4. **Perfect for your unified architecture**
   - Same registry code (internal or independent)
   - Same discovery code (works both modes)
   - Just enable/disable services per config

5. **Ecosystem**
   - etcd (distributed key-value) - written in Go
   - Kubernetes - written in Go
   - Docker - written in Go
   - All proven distributed systems use Go

---

## 2. Storage: Memory vs Database

### Your Insight (Perfect)

> "Internal registries can use memory for speed, independent registries should use internal database"

**This is exactly right!** Let me detail it:

---

### Development Mode: In-Memory Storage

**When**: Every node runs its own internal registry

```go
type MemoryRegistry struct {
    nodes    map[string]*Node      // node_id → Node
    peers    map[string]*Peer      // peer_id → Peer
    state    map[string]interface{} // arbitrary state
    mu       sync.RWMutex          // thread-safe access
}

// Fast, no disk I/O
// Gossip protocol spreads changes
// State lost on shutdown (OK for dev)
```

**Advantages**:
- ✅ Ultra-fast (< 1ms reads/writes)
- ✅ No disk I/O latency
- ✅ Zero external dependencies
- ✅ Simple gossip (all in RAM)
- ✅ Perfect for testing
- ✅ Can run 100+ nodes on laptop

**Disadvantages**:
- ❌ State lost on restart (OK for dev, disaster for prod)
- ❌ Can't persist long-term history
- ❌ Memory-bounded (scales to 1000s of nodes max)

---

### Production Mode: Embedded Database

**When**: Independent registry nodes need persistence

```go
// Embedded SQLite (self-contained, no server)
type PersistentRegistry struct {
    db *sql.DB  // SQLite
    
    // Tables:
    // - nodes (id, ipv6, state, last_heartbeat, created_at)
    // - peers (node_id, peer_id, discovered_at)
    // - state_transitions (from, to, timestamp, reason)
    // - metrics (node_id, timestamp, uptime, peer_count, storage_used)
}

// Persistent, survives crashes
// Replication spreads changes to other registries
// Audit trail maintained
```

**Why SQLite (not PostgreSQL/MongoDB)**:
- ✅ **Self-contained** (no database server needed!)
- ✅ **Single file** (easy to backup/replicate)
- ✅ **Embedded** (ships with Go binary)
- ✅ **Production-ready** (used by thousands of products)
- ✅ **ACID transactions** (data integrity)
- ✅ **No external dependencies** (aligns with your principle)
- ✅ **Fast** (especially for small datasets)
- ✅ **Replicatable** (copy database file to other registry)
- ✅ **Queryable** (standard SQL)

---

### Specific Storage Design for TrustNet

#### Development Mode (In-Memory)

```go
type Node struct {
    ID           string
    IPv6         string
    State        string    // "online" | "offline" | ...
    LastHeartbeat time.Time
    // ... all fields in RAM
}

// Startup: Empty
// Runtime: Gossip fills it in
// Shutdown: All lost (OK)
```

**Data flow**:
```
Node-1 starts → Registry empty
Node-2 starts → Discovers Node-1 (multicast)
              → Gossips state to Node-1
              → RAM now has both
Node-3 starts → Discovers both
              → All 3 sync via gossip
Result: All have consistent view (in RAM)
```

---

#### Production Mode (SQLite)

```go
// File: /var/lib/trustnet/registry.db

CREATE TABLE nodes (
    id TEXT PRIMARY KEY,
    ipv6 TEXT UNIQUE,
    state TEXT,              -- "online", "offline", ...
    last_heartbeat TIMESTAMP,
    registered_at TIMESTAMP,
    health_status TEXT,
    metrics JSON
);

CREATE TABLE state_transitions (
    id INTEGER PRIMARY KEY,
    node_id TEXT,
    from_state TEXT,
    to_state TEXT,
    timestamp TIMESTAMP,
    reason TEXT
);

CREATE TABLE peers (
    id INTEGER PRIMARY KEY,
    registry_node_id TEXT,
    peer_node_id TEXT,
    discovered_at TIMESTAMP
);

-- Indexes for fast queries
CREATE INDEX idx_nodes_state ON nodes(state);
CREATE INDEX idx_nodes_last_hb ON nodes(last_heartbeat);
CREATE INDEX idx_transitions_timestamp ON state_transitions(timestamp);
```

**Data flow**:
```
Node-1 heartbeat → Registry writes to SQLite (ACID)
                 → Replication daemon reads db
                 → Replicates to Registry-2, Registry-3
Result: Persistent, replicated, consistent
```

---

### Code Strategy: Same Interface, Different Implementation

```go
// Interface (same for both modes)
type Registry interface {
    AddNode(node *Node) error
    UpdateNode(node *Node) error
    GetNode(id string) (*Node, error)
    GetNodes(filter func(*Node) bool) ([]*Node, error)
    RemoveNode(id string) error
}

// Development: MemoryRegistry
type MemoryRegistry struct {
    mu    sync.RWMutex
    nodes map[string]*Node
}
func (r *MemoryRegistry) AddNode(n *Node) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    r.nodes[n.ID] = n
    return nil
}

// Production: SqliteRegistry
type SqliteRegistry struct {
    db *sql.DB
}
func (r *SqliteRegistry) AddNode(n *Node) error {
    _, err := r.db.Exec(
        "INSERT INTO nodes VALUES (?, ?, ?, ?, ?)",
        n.ID, n.IPv6, n.State, n.LastHeartbeat, time.Now(),
    )
    return err
}

// Usage: Same everywhere
func (srv *Server) RegisterNode(n *Node) error {
    return srv.registry.AddNode(n)  // Works both modes!
}
```

**Same code path!** Just different implementation.

---

### Storage Summary

```yaml
Development Mode:
  Registry: In-Memory
  Data: Transient (lost on restart)
  Speed: Ultra-fast (< 1ms)
  Persistence: None needed
  
  Structure:
    nodes map[string]*Node
    peers map[string]*Peer
    
  Good for: Testing, iteration, dev cluster

Production Mode:
  Registry: SQLite (embedded database)
  Data: Persistent (survives crashes)
  Speed: Fast (10-100ms per transaction)
  Persistence: Automatic, replicated
  
  Structure:
    nodes table (with indexes)
    state_transitions table (audit trail)
    peers table (mesh topology)
    metrics table (historical data)
    
  Good for: Enterprise, monitoring, audit trail
```

---

## 3. Monitoring System: Custom vs Off-the-Shelf

### Your Insight (Perfect)

> "Let's use custom monitoring to reduce costs and have more control"

**Absolutely right!** Here's why:

---

### Option 1: Off-the-Shelf (Prometheus + Grafana)

**Pros**:
- ✅ Industry standard
- ✅ Pre-built dashboards
- ✅ Rich querying

**Cons**:
- ❌ Requires Prometheus server (separate deployment)
- ❌ Requires Grafana server (separate deployment)
- ❌ More infrastructure to manage
- ❌ Costs money (managed versions)
- ❌ Not self-contained

---

### Option 2: Custom Monitoring ⭐ RECOMMENDED

**Build your own, it's simple!**

#### Metrics Collection (Built-in)

```go
// Metrics struct (embedded in registry)
type Metrics struct {
    NodesOnline      int64
    NodesOffline     int64
    NodesInactive    int64
    NodesDead        int64
    
    HeartbeatsTotal  int64
    HeartbeatErrors  int64
    
    StateChanges     int64
    NodesRemoved     int64
    
    AvgHeartbeatLatency float64
    MaxHeartbeatLatency int
    
    LastCleanup      time.Time
    NodesRemovedLastHour int64
}

// Update metrics every second (built-in goroutine)
func (r *Registry) UpdateMetrics() {
    ticker := time.NewTicker(1 * time.Second)
    for range ticker.C {
        r.metrics.NodesOnline = int64(len(r.getOnlineNodes()))
        r.metrics.NodesOffline = int64(len(r.getOfflineNodes()))
        // ... more updates
    }
}
```

#### HTTP Endpoint: `/metrics`

```go
// REST API endpoint (same as Prometheus format)
func (r *Registry) HandleMetrics(w http.ResponseWriter, req *http.Request) {
    w.Header().Set("Content-Type", "text/plain")
    
    m := r.metrics
    fmt.Fprintf(w, "# HELP trustnet_nodes_online Number of online nodes\n")
    fmt.Fprintf(w, "# TYPE trustnet_nodes_online gauge\n")
    fmt.Fprintf(w, "trustnet_nodes_online %d\n", m.NodesOnline)
    
    fmt.Fprintf(w, "# HELP trustnet_nodes_offline Number of offline nodes\n")
    fmt.Fprintf(w, "# TYPE trustnet_nodes_offline gauge\n")
    fmt.Fprintf(w, "trustnet_nodes_offline %d\n", m.NodesOffline)
    
    fmt.Fprintf(w, "# HELP trustnet_heartbeats_total Total heartbeats received\n")
    fmt.Fprintf(w, "# TYPE trustnet_heartbeats_total counter\n")
    fmt.Fprintf(w, "trustnet_heartbeats_total %d\n", m.HeartbeatsTotal)
    
    // ... more metrics
}
```

**Usage**:
```bash
curl http://registry:8053/metrics

# Output:
trustnet_nodes_online 12
trustnet_nodes_offline 2
trustnet_nodes_inactive 0
trustnet_nodes_dead 0
trustnet_heartbeats_total 3600
trustnet_heartbeat_errors 2
trustnet_state_changes_total 45
trustnet_nodes_removed_total 3
trustnet_avg_heartbeat_latency_ms 12.5
```

#### Custom Dashboard (Simple)

```go
// HTML dashboard (served from registry)
func (r *Registry) HandleDashboard(w http.ResponseWriter, req *http.Request) {
    w.Header().Set("Content-Type", "text/html")
    
    html := fmt.Sprintf(`
        <!DOCTYPE html>
        <html>
        <head><title>TrustNet Dashboard</title></head>
        <body>
            <h1>TrustNet Registry</h1>
            
            <h2>Node Status</h2>
            <p>Online: <strong>%d</strong></p>
            <p>Offline: <strong>%d</strong></p>
            <p>Inactive: <strong>%d</strong></p>
            <p>Dead: <strong>%d</strong></p>
            
            <h2>Heartbeat</h2>
            <p>Total: <strong>%d</strong></p>
            <p>Errors: <strong>%d</strong></p>
            <p>Avg Latency: <strong>%.1f ms</strong></p>
            
            <h2>Cleanup</h2>
            <p>Nodes Removed (Last Hour): <strong>%d</strong></p>
            <p>Last Cleanup: <strong>%s</strong></p>
            
            <h2>Node List</h2>
            <table border="1">
                <tr><th>Node</th><th>State</th><th>Peers</th><th>Last Heartbeat</th></tr>
        `,
        r.metrics.NodesOnline,
        r.metrics.NodesOffline,
        r.metrics.NodesInactive,
        r.metrics.NodesDead,
        r.metrics.HeartbeatsTotal,
        r.metrics.HeartbeatErrors,
        r.metrics.AvgHeartbeatLatency,
        r.metrics.NodesRemovedLastHour,
        r.metrics.LastCleanup.Format("2006-01-02 15:04:05"),
    )
    
    for _, node := range r.getAllNodes() {
        html += fmt.Sprintf(
            "<tr><td>%s</td><td>%s</td><td>%d</td><td>%s</td></tr>\n",
            node.ID,
            node.State,
            len(node.Peers),
            time.Since(node.LastHeartbeat),
        )
    }
    
    html += `
            </table>
        </body>
        </html>
    `
    
    w.Write([]byte(html))
}
```

**Access**: `http://registry:8053/dashboard`

---

### Monitoring Metrics to Track

```go
// Development Mode (gossip-based)
✅ Nodes online/offline/inactive/dead (from peer list)
✅ Gossip messages sent/received
✅ State convergence time
✅ Peer discovery latency

// Production Mode (heartbeat-based)
✅ Heartbeats received/failed (per node)
✅ Heartbeat latency distribution
✅ State transitions per hour
✅ Nodes removed per hour
✅ Cleanup daemon runs
✅ Registry replication lag
```

---

### Why Custom Monitoring is Better

1. **Self-contained**
   - No external services
   - No dependencies
   - Works even if Internet down

2. **Cost-free**
   - No Prometheus server
   - No Grafana license
   - Just HTTP endpoints

3. **Control**
   - Metrics you care about
   - Custom dashboard
   - Alert logic in your code

4. **Simple**
   - 100 lines of code
   - Built into registry
   - No separate infrastructure

---

## 4. Alerting System: Email → Messaging

### Your Insight (Perfect)

> "Start with email, later add Telegram/WhatsApp"

**Exactly right architecture!** Let me design the alerting system:

---

### Alert Types

```go
type AlertLevel string

const (
    INFO     AlertLevel = "INFO"     // Informational
    WARNING  AlertLevel = "WARNING"  // Attention needed
    CRITICAL AlertLevel = "CRITICAL" // Immediate action
)

type Alert struct {
    Level     AlertLevel
    Title     string
    Message   string
    Timestamp time.Time
    NodeID    string
}

// Examples:
// INFO: "Node-5 registered successfully"
// WARNING: "20% of nodes offline (5 min duration)"
// CRITICAL: "50% of nodes offline - possible network issue"
```

---

### Phase 1: Email Alerts

**Implementation** (simple):

```go
import "net/smtp"

type EmailAlerter struct {
    smtpHost   string
    smtpPort   int
    from       string
    password   string
    recipients []string
}

func (a *EmailAlerter) Send(alert Alert) error {
    auth := smtp.PlainAuth("", a.from, a.password, a.smtpHost)
    
    subject := fmt.Sprintf("[%s] %s", alert.Level, alert.Title)
    body := fmt.Sprintf(
        "Time: %s\nNode: %s\n\n%s",
        alert.Timestamp.Format("2006-01-02 15:04:05"),
        alert.NodeID,
        alert.Message,
    )
    
    message := fmt.Sprintf("Subject: %s\n\n%s", subject, body)
    
    return smtp.SendMail(
        fmt.Sprintf("%s:%d", a.smtpHost, a.smtpPort),
        auth,
        a.from,
        a.recipients,
        []byte(message),
    )
}
```

**Configuration**:
```yaml
alerting:
  enabled: true
  method: "email"
  
  email:
    smtp_host: "smtp.gmail.com"
    smtp_port: 587
    from: "trustnet-alerts@example.com"
    password: "${TRUSTNET_EMAIL_PASSWORD}"
    recipients:
      - "admin@example.com"
      - "devops@example.com"
```

**Usage**:
```go
alerter := NewEmailAlerter(config.Alerting.Email)

// When critical event happens:
alerter.Send(Alert{
    Level: CRITICAL,
    Title: "Majority nodes offline",
    Message: "50% of nodes offline for 5 minutes",
    NodeID: "",
})
```

---

### Phase 2: Telegram Bot Alerts

**Why Telegram?**
- ✅ Free (no SMS costs)
- ✅ Instant notifications
- ✅ Web API (no special libraries)
- ✅ Groups and channels
- ✅ Rich formatting

**Implementation**:

```go
type TelegramAlerter struct {
    botToken string
    chatID   string
    client   *http.Client
}

func (a *TelegramAlerter) Send(alert Alert) error {
    message := fmt.Sprintf(
        "🚨 *[%s]* %s\n\n%s\n\nNode: %s\nTime: %s",
        alert.Level,
        alert.Title,
        alert.Message,
        alert.NodeID,
        alert.Timestamp.Format("2006-01-02 15:04:05"),
    )
    
    // Telegram Bot API
    url := fmt.Sprintf(
        "https://api.telegram.org/bot%s/sendMessage",
        a.botToken,
    )
    
    data := url.Values{}
    data.Set("chat_id", a.chatID)
    data.Set("text", message)
    data.Set("parse_mode", "Markdown")
    
    resp, err := a.client.PostForm(url, data)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    return nil
}
```

**Setup**:
1. Create Telegram bot (talk to @BotFather)
2. Get bot token
3. Create channel or group
4. Add bot to channel
5. Get chat ID

**Configuration**:
```yaml
alerting:
  enabled: true
  method: "telegram"
  
  telegram:
    bot_token: "${TELEGRAM_BOT_TOKEN}"
    chat_id: "${TELEGRAM_CHAT_ID}"
```

---

### Phase 3: Multiple Channels (Flexible)

**Alert Router** (supports any method):

```go
type AlertRouter struct {
    alerters map[AlertLevel][]Alerter
}

// Alerter interface (swap implementations)
type Alerter interface {
    Send(alert Alert) error
}

func (r *AlertRouter) SendAlert(alert Alert) error {
    alerters := r.alerters[alert.Level]
    
    for _, alerter := range alerters {
        go alerter.Send(alert)  // Fire and forget
    }
    
    return nil
}

// Usage:
router := NewAlertRouter()
router.Register(INFO, emailAlerter)        // Email for info
router.Register(WARNING, telegramAlerter)  // Telegram for warnings
router.Register(CRITICAL, slackAlerter)    // Slack for critical
router.Register(CRITICAL, emailAlerter)    // AND email for critical

// Send once, reaches all:
router.SendAlert(Alert{
    Level: CRITICAL,
    Title: "Network issue",
})
// → Sends to Slack, Email (both get it immediately)
```

---

### Alert Rules (Built-in)

```go
type AlertRule struct {
    Name        string
    Condition   func(*Registry) bool
    Alert       Alert
    CheckInterval time.Duration
}

// Example rules:
rules := []AlertRule{
    {
        Name: "many_nodes_offline",
        Condition: func(r *Registry) bool {
            total := r.metrics.NodesOnline + r.metrics.NodesOffline
            offline := r.metrics.NodesOffline
            return offline > 0 && (float64(offline)/float64(total)) > 0.1  // > 10%
        },
        Alert: Alert{
            Level: WARNING,
            Title: "High number of offline nodes",
        },
        CheckInterval: 1 * time.Minute,
    },
    {
        Name: "majority_offline",
        Condition: func(r *Registry) bool {
            total := r.metrics.NodesOnline + r.metrics.NodesOffline
            offline := r.metrics.NodesOffline
            return offline > 0 && (float64(offline)/float64(total)) > 0.5  // > 50%
        },
        Alert: Alert{
            Level: CRITICAL,
            Title: "Critical: Majority nodes offline",
        },
        CheckInterval: 10 * time.Second,
    },
}

// Alert daemon
func (r *Registry) AlertDaemon(rules []AlertRule) {
    for _, rule := range rules {
        go func(r *AlertRule) {
            ticker := time.NewTicker(r.CheckInterval)
            lastAlerted := time.Time{}
            
            for range ticker.C {
                if r.Condition(r) {
                    // Avoid spam: only alert once per 5 minutes
                    if time.Since(lastAlerted) > 5*time.Minute {
                        router.SendAlert(r.Alert)
                        lastAlerted = time.Now()
                    }
                }
            }
        }(rule)
    }
}
```

---

## Technology Stack Summary

### Recommended Stack

```
Language:        Go
                 ├─ Single executable
                 ├─ Cross-platform
                 └─ Production-ready

Storage:
  Development:   In-Memory (fast, transient)
  Production:    SQLite (persistent, replicated)
                 ├─ Self-contained
                 ├─ No server needed
                 └─ Easy to backup

Monitoring:      Custom HTTP endpoint
                 ├─ /metrics (Prometheus format)
                 ├─ /dashboard (HTML)
                 └─ Built into registry

Alerting:
  Phase 1:       Email (simple, immediate)
  Phase 2:       Telegram (free, instant)
  Phase 3:       Multiple channels (flexible)
                 └─ Alert router for scalability
```

---

## Code Organization Summary

```
trustnet/
├── cmd/
│   └── trustnet/main.go              (Entry point, config loading)
│
├── internal/
│   ├── registry/
│   │   ├── registry.go               (Interface, shared logic)
│   │   ├── memory.go                 (Dev: In-memory impl)
│   │   ├── sqlite.go                 (Prod: SQLite impl)
│   │   ├── heartbeat.go
│   │   ├── gossip.go
│   │   ├── cleanup.go
│   │   └── metrics.go
│   │
│   ├── alerting/
│   │   ├── alert.go                  (Alert types)
│   │   ├── router.go                 (Router, rules)
│   │   ├── email.go                  (Email alerter)
│   │   ├── telegram.go               (Telegram alerter)
│   │   └── slack.go                  (Slack alerter - future)
│   │
│   ├── monitoring/
│   │   ├── metrics.go                (Metrics struct)
│   │   ├── dashboard.go              (HTML dashboard)
│   │   └── endpoint.go               (/metrics endpoint)
│   │
│   └── discovery/
│       ├── multicast.go
│       ├── dns.go
│       └── static_peer.go
│
└── config/
    ├── development.yaml              (Dev defaults: memory, gossip)
    ├── production.yaml               (Prod defaults: sqlite, heartbeat)
    └── config.go                     (Load config file)
```

---

## Development Workflow

```bash
# 1. Develop with defaults (development.yaml)
go run ./cmd/trustnet/main.go

# Registry uses: In-memory, gossip, simple alerting
# Perfect for testing

# 2. Test production mode
go run ./cmd/trustnet/main.go --config production.yaml

# Registry uses: SQLite, heartbeat, email alerts
# Same code, different behavior

# 3. Deploy to production
docker build -t trustnet:latest .
kubectl apply -f trustnet-production.yaml

# Same code, just runs differently
```

---

## Cost Analysis

### Off-the-shelf Stack
- Prometheus: $20-100/month
- Grafana Cloud: $150-300/month
- PagerDuty: $50-100/month
- SMS Alerts: $$$
- **Total: $500+ per month**

### Your Stack
- Email: Free (Gmail, your domain)
- Telegram: Free
- Custom monitoring: $0 (built-in)
- Custom alerting: $0 (built-in)
- **Total: $0 per month**

**Savings: $6,000+/year!**

---

## VM Infrastructure & Disk Architecture

### Alpine VM (FactoryVM Pattern)

**Decision**: Run TrustNet nodes inside Alpine Linux VMs (QEMU-based)

**Rationale**:
- ✅ **Isolation**: VM provides complete isolation from host
- ✅ **Reproducibility**: Alpine ensures consistent environment
- ✅ **Lightweight**: Alpine minimal footprint (~130MB ISO)
- ✅ **Security**: VM isolation + Alpine hardened packages
- ✅ **Proven pattern**: Reuses FactoryVM infrastructure (battle-tested)

**Implementation**:
- QEMU virtualization (ARM64/x86_64)
- Alpine Linux (latest version, auto-detected)
- Passwordless SSH access (warden user)
- Caddy reverse proxy (HTTPS with Let's Encrypt)
- One-liner installer (curl | bash)

### 3-Disk Architecture with Preservation

**Decision**: Separate system, cache, and data into independent disks with smart preservation logic

**Rationale**:
- **System disk** (20GB): OS and software - **RECREATED** on each install
  - Ensures clean state (no cruft from previous installs)
  - Gets latest Alpine, Go, Cosmos SDK versions
  - Quick to rebuild (disposable)
  
- **Cache disk** (5GB): Downloaded packages - **PRESERVED** across reinstalls
  - Go tarball (~200MB)
  - Alpine ISO (~200MB)
  - Dependencies (git, make, gcc, etc.)
  - **Benefit**: 5-10 minutes saved on reinstalls
  - **Benefit**: Enables offline installs (no internet required)
  
- **Data disk** (30GB): Blockchain data, keys, configs - **PRESERVED** across reinstalls
  - Identity keypairs (Ed25519)
  - Blockchain state (blocks, transactions)
  - TRUST token wallet
  - Reputation history
  - **Benefit**: Same identity across reinstalls
  - **Benefit**: Transaction history preserved
  - **Benefit**: Testing continuity (same user, same state)

**Preservation Logic**:
```bash
# vm-lifecycle.sh checks disk existence:

if [ ! -f "$SYSTEM_DISK" ]; then
    create_disk  # Always create fresh
fi

if [ ! -f "$CACHE_DISK" ]; then
    check_backup || create_disk  # Restore or create
else
    log "✓ Preserving cache"  # Reuse existing
fi

if [ ! -f "$DATA_DISK" ]; then
    create_disk  # Create fresh
else
    log "✓ Preserving blockchain data"  # Reuse existing
fi
```

**Testing Workflow**:
1. First install: Create all 3 disks, download everything
2. Development: Make changes, test features
3. Reinstall: `rm ~/vms/trustnet/trustnet.qcow2 && curl ... | bash`
   - System disk: Recreated (fresh Alpine, latest Go)
   - Cache disk: Reused (no downloads, instant)
   - Data disk: Reused (same blockchain state)
4. Continue where you left off (same identity, keys, TRUST balance)

**Production Benefits**:
- ✅ **Backup strategy**: Only data disk critical (30GB vs 55GB total)
- ✅ **Disaster recovery**: System + cache recreatable, data is source of truth
- ✅ **Easy migration**: Copy data disk, reinstall on new host
- ✅ **Faster iteration**: Clean OS without losing blockchain state

**Cost Impact**: $0 (no cloud storage needed, local disks only)

---

## Conclusion

**Technology choices that work together:**

1. **Go** - Fast, reliable, production-ready language
2. **In-Memory (dev) + SQLite (prod)** - Self-contained, no external services
3. **Custom monitoring** - Built-in, cheap, effective
4. **Email → Telegram** - Upgrade path, minimal costs

All designed for your unified hybrid architecture:
- **Same code** runs in dev and prod
- **Same tests** verify both modes
- **Same reliability** from day one

Ready to implement! 🎯


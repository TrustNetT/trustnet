# TrustNet Module Distribution Strategy

**Version**: 1.0  
**Date**: February 2, 2026  
**Status**: Design Document

---

## Core Concept

**Use the existing P2P network for decentralized module distribution.**

Instead of a central module repository, modules propagate through the TrustNet P2P network like any other data:

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Node A     │ ──────→ │   Node B     │ ──────→ │   Node C     │
│  (Warden 1)  │  sync   │  (Warden 2)  │  sync   │  (Warden 3)  │
│              │ module  │              │ module  │              │
│  Module X v1 │         │  Module X v1 │         │  Module X v1 │
└──────────────┘         └──────────────┘         └──────────────┘
       ↓                        ↓                        ↓
  Upload module              Receives it             Receives it
  to any node              automatically          automatically
```

**Key Insight**: Nodes are already talking to each other for:
- Blockchain consensus
- Transaction validation
- Registry synchronization

**So they can also share**:
- Module packages
- Module metadata
- Module versions
- Module trust ratings

---

## Module Control Panel

### Web-Based Control Panel

Every node has a control panel accessible at:

```
https://trustnet.local/modules
```

**Features**:

1. **Available Modules** - See all modules on the network
2. **Installed Modules** - Manage your active modules
3. **Module Details** - View description, version, trust score
4. **Activate/Deactivate** - Toggle modules on/off
5. **Update Modules** - One-click updates when available
6. **Upload Module** - Share new module with network

### Control Panel UI (Mockup)

```
┌────────────────────────────────────────────────────────────┐
│  TrustNet Module Manager                                   │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Available Modules (from network):                         │
│                                                            │
│  ┌──────────────────────────────────────────────────┐     │
│  │ 📦 Identity Registration                  v1.2.3 │     │
│  │ Manage user identities and DIDs                  │     │
│  │ Trust Score: ⭐⭐⭐⭐⭐ (127 nodes)                │     │
│  │ Status: ✅ Installed & Active                    │     │
│  │ [Deactivate] [Update] [Details]                  │     │
│  └──────────────────────────────────────────────────┘     │
│                                                            │
│  ┌──────────────────────────────────────────────────┐     │
│  │ 📦 Transaction Viewer                    v2.0.1  │     │
│  │ Browse and search transaction history            │     │
│  │ Trust Score: ⭐⭐⭐⭐ (89 nodes)                  │     │
│  │ Status: ⭕ Available (not installed)              │     │
│  │ [Install] [Details]                              │     │
│  └──────────────────────────────────────────────────┘     │
│                                                            │
│  ┌──────────────────────────────────────────────────┐     │
│  │ 📦 Key Management                        v1.0.5  │     │
│  │ Generate and manage cryptographic keys           │     │
│  │ Trust Score: ⭐⭐⭐⭐⭐ (203 nodes)                │     │
│  │ Status: ✅ Installed (inactive)                  │     │
│  │ [Activate] [Update] [Details]                    │     │
│  └──────────────────────────────────────────────────┘     │
│                                                            │
│  [Upload New Module] [Refresh] [Settings]                 │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## P2P Module Distribution Protocol

### How Modules Propagate

**Step 1: Developer Uploads Module**

```bash
# Developer builds module
cd ~/GitProjects/TrustNet/trustnet-wip/modules/new-feature/
./build.sh

# Upload to their node
ssh trustnet
cd /tmp/
# Upload via web UI or CLI
doas module-upload new-feature-v1.0.0.tar.gz
```

**Step 2: Node Validates and Signs Module**

```bash
# Node validates module
- Checks structure (module.json, files)
- Scans for malicious code
- Runs security checks
- Signs with node's key

# Creates module package
{
  "name": "new-feature",
  "version": "1.0.0",
  "hash": "sha256:abc123...",
  "signature": "node-key-signature...",
  "timestamp": "2026-02-02T10:30:00Z",
  "uploaded_by": "did:trust:developer123",
  "trust_score": 1  // Initial score from uploader
}
```

**Step 3: Module Announced to Network**

```bash
# Node broadcasts to peers
→ "New module available: new-feature v1.0.0"
→ Peers receive announcement
→ Peers can request module package
```

**Step 4: Peers Download and Validate**

```bash
# Peer node receives announcement
→ Checks if module already exists
→ If not, downloads module package
→ Validates signature
→ Checks hash
→ Stores in local module cache

# Peer broadcasts to its peers
→ "New module available: new-feature v1.0.0"
→ Network-wide propagation
```

**Step 5: Users See Module in Control Panel**

```bash
# User opens control panel
https://trustnet.local/modules

# New module appears:
📦 New Feature v1.0.0
Status: ⭕ Available (not installed)
Trust Score: ⭐ (1 node)
[Install] [Details]
```

**Step 6: Users Install and Trust Score Grows**

```bash
# Users install module
[Install] → Module activated

# Trust score increases
Trust Score: ⭐⭐ (5 nodes)
Trust Score: ⭐⭐⭐ (20 nodes)
Trust Score: ⭐⭐⭐⭐ (50 nodes)
Trust Score: ⭐⭐⭐⭐⭐ (100+ nodes)
```

---

## Module Package Format

### module.json

Every module has a manifest file:

```json
{
  "name": "identity",
  "version": "1.2.3",
  "description": "Identity registration and management",
  "author": "did:trust:developer123",
  "license": "MIT",
  "type": "frontend",  // or "backend", "full-stack"
  
  "dependencies": {
    "trustnet-core": ">=1.0.0",
    "blockchain-api": ">=2.0.0"
  },
  
  "files": {
    "frontend": ["index.html", "app.js", "style.css"],
    "backend": ["identity-service"],
    "config": ["identity.toml"]
  },
  
  "endpoints": [
    "GET /api/identity/:did",
    "POST /api/identity/register",
    "PUT /api/identity/:did"
  ],
  
  "permissions": [
    "read-identities",
    "write-identities",
    "access-blockchain"
  ],
  
  "checksum": "sha256:abc123...",
  "signature": "signature-by-author..."
}
```

### Module Package Structure

```
new-feature-v1.0.0.tar.gz
├── module.json              # Manifest
├── frontend/
│   ├── index.html          # UI
│   ├── app.js              # Frontend logic
│   └── style.css           # Styles
├── backend/
│   ├── service             # Compiled binary (Go/Rust)
│   └── config.toml         # Default config
├── docs/
│   ├── README.md           # User guide
│   └── API.md              # API documentation
└── signatures/
    ├── author.sig          # Author's signature
    └── trust.json          # Trust ratings
```

---

## Security & Trust Model

### Module Signing

**Every module must be signed**:

1. **Author Signature**: Developer signs with their DID key
2. **Node Signature**: Uploading node verifies and signs
3. **Network Validation**: Other nodes validate signatures

**Chain of Trust**:
```
Developer → Signs module
     ↓
Node A → Validates + signs
     ↓
Node B → Validates + signs
     ↓
Node C → Validates + signs
     ↓
Trust Score increases
```

### Trust Score Algorithm

```python
def calculate_trust_score(module):
    score = 0
    
    # Factor 1: Number of nodes running it
    nodes_running = count_nodes_with_module(module)
    score += min(nodes_running / 10, 50)  # Max 50 points
    
    # Factor 2: Author reputation
    author_reputation = get_author_reputation(module.author)
    score += author_reputation / 2  # Max 50 points
    
    # Factor 3: Age (older = more trusted)
    days_old = (now() - module.timestamp).days
    score += min(days_old / 10, 20)  # Max 20 points
    
    # Factor 4: No security reports
    if module.security_reports == 0:
        score += 10
    
    # Factor 5: Code review passed
    if module.code_review_passed:
        score += 20
    
    # Total: 0-150, normalized to 1-5 stars
    stars = int(score / 30) + 1
    return min(stars, 5)
```

### Security Scanning

**Before accepting a module, nodes run**:

1. **Static Analysis**:
   ```bash
   # Check for suspicious patterns
   - Network calls to unknown hosts
   - File system access outside module directory
   - Execution of shell commands
   - Cryptocurrency mining code
   ```

2. **Sandboxing** (optional):
   ```bash
   # Run module in isolated container
   - Limited CPU/memory
   - No network access initially
   - Monitored file system access
   - If safe, allow network
   ```

3. **Community Review**:
   ```bash
   # After X nodes validate
   - Module marked "Community Verified"
   - Trust score boosted
   - Recommended for installation
   ```

### Module Permissions

**Modules declare required permissions**:

```toml
[permissions]
read_blockchain = true       # Read blockchain data
write_blockchain = false     # Cannot write to blockchain
read_identities = true       # Read identity registry
write_identities = true      # Create/update identities
network_access = true        # Make external API calls
file_system_access = false   # Cannot access host filesystem
execute_commands = false     # Cannot run shell commands
```

**Users approve permissions before install**:

```
┌────────────────────────────────────────┐
│  Install Identity Module v1.2.3?       │
├────────────────────────────────────────┤
│  This module requests:                 │
│                                        │
│  ✅ Read blockchain data               │
│  ✅ Read identity registry             │
│  ✅ Create/update identities           │
│  ✅ Make network calls                 │
│  ❌ Access filesystem                  │
│  ❌ Execute commands                   │
│                                        │
│  [Approve] [Deny] [Details]            │
└────────────────────────────────────────┘
```

---

## Module Lifecycle

### 1. Development

```bash
# Developer creates module
cd ~/GitProjects/TrustNet/trustnet-wip/modules/new-feature/

# Build module
./build.sh
# → Creates new-feature-v1.0.0.tar.gz

# Sign module
./sign-module.sh new-feature-v1.0.0.tar.gz
# → Uses developer's DID key
```

### 2. Upload to Network

```bash
# Via web UI
https://trustnet.local/modules
[Upload New Module] → Select file → Upload

# Or via CLI
ssh trustnet
doas module-upload /path/to/new-feature-v1.0.0.tar.gz

# Node validates and propagates
→ Checks signature
→ Scans for security issues
→ Announces to peers
→ Stores in local cache
```

### 3. Network Propagation

```bash
# Automatic P2P distribution
Node A → Announces to peers
Node B → Downloads from Node A
Node C → Downloads from Node B
...
# Within minutes, all nodes have module

# Control panel shows:
📦 New Feature v1.0.0
Status: ⭕ Available (not installed)
Trust Score: ⭐ (growing...)
```

### 4. User Installation

```bash
# User clicks [Install]
→ Downloads module (if not cached)
→ Validates signatures
→ Checks permissions
→ User approves
→ Module extracted to /var/www/html/modules/
→ Service started
→ Routes registered in Caddy
→ Module active
```

### 5. Module Updates

```bash
# Developer releases v1.0.1
→ Uploads to network
→ Network propagates update

# Control panel shows:
📦 New Feature v1.0.0 → v1.0.1 available
[Update] button appears

# User clicks [Update]
→ Downloads v1.0.1
→ Stops v1.0.0
→ Installs v1.0.1
→ Migrates data (if needed)
→ Starts v1.0.1
→ Update complete
```

### 6. Module Deprecation

```bash
# Developer marks module deprecated
→ Upload deprecation notice
→ Network propagates

# Control panel shows:
📦 Old Feature v1.0.0
⚠️ Deprecated - Use New Feature instead
[Migrate] [Uninstall]
```

---

## Implementation Plan

### Phase 1: Module Package Format (Week 1)

**Tasks**:
- Define `module.json` schema
- Create module packaging tool
- Implement signature generation
- Test package creation

**Deliverables**:
```bash
tools/create-module.sh       # Package module
tools/sign-module.sh         # Sign with DID key
tools/validate-module.sh     # Verify signatures
```

### Phase 2: Control Panel UI (Week 2)

**Tasks**:
- Design web UI for module management
- List available modules
- Show module details (version, trust score)
- Install/activate/deactivate buttons

**Deliverables**:
```bash
frontend/modules/
├── module-list.html        # List all modules
├── module-detail.html      # Show module info
├── module-install.html     # Install workflow
└── module-manager.js       # Frontend logic
```

### Phase 3: P2P Module Distribution (Week 3)

**Tasks**:
- Extend P2P protocol for module sync
- Implement module announcement
- Implement module request/response
- Cache downloaded modules

**Deliverables**:
```bash
api/services/module-sync/
├── announce.go             # Broadcast module
├── request.go              # Request from peer
├── validate.go             # Verify module
└── store.go                # Cache locally
```

### Phase 4: Security & Trust (Week 4)

**Tasks**:
- Implement trust score algorithm
- Add security scanning
- Implement permission system
- User approval workflow

**Deliverables**:
```bash
api/services/security/
├── scanner.go              # Static analysis
├── trust-score.go          # Calculate trust
├── permissions.go          # Permission checks
└── sandbox.go              # Isolated execution
```

### Phase 5: Module Lifecycle Management (Week 5)

**Tasks**:
- Install/uninstall workflow
- Update mechanism
- Data migration
- Rollback on failure

**Deliverables**:
```bash
api/services/modules/
├── install.go              # Install module
├── update.go               # Update module
├── uninstall.go            # Remove module
└── migrate.go              # Data migration
```

---

## Technical Architecture

### Module Storage

**On each node**:

```
/opt/trustnet/modules/
├── cache/                  # Downloaded modules
│   ├── identity-v1.2.3.tar.gz
│   ├── transactions-v2.0.1.tar.gz
│   └── keys-v1.0.5.tar.gz
├── installed/              # Active modules
│   ├── identity/
│   ├── transactions/
│   └── keys/
├── metadata/               # Module metadata
│   ├── identity.json
│   ├── transactions.json
│   └── keys.json
└── trust/                  # Trust ratings
    ├── identity-trust.json
    └── ...
```

### P2P Protocol Extension

**New message types**:

```protobuf
// Module announcement
message ModuleAnnouncement {
  string name = 1;
  string version = 2;
  string hash = 3;
  bytes signature = 4;
  int64 timestamp = 5;
}

// Module request
message ModuleRequest {
  string name = 1;
  string version = 2;
}

// Module response
message ModuleResponse {
  string name = 1;
  string version = 2;
  bytes package = 3;  // tar.gz data
  bytes signature = 4;
}

// Module trust update
message ModuleTrustUpdate {
  string name = 1;
  string version = 2;
  int32 nodes_running = 3;
  float trust_score = 4;
}
```

### API Endpoints

```bash
# Module Management
GET    /api/modules                    # List all available
GET    /api/module/:name               # Get module details
GET    /api/module/:name/:version      # Get specific version
POST   /api/module/upload              # Upload new module
POST   /api/module/:name/install       # Install module
DELETE /api/module/:name/uninstall     # Remove module
PUT    /api/module/:name/activate      # Enable module
PUT    /api/module/:name/deactivate    # Disable module
GET    /api/module/:name/trust         # Get trust score

# Module Discovery
GET    /api/modules/search?q=identity  # Search modules
GET    /api/modules/popular            # Most installed
GET    /api/modules/trusted            # Highest trust
GET    /api/modules/recent             # Recently added
```

### Database Schema

```sql
-- Module registry
CREATE TABLE modules (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  version VARCHAR(50) NOT NULL,
  description TEXT,
  author VARCHAR(255),  -- DID
  upload_timestamp TIMESTAMP,
  hash VARCHAR(64),
  signature TEXT,
  trust_score FLOAT DEFAULT 0,
  nodes_running INT DEFAULT 0,
  UNIQUE(name, version)
);

-- Module installations
CREATE TABLE module_installations (
  id SERIAL PRIMARY KEY,
  module_id INT REFERENCES modules(id),
  installed_at TIMESTAMP,
  status VARCHAR(50),  -- active, inactive, failed
  permissions JSONB
);

-- Module trust ratings
CREATE TABLE module_trust (
  id SERIAL PRIMARY KEY,
  module_id INT REFERENCES modules(id),
  node_id VARCHAR(255),  -- DID of node
  rating INT,  -- 1-5
  timestamp TIMESTAMP
);
```

---

## Advantages of This Approach

### 1. True Decentralization
- ✅ No central module repository
- ✅ No single point of failure
- ✅ Censorship-resistant
- ✅ Community-driven

### 2. Efficient Distribution
- ✅ Uses existing P2P network
- ✅ Fast propagation (minutes)
- ✅ Reduces bandwidth (cached locally)
- ✅ Redundant storage (every node)

### 3. Security Through Trust
- ✅ Community validation
- ✅ Trust score based on adoption
- ✅ Signature verification
- ✅ Permission system

### 4. User Experience
- ✅ Simple web UI
- ✅ One-click install/update
- ✅ No manual file transfers
- ✅ Automatic updates (optional)

### 5. Developer Experience
- ✅ Upload once, available everywhere
- ✅ Automatic distribution
- ✅ Version management
- ✅ User feedback via trust scores

---

## Challenges & Solutions

### Challenge 1: Module Size

**Problem**: Large modules consume bandwidth

**Solutions**:
- Compress modules (tar.gz)
- Differential updates (only changed files)
- Lazy loading (download on demand)
- Bandwidth throttling (configurable)

### Challenge 2: Malicious Modules

**Problem**: Someone uploads malware

**Solutions**:
- Static code analysis
- Sandbox execution
- Permission system
- Community reporting
- Automatic quarantine if flagged

### Challenge 3: Version Conflicts

**Problem**: Module A v1 requires Core v1, Module B v2 requires Core v2

**Solutions**:
- Dependency checking before install
- Clear compatibility matrix
- Warning on conflicts
- Suggest compatible versions

### Challenge 4: Storage Limits

**Problem**: Nodes cache too many modules

**Solutions**:
- Configurable cache size
- LRU eviction (least recently used)
- Keep only installed + popular modules
- Prune old versions automatically

### Challenge 5: Trust Manipulation

**Problem**: Developer creates fake nodes to boost trust score

**Solutions**:
- Reputation of uploader node matters
- Age of node matters (new nodes = low weight)
- Require minimum uptime before vote counts
- Community review for high-trust modules

---

## Comparison: Centralized vs P2P Distribution

| Aspect | Centralized Repo | P2P Distribution (Our Approach) |
|--------|------------------|----------------------------------|
| **Single Point of Failure** | ❌ Yes (repo down = no modules) | ✅ No (any node can serve) |
| **Censorship** | ❌ Repo owner controls content | ✅ Community decides |
| **Speed** | ⚠️ Depends on repo bandwidth | ✅ Fast (local cache + peers) |
| **Trust** | ⚠️ Trust the repo maintainer | ✅ Community validation |
| **Cost** | ❌ Hosting costs | ✅ Free (shared by network) |
| **Availability** | ⚠️ 99.9% SLA if paying | ✅ 100% (distributed) |
| **Discovery** | ✅ Easy (browse repo) | ✅ Easy (control panel) |
| **Security** | ⚠️ Repo must scan | ✅ Every node scans |

**Winner**: P2P Distribution (aligns with TrustNet philosophy)

---

## Future Enhancements

### Module Marketplace

**Paid Modules** (future):
```bash
# Developer sets price
module.json:
"price": "10 TRUST tokens"

# User pays to install
[Install for 10 TRUST] → Payment → Module unlocked
```

### Automatic Updates

**Opt-in auto-updates**:
```bash
# User enables in settings
Auto-update modules: [✓] Enabled
Update schedule: Daily at 3am

# Node automatically:
- Checks for updates
- Downloads new versions
- Tests in staging
- Applies if tests pass
```

### Module Analytics

**Usage statistics** (privacy-preserving):
```bash
# Developers see aggregated stats
- Total installations: 523
- Active users: 498
- Average uptime: 99.2%
- Most-used endpoints: /api/identity/register
```

### Module Bundles

**Pre-packaged sets**:
```bash
# Install multiple modules
[Install Essential Bundle]
→ Identity + Transactions + Keys
→ All installed at once
```

---

## Conclusion

**This P2P module distribution strategy**:

✅ **Aligns with TrustNet's decentralized philosophy**  
✅ **Uses existing infrastructure** (P2P network already there)  
✅ **Provides excellent UX** (web control panel, one-click install)  
✅ **Ensures security** (signatures, trust scores, permissions)  
✅ **Scales well** (more nodes = better distribution)  

**Next Steps**:
1. Implement module package format
2. Build control panel UI
3. Extend P2P protocol for module sync
4. Add security scanning
5. Launch with first official modules

**Timeline**: 5 weeks to production-ready module distribution system

---

*Document created: February 2, 2026*  
*Status: Design Complete - Ready for Implementation*  
*Related*: [MODULAR_DEVELOPMENT_PLAN.md](MODULAR_DEVELOPMENT_PLAN.md), [OPERATIONS_MANUAL.md](OPERATIONS_MANUAL.md)

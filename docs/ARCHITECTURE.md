# TrustNet Architecture Document

**Version**: 1.0.0  
**Date**: February 2, 2026  
**Status**: All technology decisions finalized  

---

## Executive Summary

TrustNet is a **modular blockchain platform** built on Cosmos SDK with a focus on:
- **Security-first architecture** (one security issue = project death)
- **Rapid development** (5-second iteration vs 30-minute VM rebuilds)
- **Hot-swappable modules** (install/remove without downtime)
- **Lightweight deployment** (Alpine VM, ~5GB production, 10GB dev)
- **Cross-platform support** (Desktop, iOS, Android via PWA)
- **Developer-friendly** (modern tooling, simple patterns)

**Critical principle**: Security is not optional. TrustNet is about identity and trust—one breach destroys everything.

This document captures all architectural decisions, rationale, and implementation strategy.

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Technology Decisions](#technology-decisions)
3. [Module Architecture](#module-architecture)
4. [Development Workflow](#development-workflow)
5. [Deployment Strategy](#deployment-strategy)
6. [Security Model](#security-model)
7. [Implementation Roadmap](#implementation-roadmap)

---

## System Architecture

### High-Level Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    User Devices                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │ Desktop  │  │   iOS    │  │  Android │                  │
│  │ Browser  │  │  Safari  │  │  Chrome  │                  │
│  └─────┬────┘  └─────┬────┘  └─────┬────┘                  │
│        │             │              │                       │
│        └─────────────┴──────────────┘                       │
│                      │ HTTPS                                │
└──────────────────────┼──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              TrustNet VM (Alpine Linux)                     │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                Caddy Web Server                       │  │
│  │  - SSL termination (HTTPS)                            │  │
│  │  - Reverse proxy                                      │  │
│  │  - Static file serving                                │  │
│  └────┬─────────────────────────┬────────────────────────┘  │
│       │ Static Files            │ API Proxy                 │
│       ▼                         ▼                           │
│  ┌─────────────────┐  ┌──────────────────────────────┐     │
│  │   Frontend      │  │    API Gateway               │     │
│  │   Modules       │  │    (Python FastAPI)          │     │
│  │                 │  │                              │     │
│  │ ┌─────────────┐ │  │  ┌────────────────────────┐ │     │
│  │ │  Identity   │ │  │  │  Cosmos SDK Client     │ │     │
│  │ │  (Vite+JS)  │ │  │  │  - Transaction builder│ │     │
│  │ └─────────────┘ │  │  │  - RPC/REST calls      │ │     │
│  │                 │  │  │  - Query handler       │ │     │
│  │ ┌─────────────┐ │  │  └────────────────────────┘ │     │
│  │ │Transactions │ │  │                              │     │
│  │ │  (Vite+JS)  │ │  │  ┌────────────────────────┐ │     │
│  │ └─────────────┘ │  │  │  Module Routes         │ │     │
│  │                 │  │  │  - /api/identity       │ │     │
│  │ ┌─────────────┐ │  │  │  - /api/transactions  │ │     │
│  │ │    Keys     │ │  │  │  - /api/keys          │ │     │
│  │ │  (Vite+JS)  │ │  │  └────────────────────────┘ │     │
│  │ └─────────────┘ │  └──────────────┬───────────────┘     │
│  └─────────────────┘                 │ HTTP/gRPC            │
│                                      ▼                       │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           Cosmos SDK Blockchain Node (Go)            │  │
│  │                                                       │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────┐  │  │
│  │  │  Tendermint │  │  Cosmos SDK  │  │  Custom    │  │  │
│  │  │     BFT     │  │    Modules   │  │  TrustNet  │  │  │
│  │  │ Consensus   │  │              │  │  Modules   │  │  │
│  │  └─────────────┘  └──────────────┘  └────────────┘  │  │
│  │                                                       │  │
│  │  APIs:                                                │  │
│  │  - RPC: localhost:26657                              │  │
│  │  - REST: localhost:1317                              │  │
│  │  - gRPC: localhost:9090                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│               Development Environment (Host)                 │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  VSCode Editor                                        │  │
│  │  ~/GitProjects/TrustNet/trustnet-wip/                │  │
│  │  ├── modules/identity/                                │  │
│  │  ├── modules/transactions/                            │  │
│  │  └── api/                                             │  │
│  └──────────────────────────────────────────────────────┘  │
│                           │                                  │
│                           │ dev-sync.sh (rsync + inotify)   │
│                           │ 2-5 second sync                  │
│                           ▼                                  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  TrustNet VM (running locally)                        │  │
│  │  /var/www/html/modules/ ← synced files               │  │
│  │  /opt/trustnet/api/ ← synced API                     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Technology Decisions

All 7 critical technology decisions with rationale:

### 1. Development Method: Rsync + inotify ✅

**Decision**: Use rsync with inotify file watching for live synchronization.

**Why**:
- **Proven technology** - rsync has been reliable for 25+ years
- **Fast** - 2-5 second latency from save to VM update
- **Simple** - No complex build pipelines or tooling
- **Works with dev-disk** - Can sync to detachable dev disk
- **No core changes needed** - Doesn't modify VM infrastructure

**Alternatives considered**:
- ❌ QEMU 9P shared folders - Complex setup, potential issues
- ❌ NFS/SSHFS mounts - Network overhead, reliability issues
- ❌ Full rebuild - 30+ minutes per change (too slow)

**Implementation**: `tools/dev-sync.sh` script with inotifywait

---

### 2. Frontend Technology: Vite + Modern JavaScript ✅

**Decision**: Use Vite build tool with vanilla JavaScript (ES6+), no framework.

**Why**:
- **Minimal bundle size** - 15-30KB per module (vs 180KB+ with React)
- **No framework lock-in** - Can add React to specific modules later
- **Fast development** - Vite HMR updates in <100ms
- **Standards-based** - Web Components, native ES modules
- **PWA-ready** - Easy to add Progressive Web App support
- **Simple onboarding** - Any JavaScript developer can contribute

**Alternatives considered**:
- ❌ Plain HTML/CSS/JS - Too simple, lacks build optimization
- ❌ React - Overkill for simple modules, larger bundles, more dependencies
- ❌ Vue/Svelte - Framework lock-in, learning curve

**Tech stack**:
```json
{
  "build": "vite",
  "language": "JavaScript ES6+",
  "styling": "Tailwind CSS",
  "components": "Web Components (native)",
  "package-manager": "pnpm"
}
```

**Module bundle sizes**:
- Identity module: ~15KB (gzipped)
- Transaction viewer: ~20KB (gzipped)
- Settings panel: ~12KB (gzipped)

---

### 3. Mobile Strategy: Progressive Web App (PWA) ✅

**Decision**: Build as PWA for cross-platform mobile support.

**Why**:
- **One codebase** - Works on desktop, iOS, Android
- **Zero extra work** - Add vite-plugin-pwa, done
- **No app stores** - Deploy via web, users install directly
- **Instant updates** - Push update, users get it immediately
- **Installable** - Add to home screen on iOS/Android
- **Offline support** - Service Worker caches for offline use

**Alternatives considered**:
- ❌ React Native - Different codebase, double development
- ❌ Capacitor - Only if need native features (camera, biometrics)
- ❌ Native apps (Swift/Kotlin) - Triple codebase, too slow

**PWA features**:
- Installable on iOS (Safari) and Android (Chrome)
- Works offline with Service Worker
- App icon on home screen
- Full-screen experience
- Push notifications (Android, not iOS)
- Can upgrade to Capacitor later if need native features

**Tech stack**:
```json
{
  "pwa": "vite-plugin-pwa",
  "offline": "Workbox (auto-configured)",
  "manifest": "Web App Manifest",
  "icons": "192x192, 512x512 PNG"
}
```

---

### 4. Backend Language: Python + FastAPI ✅

**Decision**: Use Python with FastAPI framework for module APIs.

**Why**:
- **2-3x faster development** - Less boilerplate than Go
- **Modules just call Cosmos SDK APIs** - Don't need Go's SDK imports
- **Rich ecosystem** - FastAPI, Pydantic, async/await
- **Hot reload** - uvicorn restarts on file change
- **Alpine-friendly** - Python runtime ~50MB (shared across modules)
- **Easy testing** - pytest, asyncio support
- **Auto-documentation** - Swagger/ReDoc generated automatically

**Alternatives considered**:
- ❌ Go - 2-3x more code, slower development (only needed for extending Cosmos SDK itself)
- ❌ Node.js - Good alternative, but Python better for blockchain devs

**Module resource footprint**:
```
Python runtime (shared):  ~50MB
FastAPI + dependencies:   ~20MB
Module code:              ~5MB
─────────────────────────────
Total per module:         ~80MB (Python shared, so incremental cost is ~25MB)
```

**When to use Go instead**:
- Extending Cosmos SDK blockchain itself
- Custom transaction types
- Consensus modifications
- Performance-critical services (>10K req/sec)

**Tech stack**:
```python
{
  "framework": "FastAPI 0.109+",
  "server": "uvicorn (ASGI)",
  "validation": "Pydantic 2.5+",
  "http-client": "httpx (async)",
  "cosmos-sdk": "cosmospy, mospy",
  "testing": "pytest, pytest-asyncio"
}
```

---

### 5. First Module: Identity Registration ✅

**Decision**: Build Identity Registration module first.

**Why**:
- **Foundation** - Required by all other modules
- **Proves architecture** - Tests modular design end-to-end
- **Most critical** - Identities are core to TrustNet trust network
- **Includes keys** - Generates keys during registration (not separate)
- **Complete flow** - Frontend → API → Blockchain

**Identity module features**:
- Register new identity (name + email)
- Auto-generate key pair client-side (Web Crypto API)
- Create DID (Decentralized Identifier)
- Store public key on blockchain
- Download encrypted private key backup
- View identity details
- Search identities

**Key generation approach**:
```javascript
// Option C: Keys generated DURING identity registration
// User enters name + email
// → System generates key pair client-side
// → Public key sent to blockchain
// → Private key encrypted and stored locally
// → User downloads backup

// Benefits:
// - One-step registration (simple UX)
// - Client-side crypto (secure)
// - User controls keys (self-sovereign)
// - Progressive disclosure (backup optional)
```

**Alternatives considered**:
- ❌ Transaction Viewer - More visible but less critical
- ❌ Key Management - Too complex for first module
- ❌ Keys first, then identity - Extra step, worse UX

---

### 6. Implementation Priority: API Infrastructure FIRST ✅

**Decision**: Build API Gateway before any modules.

**Why**:
- **Modules are useless without API** - Can't talk to blockchain
- **Shared foundation** - All modules use same API client
- **Test once, use many** - Cosmos SDK integration tested once
- **Prevents duplication** - No copy-paste blockchain code
- **Clear contracts** - API spec defines module interface

**API Gateway responsibilities**:
1. **Cosmos SDK client** - Transaction broadcast, queries, health checks
2. **Shared utilities** - DID generation, response formatting, validation
3. **Module registration** - Modules plug in via routers
4. **Error handling** - Standard error codes and formats
5. **CORS** - Cross-origin support for frontend
6. **Documentation** - Auto-generated Swagger/ReDoc

**Architecture**:
```python
api/
├── main.py              # FastAPI gateway
├── lib/
│   ├── cosmos_client.py # Cosmos SDK client (reusable)
│   └── utils.py         # Shared utilities
├── modules/
│   └── identity/
│       └── routes.py    # Identity endpoints
└── tests/               # pytest suite
```

**Implementation order**:
1. Week 1: API infrastructure
2. Week 2: dev-sync.sh
3. Week 3: Identity module (uses API)

---

### 7. Module Architecture: Hot-Swappable ✅

**Decision**: Modules are independent, installable, and removable without VM rebuild.

**Why**:
- **Rapid iteration** - Add features without downtime
- **Safe experimentation** - Install/test/remove easily
- **User choice** - Users install only modules they need
- **P2P distribution** - Modules can be shared via blockchain network
- **Version control** - Each module versioned independently

**Module structure**:
```
modules/{name}/
├── module.json          # Metadata, dependencies, permissions
├── frontend/            # Vite + JS
│   ├── index.html
│   ├── main.js
│   └── components/
├── api/                 # Python FastAPI
│   ├── routes.py
│   ├── models.py
│   └── requirements.txt
├── tests/
└── README.md
```

**Module lifecycle**:
```bash
# Install module
./tools/module-install.sh identity
# → Copies frontend to /var/www/html/modules/identity/
# → Installs Python dependencies
# → Starts API service (systemd)
# → Registers routes in Caddy
# → No VM rebuild needed

# Remove module
./tools/module-remove.sh identity
# → Stops API service
# → Removes files
# → Updates Caddy config

# List installed
./tools/module-list.sh
# → Shows installed modules, versions, status
```

**Module.json spec**:
```json
{
  "name": "identity",
  "version": "1.0.0",
  "description": "Identity registration and management",
  "api": {
    "basePath": "/api/identity",
    "port": 8081
  },
  "frontend": {
    "routes": ["/identity", "/identity/register"]
  },
  "permissions": [
    "cosmos.tx.broadcast",
    "cosmos.query.account"
  ],
  "resources": {
    "memory": "128MB",
    "cpu": "0.5"
  }
}
```

---

## Module Architecture

### Communication Flow

```
┌──────────────────────────────────────────────────────────┐
│                    User Action                           │
│  "Click Register Button"                                 │
└───────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│              Frontend (Browser)                          │
│  modules/identity/frontend/register.js                   │
│                                                           │
│  1. Generate key pair (Web Crypto API)                   │
│  2. Create request body:                                 │
│     { name: "Alice", email: "...", publicKey: "..." }    │
│  3. fetch('/api/identity/register', { ... })             │
└───────────────────────┬──────────────────────────────────┘
                        │ HTTP POST
                        │ Content-Type: application/json
                        ▼
┌──────────────────────────────────────────────────────────┐
│              API Gateway (VM)                            │
│  api/main.py (FastAPI)                                   │
│                                                           │
│  CORS check → Validate request → Route to module         │
└───────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│          Identity Module API                             │
│  modules/identity/api/routes.py                          │
│                                                           │
│  1. Validate input (Pydantic)                            │
│  2. Generate DID: did:trustnet:abc123                    │
│  3. Create Cosmos SDK transaction:                       │
│     {                                                     │
│       type: "trustnet/RegisterIdentity",                 │
│       value: { did, name, email, publicKey }             │
│     }                                                     │
│  4. Call cosmos_client.broadcast_tx(tx)                  │
└───────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│          Cosmos SDK Client Library                       │
│  api/lib/cosmos_client.py                                │
│                                                           │
│  async def broadcast_tx(tx):                             │
│    response = await httpx.post(                          │
│      "http://localhost:26657/broadcast_tx_commit",       │
│      json={"tx": tx}                                     │
│    )                                                      │
│    return response.json()                                │
└───────────────────────┬──────────────────────────────────┘
                        │ HTTP POST (RPC)
                        ▼
┌──────────────────────────────────────────────────────────┐
│       Cosmos SDK Blockchain Node (Go)                    │
│  localhost:26657 (RPC)                                   │
│                                                           │
│  1. Receive transaction                                  │
│  2. Validate transaction                                 │
│  3. Add to mempool                                       │
│  4. Consensus (Tendermint BFT)                           │
│  5. Execute transaction                                  │
│  6. Store in blockchain                                  │
│  7. Return result: { hash, height, code, log }           │
└───────────────────────┬──────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────────────────┐
│          Response Flow (back up the stack)               │
│                                                           │
│  Cosmos SDK → cosmos_client → Identity API →             │
│  → API Gateway → Frontend                                │
│                                                           │
│  Frontend receives:                                      │
│  {                                                        │
│    success: true,                                        │
│    data: {                                               │
│      did: "did:trustnet:abc123",                         │
│      txHash: "0x...",                                    │
│      height: 12345                                       │
│    }                                                      │
│  }                                                        │
│                                                           │
│  Frontend displays:                                      │
│  "✅ Identity created! DID: did:trustnet:abc123"         │
└──────────────────────────────────────────────────────────┘
```

### API Standards

All modules follow these standards:

**URL Pattern**: `/api/{module}/{resource}/{action}`

**Request Format**:
```json
{
  "field1": "value",
  "field2": 123
}
```

**Response Format** (Success):
```json
{
  "success": true,
  "data": {
    "result": "...",
    "details": { ... }
  },
  "meta": {
    "timestamp": "2026-02-02T10:30:00Z",
    "requestId": "req-xyz789"
  }
}
```

**Response Format** (Error):
```json
{
  "success": false,
  "error": {
    "code": "IDENTITY_ALREADY_EXISTS",
    "message": "An identity with this email already exists",
    "details": { "field": "email" }
  },
  "meta": {
    "timestamp": "2026-02-02T10:30:00Z",
    "requestId": "req-xyz789"
  }
}
```

**HTTP Status Codes**:
- 200: Success (GET, PUT, PATCH, DELETE)
- 201: Created (POST)
- 400: Bad Request (validation error)
- 401: Unauthorized (missing auth)
- 403: Forbidden (insufficient permissions)
- 404: Not Found (resource doesn't exist)
- 409: Conflict (duplicate resource)
- 500: Internal Server Error
- 503: Service Unavailable (Cosmos SDK unreachable)

---

## Development Workflow

### Dual-Disk Architecture

```
Main Disk (trustnet.qcow2 - 5GB):
├── Alpine Linux 3.21
├── Caddy web server
├── Python runtime
├── Cosmos SDK node
└── Production-ready modules

Dev Disk (trustnet-dev-tools.qcow2 - 10GB):
├── Go compiler
├── Ignite CLI
├── Git
├── Make, GCC
└── Development tools

Switching modes:
./start-trustnet.sh           # Production (main disk only)
./start-trustnet.sh --dev     # Development (attach dev disk)
```

**Benefits**:
- Production disk stays pristine (5GB)
- Dev tools don't consume production resources
- Attach/detach in 5 seconds (no rebuild)
- Clear separation of concerns

### Development Cycle

```
┌─────────────────────────────────────────────────────────┐
│  1. Edit Code (Host)                                    │
│     VSCode: modules/identity/frontend/register.js       │
│     Save file (Ctrl+S)                                  │
└───────────────┬─────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│  2. Auto-Sync (2-5 seconds)                             │
│     dev-sync.sh detects change (inotifywait)            │
│     rsync -av modules/identity/ vm:/var/www/html/...    │
└───────────────┬─────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────┐
│  3. View Result (Browser)                               │
│     Refresh: https://trustnet.local/identity            │
│     OR: Vite HMR auto-updates                           │
└─────────────────────────────────────────────────────────┘

Total time: 2-5 seconds (vs 30 minutes for VM rebuild)
```

### Local Development (Host Machine)

```bash
# Option 1: Test frontend locally (fastest)
cd modules/identity/frontend
pnpm dev
# → http://localhost:5173/identity
# → Calls API at https://trustnet.local/api/

# Option 2: Test API locally
cd api/
source venv/bin/activate
uvicorn main:app --reload
# → http://localhost:8080/api/docs
# → Calls Cosmos SDK at localhost:26657

# Option 3: Test in VM (production-like)
./tools/dev-sync.sh
# → Syncs to VM
# → https://trustnet.local/identity
```

---

## Deployment Strategy

### Development Environment

```
Developer Machine:
├── Ubuntu/macOS/Windows
├── VSCode
├── pnpm (for frontend)
├── Python 3.11+ (for API)
└── QEMU (for VM)

TrustNet VM (running locally):
├── Alpine Linux 3.21
├── Caddy (HTTPS server)
├── Python FastAPI (API Gateway)
├── Cosmos SDK node
└── Modules (synced from host)
```

### Production Deployment

```
User's Machine:
└── TrustNet VM
    ├── Main disk only (5GB)
    ├── No dev tools
    ├── Optimized modules
    └── Production Cosmos SDK
```

### Module Distribution

**Phase 1** (Current): Manual installation
```bash
curl -sSL https://trustnet.io/install.sh | bash
# → Downloads VM
# → Starts TrustNet
# → Access: https://trustnet.local
```

**Phase 2** (Future): P2P module distribution
```bash
# Upload module to one node
./tools/module-publish.sh identity

# Propagates to all nodes via P2P network
# → Other nodes discover module
# → Download and verify signature
# → Install if trusted
```

---

## Security Model

### Identity & Keys

**Key Generation**:
- Client-side only (Web Crypto API)
- Never sent to server
- AES-256-GCM encryption with user password
- Stored in localStorage (encrypted)

**Backup**:
- Encrypted JSON file download
- QR code export (for mobile)
- Paper wallet option

**Authentication**:
- JWT tokens (signed by server)
- DID-based (no username/password)
- Biometric unlock (PWA on mobile)

### Module Permissions

Each module declares required permissions in `module.json`:

```json
{
  "permissions": [
    "cosmos.tx.broadcast",      // Can send transactions
    "cosmos.query.account",     // Can query accounts
    "storage.local.write",      // Can write to localStorage
    "camera.access"             // Can access camera (PWA)
  ]
}
```

User must approve permissions on first run.

### Network Security

```
All communication HTTPS:
├── Browser ↔ Caddy: TLS 1.3
├── Caddy ↔ API: localhost (internal)
├── API ↔ Cosmos SDK: localhost (internal)
└── IPv6 exclusive (no IPv4)
```

---

## Resource Management

### Alpine VM Footprint

**Production (Main Disk - 5GB)**:
```
Alpine Linux base:      ~150MB
Caddy web server:       ~40MB
Python 3.11 runtime:    ~50MB
FastAPI + deps:         ~20MB
Cosmos SDK node:        ~200MB
Identity module:        ~80MB
Transaction module:     ~75MB
Keys module:            ~70MB
Blockchain data:        ~500MB (grows over time)
────────────────────────────
Total (fresh install):  ~1.2GB
```

**Development (Dev Disk - 10GB)**:
```
Go compiler:            ~500MB
Ignite CLI:             ~200MB
Git, Make, GCC:         ~150MB
Node.js (optional):     ~100MB
Build cache:            ~500MB
────────────────────────────
Total dev tools:        ~1.5GB
```

### Per-Module Resource Limits

Configured in `module.json`:
```json
{
  "resources": {
    "memory": "128MB",     // Maximum RAM
    "cpu": "0.5",          // Half CPU core
    "disk": "100MB",       // Maximum disk space
    "network": "10Mbps"    // Network bandwidth limit
  }
}
```

Enforced via systemd:
```ini
[Service]
MemoryLimit=128M
CPUQuota=50%
```

---

## Implementation Roadmap

### Week 1: API Infrastructure

**Goal**: Build foundation for all modules

**Tasks**:
- [ ] Create `api/` directory structure
- [ ] Implement Cosmos SDK client (`cosmos_client.py`)
- [ ] Build API Gateway (`main.py`)
- [ ] Create shared utilities (`utils.py`)
- [ ] Write test suite (`tests/`)
- [ ] Document API endpoints (auto-generated Swagger)
- [ ] Test Cosmos SDK connectivity
- [ ] Verify health checks pass

**Deliverables**:
- Working API Gateway on port 8080
- Cosmos SDK client library
- API documentation at `/api/docs`
- Test suite passing

---

### Week 2: Development Workflow

**Goal**: Enable rapid iteration

**Tasks**:
- [ ] Create `tools/dev-sync.sh` script
- [ ] Install inotify-tools
- [ ] Configure watch directories
- [ ] Test sync latency (target: <5 seconds)
- [ ] Create simple test HTML file
- [ ] Verify sync works
- [ ] Document developer workflow

**Deliverables**:
- Auto-sync script working
- Developer documentation
- 2-5 second iteration cycle

---

### Week 3: Identity Module

**Goal**: First complete module

**Tasks**:
- [ ] Create `modules/identity/` structure
- [ ] Build frontend (Vite + JS)
  - [ ] Registration form
  - [ ] Key generation (Web Crypto API)
  - [ ] Backup download
- [ ] Build backend API
  - [ ] `/api/identity/register` endpoint
  - [ ] `/api/identity/did/{did}` endpoint
  - [ ] Cosmos SDK integration
- [ ] Write tests
- [ ] Test end-to-end flow
- [ ] Document module

**Deliverables**:
- Working identity registration
- Client-side key generation
- Blockchain integration
- Full test coverage

---

### Week 4: Additional Modules

**Transaction Viewer**:
- List transactions
- View transaction details
- Search/filter transactions

**Key Management** (Advanced):
- Key rotation
- Multiple keys per identity
- Hardware wallet support
- Recovery mechanisms

---

## Success Criteria

### Technical Metrics

- **Development speed**: 2-5 second iteration (vs 30+ minutes)
- **Bundle size**: <30KB per module (vs 180KB+ with React)
- **VM footprint**: <2GB production (vs 10GB+ with dev tools)
- **API latency**: <100ms for queries, <2s for transactions
- **Module install**: <30 seconds (no rebuild)

### User Experience

- **Onboarding**: Register identity in <60 seconds
- **Mobile**: PWA installable on iOS/Android
- **Offline**: Service Worker caches for offline use
- **Cross-platform**: Works on desktop, iOS, Android

### Developer Experience

- **Setup time**: <10 minutes (clone, install, run)
- **Learning curve**: <1 day to understand architecture
- **First module**: <3 days to build and deploy
- **Documentation**: Auto-generated API docs

---

## Conclusion

TrustNet's architecture prioritizes:

1. **Developer velocity** - 2-5 second iteration vs 30 minutes
2. **Modularity** - Hot-swappable modules without downtime
3. **Resource efficiency** - 5GB production VM, 10GB dev
4. **Cross-platform** - Desktop, iOS, Android via PWA
5. **Simplicity** - Modern tools, clear patterns, auto-documentation

All technology decisions align with these goals:
- ✅ Rsync → Fast sync (2-5s)
- ✅ Vite + JS → Small bundles (15-30KB)
- ✅ PWA → Cross-platform (one codebase)
- ✅ Python → Rapid development (2-3x faster)
- ✅ Identity first → Foundational module
- ✅ API first → Enables all modules
- ✅ Hot-swap → No rebuilds

**Next step**: Implement API infrastructure (Week 1).

---

## References

**Decision Documents**:
- [Modular Development Plan](./MODULAR_DEVELOPMENT_PLAN.md)
- [Frontend Technology Comparison](./FRONTEND_TECHNOLOGY_COMPARISON.md)
- [Mobile Strategy](./MOBILE_STRATEGY.md)
- [Backend Language Analysis](./BACKEND_LANGUAGE_ANALYSIS.md)
- [Module API Specification](./MODULE_API_SPECIFICATION.md)
- [Identity vs Keys Decision](./IDENTITY_VS_KEYS_DECISION.md)
- [API Implementation Plan](./API_IMPLEMENTATION_PLAN.md)

**External Resources**:
- [Cosmos SDK Documentation](https://docs.cosmos.network)
- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Vite Documentation](https://vitejs.dev)
- [Web Crypto API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Crypto_API)

---

*Document Version: 1.0.0*  
*Created: February 2, 2026*  
*Status: All decisions finalized*  
*Ready for implementation*

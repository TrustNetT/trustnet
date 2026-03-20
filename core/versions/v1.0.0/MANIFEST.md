# v1.0.0 - Manifest

**Release Date**: February 2, 2026  
**Status**: ✅ STABLE - Production Ready  
**Archive Date**: March 19, 2026

---

## Overview

TrustNet Core v1.0.0 is the **current production version**. This is the baseline stable version with all working functionality. All future versions build upon this foundation.

---

## Component Inventory

### Base Operating System
- **Alpine Linux**: 3.21 (minimal, ~5GB)
- **Kernel**: Alpine default (5.15+)
- **Package Manager**: apk

### Core Infrastructure
- **Caddy Web Server**: 2.7+ (reverse proxy + SSL termination)
- **OpenSSL**: 3.1+ (certificate management)
- **SSH**: OpenSSH (remote access)

### Blockchain
- **Tendermint**: BFT consensus engine
- **Cosmos SDK**: Application framework
- **Go**: 1.25.6 (build/runtime)

### Networking
- **IPv6**: ULA networks (fd10::/7)
- **mDNS**: Hybrid discovery (multicast ff02::1)
- **DNS TNR**: Node registry (AAAA records)

### APIs
- **REST**: Cosmos SDK (port 1317)
- **RPC**: Tendermint (port 26657)
- **gRPC**: Cosmos (port 9090)
- **Web**: Caddy (port 80/443)

### Development/Building
- **Node.js**: 20.11.0 (for frontend build)
- **Python**: 3.12.1 (utilities)
- **Git**: Version control

---

## Included Files

### Installation & Setup
```
tools/
├── setup-trustnet-node.sh          (main installer - 500+ lines)
├── setup-root-registry.sh          (registry setup)
├── setup-node.sh                   (node-specific config)
├── setup-vms.sh                    (multi-VM setup)
├── alpine-install.exp              (expect automation)
└── lib/                            (modular installation)
    ├── install-caddy.sh
    ├── install-certificates.sh
    ├── create-vm.sh
    ├── setup-network.sh
    └── ... (12+ modules)
```

### Documentation
```
docs/
├── INSTALLATION.md                 (step-by-step guide)
├── ARCHITECTURE.md                 (system design)
├── TROUBLESHOOTING.md              (common issues)
├── TRUST_SYSTEM.md                 (trust model)
├── deployment/                     (K8s deployment)
├── guides/                         (how-to guides)
├── security/                       (security hardening)
└── ... (15+ docs)
```

### Configuration Templates
```
config/
├── caddy/
│   └── Caddyfile-template
├── alpine/
│   └── setup-answers.conf
└── blockchain/
    └── genesis-template.json
```

---

## Installation Size & Requirements

| Component | Size | Notes |
|-----------|------|-------|
| Alpine Linux base | ~500MB | Downloaded during install |
| Build artifacts cache | ~1-2GB | Cleaned after build |
| Final VM disk | ~5GB | Production deployment |
| Development tools | ~3GB | Optional (not installed by default) |

---

## Tested Deployments

### Local Development
- ✅ QEMU x86_64 on Linux (Ubuntu 22.04+)
- ✅ QEMU ARM64 on macOS (M1/M2/M3)
- ✅ Docker simulation (limited testing)

### Production
- ✅ OCI Always-Free Instance (oracledev)
- ✅ Factory.local (ARM64 builder)
- ✅ jenkins.ingasti.com environment

### Configurations Tested
- ✅ Standalone single node
- ✅ Multiple nodes on same network
- ✅ IPv6-only network
- ✅ Behind Caddy reverse proxy
- ✅ Let's Encrypt certificate automation

---

## Known Limitations

### Network
- ⚠️ IPv6-only (no IPv4 support by design)
- ⚠️ Requires IPv6-capable network infrastructure
- ⚠️ Cannot work behind IPv4-only firewalls

### Setup & Configuration
- ⚠️ Manual node endpoint entry required on iOS
- ⚠️ No first-time setup UI
- ⚠️ Setup requires SSH access for configuration

### Performance
- ⚠️ Alpine Linux has limited package repository
- ⚠️ Minimal build tools (intentional for production)
- ⚠️ No build-in monitoring (must add separately)

### Developer Experience
- ⚠️ No QR code generation for quick setup
- ⚠️ Certificate fingerprint must be verified manually on iOS
- ⚠️ PIN-based verification not implemented

**Note**: These limitations are addressed in v1.1.0

---

## Verification Checklist

Before deploying v1.0.0, verify:

- [x] Alpine Linux boots successfully
- [x] Caddy web server starts and serves HTTPS
- [x] SSL certificates load from Let's Encrypt
- [x] IPv6 networking functional
- [x] Node registry discovery works (mDNS + DNS)
- [x] Blockchain node runs (Tendermint + Cosmos)
- [x] REST API responds at :1317
- [x] RPC endpoint responds at :26657
- [x] Web UI displays at https://[IPv6]:443
- [x] SSH access configured and working
- [x] User can create transactions via RPC
- [x] User can retrieve blockchain state via REST
- [x] Multiple nodes can connect and communicate

---

## Version Location

**Source Repository**: `core/versions/v1.0.0/`

```
trustnet-wip/
└── core/
    ├── versions/
    │   └── v1.0.0/
    │       ├── tools/
    │       ├── docs/
    │       ├── config/
    │       ├── MANIFEST.md <-- You are here
    │       └── CHANGELOG.md
```

---

## How to Use This Version

### For Fresh Installation

```bash
cd ~/TrustNet/trustnet-wip/core/versions/v1.0.0
./tools/setup-trustnet-node.sh
```

### For Development/Modification

```bash
# Copy to working directory
cp -r ~/TrustNet/trustnet-wip/core/versions/v1.0.0 ~/my-trustnet-v1
cd ~/my-trustnet-v1
# Make changes...
./tools/setup-trustnet-node.sh --test
```

### For Comparison

```bash
# Compare v1.0.0 with v1.1.0
diff -r core/versions/v1.0.0/tools/ core/versions/v1.1.0/tools/
diff -r core/versions/v1.0.0/docs/ core/versions/v1.1.0/docs/
```

---

## Related Documentation

- **Installation Guide**: [docs/INSTALLATION.md](../INSTALLATION.md)
- **All Versions**: [docs/VM_VERSIONS.md](../VM_VERSIONS.md)
- **Changelog**: [CHANGELOG.md](CHANGELOG.md)
- **v1.1.0 Preview**: [../versions/v1.1.0/MANIFEST.md](../v1.1.0/MANIFEST.md)

---

**Archived**: March 19, 2026  
**Maintained by**: GitHub Copilot

# Production vs Development Nodes - Architecture Decision

**Date**: February 2, 2026  
**Status**: Decision Needed  
**Impact**: Core installer, deployment strategy, VM size

---

## Problem Statement

Current TrustNet nodes install **all development tools**:
- Go compiler (200MB)
- Ignite CLI (build scaffolding)
- Git, Make, GCC (build tools)
- Total VM size: ~20GB

**Question**: Should production users get this heavyweight setup?

---

## User Types

### Production User
**Who**: Regular users running TrustNet nodes  
**Needs**: 
- Web UI (view identity, transactions)
- Blockchain node (participate in network)
- Caddy web server (HTTPS access)

**Does NOT need**:
- Go compiler
- Build tools
- Development dependencies

**Ideal VM size**: ~5GB

---

### Developer User
**Who**: Blockchain protocol developers  
**Needs**:
- Everything production user needs +
- Go compiler (modify blockchain code)
- Ignite CLI (scaffold new modules)
- Build tools (compile changes)

**Ideal VM size**: ~20GB

---

### Module Developer (Us)
**Who**: TrustNet feature developers (identity, transactions, etc.)  
**Needs**:
- **Build on host machine** (Go, Node.js, etc.)
- **Deploy compiled artifacts to VM**
- VM only needs runtime (no build tools)

**Key insight**: Module development happens **outside the VM**

---

## Solutions Comparison

### Option 1: Two Installation Modes ⭐

**Implementation**: Modify `core/tools/setup-trustnet-node.sh`

```bash
# Interactive mode
./setup-trustnet-node.sh

? What type of node?
  1) Production  - Minimal runtime (recommended)
  2) Development - Full build tools (blockchain devs)
> 1

# Or automated
./setup-trustnet-node.sh --mode=production   # Default
./setup-trustnet-node.sh --mode=development  # Blockchain development
```

**Production Mode** (Default):
- ✅ Caddy web server
- ✅ Pre-built blockchain binaries (download from GitHub releases)
- ✅ Web UI static files
- ✅ Runtime dependencies only
- ❌ NO Go compiler
- ❌ NO build tools
- **Size**: ~5GB

**Development Mode**:
- ✅ Everything from production +
- ✅ Go compiler
- ✅ Ignite CLI
- ✅ Git, Make, GCC
- **Size**: ~20GB

**Pros**:
- ✅ Production users get minimal, secure nodes
- ✅ Blockchain devs get full toolchain
- ✅ One installer, clear choice
- ✅ Smaller attack surface for production

**Cons**:
- ❌ Requires pre-built binaries (CI/CD for releases)
- ❌ More installer complexity

---

### Option 2: Build Modules on Host, Deploy Binaries

**Our modular architecture approach**:

```
┌─────────────────────────────────────────┐
│  HOST MACHINE (Developer Laptop)       │
│                                         │
│  ~/GitProjects/TrustNet/trustnet-wip/   │
│  ├── Go 1.25.6 (build Go modules)      │
│  ├── Node.js 20 (build frontend)       │
│  ├── Build: go build -o binary         │
│  └── Deploy: rsync binary to VM        │
└─────────────────────────────────────────┘
              ↓ rsync/deploy
┌─────────────────────────────────────────┐
│  TRUSTNET VM (Alpine Linux)             │
│                                         │
│  /var/www/html/modules/identity/        │
│  ├── frontend/ (HTML/CSS/JS)           │
│  ├── identity-service (binary)         │
│  └── Run binary (no compilation)       │
│                                         │
│  NO BUILD TOOLS NEEDED IN VM            │
└─────────────────────────────────────────┘
```

**Workflow**:
```bash
# 1. Build on host
cd ~/GitProjects/TrustNet/trustnet-wip/modules/identity/api
go build -o identity-service

# 2. Deploy to VM
./tools/dev-sync.sh
# → Syncs compiled binary + frontend to VM
# → VM receives ready-to-run artifacts

# 3. VM runs binary (no compilation)
ssh trustnet
doas rc-service identity-service start
```

**Pros**:
- ✅ VM never compiles (faster, smaller)
- ✅ Consistent builds (host controls compiler)
- ✅ Works for both dev and prod VMs
- ✅ Host has full dev environment (IDE, debugger)

**Cons**:
- ❌ Cross-compilation if host ≠ VM architecture
- ❌ Requires build step on host

---

### Option 3: Dev Tools on Separate Disk ⭐⭐

**Implementation**: Dev tools on detachable QEMU disk

```
Production Node:
/dev/vda → 5GB disk (Alpine + Caddy + blockchain)
         → Minimal, clean, ready for production

Development Mode:
/dev/vda → 5GB disk (same as production)
/dev/vdb → 10GB dev-disk (Go, Ignite CLI, build tools)
         → Mounted at /opt/dev-tools/
         → PATH includes /opt/dev-tools/bin/

To Go Production:
1. Stop VM
2. Detach dev-disk (remove -drive flag)
3. Start VM → Production node (no dev tools)
4. No rebuild needed!
```

**Disk Management**:
```bash
# Create dev-disk once
qemu-img create -f qcow2 trustnet-dev-tools.qcow2 10G

# Attach dev-disk (development mode)
qemu-system-x86_64 \
  -drive file=trustnet.qcow2 \         # Main OS disk
  -drive file=trustnet-dev-tools.qcow2 # Dev tools disk

# Inside VM: Mount and use dev tools
doas mount /dev/vdb /opt/dev-tools
export PATH="/opt/dev-tools/bin:$PATH"
go version  # Works!

# Production mode: Just remove the dev-disk line
qemu-system-x86_64 \
  -drive file=trustnet.qcow2           # Only main disk
```

**Installation Workflow**:
```bash
# 1. Install base node (production-ready)
./install.sh --mode=production
# → Creates trustnet.qcow2 (5GB)

# 2. Create dev-disk (optional)
./tools/create-dev-disk.sh
# → Creates trustnet-dev-tools.qcow2 (10GB)
# → Installs Go, Ignite CLI, Git, Make, GCC
# → Sets up /opt/dev-tools/ structure

# 3. Attach dev-disk when developing
./start-trustnet.sh --dev
# → Starts VM with both disks
# → Auto-mounts /opt/dev-tools
# → Adds to PATH

# 4. Detach for production
./start-trustnet.sh
# → Starts VM with main disk only
# → Clean production node
```

**Pros**:
- ✅ **Zero rebuild needed** - attach/detach disk in seconds
- ✅ Production disk stays pristine (never touched)
- ✅ Dev tools completely isolated
- ✅ Can share dev-disk across multiple VMs
- ✅ Backup dev-disk separately
- ✅ Switch modes without reinstall

**Cons**:
- ❌ Need to manage two disk images
- ❌ Slightly more complex VM startup script

---

## Recommended Architecture

**NEW RECOMMENDATION: Option 3 (Separate Dev Disk) + Option 2 (Build on Host)**

### Why This Is Better

**Separating dev tools to a detachable disk solves all problems**:
1. ✅ Production disk: Minimal, clean, production-ready (5GB)
2. ✅ Dev disk: All build tools isolated (10GB)
3. ✅ Switch modes: Attach/detach disk (5 seconds, no rebuild)
4. ✅ Module builds: Still on host (fast, consistent)
5. ✅ VM compilation: Available when needed (attach dev disk)

### Disk Architecture

**Main Disk** (`trustnet.qcow2` - 5GB):
```
/dev/vda1 (5GB) - Production OS
├── /etc/         - System configs
├── /usr/         - System binaries
├── /var/www/html/- Web UI + modules
├── /opt/trustnet/- Blockchain node
└── /home/warden/ - User data
```

**Dev Disk** (`trustnet-dev-tools.qcow2` - 10GB):
```
/dev/vdb1 (10GB) - Development Tools (Optional)
└── /opt/dev-tools/
    ├── bin/      - Go, Git, Make, GCC
    ├── lib/      - Development libraries
    ├── src/      - Go source cache
    └── pkg/      - Go packages
```

**Mounting Strategy**:
```bash
# VM boot script checks for /dev/vdb
if [ -b /dev/vdb ]; then
    echo "Dev disk detected, mounting..."
    mount /dev/vdb /opt/dev-tools
    export PATH="/opt/dev-tools/bin:$PATH"
    echo "Development mode enabled"
else
    echo "Production mode (no dev disk)"
fi
```

### Module Development Workflow

**Day-to-day development** (build on host):
```bash
# Host machine
cd ~/GitProjects/TrustNet/trustnet-wip/
# Edit Go code
go build -o binary modules/identity/api/
# Deploy to VM
rsync binary warden@trustnet.local:/var/www/html/modules/identity/
```
✅ **No dev disk needed** - VM just runs binaries

**Blockchain protocol work** (need dev tools in VM):
```bash
# Attach dev disk
./start-trustnet.sh --dev
# SSH to VM
ssh warden@trustnet.local
# Now have Go compiler
go version  # go version go1.25.6 linux/amd64
ignite scaffold chain mycustomchain
```
✅ **Dev disk provides full toolchain**

**Going to production**:
```bash
# Stop VM
./stop-trustnet.sh
# Start without dev disk
./start-trustnet.sh
# VM boots clean (no dev tools in PATH)
```
✅ **5GB minimal production node**

### Disk Size Comparison

| Disk | Production | With Dev Disk |
|------|-----------|---------------|
| **Main disk** | 5GB | 5GB (unchanged) |
| **Dev disk** | - | 10GB (detachable) |
| **Total when developing** | 5GB | 15GB |
| **Total when in production** | 5GB | 5GB |

---

## Implementation Plan

### Phase 1: Create Dev Disk Tool

**File**: `tools/create-dev-disk.sh`

```bash
#!/bin/bash
# Create detachable development tools disk

set -e

DEV_DISK="trustnet-dev-tools.qcow2"
DEV_SIZE="10G"
MOUNT_POINT="/mnt/dev-disk"

echo "Creating dev tools disk ($DEV_SIZE)..."
qemu-img create -f qcow2 "$DEV_DISK" "$DEV_SIZE"

echo "Formatting disk..."
# Create filesystem
sudo modprobe nbd max_part=8
sudo qemu-nbd --connect=/dev/nbd0 "$DEV_DISK"
sudo mkfs.ext4 -L dev-tools /dev/nbd0
sudo qemu-nbd --disconnect /dev/nbd0

echo "Mounting disk..."
sudo mkdir -p "$MOUNT_POINT"
sudo mount -o loop "$DEV_DISK" "$MOUNT_POINT"

echo "Installing dev tools..."
sudo mkdir -p "$MOUNT_POINT/bin" "$MOUNT_POINT/lib" "$MOUNT_POINT/src"

# Download and install Go
echo "Installing Go 1.25.6..."
wget https://go.dev/dl/go1.25.6.linux-amd64.tar.gz
sudo tar -C "$MOUNT_POINT" -xzf go1.25.6.linux-amd64.tar.gz
rm go1.25.6.linux-amd64.tar.gz

# Create environment setup script
cat > "$MOUNT_POINT/setup-env.sh" << 'EOF'
#!/bin/sh
export PATH="/opt/dev-tools/go/bin:$PATH"
export GOROOT="/opt/dev-tools/go"
export GOPATH="/opt/dev-tools/gopath"
export PATH="$GOPATH/bin:$PATH"
echo "Development environment loaded"
go version
EOF
chmod +x "$MOUNT_POINT/setup-env.sh"

# Install Ignite CLI
echo "Installing Ignite CLI..."
sudo GOROOT="$MOUNT_POINT/go" GOPATH="$MOUNT_POINT/gopath" \
  "$MOUNT_POINT/go/bin/go" install github.com/ignite/cli/ignite/cmd/ignite@latest

# Install build tools
echo "Installing build tools..."
# (Git, Make, GCC would be in Alpine's package manager)

echo "Unmounting..."
sudo umount "$MOUNT_POINT"

echo "✅ Dev disk created: $DEV_DISK"
echo "Attach to VM with: ./start-trustnet.sh --dev"
```

### Phase 2: Modify VM Startup Script

**File**: `tools/start-trustnet.sh`

```bash
#!/bin/bash
# Start TrustNet VM with optional dev disk

VM_DISK="trustnet.qcow2"
DEV_DISK="trustnet-dev-tools.qcow2"
VM_NAME="trustnet"

# Parse arguments
DEV_MODE=false
if [ "$1" = "--dev" ]; then
    DEV_MODE=true
fi

# Build QEMU command
QEMU_CMD="qemu-system-x86_64 \
  -m 4G \
  -smp 2 \
  -drive file=$VM_DISK,format=qcow2"

# Add dev disk if in dev mode
if [ "$DEV_MODE" = true ]; then
    if [ -f "$DEV_DISK" ]; then
        echo "Starting in DEVELOPMENT mode (with dev tools disk)..."
        QEMU_CMD="$QEMU_CMD -drive file=$DEV_DISK,format=qcow2"
    else
        echo "⚠️  Dev disk not found. Create with: ./tools/create-dev-disk.sh"
        exit 1
    fi
else
    echo "Starting in PRODUCTION mode (no dev tools)..."
fi

# Add network, display, etc.
QEMU_CMD="$QEMU_CMD \
  -netdev user,id=net0,hostfwd=tcp::2223-:22,hostfwd=tcp::8443-:443 \
  -device virtio-net-pci,netdev=net0 \
  -nographic"

echo "Command: $QEMU_CMD"
eval $QEMU_CMD
```

### Phase 3: VM Boot Script (Inside VM)

**File**: `/etc/init.d/mount-dev-tools` (in VM)

```bash
#!/sbin/openrc-run
# Auto-mount dev disk if present

depend() {
    need localmount
}

start() {
    if [ -b /dev/vdb ]; then
        ebegin "Mounting development tools disk"
        mkdir -p /opt/dev-tools
        mount /dev/vdb /opt/dev-tools
        eend $?
        
        # Source environment
        if [ -f /opt/dev-tools/setup-env.sh ]; then
            echo "source /opt/dev-tools/setup-env.sh" >> /etc/profile.d/dev-tools.sh
        fi
    fi
}

stop() {
    if mountpoint -q /opt/dev-tools; then
        ebegin "Unmounting development tools disk"
        umount /opt/dev-tools
        eend $?
    fi
}
```

### Phase 4: Host-Based Module Build (Unchanged)

**File**: `tools/dev-sync.sh`

```bash
#!/bin/bash
# Build modules on host, deploy to VM
# Works with or without dev disk in VM

# 1. Build Go services on host
cd modules/identity/api
go build -o identity-service
cd ../../..

# 2. Build frontend on host (if using Vite)
cd modules/identity/frontend
pnpm build
cd ../../..

# 3. Sync to VM
rsync -avz modules/ warden@127.0.0.1:/var/www/html/modules/ -e "ssh -p 2223"
```

**Note**: This still works because VM just receives compiled binaries. Dev disk not needed.

---

## Decision Matrix

| Requirement | Option 1 | Option 2 | Option 3 | Winner |
|------------|----------|----------|----------|--------|
| Minimal prod nodes | ✅ | ✅ | ✅ | All |
| Fast module dev | ❌ | ✅ | ✅ | 2+3 |
| Simple install | ✅ | ✅ | ✅ | All |
| Blockchain protocol dev | ✅ | ❌ | ✅ | 1+3 |
| Security (less tools) | ✅ | ✅ | ✅ | All |
| Zero rebuild switching | ❌ | N/A | ✅ | **Option 3** |
| Disk isolation | ❌ | N/A | ✅ | **Option 3** |
| Share dev tools across VMs | ❌ | ❌ | ✅ | **Option 3** |

**Final Recommendation**: **Option 3 (Dev Disk) + Option 2 (Build on Host)**

### Why This Wins

1. **Best of both worlds**:
   - Production disk stays pristine (5GB)
   - Dev tools available when needed (attach disk)
   - Module builds on host (fast, consistent)

2. **Operational flexibility**:
   - Attach dev disk: Full blockchain development
   - No dev disk: Fast module deploys from host
   - Production: Detach dev disk in 5 seconds

3. **Real-world scenarios**:
   - **Module developer** (us): Build on host, deploy to VM (no dev disk needed)
   - **Blockchain developer**: Attach dev disk, modify protocol, test
   - **Production user**: Never attach dev disk, minimal 5GB node

---

## Questions for User

Before implementing, please decide:

### 1. Installation Modes
Should we add `--mode=production|development` to installer?
- **Yes** - Users choose minimal or full install
- **No** - All nodes get same install (which one?)

### 2. Module Build Location
Where should modules be built?
- **A) Host machine** (recommended) - Build on laptop, deploy to VM
- **B) In VM** - VM compiles modules (needs dev tools)

### 3. Current Node
What should we do with your existing node?
- **Keep as-is** - Has dev tools, works for testing
- **Rebuild as production** - Test minimal mode
- **Add mode later** - Continue with current setup

### 4. Pre-built Binaries
Should production mode download pre-built binaries?
- **Yes** - Need GitHub Actions for releases
- **No** - Compile during install (slower, needs tools)

### 5. Priority
What to implement first?
- **A) Installation modes** - Modify core installer (affects core branch)
- **B) Host-based builds** - Create dev-sync.sh (affects modules)
- **C) Both together** - Complete solution
- **D) Neither yet** - Focus on module development first, decide later

---

## Impact Assessment

### If we do Option 1 + 2:

**Benefits**:
- ✅ Production users: 5GB minimal nodes
- ✅ Module devs: Build on powerful host machine
- ✅ Faster iterations (no VM compilation)
- ✅ Cleaner separation of concerns

**Work Required**:
- Modify `core/tools/setup-trustnet-node.sh` (production/dev modes)
- Create `tools/dev-sync.sh` (auto-build and deploy)
- Set up GitHub Actions (pre-built binaries)
- Update documentation

**Timeline**:
- Week 1: Installation modes
- Week 2: Host-based builds
- Week 3: CI/CD for binaries
- Week 4: Documentation + testing

### If we defer this decision:

**Current State**:
- All nodes install dev tools (~20GB)
- Works fine for development
- Not optimal for production users

**Can implement later**:
- Focus on module functionality first
- Add installation modes when ready for production release
- No blocking issues for development

---

## Recommendation Summary

**Immediate** (This week):
1. ✅ **Rebuild main disk as production** (5GB minimal)
   - Clean Alpine install
   - Caddy + blockchain node only
   - No dev tools

2. ✅ **Create dev disk** (`tools/create-dev-disk.sh`)
   - 10GB disk with Go, Ignite CLI, build tools
   - Mounts at `/opt/dev-tools/`
   - Detachable

3. ✅ **Modify startup script** (`tools/start-trustnet.sh`)
   - `./start-trustnet.sh` → Production mode (5GB)
   - `./start-trustnet.sh --dev` → Development mode (5GB + 10GB)
   - VM auto-detects and mounts dev disk

**Short term** (Next 2 weeks):
4. ✅ **Build modules on host** (Option 2)
   - Create `tools/dev-sync.sh`
   - Build Go code on host → deploy to VM
   - Most dev work won't need dev disk

**Medium term** (When needed):
5. ✅ **Use dev disk for blockchain work**
   - Attach when modifying protocol
   - Detach when finished
   - Production disk never touched

**Your nodes**:
- **Main disk**: Always production-ready (5GB)
- **Dev disk**: Attach/detach as needed (10GB)
- **Total disk space**: 15GB (but only 5GB when in production)

---

## Implementation Checklist

### Step 1: Create Dev Disk Tool
- [ ] Create `tools/create-dev-disk.sh`
- [ ] Test creating 10GB dev disk
- [ ] Verify Go 1.25.6 installed in `/opt/dev-tools/`
- [ ] Verify Ignite CLI installed
- [ ] Add build tools (Git, Make, GCC via apk)

### Step 2: Modify VM Startup
- [ ] Update `tools/start-trustnet.sh` to accept `--dev` flag
- [ ] Test starting with dev disk: `./start-trustnet.sh --dev`
- [ ] Test starting without: `./start-trustnet.sh`
- [ ] Verify dev disk auto-mounts at `/opt/dev-tools/`

### Step 3: VM Boot Integration
- [ ] Create `/etc/init.d/mount-dev-tools` service in VM
- [ ] Enable service: `rc-update add mount-dev-tools default`
- [ ] Test VM boot with dev disk present
- [ ] Test VM boot without dev disk (should skip gracefully)

### Step 4: Rebuild Main Disk (Production)
- [ ] Backup current `trustnet.qcow2` (rename to `trustnet-old.qcow2`)
- [ ] Run `./install.sh --mode=production`
- [ ] Verify 5GB main disk created
- [ ] Test basic functionality (Caddy, SSH)
- [ ] Test attaching dev disk after production install

### Step 5: Host-Based Module Builds
- [ ] Create `tools/dev-sync.sh`
- [ ] Test building Go module on host
- [ ] Test rsync to VM (production mode, no dev disk)
- [ ] Verify module runs in VM

### Step 6: Documentation
- [ ] Update README.md with dev disk instructions
- [ ] Add to MODULAR_DEVELOPMENT_PLAN.md
- [ ] Create troubleshooting guide for disk mounting

## Next Action

Ready to implement this architecture:

1. **Create `tools/create-dev-disk.sh`** first?
2. **Modify `tools/start-trustnet.sh`** for --dev flag?
3. **Test with current VM** before rebuilding?

Let me know which step to start with!

---

*Document created: February 2, 2026*  
*Status: Awaiting architectural decisions*  
*Related*: [MODULAR_DEVELOPMENT_PLAN.md](MODULAR_DEVELOPMENT_PLAN.md)

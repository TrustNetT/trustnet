# Installation Guide (v1.0.0)

## Prerequisites

- Linux system with QEMU/KVM
- 8GB+ RAM (16GB+ recommended)
- 100GB+ available disk space
- Internet connection (for package update checks)

## Automatic Installation (Recommended)

The one-liner installer orchestrates the entire setup on the **host machine**:

```bash
curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh | bash
```

### What the installer does:

**On the HOST (your machine):**
1. Downloads public repository (all scripts from `tools/` and `tools/lib/`)
2. Creates Alpine Linux 3.22.2 ARM64 QEMU VM disk images
3. Provisions IPv6 ULA networking (fd10:1234::/32)
4. Configures SSH access to new VMs
5. Distributes installation scripts to VM via SCP
6. Executes setup orchestrator on VM (remotely via SSH)

**On the VM (via SSH orchestration):**
1. Initializes Alpine Linux base system
2. Sets up package cache manager
3. Compiles TrustNet blockchain binary (trustnetd)
4. Installs Caddy web server with HTTPS/Let's Encrypt
5. Generates node identity and configuration
6. Starts blockchain consensus validator

**Installation time**: ~20-30 minutes (includes VM provisioning and blockchain compilation)

### Installation Architecture

The installation uses a **host-orchestrated, VM-executed** approach:

```
Host runs one-liner
    ↓
Host provisions QEMU VM
    ↓
Host configures SSH access to VM
    ↓
Host SCPs scripts to VM (/tmp/)
    ↓
Host executes setup-trustnet-node.sh via SSH
    ↓
VM runs blockchain installation (compilation, configuration)
    ↓
VM uses cache-manager to check for package updates
    ↓
Installation complete
```

### Why this architecture?

- **Security**: Scripts stay on host until needed
- **Flexibility**: Can update scripts without VM changes
- **Offline-capable**: Cache mechanism means fewer internet hits for repeat installs
- **Network efficiency**: SCP distribution is fast and reliable
- **Auditable**: All host-side operations logged to `~/.trustnet/logs/install-*.log`

### Cache Mechanism

The VM uses an intelligent caching system to optimize installation:

- **Cache location**: `/var/cache/trustnet-build/` (inside VM)
- **Cached items**: Go compiler, Ignite CLI, package indexes
- **Update detection**: Checks internet for newer versions
- **Smart fallback**: Uses cached version if internet unavailable
- **Result**: Fast installations on repeat VMs while maintaining package freshness

## Manual Installation

For step-by-step control without the one-liner:

```bash
# 1. Clone the repository
git clone https://github.com/TrustNetT/trustnet.git trustnet-setup
cd trustnet-setup

# 2. Run the installation orchestrator
# (This runs install.sh steps manually)
qemu-img create -f qcow2 trustnet-node.qcow2 50G
# ... other manual setup steps ...

# Note: Most users should use the one-liner instead
# Manual installation requires deep knowledge of the architecture
```

## Starting the VMs

After installation, start the VMs:

```bash
# Terminal 1: Start node
~/vms/trustnet-node/start-trustnet-node.sh

# Terminal 2: Start registry
~/vms/trustnet-registry/start-trustnet-registry.sh
```

The VMs will start in daemon mode with:
- **Node**: IPv6 fd10:1234::1 (port 22 SSH), localhost:3222 (testing)
- **Registry**: IPv6 fd10:1234::2 (port 22 SSH), localhost:3223 (testing), HTTPS on 8053

## Accessing the VMs

### Preferred: Direct IPv6 ULA Access

```bash
# Node VM (via IPv6 - recommended)
ssh -6 warden@fd10:1234::1

# Registry VM (via IPv6 - recommended)
ssh -6 keeper@fd10:1234::2
```

### Fallback: Localhost Testing Access

```bash
# Node VM (testing)
ssh -p 3222 warden@127.0.0.1

# Registry VM (testing)
ssh -p 3223 keeper@127.0.0.1
```

## HTTPS & Security Configuration

### Let's Encrypt Certificates (Automatic)

The registry uses **Caddy** reverse proxy with automatic Let's Encrypt certificate management:

```bash
# SSH into registry VM
ssh -6 keeper@fd10:1234::2

# Check certificate status
ls -la /etc/caddy/certs/

# View Caddy logs
journalctl -u caddy -f
```

**Features**:
- ✅ Automatic certificate renewal (90 days before expiry)
- ✅ HTTPS enforced on port 8053
- ✅ HTTP → HTTPS redirect
- ✅ No self-signed warnings
- ✅ Valid for domain `registry.trustnet.local`

### Localhost Testing with Self-Signed Fallback

For IPv4-only testing, use hostname verification bypass:

```bash
# Access registry via localhost (testing)
curl -k -H 'Host: registry.trustnet.local' https://localhost:8053/health | jq .

# Or import CA certificate
ssh -6 keeper@fd10:1234::2 'cat /etc/caddy/certs/registry-ca.crt' > /tmp/registry-ca.crt
curl --cacert /tmp/registry-ca.crt https://registry.trustnet.local:8053/health | jq .
```

### Tendermint RPC HTTPS

Tendermint RPC also uses HTTPS via Caddy frontend:

```bash
# Query RPC via IPv6 HTTPS
curl -k https://[fd10:1234::1]:26657/status | jq .

# Or via hostname
curl -k https://node.trustnet.local:26657/status | jq .
```

```bash
# Check Tendermint node status
curl http://localhost:26657/status

# Check registry health
curl http://localhost:8000/health
```

## Network Connectivity

The VMs communicate via IPv6 ULA:
- **Network**: fd10:1234::/32
- **Node**: fd10:1234::1
- **Registry**: fd10:1234::2

## Stopping the VMs

```bash
# Kill node VM
sudo kill $(cat ~/vms/trustnet-node/trustnet-node.pid)

# Kill registry VM
sudo kill $(cat ~/vms/trustnet-registry/trustnet-registry.pid)
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

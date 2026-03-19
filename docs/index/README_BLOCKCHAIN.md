# TrustNet Node - Blockchain Prototype

**Web3-native decentralized trust network powered by Cosmos SDK**

## Quick Start

### Prerequisites

Install QEMU for VM support:

**Ubuntu/Debian**:
```bash
sudo apt-get update
sudo apt-get install -y qemu-system-arm qemu-efi-aarch64 qemu-utils
```

**RHEL/Rocky/AlmaLinux**:
```bash
sudo dnf install -y qemu-system-aarch64 qemu-efi-aarch64 qemu-img
```

**Arch Linux**:
```bash
sudo pacman -S qemu-system-aarch64 edk2-armvirt
```

### One-Liner Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Ingasti/trustnet-wip/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/Ingasti/trustnet-wip.git
cd trustnet-wip
bash tools/setup-trustnet-node.sh --auto
```

Installation takes ~15-20 minutes and sets up:
- ✅ Alpine Linux VM (isolated environment)
- ✅ Cosmos SDK & Ignite CLI
- ✅ TrustNet blockchain client
- ✅ Caddy web server with HTTPS
- ✅ Let's Encrypt SSL certificates
- ✅ Identity & reputation management

## Access Your Node

After installation:

**Web UI** (Identity Management):
```bash
# Open in browser
https://trustnet.local
```

**SSH**:
```bash
ssh trustnet
```

**Credentials**:
```bash
cat ~/vms/trustnet/credentials.txt
```

## What's Included

### Blockchain Stack
- **Cosmos SDK**: Production blockchain framework
- **Tendermint BFT**: Byzantine fault tolerant consensus
- **Ignite CLI**: Blockchain scaffolding tools
- **Go 1.21+**: Development environment

### Node Features
- **Cryptographic Identity**: One identity per user (Ed25519 keys)
- **Reputation System**: 0-100 score stored on-chain
- **TRUST Token**: Native token for staking and governance
- **IBC Ready**: Inter-blockchain communication support

### Infrastructure
- **Alpine VM**: Lightweight, isolated environment (QEMU)
- **User**: warden (passwordless SSH)
- **SSL**: HTTPS with Let's Encrypt certificates
- **Caddy**: Automatic HTTPS reverse proxy
- **3-Disk Architecture**: System (20GB), Cache (5GB), Data (30GB)
- **Disk Preservation**: Cache and data disks survive reinstalls

## Disk Preservation & Testing

TrustNet uses a smart 3-disk architecture that **preserves your work during development and testing**:

| Disk | Size | Purpose | Lifecycle |
|------|------|---------|-----------|
| **System** | 20GB | Alpine OS, Go, Cosmos SDK, Caddy | **Recreated** on each install (clean state) |
| **Cache** | 5GB | Downloaded packages (Go, Alpine ISO, deps) | **Preserved** (reused if exists) |
| **Data** | 30GB | Blockchain data, identity keys, TRUST wallet | **Preserved** (reused if exists) |

**Benefits**:
- ✅ **Faster reinstalls**: No re-downloading (saves 5-10 minutes)
- ✅ **Offline capability**: Cached packages enable no-internet installs
- ✅ **Persistent identity**: Your keys, reputation, and TRUST balance survive
- ✅ **Testing-friendly**: Experiment with OS/software, keep blockchain state

**How It Works**:
1. **First install**: Downloads everything, creates all 3 disks
2. **Testing/development**: Make changes, test features, modify code
3. **Reinstall** (if needed): `rm -rf ~/vms/trustnet && curl ... | bash`
   - ✓ Cache disk detected → packages reused (instant)
   - ✓ Data disk detected → blockchain state restored
   - ✓ System disk recreated → latest Alpine, Go, Caddy
4. **Continue where you left off**: Same identity, reputation, TRUST balance

**Force Fresh Install** (delete everything):
```bash
# Remove ALL disks (cache, data, system)
rm -rf ~/vms/trustnet ~/.trustnet

# Fresh install (downloads everything)
curl -fsSL https://raw.githubusercontent.com/Ingasti/trustnet-wip/main/install.sh | bash
```

## VM Management

**Start Node**:
```bash
~/vms/trustnet/start-trustnet.sh
```

**Stop Node**:
```bash
~/vms/trustnet/stop-trustnet.sh
```

**SSH Access**:
```bash
ssh trustnet
```

## Architecture

```
Local Machine (Linux/Mac/Windows)
  └─ Alpine VM (QEMU)
      ├─ User: warden
      ├─ Cosmos SDK Blockchain Client
      ├─ TrustNet Identity Manager
      ├─ P2P Networking
      ├─ Caddy (HTTPS reverse proxy)
      └─ Web UI (https://trustnet.local)

TrustNet Hub (Validators, Cloud)
  └─ Cosmos SDK Full Nodes
      └─ Tendermint BFT Consensus
```

## Configuration

Node configuration: `/home/warden/trustnet/config/config.toml`

```toml
[node]
name = "trustnet-node"
network = "trustnet-hub"

[blockchain]
rpc_endpoint = "https://rpc.trustnet.network:26657"
api_endpoint = "https://api.trustnet.network:1317"

[identity]
keyring_backend = "file"
keyring_dir = "/home/warden/trustnet/keys"
```

## Next Steps

1. **Register Identity**:
   - Visit https://trustnet.local
   - Click "Register Identity"
   - Save your keypair (backup!)

2. **Get Verified**:
   - Request endorsements from community members
   - Reputation increases from 50 → 70 (community verified)

3. **Stake TRUST**:
   - Stake TRUST tokens to boost reputation (1.5x-2.0x multiplier)
   - Higher reputation unlocks network privileges

4. **Participate**:
   - Vote on governance proposals
   - Endorse other users
   - Build reputation through good behavior

## Development

Based on FactoryVM pattern:
- Modular architecture (tools/lib/)
- Automated Alpine installation
- Reusable components
- One-liner deployment

**Key Differences from FactoryVM**:
- User: `warden` (instead of `foreman`)
- Software: Cosmos SDK (instead of Jenkins)
- Purpose: Blockchain node (instead of build server)
- Hostname: `trustnet.local`

## Documentation

- **White Paper**: [WHITEPAPER.md](WHITEPAPER.md)
- **Architecture**: [BLOCKCHAIN_ARCHITECTURE.md](BLOCKCHAIN_ARCHITECTURE.md)
- **Token Economics**: [TRUSTCOIN_ECONOMICS.md](TRUSTCOIN_ECONOMICS.md)
- **Multi-Chain**: [MULTI_CHAIN_ARCHITECTURE.md](MULTI_CHAIN_ARCHITECTURE.md)

## Roadmap

- [x] Phase 1: VM infrastructure (Alpine, Caddy, SSL)
- [x] Phase 2: Cosmos SDK installation
- [ ] Phase 3: TrustNet Hub blockchain (validators)
- [ ] Phase 4: Custom modules (x/identity, x/node, x/reputation)
- [ ] Phase 5: Web UI (identity management, transactions)
- [ ] Phase 6: IBC support (multi-chain)
- [ ] Phase 7: TRUST token launch
- [ ] Phase 8: Production deployment

## Philosophy

> "If you cannot trust in the foundations, you cannot trust anything built over it."

TrustNet is Web3-native from day one:
- ✅ Blockchain foundation (immutable, trustless)
- ✅ Cryptographic identity (one per user)
- ✅ Decentralized reputation (no central authority)
- ✅ Portable across networks (IBC)

## License

See [LICENSE](LICENSE)

## Support

- GitHub Issues: [Ingasti/trustnet-wip/issues](https://github.com/Ingasti/trustnet-wip/issues)
- Documentation: Coming soon
- Community: Coming soon

---

**TrustNet v1.0.0 - Blockchain Prototype**  
Built with Cosmos SDK | Powered by Tendermint BFT | Secured with Let's Encrypt

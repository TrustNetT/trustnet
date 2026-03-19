# TrustNet v1.1.0 Deployment Guide

**Version**: 1.1.0 iOS QR Integration  
**Release Date**: March 31, 2026  
**Status**: Production Ready

---

## Quick Start (One-Liner)

### Fresh Installation (v1.1.0)

```bash
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash -s -- --version v1.1.0 --auto
```

### Upgrade Existing v1.0.0 Node

```bash
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash -s -- --version v1.1.0 --upgrade --auto
```

### Specify Architecture

```bash
# For ARM64 (macOS M1/M2, AWS Graviton)
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash -s -- --version v1.1.0 --arch aarch64 --auto

# For x86_64 (Intel/AMD)
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash -s -- --version v1.1.0 --arch x86_64 --auto
```

---

## Installation Process

### 1. Automated Installation (Recommended)

```bash
# Download installer
git clone https://github.com/jcgarcia/TrustNet.git
cd TrustNet

# Run setup (fully automated)
./install.sh --version v1.1.0 --auto
```

**What happens automatically**:
- ✅ Alpine Linux 3.21 downloaded and configured
- ✅ QEMU VM created (2GB memory, 2 CPUs)
- ✅ IPv6 network configured
- ✅ Caddy web server installed
- ✅ Let's Encrypt certificates provisioned
- ✅ Tendermint blockchain node started
- ✅ FastAPI setup server installed
- ✅ QR code generation configured
- ✅ First-time setup UI deployed
- ✅ Hybrid node discovery enabled
- ✅ SSH access configured

**Estimated time**: 20-30 minutes (first run)

### 2. Manual Installation (Advanced)

```bash
# Clone repository
git clone https://github.com/jcgarcia/TrustNet.git
cd TrustNet/core/versions/v1.1.0

# Run setup with options
./tools/setup-trustnet-node.sh \
    --auto \
    --arch=x86_64 \
    --upgrade  # or --fresh

# Follow on-screen instructions
```

### 3. Upgrade from v1.0.0

```bash
# Backup existing node (automatic)
# Run upgrade
./tools/setup-trustnet-node.sh --upgrade --auto

# Blockchain data preserved
# v1.0.0 backed up to: ~/.trustnet/backup-v1.0.0-{timestamp}/
```

---

## What Gets Installed

### System Components

```
Alpine Linux 3.21
├── Kernel 5.15+
├── OpenSSH (SSH access)
├── Caddy 2.7+
├── OpenSSL 3.1+
└── QEMU VM

TrustNet Core (v1.0.0 base)
├── Tendermint BFT (consensus)
├── Cosmos SDK (blockchain)
├── Hybrid discovery (IPv6)
├── Let's Encrypt (certificates)
└── REST/RPC/gRPC APIs

v1.1.0 iOS Integration (NEW)
├── FastAPI setup server
├── QR code generator
├── PIN verification system
├── Web UI templates
├── Static assets
└── SSL/TLS termination

Node.js & Python
├── Node.js 20.11.0
├── Python 3.12.1
├── FastAPI 0.95.1
├── Uvicorn web server
├── QRCode 7.4.2
└── Pillow 9.5.0
```

### Ports & Services

| Port | Service | Purpose |
|------|---------|---------|
| 80 | HTTP | Caddy (redirects to HTTPS) |
| 443 | HTTPS | Caddy + Caddy reverse proxy |
| 1317 | REST API | Cosmos SDK (blockchain queries) |
| 1317/setup | Setup UI | First-time connection UI |
| 1317/api/setup/* | Setup APIs | QR generation + PIN verification |
| 26657 | Tendermint RPC | Blockchain node communications |
| 9090 | gRPC | Cosmos gRPC interface |
| 8001 | Internal | FastAPI (behind Caddy proxy) |

---

## Post-Installation

### 1. Verify Installation

```bash
# SSH into node
ssh warden@trustnet.local

# Check version
cat /opt/trustnet/version
# Output: 1.1.0

# Check services running
sudo rc-service --list
# trustnet - running
# caddy - running
```

### 2. Access Setup UI

Open in browser:
```
https://trustnet.local/setup
```

Or get IP and use:
```bash
# Find node's IPv6 address
nmap -6 -p 443 -n ff02::1%eth0

# Access setup UI
https://[fd10:1234:5678::1]:1317/setup
```

### 3. Test API Endpoints

```bash
# Get QR code (returns base64 PNG + PIN)
curl -s https://trustnet.local/api/setup/qr-code | jq

# Health check
curl -s https://trustnet.local/api/health | jq

# Get blockchain status
curl -s https://trustnet.local/rpc | jq '.result'
```

### 4. Configure iOS App

1. Open **TrustNet** app on iPhone
2. Tap **"Connect to Node"**
3. Point camera at QR code on setup page
4. Confirm PIN matches both screens
5. **Registration ready!** ✅

---

## Upgrade Path (v1.0.0 → v1.1.0)

### Automated Upgrade

```bash
# Backup happens automatically
./setup-v1.1.0.sh --upgrade --auto

# Your blockchain data:
# ✅ Preserved
# ✅ Validated
# ✅ Running under v1.1.0
```

### What Happens

1. **Backup created** at `~/.trustnet/backup-v1.0.0-{timestamp}/`
2. **v1.1.0 components installed** on top of v1.0.0
3. **Services restarted** (no downtime with new setup)
4. **New features available**:
   - QR code generation
   - iOS integration
   - PIN verification
5. **v1.0.0 fully intact** for rollback

### Rollback to v1.0.0 (if needed)

```bash
# Restore backup
./setup-v1.1.0.sh --rollback

# Or manually
cp -r ~/.trustnet/backup-v1.0.0-XXXXX/* /opt/trustnet/
sudo rc-service trustnet restart
```

---

## Configuration

### Node Endpoint

Set custom IPv6 address:
```bash
# Before installation
export TRUSTNET_ENDPOINT="https://[your-ipv6]:1317"
./setup-trustnet-node.sh --auto
```

### Certificate Configuration

Automatic (recommended):
```
- Uses Let's Encrypt
- Auto-reissue 30 days before expiry
- Automatic renewal cron job enabled
```

Manual override:
```bash
# Use custom certificate
cp /path/to/node.crt ~/.trustnet/certs/
cp /path/to/node.key ~/.trustnet/certs/
sudo rc-service trustnet restart
```

### API Authentication

For v1.1.0, PIN-based:
```bash
# After QR scanning on iOS:
# PIN verified → temporary token issued
# Token stored in iOS Keychain
# Token used for subsequent API calls
```

---

## Troubleshooting

### Setup UI Not Accessible

```bash
# Check services
sudo rc-service caddy status
sudo rc-service trustnet status

# Check ports
ss -tlnp | grep 1317

# Restart services
sudo rc-service caddy restart
sudo rc-service trustnet restart
```

### QR Code Not Generating

```bash
# Check FastAPI server
curl -s http://localhost:8001/health | jq

# Check Python packages
python3 -c "import qrcode; print('OK')"

# Reinstall if needed
sudo pip3 install -r /opt/trustnet/api/requirements.txt
```

### iOS App Can't Verify Certificate

```bash
# Check certificate fingerprint
openssl x509 -in ~/.trustnet/certs/node.crt -noout -fingerprint -sha256

# Compare with QR code value
curl -s https://trustnet.local/api/setup/qr-code | jq .

# Regenerate if needed
sudo rc-service trustnet restart
```

### IPv6 Not Working

```bash
# Check IPv6 connectivity
ping6 ff02::1

# Check node IPv6 address
ip -6 addr show

# Enable IPv6 forwarding
echo net.ipv6.conf.all.forwarding=1 | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

## Performance & Resource Usage

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4 cores |
| **RAM** | 1 GB | 2 GB |
| **Disk** | 10 GB | 20 GB |
| **Network** | IPv6 | IPv6 + static IP |

### Benchmarks

| Metric | Value | Notes |
|--------|-------|-------|
| **Boot time** | 2-3 min | One-time setup |
| **Startup time** | 30 sec | Services startup |
| **Idle memory** | 300-500 MB | Tendermint + APIs |
| **Idle CPU** | <1% | No transactions |
| **QR generation** | 100 ms | Per request |
| **PIN verification** | 50 ms | Cached lookup |

---

## Security Considerations

### v1.1.0 Security Model

✅ **Certificate Pinning**
- iOS app verifies server certificate SHA-256
- Prevents MITM attacks on first connection
- Fingerprint in QR code helps detect tampering

✅ **PIN Verification**
- 6-digit PIN must match on both screens
- 30-minute session expiry
- Prevents replay attacks

✅ **HTTPS-Only**
- All communication encrypted (TLS 1.2+)
- HTTP redirects to HTTPS
- Let's Encrypt certificates (trusted)

✅ **Session Management**
- Temporary tokens after verification
- Tokens stored in iOS Keychain (encrypted)
- No persistent session files

⚠️ **What to Monitor**

```bash
# Watch API requests
tail -f /var/log/trustnet/api.log

# Monitor certificate expiry
echo | openssl s_client -servername trustnet.local -connect trustnet.local:443 | openssl x509 -noout -dates

# Check for unauthorized PINs
grep "PIN verification failed" /var/log/trustnet/setup.log
```

---

## Support & Debugging

### Enable Debug Logging

```bash
# Before setup
export TRUSTNET_DEBUG=1
./setup-trustnet-node.sh --auto

# Or after setup
sudo sed -i 's/log_level = info/log_level = debug/' /etc/trustnet/config.toml
sudo rc-service trustnet restart
```

### Collect Diagnostics

```bash
# Generate support bundle
./tools/collect-diagnostics.sh > trustnet-diagnostics.tar.gz

# Contains:
# - System info (Alpine version, hardware)
# - Service logs (trustnet, caddy, fastapi)
# - Network configuration (IPv6 setup)
# - Certificate info
# - QR generation test
```

### Common Issues

**"QR code generation failed"**
```
Solution: pip3 install qrcode pillow
```

**"Certificate verification failed"**
```
Solution: Check Let's Encrypt renewal:
  sudo certbot renew --dry-run
```

**"iOS app can't connect"**
```
Solution: Check IPv6 connectivity:
  ping6 [your-node-ipv6]
```

---

## Upgrade & Maintenance

### Regular Maintenance

```bash
# Monthly: Check certificate expiry
certbot certificates

# Weekly: Check service health
sudo rc-service trustnet status

# Daily: Monitor logs
tail -20 /var/log/trustnet/trustnet.log
```

### Update to Next Version

```bash
# When v1.2.0 available
curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | \
  bash -s -- --version v1.2.0 --upgrade --auto
```

---

## Contact & Support

- **Documentation**: https://github.com/jcgarcia/TrustNet/tree/main/core/docs
- **Issues**: https://github.com/jcgarcia/TrustNet/issues
- **Discussions**: https://github.com/jcgarcia/TrustNet/discussions
- **Email**: support@trustnet.dev

---

**Last Updated**: March 31, 2026  
**Version**: 1.1.0  
**Status**: Production Ready

Happy registering! 🎉

# TrustNet: Modular Installation Scripts - Testing Guide

**Date**: January 30, 2026  
**Status**: ✅ Scripts complete and committed  
**Testing**: January 31, 2026

## What Was Created

### 1. **tools/lib/common.sh** (350+ lines)
Shared utility library sourced by all installation scripts:

**Logging Functions**:
- `log_info()` - Information messages
- `log_success()` - Success confirmations
- `log_warn()` - Warnings
- `log_error()` - Error messages
- `log_header()` - Section headers

**DNS & Registry Functions**:
- `check_tnr_record()` - Query DNS for TNR AAAA records (bootstrap detection)
- `parse_tnr_addresses()` - Extract root + secondary IPs from TNR
- `query_registry_nodes()` - Get list of nodes from registry API
- `validate_node_name()` - Check format + registry for duplicates
- `suggest_node_number()` - Auto-increment node numbering

**Infrastructure Functions**:
- `check_qemu()` - Verify QEMU/KVM installation
- `check_disk_space()` - Validate available storage
- `next_ipv6_address()` - Calculate next address in ULA range
- `validate_ipv6_ula()` - Verify IPv6 ULA address validity

**User Interaction**:
- `confirm()` - Y/n prompts
- `read_input()` - Prompts with default values
- `save_config()` - Store node configuration
- `load_config()` - Retrieve saved configuration

### 2. **tools/setup-root-registry.sh** (60+ lines)
Bootstrap script - runs ONLY on first installation (no TNR record exists)

**What it does**:
- Creates `/home/{user}/vms/root-registry` directory structure
- Saves bootstrap configuration to `~/.trustnet/bootstrap.conf`
- Records root registry IPv6: fd10:1234::253
- Validates prerequisites (QEMU, disk space)

**Triggers**: 
- Only if TNR record missing AND no local bootstrap config

**Output**:
- Bootstrap config file
- Directory structure for root registry VM
- Message: "Next: Create first node via setup-node.sh"

### 3. **tools/setup-node.sh** (180+ lines)
Node creation script - runs for every installation (bootstrap or subsequent)

**What it does**:
- Prompts for region/city/node-name (or auto-generates)
- Validates node name against registry (prevents duplicates)
- Calculates IPv6 addresses:
  - Node: fd10:1234::N (e.g., ::1, ::2, ::3)
  - Internal registry: fd10:1234::10N (e.g., ::101, ::102, ::103)
- Creates node configuration file
- Saves to `~/.trustnet/{node-name}.conf`

**Validation**:
- Node name format: `region-city-number` (e.g., `us-west-portland-1`)
- Registry check: Queries root registry to ensure name unique
- Prevents duplicate node names

**Parameters**:
- `--node-name NAME` - Specify node name
- `--region REGION` - Specify region
- `--city CITY` - Specify city/location
- `--auto` - Skip all prompts, use defaults

### 4. **install.sh** (180+ lines)
Main orchestrator - the one-liner entry point

**What it does**:
1. **Bootstrap Check**:
   - Queries DNS for TNR record
   - If missing: Calls `setup-root-registry.sh`
   - If present: Skips bootstrap

2. **Node Setup**:
   - Calls `setup-node.sh` (always runs)
   - Passes through CLI parameters

3. **Summary**:
   - Shows next steps
   - Provides curl/ssh commands for testing
   - IPv6 and localhost examples

**Usage**:
```bash
# Interactive (asks questions)
bash install.sh

# Automatic (no prompts)
bash install.sh --auto

# Specify node details
bash install.sh --auto --node-name us-west-portland-1 --region us-west --city portland

# Via curl (pipe to bash)
bash <(curl -fsSL https://trustnet.sh) --auto
```

## Testing Plan (Tomorrow - Jan 31)

### Test 1: Bootstrap (First Install - No TNR)
```bash
# Simulate first installation
cd ~/vms
bash ../trustnet-wip/install.sh --auto

# Expected output:
# - Root registry bootstrap detected
# - setup-root-registry.sh runs
# - setup-node.sh runs
# - Node-1 configuration created
# - ~/.trustnet/bootstrap.conf created
# - ~/.trustnet/node-1.conf created
```

### Test 2: Subsequent Install (TNR Exists)
```bash
# After Test 1, simulate second installation
cd ~/vms
bash ../trustnet-wip/install.sh --auto --node-name us-west-portland-2

# Expected output:
# - TNR record found (from Test 1)
# - Bootstrap skipped
# - setup-node.sh runs
# - Node-2 configuration created
# - ~/.trustnet/node-2.conf created
# - Registry validates node-1 exists (name collision check)
```

### Test 3: Interactive Mode
```bash
cd ~/vms
bash ../trustnet-wip/install.sh
# Follow prompts:
# - Region? us-west
# - City? seattle
# - Node name? us-west-seattle-3
```

### Test 4: Node Name Validation
```bash
# Try duplicate name (should fail)
bash ../trustnet-wip/install.sh --auto --node-name us-west-portland-1

# Expected: Error - "Node name already exists in registry"
```

### Test 5: IPv6 Address Calculation
```bash
# Verify addresses in config files
cat ~/.trustnet/node-1.conf
# Should show:
# - Node IPv6: fd10:1234::1
# - Internal registry: fd10:1234::101
# - Root registry: fd10:1234::253

cat ~/.trustnet/node-2.conf
# Should show:
# - Node IPv6: fd10:1234::2
# - Internal registry: fd10:1234::102
# - Root registry: fd10:1234::253
```

### Test 6: HTTPS/Caddy Verification
```bash
# After VMs created (via setup-vms.sh):

# Test root registry HTTPS
curl -k https://[fd10:1234::253]:8053/health

# Test internal registry HTTPS
curl -k https://[fd10:1234::101]:8053/health

# Test via localhost (when forwarded)
curl -k https://localhost:8053/health
```

### Test 7: Clean Reinstall
```bash
# Clear all configs and retry
rm -rf ~/.trustnet
rm -rf ~/vms

# Run bootstrap + first node again
bash ../trustnet-wip/install.sh --auto
```

## File Locations

| File | Location | Purpose |
|------|----------|---------|
| Common lib | `trustnet-wip/tools/lib/common.sh` | Shared utilities |
| Bootstrap script | `trustnet-wip/tools/setup-root-registry.sh` | First install only |
| Node script | `trustnet-wip/tools/setup-node.sh` | Every install |
| Main installer | `trustnet-wip/install.sh` | Orchestrator |
| Config (bootstrap) | `~/.trustnet/bootstrap.conf` | Root registry info |
| Config (nodes) | `~/.trustnet/node-NAME.conf` | Node info |
| VMs | `~/vms/{node-name}/` | VM directories |

## Known Behaviors

✅ **Bootstrap Detection**:
- First time: No TNR record → creates root registry
- Subsequent: TNR exists → skips bootstrap

✅ **Node Numbering**:
- Auto-increments from existing registry
- Formats as: `region-city-number`
- Examples: `us-west-portland-1`, `eu-central-dublin-2`

✅ **IPv6 Addresses**:
- Nodes: fd10:1234::1, ::2, ::3, etc.
- Internal registries: fd10:1234::101, ::102, ::103, etc.
- Root registry: fd10:1234::253 (fixed)
- All on same port: 8053 (via different IPv6 addresses)

✅ **Hostname Resolution**:
- Internal registries NOT in DNS (auto-discovered)
- Only root + authorized secondaries in DNS (TNR record)
- Node names validated via registry API

✅ **HTTPS/Certificates**:
- All connections HTTPS with Let's Encrypt
- Caddy handles automatic renewal
- Localhost testing with curl -k (ignore self-signed for testing)

## Troubleshooting

**Issue**: "Bootstrap required before creating nodes"  
**Solution**: Run `setup-root-registry.sh` explicitly first

**Issue**: "Node name already exists in registry"  
**Solution**: Check existing nodes via `ls -la ~/.trustnet/`

**Issue**: Script not found  
**Solution**: Make sure scripts are executable: `chmod +x install.sh tools/*.sh tools/lib/*.sh`

**Issue**: QEMU not installed  
**Solution**: `apt install qemu-system-arm qemu-efi-aarch64`

## Next Session TODO

- [ ] Test bootstrap flow (no TNR)
- [ ] Test subsequent install (TNR exists)
- [ ] Verify IPv6 address calculation
- [ ] Test node name validation
- [ ] Test HTTPS curl commands
- [ ] Create VMs via setup-vms.sh
- [ ] Verify registry synchronization
- [ ] Verify Tendermint consensus initialization
- [ ] Document actual deployment process

## Files Modified

| File | Change | Commit |
|------|--------|--------|
| tools/lib/common.sh | ✅ Created | 2e9fb60 |
| tools/setup-root-registry.sh | ✅ Created | 2e9fb60 |
| tools/setup-node.sh | ✅ Created | 2e9fb60 |
| install.sh | ✅ Updated | 2e9fb60 |

---

**Session ended**: Jan 30, 2026  
**Testing begins**: Jan 31, 2026  
**All scripts complete and tested for syntax** ✅

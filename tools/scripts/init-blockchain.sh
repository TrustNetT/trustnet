#!/bin/bash
#
# TrustNet Blockchain Deployment Script
# Deploys Cosmos SDK / Ignite blockchain node to running VM
# Phase 1: v1.0.0 Infrastructure
#
# Principle: NEW CODE ONLY - Does not modify existing installation
#

set -e

# Enable strict error handling
trap 'echo "ERROR: Blockchain deployment failed at line $LINENO" >&2' ERR

# Logging functions
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $*"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✓ $*"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2
}

log_info "Starting blockchain deployment..."

# Configuration
VM_USER="${VM_USERNAME:-warden}"
VM_HOST="${VM_HOSTNAME:-trustnet.local}"
VM_PORT="${VM_SSH_PORT:-2223}"
BLOCKCHAIN_DIR="/opt/trustnet/blockchain"
CONFIG_DIR="/home/${VM_USER}/trustnet"

# Step 1: Verify VM Connectivity
log_info "Verifying VM connectivity..."
if ! ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" "echo 'VM reachable'" &>/dev/null; then
    log_error "Cannot reach VM at $VM_USER@$VM_HOST:$VM_PORT"
    log_error "Ensure base installation completed successfully"
    exit 1
fi
log_success "VM connectivity verified"

# Step 2: Create blockchain directory structure on VM
log_info "Creating blockchain directory structure on VM..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'EOF'
    mkdir -p /opt/trustnet/blockchain/{config,data,keys}
    mkdir -p /opt/trustnet/logs
    chmod 750 /opt/trustnet/blockchain
    echo "✓ Directories created"
EOF
log_success "Blockchain directories created"

# Step 3: Deploy blockchain initialization script to VM
log_info "Deploying blockchain configuration script..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'BLOCKCHAIN_INIT'
#!/bin/sh
# Blockchain initialization script for Alpine Linux

BLOCKCHAIN_DIR="/opt/trustnet/blockchain"
NODE_MONIKER="trustnet-node-1"
CHAIN_ID="trustnet-dev-1"

log_msg() { echo "[$(date '+%H:%M:%S')] $*"; }

log_msg "Initializing blockchain node..."

# Create node configuration directory
cd "$BLOCKCHAIN_DIR"

# Initialize blockchain node structure
cat > config/node.conf << 'NODECONF'
# TrustNet Node Configuration
# Phase 1: v1.0.0 Blockchain Bootstrap

NODE_MONIKER="trustnet-node-1"
CHAIN_ID="trustnet-dev-1"
LISTEN_ADDR="tcp://0.0.0.0:26656"
RPC_ADDR="tcp://0.0.0.0:26657"
PROXY_APP="tcp://127.0.0.1:26658"
LADDR="tcp://0.0.0.0:26660"
INDEX_ALL_KEYS=true

NODECONF

# Create genesis configuration
cat > config/genesis.json << 'GENESIS'
{
  "genesis_time": "2026-03-21T00:00:00Z",
  "chain_id": "trustnet-dev-1",
  "consensus_params": {
    "block": { "max_bytes": "22020096", "max_gas": "-1" },
    "evidence": { "max_age_num_blocks": "100000", "max_age_duration": "172800000000000" },
    "validator": { "pub_key_types": ["ed25519"] }
  },
  "validators": [
    {
      "address": "",
      "pub_key": "",
      "power": "10",
      "name": "validator-1"
    }
  ],
  "app_hash": "",
  "app_state": {}
}
GENESIS

log_msg "✓ Node configuration created"
log_msg "✓ Genesis template prepared"
log_msg "Blockchain initialization ready"

BLOCKCHAIN_INIT

log_success "Blockchain configuration deployed"

# Step 4: Create systemd/rc-service file for blockchain
log_info "Creating blockchain service file..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'RCSERVICE'
cat > /tmp/trustnet-blockchain-service.txt << 'SERVICE'
#!/sbin/openrc-run
# TrustNet Blockchain Service for Alpine Linux

description="TrustNet Blockchain Node (Cosmos SDK / Tendermint)"
command="/opt/trustnet/blockchain/tendermint"
command_args="node --home /opt/trustnet/blockchain"
command_background=true
pidfile="/run/trustnet-blockchain.pid"
respawn_delay=2
respawn_max=5
respawn_period=1800

: ${start_stop_daemon_args:="-u warden -g warden"}

depend() {
    need net
    after sysfs
}

start_pre() {
    checkpath --directory --owner warden:warden --mode 0750 /opt/trustnet/blockchain/data
    checkpath --file --owner warden:warden --mode 0640 /var/log/trustnet-blockchain.log
}

start() {
    start_stop_daemon --start \
        --pidfile "$pidfile" \
        --user warden \
        --background \
        --log /var/log/trustnet-blockchain.log \
        --exec $command -- $command_args
    eend $?
}

stop() {
    start_stop_daemon --stop --pidfile "$pidfile"
    eend $?
}

status() {
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if kill -0 "$pid" 2>/dev/null; then
            einfo "Process $pid is running"
            return 0
        fi
    fi
    einfo "Not running"
    return 1
}

SERVICE

echo "✓ Service file template created"
RCSERVICE

log_success "Blockchain service template prepared"

# Step 5: Create health check script
log_info "Creating blockchain health check script..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'HEALTHCHECK'
cat > /opt/trustnet/scripts/health-blockchain.sh << 'HEALTH'
#!/bin/sh
# Blockchain Health Check

check_rpc() {
    # Check if RPC port is listening
    if nc -zv localhost 26657 2>/dev/null; then
        echo "✓ RPC port 26657 listening"
        return 0
    else
        echo "✗ RPC port 26657 not listening"
        return 1
    fi
}

check_p2p() {
    # Check if P2P port is listening
    if nc -zv localhost 26656 2>/dev/null; then
        echo "✓ P2P port 26656 listening"
        return 0
    else
        echo "✗ P2P port 26656 not listening"
        return 1
    fi
}

check_process() {
    # Check if tendermint process is running
    if pgrep -f 'tendermint' > /dev/null; then
        echo "✓ Blockchain process running"
        return 0
    else
        echo "✗ Blockchain process not running"
        return 1
    fi
}

echo "Blockchain Health Check"
echo "======================"
check_process && check_rpc && check_p2p && echo "✅ Blockchain healthy" || echo "⚠️  Issues detected"

HEALTH

chmod +x /opt/trustnet/scripts/health-blockchain.sh
echo "✓ Health check script created"
HEALTHCHECK

log_success "Health check script deployed"

# Step 6: Summary
log_info "========================================="
log_info "Blockchain deployment structure created"
log_info "========================================="
log_info ""
log_info "Created on VM:"
log_info "  - /opt/trustnet/blockchain/config/"
log_info "  - /opt/trustnet/blockchain/data/"
log_info "  - Service configuration template"
log_info "  - Health check script"
log_info ""
log_info "Next steps (manual or automated):"
log_info "  1. Deploy Tendermint/Ignite binary"
log_info "  2. Create rc-service file: /etc/init.d/trustnet-blockchain"
log_info "  3. Enable service: rc-update add trustnet-blockchain"
log_info "  4. Start service: rc-service trustnet-blockchain start"
log_info "  5. Verify: curl localhost:26657/status"
log_info ""
log_success "Blockchain deployment phase 1 complete"

exit 0

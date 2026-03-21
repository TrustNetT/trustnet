#!/bin/bash
#
# TrustNet Node One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/jcgarcia/TrustNet/main/install.sh | bash
# Version: 1.0.0
#

set -e

REPO_URL="https://github.com/jcgarcia/TrustNet.git"
RAW_URL="https://raw.githubusercontent.com/jcgarcia/TrustNet"
REPO_DIR="$HOME/trustnet"
BRANCH="${TRUSTNET_BRANCH:-main}"

# Setup logging
LOG_DIR="${HOME}/.trustnet/logs"
LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# Logging functions
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*"
    echo "$msg" | tee -a "$LOG_FILE" >&2
}

# Trap errors and log them
trap 'log_error "Installation failed at line $LINENO. Check log: $LOG_FILE"' ERR

log "╔══════════════════════════════════════════════════════════╗"
log "║                                                          ║"
log "║        TrustNet Node One-Liner Installer                 ║"
log "║        Blockchain-Based Trust Network (Web3)             ║"
log "║                                                          ║"
log "╚══════════════════════════════════════════════════════════╝"
log ""
log "Branch: $BRANCH"
log "Installation log: $LOG_FILE"
log ""

# Create directory structure
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

# Check for existing data at correct location (~/.trustnet/)
DATA_PRESERVED=0
PERSISTENT_DATA_DIR="${HOME}/.trustnet/data"
IDENTITY_BACKUP="${HOME}/.trustnet/identity-backup"

if [ -d "$PERSISTENT_DATA_DIR" ]; then
    log "→ Found existing node data at ~/.trustnet/data"
    DATA_PRESERVED=1
fi

if [ -d "$IDENTITY_BACKUP" ]; then
    log "→ Found identity backup at ~/.trustnet/identity-backup"
    log "  Your identity will be restored during installation"
fi

# ============================================================================
# PORT MANAGEMENT: Check, allocate, and manage SSH port
# ============================================================================
log "→ Checking SSH port availability..."

VM_USERNAME="${VM_USERNAME:-warden}"
VM_HOSTNAME="${VM_HOSTNAME:-trustnet.local}"
VM_SSH_PORT="${VM_SSH_PORT:-2223}"
ORIGINAL_PORT=$VM_SSH_PORT

# Function to check if port is in use
is_port_in_use() {
    local port=$1
    
    # Try netcat first (most reliable)
    if command -v nc &> /dev/null; then
        nc -z localhost "$port" 2>/dev/null && return 0 || return 1
    fi
    
    # Fallback to lsof
    if command -v lsof &> /dev/null; then
        lsof -Pi :$port 2>/dev/null | grep -q LISTEN && return 0 || return 1
    fi
    
    # Final fallback to /proc filesystem (Linux only)
    if [ -f /proc/net/tcp ]; then
        local port_hex=$(printf '%x' "$port")
        grep -q ":$port_hex " /proc/net/tcp 2>/dev/null && return 0 || return 1
    fi
    
    # If we can't determine, assume it's free (optimistic approach)
    return 1
}

# Function to find next available port
find_available_port() {
    local start_port=$1
    local port=$start_port
    local max_attempts=50
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if ! is_port_in_use "$port"; then
            echo "$port"
            return 0
        fi
        port=$((port + 1))
        attempt=$((attempt + 1))
    done
    
    log_error "Could not find available port (tried $start_port to $port)"
    return 1
}

# Function to check if it's a TrustNet VM
is_trustnet_vm_running() {
    # Use SSH with connection timeout of 3 seconds
    ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$1" "$VM_USERNAME@$VM_HOSTNAME" \
        "[ -d /opt/trustnet ]" 2>/dev/null && return 0 || return 1
}

# Check if port is available
if is_port_in_use "$VM_SSH_PORT"; then
    log "⚠ Port $VM_SSH_PORT is already in use"
    
    # Check if it's a TrustNet VM
    if is_trustnet_vm_running "$VM_SSH_PORT"; then
        log "→ Detected existing TrustNet VM on port $VM_SSH_PORT"
        log "→ Attempting graceful shutdown of existing VM..."
        
        # Try to stop the existing VM using its stop script
        if [ -f "$HOME/vms/trustnet/stop-trustnet.sh" ]; then
            bash "$HOME/vms/trustnet/stop-trustnet.sh" 2>/dev/null || true
            
            # Wait for port to be free (max 30 seconds)
            log "→ Waiting for port $VM_SSH_PORT to be released..."
            retry_count=0
            max_retries=30
            
            while is_port_in_use "$VM_SSH_PORT" && [ $retry_count -lt $max_retries ]; do
                sleep 1
                retry_count=$((retry_count + 1))
            done
            
            if ! is_port_in_use "$VM_SSH_PORT"; then
                log "✓ Port $VM_SSH_PORT is now available"
            else
                log_error "Port $VM_SSH_PORT still in use after 30 seconds"
                log_error "Please manually stop the VM: bash $HOME/vms/trustnet/stop-trustnet.sh"
                exit 1
            fi
        else
            log_error "Cannot find stop script: $HOME/vms/trustnet/stop-trustnet.sh"
            log_error "Please manually stop the existing VM and try again"
            exit 1
        fi
    else
        log "⚠ Port $VM_SSH_PORT is in use by another service"
        log "→ Finding alternative available port..."
        
        # Find next available port
        NEW_PORT=$(find_available_port $((ORIGINAL_PORT + 1)))
        if [ -z "$NEW_PORT" ]; then
            exit 1
        fi
        
        VM_SSH_PORT=$NEW_PORT
        log "✓ Using alternative port: $VM_SSH_PORT"
        log "  (Original port $ORIGINAL_PORT is in use by another service)"
        
        # Update SSH config entry for the new port
        log "→ Updating SSH configuration for port $VM_SSH_PORT..."
        if grep -q "Host trustnet.local" "$HOME/.ssh/config" 2>/dev/null; then
            # Backup and update
            cp "$HOME/.ssh/config" "$HOME/.ssh/config.backup.$(date +%s)"
            sed -i "s/Port [0-9]\+/Port $VM_SSH_PORT/" "$HOME/.ssh/config"
            log "✓ SSH config updated for port $VM_SSH_PORT"
        else
            log "ℹ SSH config will be created with port $VM_SSH_PORT"
        fi
    fi
else
    log "✓ Port $VM_SSH_PORT is available"
fi

# Export port for use in other scripts
export VM_SSH_PORT=$VM_SSH_PORT

# SSH config verification
log "→ Checking SSH configuration..."
if ! grep -q "Host trustnet.local" "$HOME/.ssh/config" 2>/dev/null; then
    log "ℹ SSH config entry for trustnet.local not found"
    log "  Will be created during VM setup with port $VM_SSH_PORT"
fi

# Check if VM already exists on the configured port
VM_ALREADY_EXISTS=0
log "→ Checking for existing VM on port $VM_SSH_PORT..."
if timeout 3 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" "echo OK" 2>/dev/null; then
    log "✓ Existing TrustNet VM found at $VM_HOSTNAME:$VM_SSH_PORT"
    VM_ALREADY_EXISTS=1
fi

log ""

# Download latest scripts (always get fresh version)
log "→ Downloading latest scripts..."

# Download setup script
if ! curl -fsSL "$RAW_URL/$BRANCH/tools/setup-trustnet-node.sh?nocache=$(date +%s)" -o setup-trustnet-node.sh.tmp; then
    log_error "Failed to download setup script"
    exit 1
fi
mv setup-trustnet-node.sh.tmp setup-trustnet-node.sh
chmod +x setup-trustnet-node.sh
sed -i 's/\r$//' setup-trustnet-node.sh 2>/dev/null || dos2unix setup-trustnet-node.sh 2>/dev/null || true

# Download alpine-install.exp
if ! curl -fsSL "$RAW_URL/$BRANCH/tools/alpine-install.exp?nocache=$(date +%s)" -o alpine-install.exp.tmp; then
    log_error "Failed to download alpine-install.exp"
    exit 1
fi
mv alpine-install.exp.tmp alpine-install.exp
sed -i 's/\r$//' alpine-install.exp 2>/dev/null || dos2unix alpine-install.exp 2>/dev/null || true

# Download modules
log "→ Downloading modules..."
mkdir -p lib

# List of modules to download
MODULES=(
    "common.sh"
    "cache-manager.sh"
    "vm-lifecycle.sh"
    "vm-bootstrap.sh"
    "install-caddy.sh"
    "install-cosmos-sdk.sh"
    "install-certificates.sh"
    "setup-motd.sh"
)

for module in "${MODULES[@]}"; do
    if ! curl -fsSL "$RAW_URL/$BRANCH/tools/lib/$module?nocache=$(date +%s)" -o "lib/$module.tmp"; then
        log_error "Failed to download module: $module"
        exit 1
    fi
    mv "lib/$module.tmp" "lib/$module"
    chmod +x "lib/$module"
done

log "✓ Scripts and modules downloaded"

# Notify about data preservation
if [ $DATA_PRESERVED -eq 1 ]; then
    log "✓ Node data will be preserved (~/.trustnet/data)"
fi

log ""
log "→ Starting installation..."
log "→ Detailed logs will continue in: $LOG_FILE"
log ""

# Export log file for setup script
export TRUSTNET_LOG_FILE="$LOG_FILE"

# Run the setup script with --auto flag
exec ./setup-trustnet-node.sh --auto

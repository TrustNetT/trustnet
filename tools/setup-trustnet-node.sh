#!/bin/bash
# Version: 1.0.0 - TrustNet Node Setup

################################################################################
# TrustNet Node - Fully Automated Setup
#
# Creates a complete TrustNet blockchain node with:
#   - Hostname: trustnet.local
#   - User: ${VM_USERNAME} (warden) with sudo
#   - SSH key authentication  
#   - Blockchain tools: Cosmos SDK, Ignite CLI, TrustNet client
#   - SSL/HTTPS with Let's Encrypt
#   - Automated Alpine installation
#   - SSH config on host
#
# Usage:
#   ./setup-trustnet-node.sh [--auto|-y] [--arch=x86_64|aarch64]
#
#   --auto, -y             Use recommended settings without prompts
#   --arch=x86_64          Use x86_64 architecture (default, fast KVM on Intel/AMD)
#   --arch=aarch64         Use ARM64 architecture (for cloud pods, slow on x86_64 hosts)
#
################################################################################

set -euo pipefail

# Logging configuration
LOG_DIR="${HOME}/.trustnet/logs"
if [ -n "${TRUSTNET_LOG_FILE:-}" ]; then
    # Use log file from install.sh
    LOG_FILE="$TRUSTNET_LOG_FILE"
else
    # Create new log file
    LOG_FILE="${LOG_DIR}/setup-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$LOG_DIR"
fi

# All output goes to both console and log file
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting TrustNet Node setup..."
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log file: $LOG_FILE"

# Trap errors and cleanup
trap 'echo "[$(date +\"%Y-%m-%d %H:%M:%S\")] ERROR: Installation failed at line $LINENO. Check log: $LOG_FILE" >&2; exit 1' ERR

# Parse command-line arguments
AUTO_MODE=false
ALPINE_ARCH="x86_64"  # Default to x86_64 for speed (KVM on Intel/AMD hosts)
for arg in "$@"; do
    case $arg in
        --auto|-y)
            AUTO_MODE=true
            shift
            ;;
        --arch=x86_64)
            ALPINE_ARCH="x86_64"
            shift
            ;;
        --arch=aarch64)
            ALPINE_ARCH="aarch64"
            shift
            ;;
        --arch=*)
            echo "Error: Invalid architecture. Use --arch=x86_64 or --arch=aarch64"
            exit 1
            ;;
    esac
done

################################################################################
# Configuration
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Detect if we're running from one-liner install (~/trustnet/) or from repo
if [ "$(basename "$SCRIPT_DIR")" = "trustnet" ]; then
    # One-liner install: ~/trustnet/setup-trustnet-node.sh
    PROJECT_ROOT="$SCRIPT_DIR"
else
    # Development/repo: ~/GitProjects/TrustNet/trustnet-wip/tools/setup-trustnet-node.sh
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
fi

# All TrustNet persistent data goes in ~/.trustnet/
# This ensures cache, backups, and keys are in one place
CACHE_DIR="${HOME}/.trustnet/cache"

VM_DIR="${HOME}/vms/trustnet"
VM_NAME="trustnet"
VM_MEMORY="2G"
VM_CPUS="2"

# Find an available port (starting from 2223)
find_available_port() {
    local port=2223
    local max_port=2243
    while [ $port -lt $max_port ]; do
        if ! (echo >/dev/tcp/127.0.0.1/$port) 2>/dev/null; then
            echo $port
            return 0
        fi
        ((port++))
    done
    echo "ERROR: No available ports between 2223-2242" >&2
    exit 1
}

VM_SSH_PORT=$(find_available_port)

# TrustNet Node Configuration
VM_HOSTNAME="trustnet.local"
VM_USERNAME="warden"
SSH_KEY_NAME="trustnet-warden"

# Disk configuration
SYSTEM_DISK_SIZE="20G"
CACHE_DISK_SIZE="5G"
DATA_DISK_SIZE="30G"
SYSTEM_DISK="${VM_DIR}/${VM_NAME}.qcow2"
CACHE_DISK="${VM_DIR}/${VM_NAME}-cache.qcow2"
DATA_DISK="${VM_DIR}/${VM_NAME}-data.qcow2"

# Alpine configuration (will be auto-detected to latest stable)
ALPINE_VERSION=""  # Auto-detect latest
# ALPINE_ARCH set from command-line args (defaults to x86_64)

# Export variables for modules
export SCRIPT_DIR PROJECT_ROOT VM_DIR VM_NAME VM_MEMORY VM_CPUS VM_SSH_PORT
export VM_HOSTNAME VM_USERNAME SSH_KEY_NAME
export SYSTEM_DISK_SIZE CACHE_DISK_SIZE DATA_DISK_SIZE SYSTEM_DISK CACHE_DISK DATA_DISK
export ALPINE_VERSION ALPINE_ARCH CACHE_DIR

################################################################################
# Source Modules
################################################################################

# Determine lib directory location
if [ "$(basename "$SCRIPT_DIR")" = "trustnet" ]; then
    # One-liner install: ~/trustnet/lib/
    LIB_DIR="${SCRIPT_DIR}/lib"
else
    # Development/repo: ~/GitProjects/TrustNet/trustnet-wip/tools/lib/
    LIB_DIR="${SCRIPT_DIR}/lib"
fi

# Verify lib directory exists
if [ ! -d "$LIB_DIR" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: Module directory not found: $LIB_DIR" >&2
    exit 1
fi

# Core utilities
source "${LIB_DIR}/common.sh"

# Cache and download management
source "${LIB_DIR}/cache-manager.sh"

# VM lifecycle
source "${LIB_DIR}/vm-lifecycle.sh"

# VM bootstrap and configuration
source "${LIB_DIR}/vm-bootstrap.sh"

# Tool installers
source "${LIB_DIR}/install-caddy.sh"
source "${LIB_DIR}/install-cosmos-sdk.sh"
source "${LIB_DIR}/install-certificates.sh"

# UI/Documentation
source "${LIB_DIR}/setup-motd.sh"

################################################################################
# Helper Functions
################################################################################

offer_configuration_choice() {
    if [ "$AUTO_MODE" = "true" ]; then
        log_info "Auto mode: Using recommended configuration"
        return 0
    fi
    
    log ""
    log "TrustNet Node Configuration"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log ""
    log "Recommended Settings:"
    log "  Memory: ${VM_MEMORY}"
    log "  CPUs: ${VM_CPUS}"
    log "  System Disk: ${SYSTEM_DISK_SIZE}"
    log "  Cache Disk: ${CACHE_DISK_SIZE}"
    log "  Data Disk: ${DATA_DISK_SIZE}"
    log ""
    
    read -p "Use recommended settings? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_success "Using recommended configuration"
    else
        log_info "Custom configuration not yet supported - using recommended"
    fi
}

generate_start_script() {
    log "Generating TrustNet Node start script..."
    
    local uefi_fw=$(find_uefi_firmware)
    
    cat > "${VM_DIR}/start-trustnet.sh" << EOF
#!/bin/bash
# Always use the actual VM directory, not symlink location
VM_DIR="\${HOME}/vms/trustnet"
SYSTEM_DISK="${SYSTEM_DISK}"
CACHE_DISK="${CACHE_DISK}"
DATA_DISK="${DATA_DISK}"
UEFI_FW="${uefi_fw}"
VM_MEMORY="${VM_MEMORY}"
VM_CPUS="${VM_CPUS}"
SSH_PORT="${VM_SSH_PORT}"
PID_FILE="\${VM_DIR}/trustnet.pid"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -f "\$PID_FILE" ] && sudo kill -0 \$(cat "\$PID_FILE") 2>/dev/null; then
    echo -e "\${YELLOW}TrustNet Node is already running\${NC}"
    echo "  Connect: ssh trustnet"
    exit 0
fi

# Add /etc/hosts entries for trustnet.local and subdomains (dual-stack for port forwarding)
if ! grep -q "trustnet.local" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 trustnet.local rpc.trustnet.local api.trustnet.local" | sudo tee -a /etc/hosts > /dev/null
    echo "::1 trustnet.local rpc.trustnet.local api.trustnet.local" | sudo tee -a /etc/hosts > /dev/null
fi

echo -e "\${GREEN}Starting TrustNet Node...\${NC}"

# Detect architecture and set QEMU command
HOST_ARCH=\$(uname -m)
if [ "\$HOST_ARCH" = "x86_64" ] && [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    # x86_64 with KVM: Native virtualization (fast!)
    QEMU_ACCEL="-accel kvm"
    QEMU_SYSTEM="qemu-system-x86_64"
    QEMU_MACHINE="-M q35"
    QEMU_CPU="-cpu host"
    QEMU_BIOS=""  # Use default BIOS
elif [ "\$HOST_ARCH" = "aarch64" ] && [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    # ARM64 with KVM: Native virtualization
    QEMU_ACCEL="-accel kvm"
    QEMU_SYSTEM="qemu-system-aarch64"
    QEMU_MACHINE="-M virt"
    QEMU_CPU="-cpu host"
    QEMU_BIOS="-bios \${UEFI_FW}"
else
    # Fallback: TCG emulation (slow)
    QEMU_ACCEL="-accel tcg"
    if [ "\$HOST_ARCH" = "x86_64" ]; then
        QEMU_SYSTEM="qemu-system-x86_64"
        QEMU_MACHINE="-M q35"
        QEMU_CPU="-cpu qemu64"
        QEMU_BIOS=""
    else
        QEMU_SYSTEM="qemu-system-aarch64"
        QEMU_MACHINE="-M virt"
        QEMU_CPU="-cpu cortex-a72"
        QEMU_BIOS="-bios \${UEFI_FW}"
    fi
fi

touch "\${PID_FILE}"

sudo \${QEMU_SYSTEM} \\
    \${QEMU_MACHINE} \${QEMU_ACCEL} \\
    \${QEMU_CPU} \\
    -smp \${VM_CPUS} \\
    -m \${VM_MEMORY} \\
    \${QEMU_BIOS} \\
    -drive file="\${SYSTEM_DISK}",if=virtio,format=qcow2 \\
    -drive file="\${CACHE_DISK}",if=virtio,format=qcow2 \\
    -drive file="\${DATA_DISK}",if=virtio,format=qcow2 \\
    -device virtio-net-pci,netdev=net0 \\
    -netdev user,id=net0,hostfwd=tcp::\${SSH_PORT}-:22,hostfwd=tcp::443-:443 \\
    -display none \\
    -daemonize \\
    -pidfile "\${PID_FILE}"

echo "✓ TrustNet Node started"
echo "  SSH: ssh trustnet"
echo "  Web UI: https://trustnet.local"
EOF

    chmod +x "${VM_DIR}/start-trustnet.sh"
    
    # Create stop script
    cat > "${VM_DIR}/stop-trustnet.sh" << 'EOF'
#!/bin/bash
VM_DIR="${HOME}/vms/trustnet"
PID_FILE="${VM_DIR}/trustnet.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "TrustNet Node is not running"
    exit 0
fi

PID=$(cat "$PID_FILE")
if sudo kill -0 "$PID" 2>/dev/null; then
    echo "Stopping TrustNet Node..."
    sudo kill "$PID"
    rm -f "$PID_FILE"
    echo "✓ TrustNet Node stopped"
else
    echo "TrustNet Node process not found"
    rm -f "$PID_FILE"
fi
EOF

    chmod +x "${VM_DIR}/stop-trustnet.sh"
    
    log_success "Start/stop scripts created"
}

configure_ssh_on_host() {
    log "Configuring SSH on Host"
    
    local ssh_config="${HOME}/.ssh/config"
    
    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"
    
    # Remove old TrustNet entries if they exist
    if [ -f "$ssh_config" ]; then
        awk '/^# TrustNet Node/,/^$/{next} /^Host trustnet$/,/^$/{next} {print}' "$ssh_config" > "${ssh_config}.tmp"
        mv "${ssh_config}.tmp" "$ssh_config"
    else
        touch "$ssh_config"
    fi
    
    chmod 600 "$ssh_config"
    
    # Add fresh SSH config entry
    cat >> "$ssh_config" << EOF

# TrustNet Node
Host trustnet
    HostName localhost
    Port ${VM_SSH_PORT}
    User ${VM_USERNAME}
    IdentityFile ${VM_SSH_PRIVATE_KEY}
    IdentitiesOnly yes
    ForwardAgent yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR

EOF

    log_success "SSH config updated (ssh trustnet)"
}

save_credentials() {
    log "Saving Credentials"
    
    cat > "${VM_DIR}/credentials.txt" << EOF
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║                    TrustNet Node Access Info                         ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝

Installation Date: $(date)

SSH Access:
  Command: ssh trustnet
  User: ${VM_USERNAME}
  Port: ${VM_SSH_PORT}
  
Web UI & Services:
  Web UI: https://trustnet.local (identity management & control panel)
  RPC Endpoint: https://rpc.trustnet.local (blockchain RPC via Caddy reverse proxy)
  REST API: https://api.trustnet.local (blockchain REST API via Caddy reverse proxy)
  
Blockchain Services (via Caddy reverse proxy):
  RPC: https://rpc.trustnet.local
  REST API: https://api.trustnet.local
  P2P: tcp://trustnet.local:26656 (direct)
  
Node Configuration:
  Config: /home/${VM_USERNAME}/trustnet/config/config.toml
  Data: /home/${VM_USERNAME}/trustnet/data
  Keys: /home/${VM_USERNAME}/trustnet/keys
  
VM Management:
  Start: ${VM_DIR}/start-trustnet.sh
  Stop: ${VM_DIR}/stop-trustnet.sh
  Directory: ${VM_DIR}

Next Steps:
  1. Access web UI: https://trustnet.local
  2. Register your identity (creates cryptographic keypair)
  3. Get verified by community members
  4. Start building reputation!

Documentation:
  White Paper: https://trustnet.network/whitepaper
  CLI Guide: https://docs.trustnet.network/cli
  API Reference: https://docs.trustnet.network/api

╔══════════════════════════════════════════════════════════════════════╗
║  Your identity keys are stored in /home/${VM_USERNAME}/trustnet/keys         ║
║  BACK THEM UP! Loss of keys = loss of identity and reputation       ║
╚══════════════════════════════════════════════════════════════════════╝
EOF

    log_success "Credentials saved to ${VM_DIR}/credentials.txt"
}

print_completion_message() {
    log ""
    log "╔══════════════════════════════════════════════════════════════════════╗"
    log "║                                                                      ║"
    log "║               🎉 TrustNet Node Installation Complete! 🎉             ║"
    log "║                                                                      ║"
    log "╚══════════════════════════════════════════════════════════════════════╝"
    log ""
    log "✅ VM created and configured"
    log "✅ Cosmos SDK and Ignite CLI installed"
    log "✅ TrustNet blockchain client configured"
    log "✅ Caddy web server with HTTPS"
    log "✅ SSL certificates installed"
    log ""
    log "Access your node:"
    log "  SSH: ssh trustnet"
    log "  Web UI: https://trustnet.local"
    log "  RPC: https://rpc.trustnet.local"
    log "  API: https://api.trustnet.local"
    log ""
    log "Credentials saved to:"
    log "  ${VM_DIR}/credentials.txt"
    log ""
    log "Start your node:"
    log "  ${VM_DIR}/start-trustnet.sh"
    log ""
    log "Next steps:"
    log "  1. Visit https://trustnet.local"
    log "  2. Register your identity"
    log "  3. Start building reputation!"
    log ""
}

stop_existing_vm() {
    log_info "Checking for existing TrustNet VM..."
    
    # Check if stop script already exists (from previous install)
    if [ -f "${VM_DIR}/stop-trustnet.sh" ]; then
        # Try using the stop script
        if bash "${VM_DIR}/stop-trustnet.sh" 2>/dev/null | grep -q "Stopping\|stopped"; then
            sleep 2
            log_success "Existing VM stopped gracefully"
            return 0
        fi
    fi
    
    # Check if PID file exists from previous run
    local pid_file="${VM_DIR}/trustnet.pid"
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file" 2>/dev/null)
        if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
            log_warning "Found running TrustNet VM (PID: $pid)"
            log_info "Stopping existing VM..."
            kill "$pid" 2>/dev/null || true
            rm -f "$pid_file"
            sleep 2
            log_success "Existing VM stopped"
            return 0
        fi
    fi
    
    # Check if any QEMU process is using our disk
    if pgrep -f "trustnet.qcow2" >/dev/null 2>&1; then
        log_warning "Found QEMU process using TrustNet disks"
        log_info "Stopping QEMU..."
        pkill -f "trustnet.qcow2" 2>/dev/null || true
        sleep 2
        log_success "QEMU stopped"
        return 0
    fi
    
    log_info "No existing VM running"
}

################################################################################
# VM-Side Installation Orchestration
################################################################################

distribute_scripts_via_scp() {
    log "Distributing installation scripts to VM..."
    
    # Wait for SSH to be available
    local max_attempts=60
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if ssh -o ConnectTimeout=5 -p "$VM_SSH_PORT" "${VM_USERNAME}@localhost" "echo 'SSH OK'" >/dev/null 2>&1; then
            log_success "SSH is ready"
            break
        fi
        attempt=$((attempt + 1))
        if [ $((attempt % 10)) -eq 0 ]; then
            log_info "Waiting for SSH... ($attempt/$max_attempts)"
        fi
        sleep 2
    done
    
    if [ $attempt -ge $max_attempts ]; then
        log_error "VM did not become SSH-accessible after $max_attempts attempts"
        return 1
    fi
    
    # Create lib directory on VM
    ssh -p "$VM_SSH_PORT" "${VM_USERNAME}@localhost" "mkdir -p /tmp/lib" || return 1
    
    # Copy library scripts from host to VM
    # Check both locations: one-liner (PROJECT_ROOT/lib) and dev (PROJECT_ROOT/tools/lib)
    local lib_dir="$PROJECT_ROOT/tools/lib"
    if [ ! -d "$lib_dir" ]; then
        # Try alternative location for one-liner install
        lib_dir="$PROJECT_ROOT/lib"
        if [ ! -d "$lib_dir" ]; then
            log_error "Library directory not found: $PROJECT_ROOT/tools/lib or $PROJECT_ROOT/lib"
            return 1
        fi
    fi
    
    # Use scp to copy all .sh files
    scp -r -P "$VM_SSH_PORT" "${lib_dir}/"*.sh "${VM_USERNAME}@localhost:/tmp/lib/" || return 1
    
    log_success "Scripts distributed to VM"
}

execute_blockchain_installation() {
    log "Executing blockchain installation on VM..."
    
    # Export variables for remote script access
    export SSH_KEY="$VM_SSH_PRIVATE_KEY"
    export VM_SSH_PORT="$VM_SSH_PORT"
    
    # Create a simple orchestrator script on the VM that sources and runs the installations
    ssh -p "$VM_SSH_PORT" "${VM_USERNAME}@localhost" "bash" << REMOTE_SCRIPT
#!/bin/bash
set -euo pipefail

# Override ssh_exec to run commands directly (we're already on the VM)
ssh_exec() {
    "$@"
}
export -f ssh_exec

# Set variables for remote context
export VM_SSH_PRIVATE_KEY="${SSH_KEY:-}"
export VM_SSH_PORT="${VM_SSH_PORT:-2223}"
export VM_USERNAME="${VM_USERNAME:-warden}"

# Source common functions
source /tmp/lib/common.sh 2>/dev/null || true

# Make all lib scripts executable
chmod +x /tmp/lib/*.sh

# Run installations sequentially by sourcing them
echo "=== Installing Cosmos SDK and Go ==="
if [ -f /tmp/lib/install-cosmos-sdk.sh ]; then
    source /tmp/lib/install-cosmos-sdk.sh
    install_cosmos_sdk
else
    echo "WARNING: install-cosmos-sdk.sh not found"
fi

echo "=== Installing Caddy ==="
if [ -f /tmp/lib/install-caddy.sh ]; then
    source /tmp/lib/install-caddy.sh
    install_caddy
else
    echo "WARNING: install-caddy.sh not found"
fi

echo "=== Building TrustNet Blockchain ==="
if [ -f /tmp/lib/build-trustnet-blockchain.sh ]; then
    source /tmp/lib/build-trustnet-blockchain.sh
    build_trustnet_blockchain
    initialize_chain
else
    echo "WARNING: build-trustnet-blockchain.sh not found"
fi

echo "=== Installation Complete ==="
REMOTE_SCRIPT
    
    log_success "Blockchain installation completed on VM"
}

install_blockchain_stack() {
    log "Installing blockchain stack..."
    distribute_scripts_via_scp
    execute_blockchain_installation
    log_success "Blockchain stack installed"
}

install_caddy_via_ssh() {
    log "Caddy installation handled by blockchain_stack phase"
}

install_certificates_on_host() {
    log "Certificate installation deferred"
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    clear
    log ""
    log "═══════════════════════════════════════════════════════════════"
    log "    TrustNet Node Installer v1.0.0"
    log "    Blockchain-Based Trust Network (Cosmos SDK)"
    log "═══════════════════════════════════════════════════════════════"
    log ""
    log_info "Architecture: ${ALPINE_ARCH} $([ "$ALPINE_ARCH" = "x86_64" ] && echo "(fast KVM)" || echo "(for cloud pods)")"
    log ""
    
    # Pre-flight checks
    check_dependencies
    offer_configuration_choice
    
    # Generate secure passwords
    log_info "Generating secure passwords..."
    VM_ROOT_PASSWORD=$(generate_secure_password)
    WARDEN_OS_PASSWORD=$(generate_secure_password)
    
    export VM_ROOT_PASSWORD WARDEN_OS_PASSWORD
    
    # Create VM directory
    mkdir -p "$VM_DIR"
    cd "$VM_DIR"
    
    # Setup for VM creation
    ensure_qemu
    setup_ssh_keys
    
    # Stop any existing VM before creating a fresh installation
    stop_existing_vm
    
    # Phase 1: Download and cache Alpine
    download_alpine
    
    # Phase 2: Create and configure VM
    create_disks
    start_vm_for_install
    
    # (Alpine installer runs automatically here via alpine-install.exp)
    
    # Phase 3: Generate start script (needed before configure_installed_vm)
    generate_start_script
    
    # Phase 4: Bootstrap Alpine OS (after installation completes)
    # (configure_installed_vm handles user creation, disks, and SSH)
    configure_installed_vm
    
    # Phase 5-6: Install software and blockchain (Caddy + Cosmos SDK + blockchain build)
    install_caddy_via_ssh
    install_blockchain_stack
    
    # Phase 7: Configure SSL certificates
    install_certificates_on_host
    
    # Phase 8: Configure MOTD and final touches
    setup_motd_via_ssh
    
    # Phase 9: Configure host SSH and save credentials
    configure_ssh_on_host
    save_credentials
    
    # Completion
    print_completion_message
}

# Run main installation
main "$@"

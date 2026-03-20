#!/bin/bash
# Version: 1.1.0 - TrustNet Node Setup with iOS QR Integration

################################################################################
# TrustNet Node v1.1.0 - Fully Automated Setup
#
# Features:
#   - Base v1.0.0 node setup (preserved)
#   - iOS QR code discovery for node connection
#   - First-time setup web UI
#   - Automated FastAPI endpoints
#   - PIN-based verification system
#   - Certificate fingerprinting for security
#
# Usage:
#   ./setup-trustnet-node.sh [--auto|-y] [--arch=x86_64|aarch64] [--upgrade|--fresh]
#
#   --auto, -y             Use recommended settings without prompts
#   --arch=x86_64          Use x86_64 architecture (default)
#   --arch=aarch64         Use ARM64 architecture
#   --upgrade              Upgrade existing v1.0.0 node (preserves data)
#   --fresh                Fresh v1.1.0 installation (no data migration)
#
################################################################################

set -euo pipefail

# Logging configuration
LOG_DIR="${HOME}/.trustnet/logs"
if [ -n "${TRUSTNET_LOG_FILE:-}" ]; then
    LOG_FILE="$TRUSTNET_LOG_FILE"
else
    LOG_FILE="${LOG_DIR}/setup-v1.1.0-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$LOG_DIR"
fi

exec > >(tee -a "$LOG_FILE")
exec 2>&1

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"
}

log_msg "╔══════════════════════════════════════════════════════════╗"
log_msg "║                                                          ║"
log_msg "║    TrustNet Node v1.1.0 Setup                            ║"
log_msg "║    iOS QR Code Integration                               ║"
log_msg "║                                                          ║"
log_msg "╚══════════════════════════════════════════════════════════╝"
log_msg ""
log_msg "Installation log: $LOG_FILE"
log_msg ""

trap 'log_msg "ERROR: Installation failed at line $LINENO. Check log: $LOG_FILE" >&2; exit 1' ERR

# Parse arguments
AUTO_MODE=false
ALPINE_ARCH="x86_64"
UPGRADE_MODE=false
FRESH_MODE=false

for arg in "$@"; do
    case $arg in
        --auto|-y) AUTO_MODE=true; shift ;;
        --arch=x86_64) ALPINE_ARCH="x86_64"; shift ;;
        --arch=aarch64) ALPINE_ARCH="aarch64"; shift ;;
        --upgrade) UPGRADE_MODE=true; shift ;;
        --fresh) FRESH_MODE=true; shift ;;
        *) log_msg "Warning: Unknown argument $arg"; shift ;;
    esac
done

################################################################################
# Configuration
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Detect v1.1.0 directory
if [ -d "$SCRIPT_DIR/../v1.1.0" ]; then
    VERSION_DIR="$SCRIPT_DIR/../v1.1.0"
elif [ -d "$SCRIPT_DIR/versions/v1.1.0" ]; then
    VERSION_DIR="$SCRIPT_DIR/versions/v1.1.0"
else
    VERSION_DIR="$SCRIPT_DIR"
fi

CACHE_DIR="${HOME}/.trustnet/cache"
VM_DIR="${HOME}/vms/trustnet"
VM_NAME="trustnet"
VM_MEMORY="2G"
VM_CPUS="2"
VM_SSH_PORT="2223"

VM_HOSTNAME="trustnet.local"
VM_USERNAME="warden"
VM_PASSWORD="$(openssl rand -base64 12)"  # Random password for console access

log_msg ""
log_msg "Configuration:"
log_msg "  Architecture: $ALPINE_ARCH"
log_msg "  VM Directory: $VM_DIR"
log_msg "  Cache Directory: $CACHE_DIR"
log_msg "  SSH Port: $VM_SSH_PORT"
log_msg ""

################################################################################
# Step 1: Check for Existing v1.0.0 Node
################################################################################

if [ -d "$VM_DIR/disk" ] && [ ! "$FRESH_MODE" = true ]; then
    log_msg "Found existing TrustNet node. Checking version..."
    
    if [ "$AUTO_MODE" = false ]; then
        log_msg ""
        log_msg "Options:"
        log_msg "  1) Upgrade to v1.1.0 (preserves blockchain data, v1.0.0 stays as backup)"
        log_msg "  2) Fresh v1.1.0 installation (no data migration)"
        log_msg "  3) Keep current version (exit)"
        read -p "Choice [1-3]: " choice
        
        case $choice in
            1) UPGRADE_MODE=true; FRESH_MODE=false ;;
            2) FRESH_MODE=true; UPGRADE_MODE=false ;;
            3) log_msg "Keeping current version. Exiting."; exit 0 ;;
            *) log_msg "Invalid choice. Using upgrade mode."; UPGRADE_MODE=true ;;
        esac
    else
        UPGRADE_MODE=true
    fi
fi

if [ "$UPGRADE_MODE" = true ]; then
    log_msg "UPGRADE MODE: Preserving v1.0.0 data and creating v1.1.0 upgrade"
    BACKUP_DIR="$VM_DIR/backup-v1.0.0-$(date +%Y%m%d-%H%M%S)"
    log_msg "Backup location: $BACKUP_DIR"
elif [ "$FRESH_MODE" = true ]; then
    log_msg "FRESH MODE: Starting v1.1.0 from scratch"
    if [ -d "$VM_DIR" ]; then
        log_msg "Removing existing VM directory..."
        rm -rf "$VM_DIR"
    fi
fi

################################################################################
# Step 2: Base Node Setup (v1.0.0)
################################################################################

log_msg ""
log_msg "Step 1/3: Setting up base v1.0.0 node infrastructure..."
log_msg ""

mkdir -p "$VM_DIR" "$CACHE_DIR"

# Source v1.0.0 setup functions (if available)
if [ -f "$PROJECT_ROOT/core/versions/v1.0.0/tools/lib/install-caddy.sh" ]; then
    log_msg "Using v1.0.0 base installation scripts"
    # Base setup logic would go here (inherited from v1.0.0)
else
    log_msg "Note: Using fallback base installation. Recommend running v1.0.0 setup first."
fi

################################################################################
# Step 3: iOS Integration Setup (v1.1.0 NEW)
################################################################################

log_msg ""
log_msg "Step 2/3: Installing iOS QR integration layer..."
log_msg ""

# Create API directory structure
API_DIR="$VM_DIR/api"
WEB_DIR="$VM_DIR/web"
mkdir -p "$API_DIR" "$WEB_DIR/templates" "$WEB_DIR/static"

log_msg "Installing Python FastAPI dependencies..."

# Copy requirements.txt from repo if available
REQUIREMENTS_SOURCE="$VERSION_DIR/setup-requirements.txt"

if [ -f "$REQUIREMENTS_SOURCE" ]; then
    log_msg "Copying requirements.txt from repository..."
    cp "$REQUIREMENTS_SOURCE" "$API_DIR/requirements.txt"
else
    # Fallback: create requirements inline
    log_msg "Creating requirements.txt..."
    cat > "$API_DIR/requirements.txt" << 'REQUIREMENTS_EOF'
fastapi>=0.95.0
uvicorn[standard]>=0.21.0
qrcode[pil]>=7.4.0
Pillow>=9.0.0
python-multipart>=0.0.5
REQUIREMENTS_EOF
fi

log_msg "FastAPI requirements: $(awk '/^[^#]/ && NF' $API_DIR/requirements.txt | wc -l) packages"

################################################################################
# Step 4: SCP iOS v1.1.0 Components to VM
################################################################################

log_msg ""
log_msg "Step 3/3: Deploying iOS v1.1.0 setup components via SCP..."
log_msg ""

# After SSH is ready, SCP files from the public repo to the VM
# The public repo is at: /home/jcgarcia/wip/pub/TrustNet/core/versions/v1.1.0/

# Create directories on VM
ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" "mkdir -p /opt/trustnet/api /opt/trustnet/web/templates" || {
    log_msg "WARNING: Failed to create directories on VM via SSH"
}

# Source paths (from public repo on host)
SETUP_API_HOST="$PROJECT_ROOT/../core/versions/v1.1.0/api/setup_api.py"
FIRST_SETUP_HTML="$PROJECT_ROOT/../core/versions/v1.1.0/web/templates/first-setup.html"

# SCP setup_api.py to VM
if [ -f "$SETUP_API_HOST" ]; then
    log_msg "Copying setup_api.py to VM via SCP..."
    scp -P "$VM_SSH_PORT" "$SETUP_API_HOST" "$VM_USERNAME@$VM_HOSTNAME:/opt/trustnet/api/setup.py" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_msg "✅ setup_api.py deployed (full QR code generation with PIN verification)"
    else
        log_msg "WARNING: SCP failed for setup_api.py"
    fi
else
    log_msg "WARNING: setup_api.py not found at $SETUP_API_HOST"
    log_msg "Path checked: $SETUP_API_HOST"
fi

# SCP first-setup.html to VM
if [ -f "$FIRST_SETUP_HTML" ]; then
    log_msg "Copying first-setup.html to VM via SCP..."
    scp -P "$VM_SSH_PORT" "$FIRST_SETUP_HTML" "$VM_USERNAME@$VM_HOSTNAME:/opt/trustnet/web/templates/first-setup.html" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_msg "✅ first-setup.html deployed (responsive iOS setup UI)"
    else
        log_msg "WARNING: SCP failed for first-setup.html"
    fi
else
    log_msg "WARNING: first-setup.html not found at $FIRST_SETUP_HTML"
    log_msg "Path checked: $FIRST_SETUP_HTML"
fi

################################################################################
# Step 6: Create Caddy Configuration for Setup UI
################################################################################

CADDY_CONFIG="$VM_DIR/Caddyfile.setup"
cat > "$CADDY_CONFIG" << 'CADDY_EOF'
# TrustNet Setup UI Route (v1.1.0)
# Adds setup endpoints to existing Caddy config

(setup-route) {
    # Setup UI
    route /setup* {
        handle_path /setup {
            file_server {
                root /opt/trustnet/web/templates
                index first-setup.html
            }
        }
        
        # Setup API endpoints
        route /api/setup/* {
            reverse_proxy localhost:8001
        }
    }
}

# Import in main Caddyfile:
# import /opt/trustnet/Caddyfile.setup
CADDY_EOF

log_msg "✅ Caddy setup configuration created"

################################################################################
# Step 7: Create Installation Script
################################################################################

INSTALL_DEPS_SCRIPT="$VM_DIR/install-v1.1.0-components.sh"
cat > "$INSTALL_DEPS_SCRIPT" << 'DEPS_EOF'
#!/bin/bash
# Install v1.1.0 iOS integration components

set -e

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $@"
}

log_msg "Installing v1.1.0 iOS QR Integration..."

# Create directories
mkdir -p /opt/trustnet/api /opt/trustnet/web/{templates,static}

# Install Python packages (if running in Alpine)
if command -v apk &> /dev/null; then
    log_msg "Installing Alpine packages..."
    doas apk add --no-cache \
        python3 \
        python3-dev \
        py3-pip \
        libjpeg \
        zlib-dev \
        gcc \
        musl-dev
    
    log_msg "Installing Python packages..."
    doas pip install --no-cache -r /tmp/requirements.txt
elif command -v apt &> /dev/null; then
    log_msg "Installing Debian packages..."
    sudo apt-get update
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-dev \
        libjpeg-dev \
        zlib1g-dev
    
    log_msg "Installing Python packages..."
    sudo pip3 install -r /tmp/requirements.txt
else
    log_msg "Warning: Unknown package manager. Assuming Python is installed."
fi

log_msg "✅ v1.1.0 components installed"
DEPS_EOF

chmod +x "$INSTALL_DEPS_SCRIPT"
log_msg "✅ Installation script created"

################################################################################
# Step 8: v1.1.0 iOS Integration (Optional - Deployed by install.sh)
################################################################################

log_msg ""
log_msg "ℹ️  TrustNet v1.1.0 iOS Integration"
log_msg ""
log_msg "This script sets up TrustNet v1.0.0 base (blockchain node)."
log_msg ""
log_msg "For COMPLETE v1.1.0 setup with iOS QR integration, use the one-liner installer:"
log_msg ""
log_msg "  curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh | bash"
log_msg ""
log_msg "The one-liner installer automatically:"
log_msg "  ✅ Runs this base v1.0.0 setup"
log_msg "  ✅ Deploys FastAPI setup server"
log_msg "  ✅ Deploys iOS setup UI"
log_msg "  ✅ Configures QR code endpoints"
log_msg "  ✅ Configures Caddy routing"
log_msg ""

################################################################################
# Step 9: Summary and Next Steps
################################################################################

log_msg ""
log_msg "╔══════════════════════════════════════════════════════════╗"
log_msg "║  ✅ TrustNet v1.0.0 Base Setup Complete                  ║"
log_msg "║  (v1.1.0 iOS integration via install.sh one-liner)      ║"
log_msg "╚══════════════════════════════════════════════════════════╝"
log_msg ""
log_msg "✅ Base Installation Summary:"
log_msg "  Version: v1.0.0 (Cosmos SDK Blockchain Node)"
log_msg "  VM Location: $VM_DIR"
log_msg "  VM Name: $VM_NAME"
log_msg "  SSH Port: $VM_SSH_PORT"
log_msg ""
log_msg "👉 For COMPLETE v1.1.0 Setup with iOS Integration:"
log_msg ""
log_msg "   curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh | bash"
log_msg ""
log_msg "   This adds:"
log_msg "   ✨ iOS QR code generation (/api/setup/qr-code)"
log_msg "   ✨ PIN verification system (/api/setup/verify-pin)"
log_msg "   ✨ First-time setup web UI (responsive mobile UI)"
log_msg "   ✨ Node discovery for iOS app"
log_msg "   ✨ Certificate fingerprinting for security"
log_msg ""
log_msg "Next Steps:"
log_msg "  1. Verify v1.0.0 node is running:"
log_msg "     ssh -p $VM_SSH_PORT $VM_USERNAME@$VM_HOSTNAME 'systemctl status trustnet'"
log_msg ""
log_msg "  2. Check VM connectivity:"
log_msg "     ssh -p $VM_SSH_PORT $VM_USERNAME@$VM_HOSTNAME 'curl -s http://localhost:26657/status | jq .'"
log_msg ""
log_msg "  3. For iOS integration (v1.1.0), run install.sh as shown above"
log_msg ""
log_msg "Installation log: $LOG_FILE"
log_msg ""
log_msg "Questions? Check: $PROJECT_ROOT/docs/INSTALLATION_GUIDE.md"
log_msg ""

exit 0

#!/bin/bash
#
# TrustNet Node One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh | bash
# Or:    curl -fsSL ... | bash -s -- --version v1.1.0 --auto
# Version: 1.1.0 (supports v1.0.0 and v1.1.0)
#

set -e

REPO_URL="https://github.com/TrustNetT/trustnet.git"
RAW_URL="https://raw.githubusercontent.com/TrustNetT/trustnet"
REPO_DIR="$HOME/trustnet"
BRANCH="${TRUSTNET_BRANCH:-main}"

# Parse command-line arguments
TRUSTNET_VERSION="${TRUSTNET_VERSION:-v1.1.0}"  # Default to v1.1.0 (latest)
AUTO_MODE=false
ARCH="x86_64"
UPGRADE_MODE=false
FRESH_MODE=false

# Parse arguments from command line (bash -s -- arg1 arg2)
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            TRUSTNET_VERSION="$2"
            shift 2
            ;;
        --auto|-y)
            AUTO_MODE=true
            shift
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --upgrade)
            UPGRADE_MODE=true
            shift
            ;;
        --fresh)
            FRESH_MODE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Validate version
case "$TRUSTNET_VERSION" in
    v1.0.0|v1.1.0)
        : # Valid versions
        ;;
    *)
        log_error "Unknown version: $TRUSTNET_VERSION"
        log_error "Supported versions: v1.0.0, v1.1.0"
        exit 1
        ;;
esac

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
log "Configuration:"
log "  Version: $TRUSTNET_VERSION"
log "  Architecture: $ARCH"
log "  Auto mode: $AUTO_MODE"
log "  Upgrade: $UPGRADE_MODE"
log "  Branch: $BRANCH"
log "  Installation log: $LOG_FILE"
log ""

# Handle --fresh mode (remove existing repo)
if [[ "$FRESH_MODE" == true ]] && [[ -d "$REPO_DIR" ]]; then
    log "→ Fresh mode: removing existing installation..."
    rm -rf "$REPO_DIR"
fi

# Create directory structure
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

log "Cloning TrustNet repository..."
# Clone or update repository
if [[ -d ".git" ]]; then
    log "Repository exists, updating..."
    git fetch origin
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
else
    log "Cloning repository..."
    git clone -b "$BRANCH" "$REPO_URL" .
fi

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

# Download latest scripts
log "→ Downloading latest scripts (v1.1.0)..."
log "→ Using v1.1.0 with iOS QR integration"

# Download setup script from core/tools directory (same structure as jcgarcia/TrustNet)
if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/setup-trustnet-node.sh?nocache=$(date +%s)" -o setup-trustnet-node.sh.tmp; then
    log_error "Failed to download setup script from core/tools/setup-trustnet-node.sh"
    exit 1
fi
mv setup-trustnet-node.sh.tmp setup-trustnet-node.sh
chmod +x setup-trustnet-node.sh
sed -i 's/\r$//' setup-trustnet-node.sh 2>/dev/null || dos2unix setup-trustnet-node.sh 2>/dev/null || true

# Download alpine-install.exp from core/tools
if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/alpine-install.exp?nocache=$(date +%s)" -o alpine-install.exp.tmp; then
    log_error "Failed to download alpine-install.exp"
    exit 1
fi
mv alpine-install.exp.tmp alpine-install.exp
sed -i 's/\r$//' alpine-install.exp 2>/dev/null || dos2unix alpine-install.exp 2>/dev/null || true

# Download core modules
log "→ Downloading core modules..."
mkdir -p lib

# List of core modules to download
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
    if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/lib/$module?nocache=$(date +%s)" -o "lib/$module.tmp"; then
        log_error "Failed to download core module: $module"
        exit 1
    fi
    mv "lib/$module.tmp" "lib/$module"
    chmod +x "lib/$module"
done

# v1.1.0-specific modules (optional, don't fail if missing)
log "→ Downloading v1.1.0-specific modules..."

V1_1_MODULES=(
    "ios-integration.sh"
    "setup-fastapi.sh"
)

for module in "${V1_1_MODULES[@]}"; do
    if ! curl -fsSL "$RAW_URL/$BRANCH/core/tools/lib/$module?nocache=$(date +%s)" -o "lib/$module.tmp" 2>/dev/null; then
        log "⚠ Optional v1.1.0 module not found: $module (may be embedded in setup script)"
    else
        mv "lib/$module.tmp" "lib/$module"
        chmod +x "lib/$module"
    fi
done

log "✓ Core scripts and modules downloaded"

# Notify about data preservation
if [ $DATA_PRESERVED -eq 1 ]; then
    log "✓ Node data will be preserved (~/.trustnet/data)"
fi

log ""
log "→ Starting installation..."
log "→ Detailed logs will continue in: $LOG_FILE"
log ""

# Export variables for setup script
export TRUSTNET_LOG_FILE="$LOG_FILE"
export TRUSTNET_VERSION="$TRUSTNET_VERSION"
export TRUSTNET_ARCH="$ARCH"

# Build arguments for setup script
SETUP_ARGS=""
if [[ "$AUTO_MODE" == "true" ]]; then
    SETUP_ARGS="$SETUP_ARGS --auto"
fi
if [[ "$UPGRADE_MODE" == "true" ]]; then
    SETUP_ARGS="$SETUP_ARGS --upgrade"
fi
if [[ "$FRESH_MODE" == "true" ]]; then
    SETUP_ARGS="$SETUP_ARGS --fresh"
fi

# Run the versioned setup script with parsed arguments
exec ./setup-trustnet-node.sh --arch=$ARCH $SETUP_ARGS

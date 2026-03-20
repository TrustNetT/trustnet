#!/bin/bash
#
# TrustNet Node One-Liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/TrustNetT/trustnet/main/install.sh | bash
# Version: 1.1.0 (latest production)
#

set -e

REPO_URL="https://github.com/TrustNetT/trustnet.git"
RAW_URL="https://raw.githubusercontent.com/TrustNetT/trustnet"
REPO_DIR="$HOME/trustnet"
BRANCH="${TRUSTNET_BRANCH:-main}"

# Setup logging (persistent internal state)
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
./setup-trustnet-node.sh --auto
BASE_INSTALL_RESULT=$?

if [ $BASE_INSTALL_RESULT -ne 0 ]; then
    log_error "Base installation failed (exit code: $BASE_INSTALL_RESULT)"
    exit $BASE_INSTALL_RESULT
fi

log ""
log "╔══════════════════════════════════════════════════════════╗"
log "║  Base Installation Complete - Starting v1.1.0 Deployment ║"
log "╚══════════════════════════════════════════════════════════╝"
log ""

# Deploy v1.1.0 components
log "→ Downloading v1.1.0 components..."

mkdir -p v1.1.0-components
cd v1.1.0-components

# Download v1.1.0 components from repository
COMPONENTS=(
    "core/versions/v1.1.0/api/setup_api.py:api/setup.py"
    "core/versions/v1.1.0/web/templates/first-setup.html:web/first-setup.html"
    "core/versions/v1.1.0/setup-requirements.txt:setup-requirements.txt"
)

for component_spec in "${COMPONENTS[@]}"; do
    IFS=':' read -r source dest <<< "$component_spec"
    if ! curl -fsSL "$RAW_URL/$BRANCH/$source?nocache=$(date +%s)" -o "$dest"; then
        log_error "Failed to download: $source"
        exit 1
    fi
done

log "✓ v1.1.0 components downloaded"

# Create local directories for v1.1.0
VM_DIR="${HOME}/vms/trustnet"
API_DIR="$VM_DIR/api"
WEB_DIR="$VM_DIR/web"
mkdir -p "$API_DIR" "$WEB_DIR/templates"

# Copy components to VM directory
cp api/setup.py "$API_DIR/" 2>/dev/null || log "Warning: Could not copy setup.py"
cp web/first-setup.html "$WEB_DIR/templates/" 2>/dev/null || log "Warning: Could not copy first-setup.html"
cp setup-requirements.txt "$API_DIR/requirements.txt" 2>/dev/null || log "Warning: Could not copy requirements.txt"

log "✓ v1.1.0 files staged locally"

# Deploy to VM via SSH
log ""
log "→ Deploying v1.1.0 to running VM..."

VM_USERNAME="warden"
VM_HOSTNAME="trustnet.local"
VM_SSH_PORT="2223"

# Test SSH connectivity
if ! ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" "echo OK" &>/dev/null; then
    log_error "Cannot connect to VM at $VM_USERNAME@$VM_HOSTNAME:$VM_SSH_PORT"
    log "Ensure base installation completed successfully"
    exit 1
fi

log "✓ SSH connectivity verified"

# Create directories on VM
ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" "mkdir -p /opt/trustnet/api /opt/trustnet/web/templates" 2>/dev/null || true

# Deploy setup.py
if [ -f "$API_DIR/setup.py" ]; then
    scp -P "$VM_SSH_PORT" "$API_DIR/setup.py" "$VM_USERNAME@$VM_HOSTNAME:/opt/trustnet/api/" 2>/dev/null && \
    log "✓ Deployed setup.py" || \
    log "Warning: Failed to SCP setup.py"
fi

# Deploy first-setup.html
if [ -f "$WEB_DIR/templates/first-setup.html" ]; then
    scp -P "$VM_SSH_PORT" "$WEB_DIR/templates/first-setup.html" "$VM_USERNAME@$VM_HOSTNAME:/opt/trustnet/web/templates/" 2>/dev/null && \
    log "✓ Deployed first-setup.html" || \
    log "Warning: Failed to SCP first-setup.html"
fi

# Deploy requirements.txt
if [ -f "$API_DIR/requirements.txt" ]; then
    scp -P "$VM_SSH_PORT" "$API_DIR/requirements.txt" "$VM_USERNAME@$VM_HOSTNAME:/tmp/requirements.txt" 2>/dev/null && \
    log "✓ Deployed requirements.txt" || \
    log "Warning: Failed to SCP requirements.txt"
fi

# Install FastAPI on VM
log ""
log "→ Installing FastAPI dependencies on VM..."

ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" << 'SSH_INSTALL_FASTAPI'
#!/bin/bash
if command -v apk &> /dev/null; then
    doas apk add --no-cache python3 python3-dev py3-pip libjpeg zlib-dev gcc musl-dev 2>/dev/null || true
    doas pip install --no-cache -r /tmp/requirements.txt 2>/dev/null || true
elif command -v apt &> /dev/null; then
    sudo apt-get update 2>/dev/null || true
    sudo apt-get install -y python3-pip python3-dev libjpeg-dev zlib1g-dev 2>/dev/null || true
    sudo pip3 install -r /tmp/requirements.txt 2>/dev/null || true
fi
SSH_INSTALL_FASTAPI

log "✓ FastAPI installed"

# Create systemd service for Setup API
log ""
log "→ Setting up Setup API service..."

ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" << 'SSH_CREATE_SERVICE'
#!/bin/bash
cat > /tmp/trustnet-setup.service << 'SERVICE_UNIT'
[Unit]
Description=TrustNet v1.1.0 Setup API
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=_trustnet
WorkingDirectory=/opt/trustnet/api
ExecStart=/usr/bin/python3 /opt/trustnet/api/setup.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
SERVICE_UNIT

if command -v doas &> /dev/null; then
    doas cp /tmp/trustnet-setup.service /etc/init.d/trustnet-setup 2>/dev/null || true
    doas rc-service trustnet-setup start 2>/dev/null || true
elif command -v sudo &> /dev/null; then
    sudo cp /tmp/trustnet-setup.service /etc/systemd/system/trustnet-setup.service 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl enable trustnet-setup 2>/dev/null || true
    sudo systemctl start trustnet-setup 2>/dev/null || true
fi
SSH_CREATE_SERVICE

log "✓ Setup API service created and started"

# Configure Caddy for v1.1.0 setup endpoints
log ""
log "→ Configuring Caddy routing for /setup endpoint..."

ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" << 'SSH_CADDY_CONFIG'
#!/bin/bash
CADDY_FILE="/etc/caddy/Caddyfile"

if ! grep -q "/setup" "$CADDY_FILE" 2>/dev/null; then
    cat >> /tmp/caddy-setup-routes << 'CADDY_ROUTES'

# TrustNet v1.1.0 Setup UI (auto-configured)
(setup-routes) {
    route /setup* {
        handle_path /setup {
            file_server {
                root /opt/trustnet/web/templates
                index first-setup.html
            }
        }
        route /api/setup/* {
            reverse_proxy localhost:8001
        }
    }
}

:1317 {
    import setup-routes
}
CADDY_ROUTES

    if command -v doas &> /dev/null; then
        doas cp /tmp/caddy-setup-routes /etc/caddy/Caddyfile.setup 2>/dev/null || true
        echo "" | doas tee -a "$CADDY_FILE" 2>/dev/null || true
        echo "import /etc/caddy/Caddyfile.setup" | doas tee -a "$CADDY_FILE" 2>/dev/null || true
        doas rc-service caddy reload 2>/dev/null || true
    elif command -v sudo &> /dev/null; then
        sudo cp /tmp/caddy-setup-routes /etc/caddy/Caddyfile.setup 2>/dev/null || true
        echo "" | sudo tee -a "$CADDY_FILE" 2>/dev/null || true
        echo "import /etc/caddy/Caddyfile.setup" | sudo tee -a "$CADDY_FILE" 2>/dev/null || true
        sudo systemctl reload caddy 2>/dev/null || true
    fi
fi
SSH_CADDY_CONFIG

log "✓ Caddy routing configured"

cd ..
rm -rf v1.1.0-components

log ""
log "╔══════════════════════════════════════════════════════════╗"
log "║  ✅ TrustNet v1.1.0 Installation Complete                ║"
log "╚══════════════════════════════════════════════════════════╝"
log ""
log "Installation Summary:"
log "  ✓ Base v1.0.0 (Cosmos SDK blockchain node)"
log "  ✓ v1.1.0 (iOS QR code integration)"
log ""
log "Available Features:"
log "  • Blockchain node: https://trustnet.local/"
log "  • Setup UI: https://trustnet.local/setup"
log "  • QR code API: http://trustnet.local:8001/api/setup/qr-code"
log "  • PIN verification: http://trustnet.local:8001/api/setup/verify-pin"
log ""
log "View logs: cat $LOG_FILE"
log ""

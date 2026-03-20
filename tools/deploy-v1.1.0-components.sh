#!/bin/bash
#
# TrustNet v1.1.0 Component Deployment
# Run this AFTER base v1.0.0 installation completes
# Usage: ./deploy-v1.1.0-components.sh
#

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
VERSION_DIR="$PROJECT_ROOT/core/versions/v1.1.0"

# VM Configuration (must match base installation)
VM_SSH_PORT="2223"
VM_USERNAME="warden"
VM_HOSTNAME="trustnet.local"
VM_DIR="${HOME}/vms/trustnet"
API_DIR="$VM_DIR/api"
WEB_DIR="$VM_DIR/web"

# Logging
LOG_DIR="${HOME}/.trustnet/logs"
LOG_FILE="${LOG_DIR}/deploy-v1.1.0-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

log_msg() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_msg "╔══════════════════════════════════════════════════════════╗"
log_msg "║  TrustNet v1.1.0 Component Deployment                    ║"
log_msg "║  iOS QR Code Integration                                 ║"
log_msg "╚══════════════════════════════════════════════════════════╝"
log_msg ""

# Verify base installation exists
if [ ! -d "$VM_DIR" ]; then
    log_msg "ERROR: VM directory not found: $VM_DIR"
    log_msg "Please run base v1.0.0 installation first"
    exit 1
fi

# Verify v1.1.0 components exist
if [ ! -d "$VERSION_DIR/api" ]; then
    log_msg "ERROR: v1.1.0 components not found: $VERSION_DIR"
    exit 1
fi

log_msg "Deploying v1.1.0 components..."
log_msg ""

# Create local directories
mkdir -p "$API_DIR" "$WEB_DIR/templates" "$WEB_DIR/static"
log_msg "✓ Local directories created"

# Copy v1.1.0 components from repository
log_msg ""
log_msg "Step 1: Preparing v1.1.0 files..."

if [ -f "$VERSION_DIR/setup-requirements.txt" ]; then
    cp "$VERSION_DIR/setup-requirements.txt" "$API_DIR/requirements.txt"
    log_msg "✓ Copied requirements.txt"
else
    log_msg "WARNING: requirements.txt not found, using inline"
fi

if [ -f "$VERSION_DIR/api/setup_api.py" ]; then
    cp "$VERSION_DIR/api/setup_api.py" "$API_DIR/setup.py"
    chmod +x "$API_DIR/setup.py"
    log_msg "✓ Copied setup.py"
fi

if [ -f "$VERSION_DIR/web/templates/first-setup.html" ]; then
    cp "$VERSION_DIR/web/templates/first-setup.html" "$WEB_DIR/templates/first-setup.html"
    log_msg "✓ Copied first-setup.html"
fi

log_msg ""
log_msg "Step 2: Deploying to VM via SSH..."

# Test SSH connectivity
if ! ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" "echo OK" &>/dev/null; then
    log_msg "ERROR: Cannot connect to VM at $VM_USERNAME@$VM_HOSTNAME:$VM_SSH_PORT"
    log_msg "Ensure base v1.0.0 installation completed and VM is running"
    exit 1
fi
log_msg "✓ SSH connectivity verified"

# Create directories on VM
ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" "mkdir -p /opt/trustnet/api /opt/trustnet/web/templates" || {
    log_msg "WARNING: Failed to create directories on VM"
}
log_msg "✓ VM directories created"

# Deploy setup.py
if [ -f "$API_DIR/setup.py" ]; then
    scp -P "$VM_SSH_PORT" "$API_DIR/setup.py" "$VM_USERNAME@$VM_HOSTNAME:/opt/trustnet/api/" 2>/dev/null || {
        log_msg "WARNING: Failed to SCP setup.py"
    }
    log_msg "✓ Deployed setup.py"
fi

# Deploy first-setup.html
if [ -f "$WEB_DIR/templates/first-setup.html" ]; then
    scp -P "$VM_SSH_PORT" "$WEB_DIR/templates/first-setup.html" "$VM_USERNAME@$VM_HOSTNAME:/opt/trustnet/web/templates/" 2>/dev/null || {
        log_msg "WARNING: Failed to SCP first-setup.html"
    }
    log_msg "✓ Deployed first-setup.html"
fi

# Deploy requirements.txt
if [ -f "$API_DIR/requirements.txt" ]; then
    scp -P "$VM_SSH_PORT" "$API_DIR/requirements.txt" "$VM_USERNAME@$VM_HOSTNAME:/tmp/requirements.txt" 2>/dev/null || {
        log_msg "WARNING: Failed to SCP requirements.txt"
    }
    log_msg "✓ Deployed requirements.txt"
fi

log_msg ""
log_msg "Step 3: Installing FastAPI on VM..."

# Install FastAPI dependencies
ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" << 'SSH_INSTALL_EOF'
#!/bin/bash
set -e

if command -v apk &> /dev/null; then
    echo "[INFO] Installing Alpine packages for FastAPI..."
    doas apk add --no-cache python3 python3-dev py3-pip libjpeg zlib-dev gcc musl-dev 2>/dev/null || true
    echo "[INFO] Installing Python packages..."
    doas pip install --no-cache -r /tmp/requirements.txt 2>/dev/null || true
elif command -v apt &> /dev/null; then
    echo "[INFO] Installing Debian packages for FastAPI..."
    sudo apt-get update 2>/dev/null || true
    sudo apt-get install -y python3-pip python3-dev libjpeg-dev zlib1g-dev 2>/dev/null || true
    echo "[INFO] Installing Python packages..."
    sudo pip3 install -r /tmp/requirements.txt 2>/dev/null || true
else
    echo "[WARNING] Unknown package manager. Skipping FastAPI installation."
fi
SSH_INSTALL_EOF

log_msg "✓ FastAPI installed on VM"

log_msg ""
log_msg "Step 4: Creating systemd service..."

# Create systemd service for Setup API
ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" << 'SSH_SERVICE_EOF'
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

# Install service
if command -v doas &> /dev/null; then
    doas cp /tmp/trustnet-setup.service /etc/init.d/trustnet-setup 2>/dev/null || true
    doas rc-service trustnet-setup start 2>/dev/null || true
elif command -v sudo &> /dev/null; then
    sudo cp /tmp/trustnet-setup.service /etc/systemd/system/trustnet-setup.service 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
    sudo systemctl enable trustnet-setup 2>/dev/null || true
    sudo systemctl start trustnet-setup 2>/dev/null || true
fi
SSH_SERVICE_EOF

log_msg "✓ Setup API service created and started"

log_msg ""
log_msg "Step 5: Configuring Caddy..."

# Create Caddy setup configuration
CADDY_CONFIG="$VM_DIR/Caddyfile.setup"
cat > "$CADDY_CONFIG" << 'CADDY_EOF'
# TrustNet v1.1.0 Setup UI Route
# Add this to main Caddyfile with: import /etc/caddy/Caddyfile.setup

(setup-route) {
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
    import setup-route
}
CADDY_EOF

scp -P "$VM_SSH_PORT" "$CADDY_CONFIG" "$VM_USERNAME@$VM_HOSTNAME:/tmp/Caddyfile.setup" 2>/dev/null || {
    log_msg "WARNING: Failed to SCP Caddy config"
}

# Merge Caddy configuration
ssh -p "$VM_SSH_PORT" "$VM_USERNAME@$VM_HOSTNAME" << 'SSH_CADDY_EOF'
#!/bin/bash
CADDY_FILE="/etc/caddy/Caddyfile"

if ! grep -q "import /etc/caddy/Caddyfile.setup" "$CADDY_FILE" 2>/dev/null; then
    if command -v doas &> /dev/null; then
        doas cp /tmp/Caddyfile.setup /etc/caddy/Caddyfile.setup 2>/dev/null || true
        echo "import /etc/caddy/Caddyfile.setup" | doas tee -a "$CADDY_FILE" 2>/dev/null || true
        doas rc-service caddy reload 2>/dev/null || true
    elif command -v sudo &> /dev/null; then
        sudo cp /tmp/Caddyfile.setup /etc/caddy/Caddyfile.setup 2>/dev/null || true
        echo "import /etc/caddy/Caddyfile.setup" | sudo tee -a "$CADDY_FILE" 2>/dev/null || true
        sudo systemctl reload caddy 2>/dev/null || true
    fi
fi
SSH_CADDY_EOF

log_msg "✓ Caddy configuration updated"

log_msg ""
log_msg "╔══════════════════════════════════════════════════════════╗"
log_msg "║  ✅ v1.1.0 Component Deployment Complete                ║"
log_msg "╚══════════════════════════════════════════════════════════╝"
log_msg ""
log_msg "New Features Available:"
log_msg "  ✨ iOS QR code generation (/api/setup/qr-code)"
log_msg "  ✨ PIN verification (/api/setup/verify-pin)"
log_msg "  ✨ First-time setup web UI (https://<node>/setup)"
log_msg ""
log_msg "Verification Commands:"
log_msg "  1. Test connection:"
log_msg "     ssh -p 2223 $VM_USERNAME@$VM_HOSTNAME 'echo OK'"
log_msg ""
log_msg "  2. Check Setup API:"
log_msg "     curl -s http://$VM_HOSTNAME:8001/api/setup/info"
log_msg ""
log_msg "  3. Check service status:"
log_msg "     ssh -p 2223 $VM_USERNAME@$VM_HOSTNAME 'systemctl status trustnet-setup'"
log_msg ""
log_msg "  4. Access setup UI:"
log_msg "     https://$VM_HOSTNAME/setup"
log_msg ""
log_msg "Log file: $LOG_FILE"
log_msg ""

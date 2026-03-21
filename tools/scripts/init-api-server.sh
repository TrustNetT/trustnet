#!/bin/bash
#
# TrustNet v1.1.0 API Server Deployment Script
# Deploys FastAPI setup server for iOS QR integration
# Phase 2: v1.1.0 Features
#
# Principle: NEW CODE ONLY - Does not modify existing installation
#

set -e

# Enable strict error handling
trap 'echo "ERROR: API deployment failed at line $LINENO" >&2' ERR

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

log_info "Starting v1.1.0 API server deployment..."

# Configuration
VM_USER="${VM_USERNAME:-warden}"
VM_HOST="${VM_HOSTNAME:-trustnet.local}"
VM_PORT="${VM_SSH_PORT:-2223}"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/TrustNetT/trustnet/main}"
BRANCH="${TRUSTNET_BRANCH:-main}"
API_DIR="/opt/trustnet/api"
WEB_DIR="/opt/trustnet/web"

# Step 1: Verify VM Connectivity
log_info "Verifying VM connectivity..."
if ! ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" "echo 'VM reachable'" &>/dev/null; then
    log_error "Cannot reach VM at $VM_USER@$VM_HOST:$VM_PORT"
    exit 1
fi
log_success "VM connectivity verified"

# Step 2: Create API directory structure
log_info "Creating API directory structure on VM..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'EOF'
    mkdir -p /opt/trustnet/api
    mkdir -p /opt/trustnet/web/templates
    mkdir -p /opt/trustnet/venv
    chmod 750 /opt/trustnet/api
    chmod 750 /opt/trustnet/web
    echo "✓ Directories created"
EOF
log_success "API directories created"

# Step 3: Deploy setup.py to VM
log_info "Downloading setup.py from GitHub..."
if ! curl -fsSL "$RAW_URL/$BRANCH/core/versions/v1.1.0/api/setup_api.py?nocache=$(date +%s)" \
    -o /tmp/setup.py; then
    log_error "Failed to download setup.py - file may not exist on GitHub"
    exit 1
fi

log_info "Copying setup.py to VM..."
if ! scp -P "$VM_PORT" /tmp/setup.py "$VM_USER@$VM_HOST:$API_DIR/setup.py"; then
    log_error "Failed to SCP setup.py to VM"
    exit 1
fi
rm -f /tmp/setup.py
log_success "setup.py deployed"

# Step 4: Deploy first-setup.html to VM
log_info "Downloading first-setup.html from GitHub..."
if ! curl -fsSL "$RAW_URL/$BRANCH/core/versions/v1.1.0/web/templates/first-setup.html?nocache=$(date +%s)" \
    -o /tmp/first-setup.html; then
    log_error "Failed to download first-setup.html"
    exit 1
fi

log_info "Copying first-setup.html to VM..."
if ! scp -P "$VM_PORT" /tmp/first-setup.html "$VM_USER@$VM_HOST:$WEB_DIR/templates/first-setup.html"; then
    log_error "Failed to SCP first-setup.html to VM"
    exit 1
fi
rm -f /tmp/first-setup.html
log_success "first-setup.html deployed"

# Step 5: Deploy Python environment setup on VM
log_info "Setting up Python virtual environment on VM..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'PYTHONSETUP'
#!/bin/sh
set -e

log_msg() { echo "[$(date '+%H:%M:%S')] $*"; }

API_DIR="/opt/trustnet/api"
VENV_DIR="/opt/trustnet/venv"

log_msg "Creating Python virtual environment..."

# Create virtual environment
python3 -m venv "$VENV_DIR"
log_msg "✓ Virtual environment created"

# Activate and install requirements
. "$VENV_DIR/bin/activate"

# Install FastAPI and dependencies
log_msg "Installing Python packages..."
pip install --upgrade pip setuptools wheel
pip install fastapi==0.104.0
pip install uvicorn[standard]==0.24.0
pip install qrcode[pil]==7.4.2
pip install Pillow==10.0.0
pip install python-multipart==0.0.6

log_msg "✓ Python packages installed"

# Create requirements.txt in API dir for reference
cat > "$API_DIR/requirements.txt" << 'REQUIREMENTS'
fastapi==0.104.0
uvicorn[standard]==0.24.0
qrcode[pil]==7.4.2
Pillow==10.0.0
python-multipart==0.0.6
REQUIREMENTS

log_msg "✓ requirements.txt created"
log_msg "Python environment ready"

PYTHONSETUP

log_success "Python environment configured"

# Step 6: Create API startup configuration
log_info "Creating API configuration files..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'APICONFIG'
cat > /etc/conf.d/trustnet-api << 'CONF'
# TrustNet API Service Configuration

# Python virtual environment
PYTHON_VENV="/opt/trustnet/venv"

# API settings
API_HOST="127.0.0.1"
API_PORT="8001"
API_WORKERS="2"
API_LOG_LEVEL="info"

# Process management
API_USER="warden"
API_GROUP="warden"

# Service behavior
API_RESPAWN_DELAY=2
API_RESPAWN_MAX=5

CONF

echo "✓ API configuration created"
APICONFIG

log_success "API configuration deployed"

# Step 7: Create rc-service startup script (template)
log_info "Creating API startup service template..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'RCSERVICE'
cat > /tmp/trustnet-api.template << 'SERVICE'
#!/sbin/openrc-run
# TrustNet v1.1.0 API Service for Alpine Linux

description="TrustNet v1.1.0 FastAPI Setup Server"
command="/opt/trustnet/venv/bin/uvicorn"
command_args="setup:app --host 127.0.0.1 --port 8001 --workers 2"
command_background=true
pidfile="/run/trustnet-api.pid"
respawn_delay=2
respawn_max=5
respawn_period=1800

: ${API_USER:=warden}
: ${API_GROUP:=warden}
: ${start_stop_daemon_args:="-u $API_USER -g $API_GROUP"}

directory="/opt/trustnet/api"

depend() {
    need caddy
    after trustnet-blockchain
}

start_pre() {
    checkpath --directory --owner $API_USER:$API_GROUP --mode 0750 /opt/trustnet/api
    checkpath --file --owner $API_USER:$API_GROUP --mode 0640 /var/log/trustnet-api.log
}

start() {
    cd $directory
    start_stop_daemon --start \
        --pidfile "$pidfile" \
        --user $API_USER \
        --group $API_GROUP \
        --background \
        --env PYTHONUNBUFFERED=1 \
        --log /var/log/trustnet-api.log \
        --exec $command -- $command_args
    eend $?
}

stop() {
    start_stop_daemon --stop --pidfile "$pidfile"
    eend $?
}

restart() {
    stop
    sleep 1
    start
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

echo "✓ API service template created at /tmp/trustnet-api.template"
RCSERVICE

log_success "API service template prepared"

# Step 8: Create Caddy routing configuration (template)
log_info "Creating Caddy routing configuration..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'CADDYCONFIG'
cat > /tmp/api-routes.conf.template << 'CADDY'
# TrustNet v1.1.0 API Routing
# Add to /etc/caddy/conf.d/ or include in main Caddyfile

# Route API requests to FastAPI server
@api {
    path /api/*
}

# Route /setup to first-setup.html
@setup {
    path /setup*
}

reverse_proxy @api localhost:8001 {
    header_upstream Host localhost:8001
    header_upstream X-Real-IP {http.request.remote}
    header_upstream X-Forwarded-For {http.request.remote}
    header_upstream X-Forwarded-Proto {http.request.scheme}
}

# Serve first-setup.html for /setup path
route @setup {
    file_server {
        root /opt/trustnet/web
        index first-setup.html
    }
}

CADDY

echo "✓ Caddy routing template created"
CADDYCONFIG

log_success "Caddy configuration template prepared"

# Step 9: Create health check script
log_info "Creating API health check script..."
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'APIHEALTHCHECK'
cat > /opt/trustnet/scripts/health-api.sh << 'HEALTH'
#!/bin/sh
# v1.1.0 API Health Check

check_process() {
    if pgrep -f 'uvicorn' > /dev/null; then
        echo "✓ API process running"
        return 0
    else
        echo "✗ API process not running"
        return 1
    fi
}

check_port() {
    if nc -zv localhost 8001 2>/dev/null; then
        echo "✓ API port 8001 listening"
        return 0
    else
        echo "✗ API port 8001 not listening"
        return 1
    fi
}

check_endpoint() {
    if curl -s http://localhost:8001/health | grep -q "ok" 2>/dev/null; then
        echo "✓ Health endpoint responding"
        return 0
    else
        echo "⚠️  Health endpoint not responding"
        return 1
    fi
}

echo "v1.1.0 API Health Check"
echo "======================="
check_process && check_port && check_endpoint && echo "✅ API healthy" || echo "⚠️  Issues detected"

HEALTH

chmod +x /opt/trustnet/scripts/health-api.sh
echo "✓ API health check script created"
APIHEALTHCHECK

log_success "API health check script deployed"

# Step 10: Summary
log_info "========================================="
log_info "v1.1.0 API deployment complete"
log_info "========================================="
log_info ""
log_info "Deployed to VM:"
log_info "  - FastAPI server: $API_DIR/setup.py"
log_info "  - Setup UI: $WEB_DIR/templates/first-setup.html"
log_info "  - Python venv: /opt/trustnet/venv"
log_info "  - Service template: /tmp/trustnet-api.template"
log_info "  - Caddy config: /tmp/api-routes.conf.template"
log_info ""
log_info "Next steps (manual or automated):"
log_info "  1. Copy /tmp/trustnet-api.template to /etc/init.d/trustnet-api"
log_info "  2. Copy /tmp/api-routes.conf.template to /etc/caddy/conf.d/api-routes.conf"
log_info "  3. Enable service: rc-update add trustnet-api"
log_info "  4. Reload Caddy: rc-service caddy reload"
log_info "  5. Start service: rc-service trustnet-api start"
log_info "  6. Verify: curl http://localhost:8001/health"
log_info ""
log_success "v1.1.0 API deployment phase complete"

exit 0

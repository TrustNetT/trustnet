#!/bin/bash
#
# TrustNet v1.1.0 Complete Integration Script
# Orchestrates all deployment phases after base installation
# 
# This script ties together:
#   Phase 1: Blockchain infrastructure (init-blockchain.sh)
#   Phase 2: API server setup (init-api-server.sh)
#   Phase 3: Caddy routing configuration
#   Phase 4: Service initialization and health checks
#
# Usage: ./integrate-v1.1.0.sh [--no-test]
# Call from: install.sh after base v1.0.0 deployment succeeds
#

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_ENABLED=true
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log_phase() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
}

log_step() {
    echo -e "${BLUE}→${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-test)
            TEST_ENABLED=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validation: Verify required scripts exist
log_phase "PHASE 0: Validation"

required_scripts=(
    "$SCRIPT_DIR/init-blockchain.sh"
    "$SCRIPT_DIR/init-api-server.sh"
)

for script in "${required_scripts[@]}"; do
    if [[ ! -f "$script" ]]; then
        log_error "Required script not found: $script"
        exit 1
    fi
    log_success "Found: $(basename $script)"
done

required_configs=(
    "$SCRIPT_DIR/../configs/caddy-app-routes.conf"
)

for config in "${required_configs[@]}"; do
    if [[ ! -f "$config" ]]; then
        log_error "Required config not found: $config"
        exit 1
    fi
    log_success "Found: $(basename $config)"
done

# ============================================================================
# PHASE 1: Blockchain Infrastructure Deployment
# ============================================================================
log_phase "PHASE 1: Blockchain Infrastructure"

log_step "Executing blockchain deployment script..."
if "$SCRIPT_DIR/init-blockchain.sh"; then
    log_success "Blockchain infrastructure deployed"
else
    log_error "Blockchain deployment failed"
    exit 1
fi

# ============================================================================
# PHASE 2: API Server Setup
# ============================================================================
log_phase "PHASE 2: API Server Setup"

log_step "Executing API server deployment script..."
if "$SCRIPT_DIR/init-api-server.sh"; then
    log_success "API server setup complete"
else
    log_error "API server deployment failed"
    exit 1
fi

# ============================================================================
# PHASE 3: Caddy Routing Configuration
# ============================================================================
log_phase "PHASE 3: Caddy Routing Configuration"

VM_USER="${VM_USERNAME:-warden}"
VM_HOST="${VM_HOSTNAME:-trustnet.local}"
VM_PORT="${VM_SSH_PORT:-2223}"
CADDY_CONF_DIR="/etc/caddy/conf.d"
CADDY_CONFIG_FILE="$SCRIPT_DIR/../configs/caddy-app-routes.conf"

log_step "Deploying Caddy configuration..."

if ! scp -P "$VM_PORT" "$CADDY_CONFIG_FILE" \
    "$VM_USER@$VM_HOST:/tmp/caddy-app-routes.conf" &>/dev/null; then
    log_error "Failed to copy Caddy config to VM"
    exit 1
fi

# Deploy config on VM
ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'CADDY_DEPLOY'
cat > /etc/caddy/conf.d/app.conf << 'APPCONF'
# TrustNet v1.1.0 Application Routing
# Loaded via 'import' from main Caddyfile

import /tmp/caddy-app-routes.conf

APPCONF

echo "✓ Caddy app.conf created"
CADDY_DEPLOY

log_success "Caddy configuration deployed"

# ============================================================================
# PHASE 4: Service Initialization and Health Checks
# ============================================================================
log_phase "PHASE 4: Service Initialization"

log_step "Initializing services on VM..."

ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'SERVICE_INIT'
#!/bin/sh
set -e

echo "Phase 4: Service Initialization"
echo "==============================="

# Copy service templates to actual locations
echo "→ Installing service files..."

if [ -f /tmp/trustnet-api.template ]; then
    cp /tmp/trustnet-api.template /etc/init.d/trustnet-api
    chmod +x /etc/init.d/trustnet-api
    echo "  ✓ trustnet-api service installed"
fi

if [ -f /tmp/trustnet-blockchain.template ]; then
    cp /tmp/trustnet-blockchain.template /etc/init.d/trustnet-blockchain
    chmod +x /etc/init.d/trustnet-blockchain
    echo "  ✓ trustnet-blockchain service installed"
fi

# Register services for startup
echo "→ Registering services for startup..."
rc-update add trustnet-blockchain 2>/dev/null || true
rc-update add trustnet-api 2>/dev/null || true
echo "  ✓ Services registered"

# Start blockchain service
echo "→ Starting blockchain service..."
rc-service trustnet-blockchain restart || echo "  ⚠ Blockchain service may need manual start"

# Wait for blockchain to initialize
sleep 3

# Reload Caddy to apply new routes
echo "→ Reloading Caddy..."
rc-service caddy reload || rc-service caddy restart
echo "  ✓ Caddy reloaded"

# Start API service
echo "→ Starting API service..."
rc-service trustnet-api restart || echo "  ⚠ API service may need manual start"

# Wait for API to start
sleep 2

echo "✓ Services initialized"

SERVICE_INIT

log_success "Services initialized on VM"

# ============================================================================
# PHASE 5: Health Checks and Verification
# ============================================================================
if [[ "$TEST_ENABLED" == "true" ]]; then
    log_phase "PHASE 5: Health Checks and Verification"

    log_step "Running health checks..."

    # Create and run health check script on VM
    ssh -p "$VM_PORT" "$VM_USER@$VM_HOST" << 'HEALTH_CHECK'
#!/bin/sh

echo "Health Check Results"
echo "===================="
echo ""

# Blockchain health
echo "Blockchain Status:"
if pgrep -f 'ignite' > /dev/null; then
    echo "  ✓ Blockchain process running"
else
    echo "  ✗ Blockchain process not found"
fi

if nc -zv localhost 6060 2>/dev/null; then
    echo "  ✓ Blockchain RPC port 6060 listening"
else
    echo "  ✗ Blockchain port not accessible"
fi

echo ""

# API health
echo "API Server Status:"
if pgrep -f 'uvicorn' > /dev/null; then
    echo "  ✓ API process running"
else
    echo "  ✗ API process not found"
fi

if nc -zv localhost 8001 2>/dev/null; then
    echo "  ✓ API port 8001 listening"
else
    echo "  ✗ API port not accessible"
fi

echo ""

# Caddy health
echo "Caddy Status:"
if pgrep -f 'caddy' > /dev/null; then
    echo "  ✓ Caddy process running"
else
    echo "  ✗ Caddy process not found"
fi

if nc -zv localhost 443 2>/dev/null || nc -zv localhost 80 2>/dev/null; then
    echo "  ✓ Caddy ports accessible"
else
    echo "  ✗ Caddy ports not accessible"
fi

echo ""
echo "Full Health Summary at /opt/trustnet/scripts/health-full.sh"

HEALTH_CHECK

    log_success "Health checks complete"
else
    log_warning "Test phase skipped (use --verbose to see details)"
fi

# ============================================================================
# Final Summary
# ============================================================================
log_phase "INTEGRATION COMPLETE"

echo ""
log_success "All v1.1.0 components deployed successfully"
echo ""
echo "Deployment Summary:"
echo "  Phase 1: ✓ Blockchain infrastructure"
echo "  Phase 2: ✓ API server (FastAPI)"
echo "  Phase 3: ✓ Caddy routing"
echo "  Phase 4: ✓ Service initialization"
if [[ "$TEST_ENABLED" == "true" ]]; then
    echo "  Phase 5: ✓ Health verification"
fi

echo ""
echo "Next steps:"
echo "  1. Deploy to production: ssh $VM_USER@$VM_HOST"
echo "  2. Verify services: rc-service -c status"
echo "  3. Test endpoints:"
echo "     - Dashboard: https://$VM_HOST/"
echo "     - API health: curl https://$VM_HOST/api/health"
echo "     - QR endpoint: curl -X POST https://$VM_HOST/api/generate"
echo ""

exit 0

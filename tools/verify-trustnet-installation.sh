#!/bin/bash
# verify-trustnet-installation.sh
# 
# Post-installation validation for TrustNet Node
# Checks critical configuration on both host and VM
# 
# Usage: bash verify-trustnet-installation.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILURES=0

log_ok() {
    echo -e "${GREEN}✅${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
    ((FAILURES++))
}

log_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

echo "════════════════════════════════════════════════════════════════"
echo "   TrustNet Installation Verification"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
echo "PHASE 1: Checking Host Configuration"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check host /etc/hosts IPv4 entries
if grep -q "127.0.0.1 trustnet.local" /etc/hosts 2>/dev/null; then
    log_ok "Host /etc/hosts IPv4 entry: trustnet.local"
else
    log_error "Host /etc/hosts missing IPv4 entry for trustnet.local"
    log_warning "  CRITICAL: Without IPv4, browser cannot access Web UI via QEMU forwarding"
    log_warning "  Fix: echo '127.0.0.1 trustnet.local rpc.trustnet.local api.trustnet.local' | sudo tee -a /etc/hosts"
fi

# Check host /etc/hosts IPv6 entries
if grep -q "::1 trustnet.local" /etc/hosts 2>/dev/null; then
    log_ok "Host /etc/hosts IPv6 entry: trustnet.local"
else
    log_warning "Host /etc/hosts missing IPv6 entry (optional for QEMU forwarding)"
fi

# Check RPC subdomain IPv4
if grep -q "127.0.0.1.*rpc.trustnet.local" /etc/hosts 2>/dev/null; then
    log_ok "Host /etc/hosts IPv4 entry: rpc.trustnet.local"
else
    log_error "Host /etc/hosts missing IPv4 entry for rpc.trustnet.local"
fi

# Check API subdomain IPv4
if grep -q "127.0.0.1.*api.trustnet.local" /etc/hosts 2>/dev/null; then
    log_ok "Host /etc/hosts IPv4 entry: api.trustnet.local"
else
    log_error "Host /etc/hosts missing IPv4 entry for api.trustnet.local"
fi

echo ""

# ============================================================================
echo "PHASE 2: Checking VM Configuration"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Check if VM is running
if ssh -o ConnectTimeout=5 trustnet "true" 2>/dev/null; then
    log_ok "VM is reachable via SSH"
else
    log_error "VM is NOT reachable via SSH (ensure QEMU VM is running)"
    echo ""
    echo "To start the VM, run:"
    echo "  ~/vms/trustnet/start-trustnet.sh"
    exit 1
fi

# Check VM /etc/hosts IPv4
if ssh trustnet "grep -q '127.0.0.1 trustnet.local' /etc/hosts" 2>/dev/null; then
    log_ok "VM /etc/hosts IPv4 entry: trustnet.local"
else
    log_error "VM /etc/hosts missing IPv4 entry for trustnet.local"
fi

# Check VM /etc/hosts IPv6
if ssh trustnet "grep -q '::1 trustnet.local' /etc/hosts" 2>/dev/null; then
    log_ok "VM /etc/hosts IPv6 entry: trustnet.local"
else
    log_warning "VM /etc/hosts missing IPv6 entry (optional)"
fi

# Check Caddyfile exists
if ssh trustnet "sudo test -f /etc/caddy/Caddyfile" 2>/dev/null; then
    log_ok "Caddy configuration exists"
    
    # Check Caddyfile has dual-stack binding
    if ssh trustnet "sudo grep -q ':443' /etc/caddy/Caddyfile" 2>/dev/null; then
        log_ok "Caddyfile uses port 443 binding (IPv4+IPv6 compatible)"
    else
        log_error "Caddyfile does NOT have ':443' binding (check for 'bind ::')"
    fi
    
    # Check for trustnet.local block
    if ssh trustnet "sudo grep -q 'trustnet.local' /etc/caddy/Caddyfile" 2>/dev/null; then
        log_ok "Caddyfile has trustnet.local configuration"
    else
        log_error "Caddyfile missing trustnet.local block"
    fi
    
    # Check for reverse proxies
    if ssh trustnet "sudo grep -q 'reverse_proxy.*127.0.0.1.*26657' /etc/caddy/Caddyfile" 2>/dev/null; then
        log_ok "Caddyfile has RPC reverse proxy (port 26657)"
    else
        log_error "Caddyfile missing RPC reverse proxy"
    fi
    
    if ssh trustnet "sudo grep -q 'reverse_proxy.*127.0.0.1.*1317' /etc/caddy/Caddyfile" 2>/dev/null; then
        log_ok "Caddyfile has REST API reverse proxy (port 1317)"
    else
        log_error "Caddyfile missing REST API reverse proxy"
    fi
else
    log_error "Caddy configuration NOT found at /etc/caddy/Caddyfile"
fi

# Check Caddy is running
if ssh trustnet "sudo rc-service caddy status" 2>/dev/null | grep -q "running\|started"; then
    log_ok "Caddy service is running"
else
    log_warning "Caddy service may not be running (or unable to determine status)"
fi

# Check services listening
if ssh trustnet "sudo netstat -tlnp 2>/dev/null | grep -q ':443'" || \
   ssh trustnet "sudo ss -tlnp 2>/dev/null | grep -q ':443'"; then
    log_ok "Port 443 (HTTPS) is listening"
else
    log_warning "Unable to verify port 443 listening (may be permission issue)"
fi

echo ""

# ============================================================================
echo "PHASE 3: Testing Service Accessibility"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Test Web UI
if timeout 5 curl -4 -k -I https://trustnet.local/ >/dev/null 2>&1; then
    log_ok "Web UI accessible at https://trustnet.local/"
else
    log_error "Web UI NOT accessible at https://trustnet.local/"
    log_warning "  This means /etc/hosts IPv4 entry might be missing"
fi

# Test RPC endpoint
if timeout 5 curl -4 -k -I https://rpc.trustnet.local/ >/dev/null 2>&1; then
    log_ok "RPC endpoint accessible at https://rpc.trustnet.local/"
else
    log_error "RPC endpoint NOT accessible at https://rpc.trustnet.local/"
fi

# Test REST API
if timeout 5 curl -4 -k -I https://api.trustnet.local/ >/dev/null 2>&1; then
    log_ok "REST API accessible at https://api.trustnet.local/"
else
    log_error "REST API NOT accessible at https://api.trustnet.local/"
fi

echo ""

# ============================================================================
echo "PHASE 4: Certificate Verification"
echo "════════════════════════════════════════════════════════════════"
echo ""

if ssh trustnet "sudo test -f /etc/caddy/certs/trustnet.local.crt" 2>/dev/null; then
    log_ok "SSL certificate exists"
    
    # Check for wildcard SAN
    if ssh trustnet "sudo openssl x509 -in /etc/caddy/certs/trustnet.local.crt -text 2>/dev/null | grep -q '\\*.trustnet.local'" 2>/dev/null; then
        log_ok "Certificate includes wildcard SAN (*.trustnet.local)"
    fi
    
    # Check for specific SANs
    if ssh trustnet "sudo openssl x509 -in /etc/caddy/certs/trustnet.local.crt -text 2>/dev/null | grep -q 'trustnet.local'" && \
       ssh trustnet "sudo openssl x509 -in /etc/caddy/certs/trustnet.local.crt -text 2>/dev/null | grep -q 'rpc.trustnet.local'" && \
       ssh trustnet "sudo openssl x509 -in /etc/caddy/certs/trustnet.local.crt -text 2>/dev/null | grep -q 'api.trustnet.local'"; then
        log_ok "Certificate includes all Subject Alternative Names (SANs)"
    else
        log_warning "Certificate may not have all required SANs"
    fi
else
    log_error "SSL certificate NOT found at /etc/caddy/certs/trustnet.local.crt"
fi

echo ""

# ============================================================================
echo "SUMMARY"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! TrustNet is ready to use.${NC}"
    echo ""
    echo "Access points:"
    echo "  🌐 Web UI:   https://trustnet.local"
    echo "  📊 RPC:      https://rpc.trustnet.local"
    echo "  📡 REST API: https://api.trustnet.local"
    echo "  🔑 SSH:      ssh trustnet"
    echo ""
    exit 0
else
    echo -e "${RED}❌ $FAILURES check(s) failed.${NC}"
    echo ""
    echo "Critical issues to fix:"
    echo "  1. Host /etc/hosts IPv4 entry (REQUIRED for browser access)"
    echo "  2. VM /etc/hosts IPv4 entry (REQUIRED for Caddy routing)"
    echo "  3. Caddyfile configuration (must have :443 binding)"
    echo ""
    echo "Run this script again after fixing issues."
    echo ""
    exit 1
fi

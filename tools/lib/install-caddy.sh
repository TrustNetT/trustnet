#!/bin/bash
# install-caddy.sh - Install Caddy reverse proxy on Factory VM
# Part of Phase 3.5 modular architecture

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

install_caddy_via_ssh() {
    log_info "Installing Caddy reverse proxy via SSH..."
    
    # Create Caddyfile content - Dual-stack (IPv4+IPv6) with subdomains
    # - trustnet.local → Web UI (file server)
    # - rpc.trustnet.local → RPC endpoint (reverse proxy to :26657)
    # - api.trustnet.local → REST API endpoint (reverse proxy to :1317)
    # Using port 443 binding allows both IPv4 and IPv6, enabling QEMU port forwarding
    cat > /tmp/Caddyfile << CADDY_EOF
# Web UI - serves static content
:443 trustnet.local {
    root * /var/www/trustnet
    file_server
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
}

# RPC endpoint - reverse proxy to local blockchain RPC
rpc.trustnet.local:443 {
    reverse_proxy http://127.0.0.1:26657
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
}

# REST API endpoint - reverse proxy to local blockchain REST API
api.trustnet.local:443 {
    reverse_proxy http://127.0.0.1:1317
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
}
CADDY_EOF
    
    # Install Caddy
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        ${VM_USERNAME}@localhost << EOF
echo "Enabling Alpine community repository..."
echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" | sudo tee -a /etc/apk/repositories
sudo apk update

echo "Installing Caddy..."
sudo apk add caddy

echo "Creating Caddy configuration and certificate directories..."
sudo mkdir -p /etc/caddy
sudo mkdir -p /etc/caddy/certs

echo "Generating 365-day self-signed certificate for ${VM_HOSTNAME} and subdomains..."
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\
    -keyout /etc/caddy/certs/${VM_HOSTNAME}.key \\
    -out /etc/caddy/certs/${VM_HOSTNAME}.crt \\
    -subj '/CN=${VM_HOSTNAME}' \\
    -addext 'subjectAltName=DNS:${VM_HOSTNAME},DNS:rpc.${VM_HOSTNAME},DNS:api.${VM_HOSTNAME}'

# Set ownership to caddy user for permission access
sudo chown -R caddy:caddy /etc/caddy/certs
sudo chmod 644 /etc/caddy/certs/${VM_HOSTNAME}.crt
sudo chmod 640 /etc/caddy/certs/${VM_HOSTNAME}.key
EOF
    
    # Copy Caddyfile
    scp -i "$VM_SSH_PRIVATE_KEY" -P "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        /tmp/Caddyfile ${VM_USERNAME}@localhost:/tmp/
    
    # Configure and start Caddy
    ssh -i "$VM_SSH_PRIVATE_KEY" -p "$VM_SSH_PORT" \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o IdentitiesOnly=yes \
        -o ConnectTimeout=60 -o ServerAliveInterval=30 \
        ${VM_USERNAME}@localhost << 'EOF'
# Configure VM's /etc/hosts with subdomains
echo "Configuring VM hostname resolution..."
if ! grep -q "trustnet.local" /etc/hosts; then
    echo "::1 trustnet.local rpc.trustnet.local api.trustnet.local" | sudo tee -a /etc/hosts > /dev/null
fi

# Also add IPv4 loopback for compatibility
if ! grep -q "127.0.0.1.*trustnet.local" /etc/hosts; then
    echo "127.0.0.1 trustnet.local rpc.trustnet.local api.trustnet.local" | sudo tee -a /etc/hosts > /dev/null
fi

sudo mv /tmp/Caddyfile /etc/caddy/Caddyfile
sudo chown root:root /etc/caddy/Caddyfile
sudo chmod 644 /etc/caddy/Caddyfile

# Enable Caddy to start on boot
sudo rc-update add caddy default

# Start Caddy service
sudo rc-service caddy start

echo "✓ Caddy installed, configured, and started"
EOF
    
    rm -f /tmp/Caddyfile
    
    if [ $? -eq 0 ]; then
        log_success "✓ Caddy installed, configured, and started"
    else
        log_error "Caddy installation failed"
        return 1
    fi
}

# Export functions
export -f install_caddy_via_ssh

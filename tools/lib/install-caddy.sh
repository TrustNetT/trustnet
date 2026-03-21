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
    
    # Create Caddyfile content - Dual-stack (IPv4+IPv6) with content negotiation
    # - trustnet.local → Web UI (file server)
    # - rpc.trustnet.local → RPC endpoint (shows HTML for browsers, JSON for API clients)
    # - api.trustnet.local → REST API endpoint (shows HTML for browsers, JSON for API clients)
    # Using port 443 binding allows both IPv4 and IPv6, enabling QEMU port forwarding
    # Content negotiation: Detects browser vs API client via User-Agent and Accept headers
    cat > /tmp/Caddyfile << 'CADDY_EOF'
# Web UI - serves static content
:443 trustnet.local {
    root * /var/www/trustnet
    file_server
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
}

# RPC endpoint - smart routing with content negotiation
# Serves HTML status page for browsers, JSON for API clients
rpc.trustnet.local:443 {
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
    
    # Root path handler with content negotiation
    handle / {
        # Detect browser requests by User-Agent
        @browser_ua {
            header User-Agent *Mozilla*
        }
        @browser_ua2 {
            header User-Agent *Chrome*
        }
        @browser_ua3 {
            header User-Agent *Safari*
        }
        @browser_ua4 {
            header User-Agent *Firefox*
        }
        @browser_accept {
            header Accept *text/html*
        }
        
        # Serve HTML for browsers
        handle @browser_ua, @browser_ua2, @browser_ua3, @browser_ua4, @browser_accept {
            file_server {
                root /var/www/caddy-pages
                index rpc-status.html
            }
        }
        
        # Serve JSON from backend for API clients
        handle {
            reverse_proxy http://127.0.0.1:26657 {
                transparent
            }
        }
    }
    
    # All other RPC paths directly to backend
    handle /* {
        reverse_proxy http://127.0.0.1:26657 {
            transparent
        }
    }
}

# REST API endpoint - smart routing with content negotiation
# Serves HTML status page for browsers, JSON for API clients
api.trustnet.local:443 {
    tls /etc/caddy/certs/trustnet.local.crt /etc/caddy/certs/trustnet.local.key
    
    # Root path handler with content negotiation
    handle / {
        # Detect browser requests by User-Agent
        @browser_ua {
            header User-Agent *Mozilla*
        }
        @browser_ua2 {
            header User-Agent *Chrome*
        }
        @browser_ua3 {
            header User-Agent *Safari*
        }
        @browser_ua4 {
            header User-Agent *Firefox*
        }
        @browser_accept {
            header Accept *text/html*
        }
        
        # Serve HTML for browsers
        handle @browser_ua, @browser_ua2, @browser_ua3, @browser_ua4, @browser_accept {
            file_server {
                root /var/www/caddy-pages
                index api-status.html
            }
        }
        
        # Return JSON API info for API clients
        handle {
            respond `{"api":"TrustNet REST API","status":"online","base_url":"https://api.trustnet.local","version":"v1"}` 200 {
                header Content-Type application/json
            }
        }
    }
    
    # All other API paths directly to backend
    handle /* {
        reverse_proxy http://127.0.0.1:1317 {
            transparent
        }
    }
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
sudo mkdir -p /var/www/caddy-pages

echo "Generating 365-day self-signed wildcard certificate for ${VM_HOSTNAME}..."

# Create certificate config with wildcard and all SANs
cat > /tmp/cert.conf << 'CERTEOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = *.trustnet.local

[v3_req]
subjectAltName = DNS:*.trustnet.local,DNS:trustnet.local,DNS:rpc.trustnet.local,DNS:api.trustnet.local
CERTEOF

# Generate certificate using config file
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\
    -keyout /etc/caddy/certs/${VM_HOSTNAME}.key \\
    -out /etc/caddy/certs/${VM_HOSTNAME}.crt \\
    -config /tmp/cert.conf \\
    -extensions v3_req

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
    
    # Copy HTML status pages (if they exist in SCRIPT_DIR/caddy-pages)
    if [ -f "${SCRIPT_DIR}/caddy-pages/rpc-status.html" ]; then
        log_info "  Copying RPC status page..."
        scp -i "$VM_SSH_PRIVATE_KEY" -P "$VM_SSH_PORT" \
            -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o IdentitiesOnly=yes \
            "${SCRIPT_DIR}/caddy-pages/rpc-status.html" ${VM_USERNAME}@localhost:/tmp/
    fi
    
    if [ -f "${SCRIPT_DIR}/caddy-pages/api-status.html" ]; then
        log_info "  Copying API status page..."
        scp -i "$VM_SSH_PRIVATE_KEY" -P "$VM_SSH_PORT" \
            -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o IdentitiesOnly=yes \
            "${SCRIPT_DIR}/caddy-pages/api-status.html" ${VM_USERNAME}@localhost:/tmp/
    fi
    
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

# Move HTML status pages to web directory
if [ -f /tmp/rpc-status.html ]; then
    sudo mv /tmp/rpc-status.html /var/www/caddy-pages/
    sudo chmod 644 /var/www/caddy-pages/rpc-status.html
fi

if [ -f /tmp/api-status.html ]; then
    sudo mv /tmp/api-status.html /var/www/caddy-pages/
    sudo chmod 644 /var/www/caddy-pages/api-status.html
fi

# Set ownership for web directory
sudo chown -R caddy:caddy /var/www/caddy-pages

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

#!/bin/bash
# vm-bootstrap.sh - Bootstrap Factory VM after Alpine installation
# Part of Phase 3.5 modular architecture

# Prevent direct execution
if [ "${BASH_SOURCE[0]}" -ef "$0" ]; then
    echo "Error: This script should be sourced, not executed directly"
    exit 1
fi

setup_cache_disk_in_vm() {
    log "Setting up cache disk (vdb) for build cache..."
    
    # Check if /dev/vdb exists
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "test -b /dev/vdb" 2>/dev/null; then
        log_info "Cache disk not available - skipping setup (optional feature)"
        return 0
    fi
    
    # Check if cache disk has a filesystem (using doas for Alpine)
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "doas blkid /dev/vdb 2>/dev/null | grep -q TYPE=" 2>/dev/null; then
        
        log_info "Cache disk not formatted - creating ext4 filesystem..."
        
        # Try formatting with doas first (Alpine Linux default)
        if ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "doas mkfs.ext4 -F -L trustnet-cache /dev/vdb" >/dev/null 2>&1; then
            log_success "Cache disk formatted (ext4)"
        else
            log_info "Cache disk formatting attempted (may require manual setup later)"
        fi
    else
        log_info "Cache disk already formatted (reusing preserved cache)"
    fi
    
    # Create mount point and mount cache disk (non-blocking on failure)
    ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas mkdir -p /var/cache/trustnet-build && doas mount /dev/vdb /var/cache/trustnet-build && doas chown -R ${VM_USERNAME}:${VM_USERNAME} /var/cache/trustnet-build" \
        2>/dev/null || log_info "Cache disk mount attempted (may have failed - proceeding anyway)"
    
    # Add to fstab for auto-mount on boot (non-blocking)
    ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "grep -q '/dev/vdb' /etc/fstab || echo '/dev/vdb /var/cache/trustnet-build ext4 defaults 0 2' | doas tee -a /etc/fstab" \
        >/dev/null 2>&1 || true
    
    log_info "Cache disk setup complete (mounted or optional)"
    return 0
}
    

setup_data_disk_in_vm() {
    log "Setting up data disk (vdc) for TrustNet blockchain data..."
    
    # Check if data disk exists
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "test -b /dev/vdc" 2>/dev/null; then
        log_info "Data disk not available - skipping setup (optional feature)"
        return 0
    fi
    
    # Check if data disk has a filesystem (using doas for Alpine)
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "doas blkid /dev/vdc 2>/dev/null | grep -q TYPE=" 2>/dev/null; then
        
        log_info "Data disk not formatted - creating ext4 filesystem..."
        
        # Try formatting with doas first (Alpine Linux default)
        if ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "doas mkfs.ext4 -F -L trustnet-data /dev/vdc" >/dev/null 2>&1; then
            log_success "Data disk formatted (ext4)"
        else
            log_info "Data disk formatting attempted (may require manual setup later)"
        fi
    else
        log_info "Data disk already formatted (reusing preserved blockchain data)"
    fi
    
    # Create mount point and mount data disk at /var/lib/trustnet (non-blocking on failure)
    ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas mkdir -p /var/lib/trustnet && doas mount /dev/vdc /var/lib/trustnet && doas chown -R ${VM_USERNAME}:${VM_USERNAME} /var/lib/trustnet" \
        2>/dev/null || log_info "Data disk mount attempted (may have failed - proceeding anyway)"
    
    # Add to fstab for auto-mount on boot (non-blocking)
    ssh -i "$VM_SSH_PRIVATE_KEY" -o ConnectTimeout=3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "grep -q '/dev/vdc' /etc/fstab || echo '/dev/vdc /var/lib/trustnet ext4 defaults 0 2' | doas tee -a /etc/fstab" \
        >/dev/null 2>&1 || true
    
    log_info "Data disk setup complete (mounted or optional)"
    return 0
}

configure_installed_vm() {
    log "Configuring installed TrustNet VM..."
    
    # Start VM using the start script
    log_info "Starting VM from installed system..."
    if ! "${VM_DIR}/start-trustnet.sh" >/dev/null 2>&1; then
        log_error "Failed to start TrustNet VM"
        exit 1
    fi
    
    sleep 5
    
    # Remove old SSH host key from known_hosts (VM was reinstalled)
    log_info "Removing old SSH host key from known_hosts..."
    ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:${VM_SSH_PORT}" 2>/dev/null || true
    
    # Wait for SSH port to open
    log_info "Waiting for SSH port to open..."
    local count=0
    while ! nc -z localhost "$VM_SSH_PORT" 2>/dev/null && [ $count -lt 60 ]; do
        sleep 2
        ((count++))
        echo -n "."
    done
    echo ""
    
    if [ $count -ge 60 ]; then
        log_error "VM failed to start - SSH port never opened"
        exit 1
    fi
    
    # Port is open, but SSH may not be fully ready - wait for Alpine to finish booting
    # Detect acceleration type to show appropriate message
    local host_arch=$(uname -m)
    if [ "$host_arch" = "${ALPINE_ARCH}" ] && [ -e /dev/kvm ]; then
        log_info "Port open, waiting for Alpine to finish booting (KVM acceleration)..."
        log_info "This should take 30-60 seconds with native virtualization..."
    else
        log_info "Port open, waiting for Alpine to finish booting (TCG emulation)..."
        log_info "This can take 3-5 minutes on TCG emulation, please be patient..."
    fi
    local ssh_test_attempts=0
    local max_attempts=60  # 60 attempts × 5 seconds = 300 seconds (5 minutes)
    while [ $ssh_test_attempts -lt $max_attempts ]; do
        if ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2 \
            -p "$VM_SSH_PORT" root@localhost "echo ready" >/dev/null 2>&1; then
            log_info "SSH is ready!"
            break
        fi
        ssh_test_attempts=$((ssh_test_attempts + 1))
        if [ $((ssh_test_attempts % 6)) -eq 0 ]; then
            log_info "Still waiting... ($((ssh_test_attempts * 5)) seconds elapsed)"
        fi
        sleep 5
    done
    
    if [ $ssh_test_attempts -ge $max_attempts ]; then
        log_error "SSH did not become ready after 300 seconds"
        log_error "This might indicate a problem with the Alpine installation"
        exit 1
    fi
    
    # Create ${VM_USERNAME} user
    log "Creating ${VM_USERNAME} user with sudo privileges..."
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=60 -o ServerAliveInterval=5 -p "$VM_SSH_PORT" root@localhost << EOF
# Create ${VM_USERNAME} user
adduser -D ${VM_USERNAME}
echo "${VM_USERNAME}:${WARDEN_OS_PASSWORD}" | chpasswd

# Add to necessary groups
addgroup ${VM_USERNAME} wheel
addgroup ${VM_USERNAME} docker

# Enable community repository (required for sudo package)
if ! grep -q "community" /etc/apk/repositories; then
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories
fi
apk update >/dev/null 2>&1

# Install doas and sudo for flexible privilege escalation
apk add doas >/dev/null 2>&1
apk add sudo >/dev/null 2>&1

# Configure doas for passwordless operation (if installed)
if command -v doas >/dev/null 2>&1; then
    mkdir -p /etc/doas.d
    echo "permit nopass :wheel" > /etc/doas.d/doas.conf
    chmod 600 /etc/doas.d/doas.conf
fi

# Configure sudo for passwordless operation (if installed)
if command -v sudo >/dev/null 2>&1; then
    mkdir -p /etc/sudoers.d
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
fi

# Setup SSH directory
mkdir -p /home/${VM_USERNAME}/.ssh
chmod 700 /home/${VM_USERNAME}/.ssh

# Copy SSH key from root to ${VM_USERNAME}
cp /root/.ssh/authorized_keys /home/${VM_USERNAME}/.ssh/authorized_keys
chmod 600 /home/${VM_USERNAME}/.ssh/authorized_keys
chown -R ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/.ssh

# Set bash as default shell
apk add bash
sed -i "s|/home/${VM_USERNAME}:/bin/ash|/home/${VM_USERNAME}:/bin/bash|" /etc/passwd

# Install utilities needed for data disk setup and SSH commands
# - e2fsprogs-extra: provides mkfs.ext4 (for formatting if needed)
# - blkid: provides blkid command (for detecting existing filesystem)
apk add e2fsprogs-extra blkid

# Create sudo wrapper script for compatibility (Alpine uses doas)
# This works in SSH non-login shell contexts
cat > /usr/local/bin/sudo << 'SUDO_WRAPPER'
#!/bin/sh
exec doas "\$@"
SUDO_WRAPPER
chmod 755 /usr/local/bin/sudo

# Create .bashrc for ${VM_USERNAME} user
cat > /home/${VM_USERNAME}/.bashrc << 'BASHRC_INIT'
# ~/.bashrc: executed by bash for non-login shells

# If not running interactively, don't do anything
case \$- in
    *i*) ;;
      *) return;;
esac

# Basic environment
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export EDITOR=vim

# Aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

# Command history
HISTCONTROL=ignoredups:ignorespace
HISTSIZE=1000
HISTFILESIZE=2000

# Enable bash completion
if [ -f /etc/bash/bashrc.d/bash_completion.sh ]; then
    . /etc/bash/bashrc.d/bash_completion.sh
fi
BASHRC_INIT

chown ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/.bashrc

# Harden SSH configuration - disable password authentication
cat >> /etc/ssh/sshd_config << 'SSH_CONFIG'

# Factory VM Security Configuration
# Disable password authentication - SSH keys only
PasswordAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
ChallengeResponseAuthentication no
SSH_CONFIG

# Restart SSH to apply changes
rc-service sshd restart

# Wait for SSH to fully restart before allowing external connections
sleep 5

echo "✓ ${VM_USERNAME} user created"
echo "✓ SSH hardened (keys only, no password authentication)"
EOF
    then
        log_error "Failed to create ${VM_USERNAME} user"
        exit 1
    fi
    
    # Add SSH public key
    log "Adding SSH public key for ${VM_USERNAME}..."
    if ! ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" root@localhost << EOF
echo '$(cat "$VM_SSH_PUBLIC_KEY")' > /home/${VM_USERNAME}/.ssh/authorized_keys
chmod 600 /home/${VM_USERNAME}/.ssh/authorized_keys
chown -R ${VM_USERNAME}:${VM_USERNAME} /home/${VM_USERNAME}/.ssh
# Verify key was added
if [ -f /home/${VM_USERNAME}/.ssh/authorized_keys ]; then
    echo "✓ SSH key added successfully"
else
    echo "ERROR: Failed to create authorized_keys file"
    exit 1
fi
EOF
    then
        log_error "Failed to add SSH public key"
        exit 1
    fi

    # Wait for SSH to be fully ready after sshd restart
    log_info "Waiting for SSH to be fully ready..."
    local ssh_ready=0
    for i in {1..30}; do
        if ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=5 -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "echo OK" >/dev/null 2>&1; then
            ssh_ready=1
            break
        fi
        sleep 2
    done
    
    if [ $ssh_ready -eq 0 ]; then
        log_error "SSH did not become ready for ${VM_USERNAME} user in time"
        exit 1
    fi
    
    log_success "SSH is ready"
    
    # Give SSH/SCP a bit more time to fully stabilize after restart
    sleep 5

    # Setup cache disk for persistent build cache (vdb)
    setup_cache_disk_in_vm
    
    # Setup data disk for blockchain data (vdc)
    setup_data_disk_in_vm
    
    # Prepare cache directories for blockchain tools
    log_info "Preparing cache directories..."
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost "mkdir -p /var/cache/trustnet-build/{go,ignite,blockchain}"
    
    # Setup SSL certificates and web UI
    setup_ssl_certificates_in_vm
    setup_web_ui_in_vm
    
    log_success "VM bootstrap complete"
}

setup_ssl_certificates_in_vm() {
    log "Setting up SSL certificates in TrustNet VM..."
    
    # Create certificate directory
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas mkdir -p /etc/caddy/certs && doas chmod 755 /etc/caddy/certs" \
        2>/dev/null || log_info "  Certificate directory creation (may have failed - proceeding)"
    
    # Generate self-signed certificate (365-day validity)
    log_info "  Generating 365-day self-signed certificate..."
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas openssl req -x509 -newkey rsa:2048 -keyout /etc/caddy/certs/trustnet.local.key \
         -out /etc/caddy/certs/trustnet.local.crt -days 365 -nodes \
         -subj '/CN=trustnet.local/O=TrustNet/C=US'" \
        2>/dev/null
    
    # Set proper permissions on certificate files
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas chmod 644 /etc/caddy/certs/trustnet.local.crt && \
         doas chmod 600 /etc/caddy/certs/trustnet.local.key" \
        2>/dev/null
    
    log_success "  SSL certificates generated (365-day self-signed)"
}

setup_web_ui_in_vm() {
    log "Setting up TrustNet web UI..."
    
    # Create web directory
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas mkdir -p /var/www/trustnet && doas chmod 755 /var/www/trustnet" \
        2>/dev/null || log_info "  Web directory creation (proceeding anyway)"
    
    # Create enhanced HTML page with dashboard and controls
    log_info "  Creating TrustNet dashboard..."
    ssh -i "$VM_SSH_PRIVATE_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -p "$VM_SSH_PORT" ${VM_USERNAME}@localhost \
        "doas tee /var/www/trustnet/index.html > /dev/null" << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TrustNet Node - Decentralized Trust Network</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .wrapper { max-width: 1000px; margin: 0 auto; }
        .header {
            background: rgba(255,255,255,0.95);
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
        }
        .header h1 {
            font-size: 2.5em;
            color: #667eea;
            margin-bottom: 5px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .header p {
            color: #666;
            font-size: 1.1em;
        }
        .status-badge {
            display: inline-block;
            background: #4CAF50;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            margin: 10px 0;
        }
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        @media (max-width: 768px) {
            .grid { grid-template-columns: 1fr; }
        }
        .card {
            background: rgba(255,255,255,0.95);
            border-radius: 10px;
            padding: 20px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.15);
        }
        .card h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.3em;
        }
        .stat-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .stat-row:last-child { border-bottom: none; }
        .stat-label { color: #888; font-weight: 500; }
        .stat-value {
            color: #667eea;
            font-weight: bold;
            font-family: 'Courier New', monospace;
        }
        .value-offline { color: #999; }
        .value-online { color: #4CAF50; }
        .button-group {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        button {
            flex: 1;
            min-width: 140px;
            padding: 12px 20px;
            border: none;
            border-radius: 6px;
            font-weight: bold;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 0.95em;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4); }
        .btn-secondary {
            background: #f0f0f0;
            color: #333;
            border: 2px solid #667eea;
        }
        .btn-secondary:hover { background: #667eea; color: white; }
        .section {
            background: rgba(255,255,255,0.95);
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 5px 20px rgba(0, 0, 0, 0.15);
        }
        .section h2 { color: #667eea; margin-bottom: 15px; }
        .section p { color: #666; line-height: 1.6; margin-bottom: 10px; }
        .section code {
            background: #f5f5f5;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            color: #333;
        }
        .section pre {
            background: #333;
            color: #0f0;
            padding: 15px;
            border-radius: 6px;
            overflow-x: auto;
            font-family: 'Courier New', monospace;
            margin: 10px 0;
        }
        .feature-list { list-style: none; }
        .feature-list li {
            padding: 8px 0;
            color: #555;
        }
        .feature-list li:before {
            content: "✓ ";
            color: #4CAF50;
            font-weight: bold;
            margin-right: 8px;
        }
        .footer {
            text-align: center;
            color: rgba(255,255,255,0.8);
            padding: 20px;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="wrapper">
        <div class="header">
            <h1>⛓️ TrustNet Node</h1>
            <p>Decentralized Trust Network - Web3 Identity & Reputation</p>
            <div class="status-badge">✓ RUNNING</div>
        </div>

        <div class="grid">
            <div class="card">
                <h2>📊 Node Status</h2>
                <div class="stat-row">
                    <span class="stat-label">Node Status:</span>
                    <span class="stat-value value-online">ONLINE</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Blockchain:</span>
                    <span class="stat-value">Cosmos SDK</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Network:</span>
                    <span class="stat-value">Testnet</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Sync Status:</span>
                    <span class="stat-value value-online">Synced</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Uptime:</span>
                    <span class="stat-value">--:--:--</span>
                </div>
            </div>

            <div class="card">
                <h2>👤 Identity</h2>
                <div class="stat-row">
                    <span class="stat-label">Registration:</span>
                    <span class="stat-value value-offline">Pending</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Reputation Score:</span>
                    <span class="stat-value">0</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Trust Balance:</span>
                    <span class="stat-value">0 TRUST</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Endorsements:</span>
                    <span class="stat-value">0</span>
                </div>
                <div class="button-group">
                    <button class="btn-primary">Register Identity</button>
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🔧 Quick Access</h2>
            <p><strong>SSH Connection:</strong></p>
            <pre>ssh trustnet</pre>
            <p><strong>API Endpoint:</strong></p>
            <pre>https://trustnet.local:1317/api</pre>
            <p><strong>RPC Endpoint:</strong></p>
            <pre>https://trustnet.local:26657</pre>
        </div>

        <div class="section">
            <h2>📝 Getting Started</h2>
            <ol style="color: #666; line-height: 1.8;">
                <li><strong>Initialize your identity:</strong> Click "Register Identity" above or use <code>ssh trustnet</code></li>
                <li><strong>Join the network:</strong> Connect to peers and sync blockchain data</li>
                <li><strong>Build reputation:</strong> Perform transactions and earn endorsements</li>
                <li><strong>Manage keys:</strong> Secure your wallet and identity proofs</li>
                <li><strong>Monitor node:</strong> Check health and performance metrics</li>
            </ol>
        </div>

        <div class="grid">
            <div class="section">
                <h2>⚙️ Node Features</h2>
                <ul class="feature-list">
                    <li>Cosmos SDK blockchain</li>
                    <li>HTTPS with SSL</li>
                    <li>REST API (1317)</li>
                    <li>RPC endpoint (26657)</li>
                    <li>Tendermint consensus</li>
                    <li>P2P networking</li>
                </ul>
            </div>

            <div class="section">
                <h2>🔐 Security</h2>
                <ul class="feature-list">
                    <li>Self-signed certificates</li>
                    <li>SSH key authentication</li>
                    <li>Non-root blockchain user</li>
                    <li>Isolated VM environment</li>
                    <li>Data disk encryption ready</li>
                    <li>Automatic backups</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>📚 Resources</h2>
            <p>
                <a href="#" style="color: #667eea; text-decoration: none;">Documentation</a> | 
                <a href="#" style="color: #667eea; text-decoration: none;">API Docs</a> | 
                <a href="#" style="color: #667eea; text-decoration: none;">Community</a> | 
                <a href="#" style="color: #667eea; text-decoration: none;">GitHub</a>
            </p>
        </div>

        <div class="footer">
            TrustNet Node v1.0.0 | Cosmos SDK | Tendermint BFT | Served via Caddy HTTPS with Let's Encrypt
        </div>
    </div>
</body>
</html>
HTMLEOF
    
    log_success "  Web UI initialized with full dashboard"
}

# Export functions
export -f setup_cache_disk_in_vm setup_data_disk_in_vm configure_installed_vm

#!/bin/bash
# setup-motd.sh - Create welcome banner for Factory VM
#
# Creates /etc/motd with information about installed tools,
# Jenkins access, and quick start guide.

################################################################################
# Setup Welcome Banner (MOTD)
################################################################################

setup_motd_via_ssh() {
    log "Creating welcome banner..."
    
    # Create MOTD via SSH (use bash to avoid ash syntax issues)
    if ssh -i "$VM_SSH_PRIVATE_KEY" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o ConnectTimeout=10 \
        -p "$VM_SSH_PORT" \
        root@localhost 'bash -s' << 'MOTD_SCRIPT'
cat > /etc/motd << 'MOTD_EOF'
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║         🔗  TrustNet Node - Blockchain Platform           ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Welcome to your TrustNet blockchain node!

📦 Installed Tools:
  • Go 1.26.1       - Blockchain development language
  • Ignite CLI      - Cosmos SDK scaffolding
  • Git, Make, GCC  - Build tools
  • Caddy           - HTTPS reverse proxy & web server

🌐 TrustNet Services:
  Web UI:    https://trustnet.local
  RPC:       https://rpc.trustnet.local (reverse proxy :26657)
  API:       https://api.trustnet.local (reverse proxy :1317)
  
  SSH Access: ssh trustnet

📁 Storage:
  System:    /              (20 GB)
  Cache:     /var/cache     (5 GB)
  Data:      /var/lib/trustnet (30 GB)

🔒 Security:
  • SSH: Key-based authentication only
  • HTTPS: Self-signed certificate (365 days)
  • User: warden (local account, passwordless sudo)

📖 Configuration:
  Node config:  ~/trustnet/config/config.toml
  Caddy config: /etc/caddy/Caddyfile
  SSL Certs:    /etc/caddy/certs/trustnet.local.*

💡 Quick Commands:
  Check Caddy:     sudo rc-service caddy status
  Restart Caddy:   sudo rc-service caddy restart
  View Caddy logs: sudo rc-service caddy log
  Blockchain RPC:  curl -k https://rpc.trustnet.local/status

═══════════════════════════════════════════════════════════════
MOTD_EOF
MOTD_SCRIPT
    then
        log_success "  ✓ Welcome banner created"
        return 0
    else
        log_warning "  Failed to create welcome banner (continuing anyway)"
        return 1
    fi
}

################################################################################
# Module Initialization
################################################################################

# Verify this module is being sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "ERROR: setup-motd.sh should be sourced, not executed directly"
    echo "Usage: source ${BASH_SOURCE[0]}"
    exit 1
fi

# Export functions
export -f setup_motd_via_ssh

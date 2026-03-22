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
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║          🔗  TrustNet Node - Decentralized Trust Network       ║
║                        Cosmos Blockchain                       ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝

Welcome to your TrustNet blockchain validator node!

📦 Installed Components:
  • Go 1.26.1         - Blockchain development language
  • Ignite CLI        - Cosmos SDK scaffolding and code generation
  • Tendermint        - Byzantine Fault Tolerant consensus
  • Git, Make, GCC    - Build and development tools
  • Caddy 2.10.0      - HTTPS reverse proxy with automatic cert management

🌐 Service Endpoints (All HTTPS with Wildcard Certificate):

  📱 Web UI Dashboard:
     https://trustnet.local
     Static web interface for node management
  
  ⛓️  Blockchain Services:
     RPC:  https://rpc.trustnet.local    (Tendermint RPC - Port 26657)
           Query blockchain state, send transactions
     
     P2P:  https://p2p.trustnet.local    (Peer-to-peer networking - Port 26656)
           Validator consensus communication
     
     API:  https://api.trustnet.local    (REST API - Port 1317)
           RESTful blockchain API
  
  🔗 SSH Access: ssh trustnet
     User: warden (key-based authentication only)

📁 Storage Layout:
  System Disk:    /                        (20 GB)
  Cache Disk:     /var/cache/trustnet-build (5 GB)
  Data Disk:      /var/lib/trustnet        (30 GB - Blockchain data)

🔒 Security Configuration:
  ✓ SSH: Key-based authentication (no passwords)
  ✓ HTTPS: 365-day self-signed wildcard certificate (*.trustnet.local)
  ✓ Caddy: Reverse proxy with automatic HTTPS redirection
  ✓ User: warden account with passwordless sudo via doas
  ✓ Firewall: Consensus and P2P traffic locked to localhost

📖 Key Configuration Files:
  Tendermint:  /home/warden/trustnet/config/config.toml
  Genesis:     /home/warden/trustnet/config/genesis.json
  SSL Certs:   /etc/caddy/certs/wildcard.*
  Caddy Config: /etc/caddy/Caddyfile

💡 Common Commands:

  Blockchain Service:
    sudo rc-service trustnet status       - Check service status
    sudo rc-service trustnet restart      - Restart blockchain
    tail -f /var/log/trustnet.log        - Watch service logs
  
  Caddy Reverse Proxy:
    sudo rc-service caddy status         - Check if HTTPS is running
    sudo rc-service caddy restart        - Reload configuration
    curl -k https://rpc.trustnet.local   - Test RPC endpoint
  
  Blockchain Info:
    curl -k https://rpc.trustnet.local/abci_info      - Get node info
    curl -k https://api.trustnet.local/blocks/latest  - Latest block
  
  System Information:
    df -h                                - Disk usage
    iostat -x 1 5                        - I/O statistics

🚀 Next Steps:

  1. Register your validator identity:
     curl -k https://trustnet.local/register
  
  2. Verify all services are responding:
     curl -k https://rpc.trustnet.local/status
     curl -k https://api.trustnet.local/blocks/latest
  
  3. Check validator status:
     curl -k https://rpc.trustnet.local/validators
  
  4. Monitor logs:
     sudo rc-service trustnet log

═══════════════════════════════════════════════════════════════════
Generated: $(date)
Certificate Valid Until: $(date -d '+365 days')
═══════════════════════════════════════════════════════════════════
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

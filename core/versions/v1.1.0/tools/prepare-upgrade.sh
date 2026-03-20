#!/bin/bash
# Convert v1.1.0 setup script to v1.0.0-compatible form
# This extracts just the iOS integration layer without base setup

set -e

echo "Extracting v1.1.0 iOS components (compatible with v1.0.0)..."

# Create minimal setup script for existing v1.0.0 nodes
cat > upgrade-v1.0.0-to-v1.1.0.sh << 'EOF'
#!/bin/bash
# Upgrade existing v1.0.0 node to v1.1.0 (iOS QR support)
# Usage: ./upgrade-v1.0.0-to-v1.1.0.sh

set -e

echo "Upgrading TrustNet v1.0.0 → v1.1.0 (iOS QR Integration)"
echo ""

VM_DIR="${HOME}/vms/trustnet"
API_DIR="$VM_DIR/api"
WEB_DIR="$VM_DIR/web"

# Create directories
mkdir -p "$API_DIR" "$WEB_DIR/templates" "$WEB_DIR/static"

# Copy setup.py
cp setup_api.py "$API_DIR/"
cp requirements.txt "$API_DIR/"

# Copy web UI
cp first-setup.html "$WEB_DIR/templates/"

echo "✅ v1.1.0 iOS components installed"
echo ""
echo "Access setup UI at:"
echo "  https://<your-node-ipv6>:1317/setup"
echo ""

EOF

chmod +x upgrade-v1.0.0-to-v1.1.0.sh

echo "✅ Upgrade script created: upgrade-v1.0.0-to-v1.1.0.sh"

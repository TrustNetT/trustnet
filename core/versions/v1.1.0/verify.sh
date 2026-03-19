#!/bin/bash
# Quick test script for v1.1.0 setup

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  TrustNet v1.1.0 Setup Verification                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check v1.0.0 base
echo "Checking v1.0.0 base infrastructure..."
if [ -d ../v1.0.0/tools ]; then
    echo "  ✅ v1.0.0 base found"
else
    echo "  ⚠️  v1.0.0 base not found (OK for fresh install)"
fi

# Check v1.1.0 components
echo ""
echo "Checking v1.1.0 iOS components..."

components=(
    "tools/setup-trustnet-node.sh"
    "api/setup_launcher.py"
    "api/requirements.txt"
    "web/templates/first-setup.html"
    "MANIFEST.md"
)

for component in "${components[@]}"; do
    if [ -f "$component" ]; then
        echo "  ✅ $component"
    else
        echo "  ❌ $component (MISSING)"
    fi
done

echo ""
echo "Component sizes:"
wc -l tools/setup-trustnet-node.sh 2>/dev/null || echo "  setup-trustnet-node.sh: N/A"
wc -l api/setup_launcher.py 2>/dev/null || echo "  setup_launcher.py: N/A"
wc -l api/requirements.txt 2>/dev/null || echo "  requirements.txt: N/A"
wc -l web/templates/first-setup.html 2>/dev/null || echo "  first-setup.html: N/A"

echo ""
echo "✅ v1.1.0 components verification complete"
echo ""
echo "To start installation:"
echo "  ./tools/setup-trustnet-node.sh --auto"
echo ""

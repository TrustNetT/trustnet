#!/usr/bin/env python3
"""
TrustNet Setup API v1.1.0 - Standalone Launcher

Usage:
    python3 setup.py                    # Run on 0.0.0.0:8001
    python3 setup.py --port 8001        # Custom port
    python3 setup.py --host 127.0.0.1   # Custom host
    python3 setup.py --version          # Show version

For Systemd service:
    [Service]
    ExecStart=/usr/bin/python3 /opt/trustnet/api/setup.py
    WorkingDirectory=/opt/trustnet
    StandardOutput=journal
    StandardError=journal
"""

import sys
import argparse
from pathlib import Path

def main():
    parser = argparse.ArgumentParser(description="TrustNet Setup API v1.1.0")
    parser.add_argument("--version", action="store_true", help="Show version")
    parser.add_argument("--port", type=int, default=8001, help="Port (default 8001)")
    parser.add_argument("--host", default="0.0.0.0", help="Host (default 0.0.0.0)")
    parser.add_argument("--workers", type=int, default=4, help="Workers (default 4)")
    
    args = parser.parse_args()
    
    if args.version:
        print("TrustNet Setup API v1.1.0")
        print("iOS QR Code Integration")
        sys.exit(0)
    
    try:
        from setup_api import app
        import uvicorn
        
        print("╔════════════════════════════════════════════════════════════╗")
        print("║                                                            ║")
        print("║     TrustNet Setup API v1.1.0                              ║")
        print("║     iOS QR Code & PIN Verification                         ║")
        print("║                                                            ║")
        print("╚════════════════════════════════════════════════════════════╝")
        print()
        print(f"Starting FastAPI server...")
        print(f"  Host: {args.host}")
        print(f"  Port: {args.port}")
        print(f"  Workers: {args.workers}")
        print()
        print(f"Setup UI available at:")
        print(f"  https://<your-node-ipv6>/setup")
        print()
        print(f"API Endpoints:")
        print(f"  GET  /api/setup/qr-code")
        print(f"  POST /api/setup/verify-pin")
        print(f"  GET  /api/health")
        print()
        
        uvicorn.run(
            "setup_api:app",
            host=args.host,
            port=args.port,
            workers=args.workers,
            log_level="info"
        )
    
    except ImportError as e:
        print(f"❌ Error: Missing dependencies")
        print(f"   Install with: pip install -r requirements.txt")
        print(f"   Error details: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

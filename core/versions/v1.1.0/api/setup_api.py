#!/usr/bin/env python3
"""
TrustNet v1.1.0 Setup API - iOS QR Integration

Provides endpoints for QR code generation and PIN verification
for secure iOS app onboarding to TrustNet nodes.
"""

import os
import sys
import json
import hashlib
import secrets
import socket
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional, Dict, Tuple

try:
    from fastapi import FastAPI, HTTPException, Request
    from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
    from fastapi.staticfiles import StaticFiles
    from fastapi.middleware.cors import CORSMiddleware
    import qrcode
    from qrcode.image.pure import PyImageImage
    import uvicorn
except ImportError as e:
    print(f"❌ Missing dependency: {e}")
    print("Install with: pip install -r requirements.txt")
    sys.exit(1)

# ============================================================================
# Configuration
# ============================================================================

APP_VERSION = "1.1.0"
APP_NAME = "TrustNet Setup API"

# Get node info from environment or use defaults
NODE_ID = os.getenv("NODE_ID", "trustnet-node-demo")[:16]
NODE_ENDPOINT = os.getenv("NODE_ENDPOINT", "trustnet.local:443")
CERT_FINGERPRINT = os.getenv("CERT_FINGERPRINT", "abcd1234abcd1234abcd1234abcd1234abcd1234")

PIN_LIFETIME_MINUTES = 30
PIN_LENGTH = 6
QR_EXPIRE_MINUTES = 30

# ============================================================================
# QR Code Generator
# ============================================================================

class QRCodeGenerator:
    """Generates QR codes for TrustNet node discovery"""
    
    @staticmethod
    def generate_pin(length: int = PIN_LENGTH) -> str:
        """Generate random PIN"""
        return ''.join(str(secrets.randbelow(10)) for _ in range(length))
    
    @staticmethod
    def create_uri(node_id: str, endpoint: str, fingerprint: str, pin: str) -> str:
        """Create trustnet:// URI for QR encoding"""
        # Format: trustnet://node/{id}?endpoint={host}:{port}&fingerprint={sha256}&pin={code}
        return f"trustnet://node/{node_id}?endpoint={endpoint}&fingerprint={fingerprint}&pin={pin}"
    
    @staticmethod
    def generate_qr_base64(uri: str) -> str:
        """Generate QR code and return as base64 PNG"""
        import base64
        from io import BytesIO
        
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,
            box_size=10,
            border=2,
        )
        qr.add_data(uri)
        qr.make(fit=True)
        
        img = qr.make_image(fill_color="black", back_color="white")
        
        # Convert to PNG bytes
        buffer = BytesIO()
        img.save(buffer, format="PNG")
        buffer.seek(0)
        png_bytes = buffer.getvalue()
        
        # Encode as base64
        return base64.b64encode(png_bytes).decode('utf-8')

# ============================================================================
# PIN Verification Manager
# ============================================================================

class PINVerificationManager:
    """Manages PIN lifecycle and verification"""
    
    def __init__(self, lifetime_minutes: int = PIN_LIFETIME_MINUTES):
        self.lifetime = timedelta(minutes=lifetime_minutes)
        self.sessions: Dict[str, Dict] = {}
    
    def create_session(self, node_id: str, pin: str, endpoint: str, fingerprint: str) -> str:
        """Create a new verification session, return session ID"""
        session_id = secrets.token_urlsafe(32)
        self.sessions[session_id] = {
            "node_id": node_id,
            "pin": pin,
            "endpoint": endpoint,
            "fingerprint": fingerprint,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + self.lifetime,
            "verified": False,
            "token": None
        }
        return session_id
    
    def verify_pin(self, node_id: str, pin: str) -> Tuple[bool, Optional[str]]:
        """Verify PIN and return (is_valid, token)"""
        for session_id, session in list(self.sessions.items()):
            # Check expiration
            if datetime.utcnow() > session["expires_at"]:
                del self.sessions[session_id]
                continue
            
            # Check credentials
            if session["node_id"] == node_id and session["pin"] == pin:
                # Generate auth token for iOS app
                token = secrets.token_urlsafe(48)
                session["token"] = token
                session["verified"] = True
                return (True, token)
        
        return (False, None)
    
    def cleanup_expired(self):
        """Remove expired sessions"""
        expired_ids = [
            sid for sid, session in self.sessions.items()
            if datetime.utcnow() > session["expires_at"]
        ]
        for sid in expired_ids:
            del self.sessions[sid]

# ============================================================================
# FastAPI Application
# ============================================================================

app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="iOS QR Code Integration for TrustNet Node Setup"
)

# Enable CORS for iOS app requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize manager
pin_manager = PINVerificationManager()

# ============================================================================
# Endpoints
# ============================================================================

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": APP_NAME,
        "version": APP_VERSION,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/setup/qr-code")
async def get_qr_code():
    """
    Generate QR code for iOS app discovery
    
    Returns:
        {
            "qr_image_base64": "...",
            "node_id": "trustnet-node...",
            "pin_code": "123456",
            "expires_at": 1710700000,
            "endpoint": "trustnet.local:443"
        }
    """
    try:
        pin_manager.cleanup_expired()
        
        # Generate PIN
        pin = QRCodeGenerator.generate_pin()
        
        # Create QR URI
        uri = QRCodeGenerator.create_uri(NODE_ID, NODE_ENDPOINT, CERT_FINGERPRINT, pin)
        
        # Generate QR image
        qr_base64 = QRCodeGenerator.generate_qr_base64(uri)
        
        # Create session
        session_id = pin_manager.create_session(NODE_ID, pin, NODE_ENDPOINT, CERT_FINGERPRINT)
        
        expires_at = int((datetime.utcnow() + timedelta(minutes=QR_EXPIRE_MINUTES)).timestamp())
        
        return {
            "qr_image_base64": qr_base64,
            "node_id": NODE_ID,
            "pin_code": pin,
            "expires_at": expires_at,
            "endpoint": NODE_ENDPOINT,
            "session_id": session_id
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/setup/verify-pin")
async def verify_pin(request: Request):
    """
    Verify PIN from iOS app
    
    Request body:
        {
            "node_id": "trustnet-node...",
            "pin": "123456"
        }
    
    Returns:
        {
            "status": "verified",
            "token": "...",
            "endpoint": "trustnet.local:443",
            "fingerprint": "..."
        }
    """
    try:
        body = await request.json()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid request body")
    
    node_id = body.get("node_id")
    pin = body.get("pin")
    
    if not node_id or not pin:
        raise HTTPException(status_code=400, detail="Missing node_id or pin")
    
    # Verify PIN
    is_valid, token = pin_manager.verify_pin(node_id, pin)
    
    if not is_valid:
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    return {
        "status": "verified",
        "token": token,
        "endpoint": NODE_ENDPOINT,
        "fingerprint": CERT_FINGERPRINT
    }

@app.get("/setup")
async def setup_ui():
    """Serve the first-setup.html UI"""
    template_path = Path(__file__).parent.parent / "web" / "templates" / "first-setup.html"
    
    if template_path.exists():
        with open(template_path, 'r') as f:
            return HTMLResponse(f.read())
    else:
        return HTMLResponse("""
        <html>
            <body style="font-family: Arial; text-align: center; padding: 40px;">
                <h1>TrustNet Setup</h1>
                <p style="color: red;">UI template not found: {}</p>
                <p><a href="/api/health">Health Check</a></p>
            </body>
        </html>
        """.format(template_path))

@app.get("/api/setup/status")
async def setup_status():
    """Get current setup status"""
    pin_manager.cleanup_expired()
    
    return {
        "node_id": NODE_ID,
        "endpoint": NODE_ENDPOINT,
        "active_sessions": len(pin_manager.sessions),
        "version": APP_VERSION,
        "timestamp": datetime.utcnow().isoformat()
    }

# ============================================================================
# Startup
# ============================================================================

def main():
    """Parse argv and run server"""
    import argparse
    
    parser = argparse.ArgumentParser(description=APP_NAME)
    parser.add_argument("--version", action="store_true", help="Show version")
    parser.add_argument("--port", type=int, default=8001, help="Port (default 8001)")
    parser.add_argument("--host", default="0.0.0.0", help="Host (default 0.0.0.0)")
    parser.add_argument("--workers", type=int, default=4, help="Workers (default 4)")
    parser.add_argument("--node-id", default=NODE_ID, help="Node ID")
    parser.add_argument("--endpoint", default=NODE_ENDPOINT, help="Node endpoint (host:port)")
    parser.add_argument("--fingerprint", default=CERT_FINGERPRINT, help="Certificate SHA-256")
    
    args = parser.parse_args()
    
    if args.version:
        print(f"{APP_NAME} v{APP_VERSION}")
        print("iOS QR Code Integration")
        sys.exit(0)
    
    # Update global config from arguments
    globals()["NODE_ID"] = args.node_id[:16]
    globals()["NODE_ENDPOINT"] = args.endpoint
    globals()["CERT_FINGERPRINT"] = args.fingerprint
    
    print("╔════════════════════════════════════════════════════════════╗")
    print("║                                                            ║")
    print(f"║     {APP_NAME:<45}║")
    print(f"║     iOS QR Code & PIN Verification v{APP_VERSION:<30}║")
    print("║                                                            ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print()
    print(f"Configuration:")
    print(f"  Host:        {args.host}")
    print(f"  Port:        {args.port}")
    print(f"  Node ID:     {args.node_id[:16]}")
    print(f"  Endpoint:    {args.endpoint}")
    print(f"  Workers:     {args.workers}")
    print()
    print(f"Setup UI available at:")
    print(f"  https://<your-node-ipv6>:<your-port>/setup")
    print()
    print(f"API Endpoints:")
    print(f"  GET  /api/health")
    print(f"  GET  /api/setup/qr-code")
    print(f"  POST /api/setup/verify-pin")
    print(f"  GET  /api/setup/status")
    print(f"  GET  /setup")
    print()
    
    uvicorn.run(
        "setup_api:app",
        host=args.host,
        port=args.port,
        workers=args.workers,
        log_level="info"
    )

if __name__ == "__main__":
    main()

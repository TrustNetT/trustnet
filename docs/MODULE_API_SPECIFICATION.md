# TrustNet Module API Specification

**Version**: 1.0.0  
**Date**: February 2, 2026  
**Purpose**: Standard API patterns for all TrustNet modules  

---

## Overview

This document defines the **mandatory** API patterns that all TrustNet modules must follow. Consistent APIs ensure:
- Easy integration between modules
- Predictable developer experience
- Simple testing and debugging
- Automatic documentation generation

---

## Architecture

### Module Structure

Every module follows this structure:

```
modules/{module-name}/
├── frontend/              # Vite + Modern JS
│   ├── index.html
│   ├── main.js
│   ├── styles.css
│   └── components/
├── api/                   # Python + FastAPI
│   ├── main.py           # FastAPI app entry point
│   ├── routes.py         # API endpoints
│   ├── models.py         # Pydantic models
│   ├── cosmos.py         # Cosmos SDK client
│   └── requirements.txt  # Python dependencies
├── tests/
│   ├── test_api.py
│   └── test_frontend.js
├── module.json           # Module metadata
└── README.md
```

### Communication Flow

```
User Browser
    ↓
Frontend (Vite + JS)
    ↓ (HTTP/Fetch)
Module API (Python FastAPI)
    ↓ (HTTP/gRPC)
Cosmos SDK Node (Go)
    ↓
Blockchain
```

---

## Module Metadata (module.json)

Every module MUST include a `module.json` file:

```json
{
  "name": "identity",
  "version": "1.0.0",
  "description": "Identity registration and management",
  "author": "TrustNet Team",
  "license": "MIT",
  "api": {
    "basePath": "/api/identity",
    "port": 8081,
    "healthCheck": "/api/identity/health"
  },
  "frontend": {
    "entryPoint": "frontend/index.html",
    "routes": [
      "/identity",
      "/identity/register",
      "/identity/:did"
    ]
  },
  "dependencies": {
    "cosmos": ">=0.45.0",
    "python": ">=3.11",
    "modules": []
  },
  "permissions": [
    "cosmos.tx.broadcast",
    "cosmos.query.account"
  ],
  "resources": {
    "memory": "128MB",
    "cpu": "0.5"
  }
}
```

---

## API Standards

### Base URL Pattern

All module APIs MUST follow this pattern:

```
https://trustnet.local/api/{module-name}/{resource}/{action}
```

**Examples**:
```
https://trustnet.local/api/identity/register
https://trustnet.local/api/identity/did/did:trustnet:abc123
https://trustnet.local/api/transactions/list
https://trustnet.local/api/keys/generate
```

### HTTP Methods

Use standard REST HTTP methods:

| Method | Purpose | Example |
|--------|---------|---------|
| **GET** | Retrieve data | `GET /api/identity/did/did:trustnet:123` |
| **POST** | Create new resource | `POST /api/identity/register` |
| **PUT** | Update entire resource | `PUT /api/identity/did/did:trustnet:123` |
| **PATCH** | Partial update | `PATCH /api/identity/did/did:trustnet:123` |
| **DELETE** | Remove resource | `DELETE /api/keys/123` |

### Request Format

All requests MUST use JSON:

```http
POST /api/identity/register HTTP/1.1
Host: trustnet.local
Content-Type: application/json
Authorization: Bearer {jwt-token}

{
  "name": "Alice",
  "email": "alice@example.com",
  "publicKey": "0x..."
}
```

### Response Format

All responses MUST follow this structure:

**Success Response**:
```json
{
  "success": true,
  "data": {
    "did": "did:trustnet:abc123",
    "name": "Alice",
    "created": "2026-02-02T10:30:00Z"
  },
  "meta": {
    "timestamp": "2026-02-02T10:30:00Z",
    "requestId": "req-xyz789"
  }
}
```

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "IDENTITY_ALREADY_EXISTS",
    "message": "An identity with this email already exists",
    "details": {
      "field": "email",
      "value": "alice@example.com"
    }
  },
  "meta": {
    "timestamp": "2026-02-02T10:30:00Z",
    "requestId": "req-xyz789"
  }
}
```

### HTTP Status Codes

Use standard HTTP status codes:

| Code | Meaning | When to Use |
|------|---------|-------------|
| **200** | OK | Successful GET, PUT, PATCH, DELETE |
| **201** | Created | Successful POST (new resource) |
| **204** | No Content | Successful DELETE with no response body |
| **400** | Bad Request | Invalid input, validation error |
| **401** | Unauthorized | Missing or invalid authentication |
| **403** | Forbidden | Authenticated but not authorized |
| **404** | Not Found | Resource doesn't exist |
| **409** | Conflict | Resource already exists, duplicate |
| **422** | Unprocessable Entity | Validation failed |
| **500** | Internal Server Error | Server error, blockchain error |
| **503** | Service Unavailable | Cosmos SDK node unreachable |

---

## FastAPI Implementation Pattern

### Module API Template

```python
# modules/{module-name}/api/main.py

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import Optional, List
import httpx
from datetime import datetime

# Initialize FastAPI
app = FastAPI(
    title="TrustNet Identity Module",
    version="1.0.0",
    docs_url="/api/identity/docs",
    redoc_url="/api/identity/redoc"
)

# CORS middleware (for development)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://trustnet.local", "http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cosmos SDK client configuration
COSMOS_RPC = "http://localhost:26657"
COSMOS_API = "http://localhost:1317"

# ============================================
# Models (Pydantic)
# ============================================

class RegisterRequest(BaseModel):
    """Request model for identity registration"""
    name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., regex=r'^[\w\.-]+@[\w\.-]+\.\w+$')
    publicKey: Optional[str] = None
    
    class Config:
        schema_extra = {
            "example": {
                "name": "Alice",
                "email": "alice@example.com",
                "publicKey": "0x1234..."
            }
        }

class IdentityResponse(BaseModel):
    """Response model for identity data"""
    did: str
    name: str
    email: str
    reputation: int
    created: datetime
    
class ApiResponse(BaseModel):
    """Standard API response wrapper"""
    success: bool
    data: Optional[dict] = None
    error: Optional[dict] = None
    meta: dict

# ============================================
# Routes
# ============================================

@app.get("/api/identity/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check Cosmos SDK connectivity
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{COSMOS_RPC}/health")
            cosmos_healthy = response.status_code == 200
    except:
        cosmos_healthy = False
    
    return {
        "success": True,
        "data": {
            "status": "healthy" if cosmos_healthy else "degraded",
            "cosmos": cosmos_healthy,
            "timestamp": datetime.utcnow().isoformat()
        },
        "meta": {
            "timestamp": datetime.utcnow().isoformat()
        }
    }

@app.post("/api/identity/register", response_model=ApiResponse)
async def register_identity(request: RegisterRequest):
    """Register a new identity on the blockchain"""
    try:
        # 1. Validate request (Pydantic does this automatically)
        
        # 2. Check if identity already exists
        existing = await check_identity_exists(request.email)
        if existing:
            raise HTTPException(
                status_code=409,
                detail={
                    "success": False,
                    "error": {
                        "code": "IDENTITY_ALREADY_EXISTS",
                        "message": f"Identity with email {request.email} already exists",
                        "details": {"field": "email", "value": request.email}
                    }
                }
            )
        
        # 3. Generate DID
        did = f"did:trustnet:{generate_unique_id()}"
        
        # 4. Create blockchain transaction
        tx = create_identity_transaction(
            did=did,
            name=request.name,
            email=request.email,
            publicKey=request.publicKey
        )
        
        # 5. Broadcast to Cosmos SDK
        result = await broadcast_transaction(tx)
        
        # 6. Return success response
        return {
            "success": True,
            "data": {
                "did": did,
                "name": request.name,
                "email": request.email,
                "reputation": 0,
                "created": datetime.utcnow().isoformat(),
                "txHash": result["hash"]
            },
            "meta": {
                "timestamp": datetime.utcnow().isoformat(),
                "requestId": generate_request_id()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail={
                "success": False,
                "error": {
                    "code": "INTERNAL_ERROR",
                    "message": str(e)
                }
            }
        )

@app.get("/api/identity/did/{did}", response_model=ApiResponse)
async def get_identity(did: str):
    """Retrieve identity by DID"""
    try:
        # Query Cosmos SDK
        identity = await query_identity_from_blockchain(did)
        
        if not identity:
            raise HTTPException(
                status_code=404,
                detail={
                    "success": False,
                    "error": {
                        "code": "IDENTITY_NOT_FOUND",
                        "message": f"No identity found with DID {did}"
                    }
                }
            )
        
        return {
            "success": True,
            "data": identity,
            "meta": {
                "timestamp": datetime.utcnow().isoformat()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/identity/search", response_model=ApiResponse)
async def search_identities(
    query: str,
    limit: int = 10,
    offset: int = 0
):
    """Search identities by name or email"""
    try:
        results = await search_blockchain_identities(query, limit, offset)
        
        return {
            "success": True,
            "data": {
                "results": results,
                "total": len(results),
                "limit": limit,
                "offset": offset
            },
            "meta": {
                "timestamp": datetime.utcnow().isoformat()
            }
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Cosmos SDK Integration
# ============================================

async def broadcast_transaction(tx: dict) -> dict:
    """Broadcast transaction to Cosmos SDK"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{COSMOS_RPC}/broadcast_tx_commit",
            json={"tx": tx}
        )
        
        if response.status_code != 200:
            raise Exception(f"Cosmos SDK error: {response.text}")
        
        return response.json()

async def query_identity_from_blockchain(did: str) -> Optional[dict]:
    """Query identity from Cosmos SDK"""
    async with httpx.AsyncClient() as client:
        response = await client.get(
            f"{COSMOS_API}/trustnet/identity/{did}"
        )
        
        if response.status_code == 404:
            return None
        
        if response.status_code != 200:
            raise Exception(f"Cosmos SDK error: {response.text}")
        
        return response.json()

async def check_identity_exists(email: str) -> bool:
    """Check if identity with email already exists"""
    # Implementation depends on blockchain query capabilities
    return False  # Placeholder

# Helper functions
def generate_unique_id() -> str:
    """Generate unique ID for DID"""
    import uuid
    return str(uuid.uuid4())[:8]

def generate_request_id() -> str:
    """Generate request tracking ID"""
    import uuid
    return f"req-{uuid.uuid4()}"

def create_identity_transaction(did: str, name: str, email: str, publicKey: Optional[str]) -> dict:
    """Create Cosmos SDK transaction for identity registration"""
    return {
        "type": "trustnet/RegisterIdentity",
        "value": {
            "did": did,
            "name": name,
            "email": email,
            "publicKey": publicKey or ""
        }
    }

# ============================================
# Startup/Shutdown
# ============================================

@app.on_event("startup")
async def startup_event():
    """Run on application startup"""
    print("✅ Identity module API starting...")
    print(f"📡 Cosmos RPC: {COSMOS_RPC}")
    print(f"📡 Cosmos API: {COSMOS_API}")

@app.on_event("shutdown")
async def shutdown_event():
    """Run on application shutdown"""
    print("⚠️  Identity module API shutting down...")

# ============================================
# Run (development only)
# ============================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8081,
        reload=True,  # Hot reload for development
        log_level="info"
    )
```

### Requirements File

```txt
# modules/{module-name}/api/requirements.txt

fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.0
httpx==0.26.0
python-multipart==0.0.6
cosmospy==6.0.0  # Cosmos SDK Python client
```

---

## Frontend Integration Pattern

### API Client (Shared Library)

```javascript
// frontend/lib/api-client.js

/**
 * Standard API client for TrustNet modules
 */
class TrustNetAPI {
  constructor(baseURL = 'https://trustnet.local') {
    this.baseURL = baseURL
    this.defaultHeaders = {
      'Content-Type': 'application/json'
    }
  }

  /**
   * Make API request
   * @param {string} path - API path (e.g., '/api/identity/register')
   * @param {object} options - Fetch options
   * @returns {Promise<object>} - API response
   */
  async request(path, options = {}) {
    const url = `${this.baseURL}${path}`
    
    const response = await fetch(url, {
      ...options,
      headers: {
        ...this.defaultHeaders,
        ...options.headers
      }
    })
    
    const data = await response.json()
    
    // Check for API errors
    if (!data.success) {
      throw new APIError(data.error.message, data.error.code, data.error.details)
    }
    
    return data.data
  }

  async get(path, params = {}) {
    const queryString = new URLSearchParams(params).toString()
    const fullPath = queryString ? `${path}?${queryString}` : path
    return this.request(fullPath, { method: 'GET' })
  }

  async post(path, body) {
    return this.request(path, {
      method: 'POST',
      body: JSON.stringify(body)
    })
  }

  async put(path, body) {
    return this.request(path, {
      method: 'PUT',
      body: JSON.stringify(body)
    })
  }

  async delete(path) {
    return this.request(path, { method: 'DELETE' })
  }
}

class APIError extends Error {
  constructor(message, code, details) {
    super(message)
    this.code = code
    this.details = details
  }
}

// Export singleton
export const api = new TrustNetAPI()
```

### Module Frontend Example

```javascript
// modules/identity/frontend/main.js

import { api } from '../../../frontend/lib/api-client.js'

class IdentityForm extends HTMLElement {
  connectedCallback() {
    this.innerHTML = `
      <form id="register-form">
        <h2>Register Identity</h2>
        
        <div class="form-group">
          <label for="name">Name</label>
          <input type="text" id="name" required minlength="2" maxlength="100">
        </div>
        
        <div class="form-group">
          <label for="email">Email</label>
          <input type="email" id="email" required>
        </div>
        
        <button type="submit">Register</button>
        
        <div id="result"></div>
        <div id="error" class="error"></div>
      </form>
    `
    
    this.querySelector('form').addEventListener('submit', async (e) => {
      e.preventDefault()
      await this.handleSubmit()
    })
  }
  
  async handleSubmit() {
    const name = this.querySelector('#name').value
    const email = this.querySelector('#email').value
    const resultDiv = this.querySelector('#result')
    const errorDiv = this.querySelector('#error')
    
    // Clear previous messages
    resultDiv.innerHTML = ''
    errorDiv.innerHTML = ''
    
    try {
      // Call API
      const identity = await api.post('/api/identity/register', {
        name,
        email
      })
      
      // Show success
      resultDiv.innerHTML = `
        <div class="success">
          <h3>✅ Identity Created!</h3>
          <p><strong>DID:</strong> ${identity.did}</p>
          <p><strong>Name:</strong> ${identity.name}</p>
          <p><strong>Reputation:</strong> ${identity.reputation}</p>
        </div>
      `
      
      // Reset form
      this.querySelector('form').reset()
      
    } catch (error) {
      // Show error
      errorDiv.innerHTML = `
        <div class="error-message">
          <strong>Error:</strong> ${error.message}
          ${error.code ? `<br><small>Code: ${error.code}</small>` : ''}
        </div>
      `
    }
  }
}

customElements.define('identity-form', IdentityForm)
```

---

## Error Handling Standards

### Error Codes

All modules MUST use these standard error codes:

```python
class ErrorCodes:
    # Validation errors (400)
    VALIDATION_ERROR = "VALIDATION_ERROR"
    INVALID_INPUT = "INVALID_INPUT"
    MISSING_REQUIRED_FIELD = "MISSING_REQUIRED_FIELD"
    
    # Authentication errors (401)
    UNAUTHORIZED = "UNAUTHORIZED"
    INVALID_TOKEN = "INVALID_TOKEN"
    TOKEN_EXPIRED = "TOKEN_EXPIRED"
    
    # Authorization errors (403)
    FORBIDDEN = "FORBIDDEN"
    INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS"
    
    # Not found errors (404)
    RESOURCE_NOT_FOUND = "RESOURCE_NOT_FOUND"
    IDENTITY_NOT_FOUND = "IDENTITY_NOT_FOUND"
    TRANSACTION_NOT_FOUND = "TRANSACTION_NOT_FOUND"
    
    # Conflict errors (409)
    RESOURCE_ALREADY_EXISTS = "RESOURCE_ALREADY_EXISTS"
    IDENTITY_ALREADY_EXISTS = "IDENTITY_ALREADY_EXISTS"
    DUPLICATE_EMAIL = "DUPLICATE_EMAIL"
    
    # Blockchain errors (500/503)
    BLOCKCHAIN_ERROR = "BLOCKCHAIN_ERROR"
    COSMOS_SDK_UNREACHABLE = "COSMOS_SDK_UNREACHABLE"
    TRANSACTION_FAILED = "TRANSACTION_FAILED"
    
    # Internal errors (500)
    INTERNAL_ERROR = "INTERNAL_ERROR"
    DATABASE_ERROR = "DATABASE_ERROR"
```

---

## Authentication & Authorization

### JWT Authentication

All protected endpoints MUST use JWT tokens:

```python
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import jwt

security = HTTPBearer()

SECRET_KEY = "your-secret-key"  # From environment variable

def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Verify JWT token"""
    try:
        token = credentials.credentials
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Use in protected endpoints
@app.get("/api/identity/profile")
async def get_profile(user = Depends(verify_token)):
    """Get user profile (protected)"""
    return {"did": user["did"], "name": user["name"]}
```

---

## Resource Management (Alpine VM Considerations)

### Memory Limits

Each module API process MUST respect memory limits:

```python
# Set in module.json
{
  "resources": {
    "memory": "128MB",  # Maximum memory
    "cpu": "0.5"        # Half CPU core
  }
}
```

### Process Management

Modules run as separate processes managed by systemd:

```ini
# /etc/systemd/system/trustnet-identity.service
[Unit]
Description=TrustNet Identity Module API
After=network.target cosmos-sdk.service

[Service]
Type=simple
User=trustnet
WorkingDirectory=/opt/trustnet/modules/identity/api
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8081
Restart=on-failure
MemoryLimit=128M
CPUQuota=50%

[Install]
WantedBy=multi-user.target
```

### Python Runtime in Alpine

**Alpine VM footprint**:
```
Base Alpine:        ~5MB
Python 3.11:       ~50MB
FastAPI + deps:    ~20MB
Module code:        ~5MB
----------------------------
Total per module:  ~80MB
```

**Optimization strategies**:
1. **Shared Python runtime** - All modules use same Python installation
2. **Lazy loading** - Only load modules when accessed
3. **Process pooling** - Reuse Python processes
4. **Memory limits** - Enforce strict limits per module

---

## Testing Standards

### API Tests (pytest)

```python
# modules/identity/tests/test_api.py

import pytest
from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)

def test_health_check():
    """Test health check endpoint"""
    response = client.get("/api/identity/health")
    assert response.status_code == 200
    assert response.json()["success"] == True

def test_register_identity():
    """Test identity registration"""
    response = client.post("/api/identity/register", json={
        "name": "Alice",
        "email": "alice@test.com"
    })
    assert response.status_code == 201
    assert response.json()["success"] == True
    assert "did" in response.json()["data"]

def test_register_duplicate_identity():
    """Test registering duplicate identity fails"""
    # First registration
    client.post("/api/identity/register", json={
        "name": "Bob",
        "email": "bob@test.com"
    })
    
    # Duplicate should fail
    response = client.post("/api/identity/register", json={
        "name": "Bob",
        "email": "bob@test.com"
    })
    assert response.status_code == 409
    assert response.json()["error"]["code"] == "IDENTITY_ALREADY_EXISTS"

def test_get_identity():
    """Test retrieving identity"""
    # Create identity
    create_response = client.post("/api/identity/register", json={
        "name": "Charlie",
        "email": "charlie@test.com"
    })
    did = create_response.json()["data"]["did"]
    
    # Retrieve identity
    response = client.get(f"/api/identity/did/{did}")
    assert response.status_code == 200
    assert response.json()["data"]["did"] == did

def test_get_nonexistent_identity():
    """Test retrieving non-existent identity returns 404"""
    response = client.get("/api/identity/did/did:trustnet:nonexistent")
    assert response.status_code == 404
    assert response.json()["error"]["code"] == "IDENTITY_NOT_FOUND"
```

---

## Documentation Standards

### API Documentation (Auto-generated)

FastAPI automatically generates OpenAPI docs:

**Access**:
- Swagger UI: `https://trustnet.local/api/{module}/docs`
- ReDoc: `https://trustnet.local/api/{module}/redoc`
- OpenAPI JSON: `https://trustnet.local/api/{module}/openapi.json`

**Example**:
```
https://trustnet.local/api/identity/docs
https://trustnet.local/api/transactions/docs
https://trustnet.local/api/keys/docs
```

### Module README Template

```markdown
# {Module Name}

## Description
Brief description of what this module does.

## API Endpoints

### POST /api/{module}/register
Register a new resource.

**Request**:
\`\`\`json
{
  "field": "value"
}
\`\`\`

**Response**:
\`\`\`json
{
  "success": true,
  "data": { ... }
}
\`\`\`

## Installation

\`\`\`bash
./tools/module-install.sh {module-name}
\`\`\`

## Development

\`\`\`bash
cd modules/{module-name}/api
pip install -r requirements.txt
uvicorn main:app --reload --port 8081
\`\`\`

## Testing

\`\`\`bash
pytest tests/
\`\`\`
```

---

## Deployment Checklist

Before deploying a module, ensure:

- [ ] `module.json` is complete and valid
- [ ] All API endpoints follow naming conventions
- [ ] All responses use standard format (`success`, `data`, `error`, `meta`)
- [ ] Error codes are from standard list
- [ ] Health check endpoint exists
- [ ] API documentation is complete (auto-generated)
- [ ] Tests are passing (`pytest tests/`)
- [ ] Memory limit is set in `module.json`
- [ ] Python dependencies are in `requirements.txt`
- [ ] README.md is complete
- [ ] Frontend follows Web Components pattern
- [ ] CORS is configured correctly
- [ ] Authentication is implemented (if needed)
- [ ] Cosmos SDK connectivity is tested

---

## Summary

**All modules MUST**:
1. Follow URL pattern: `/api/{module}/{resource}/{action}`
2. Use standard response format with `success`, `data`, `error`, `meta`
3. Use standard HTTP status codes
4. Include `module.json` with metadata
5. Implement health check endpoint
6. Use FastAPI + Pydantic for backend
7. Use standard error codes
8. Respect memory limits (128MB default)
9. Include tests (pytest)
10. Auto-generate API documentation

**This ensures**:
- Consistent developer experience
- Easy debugging
- Simple integration
- Automatic documentation
- Resource-efficient deployment in Alpine VM

---

*Document version: 1.0.0*  
*Created: February 2, 2026*  
*Next: Implement first module following this specification*

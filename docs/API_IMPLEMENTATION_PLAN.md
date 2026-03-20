# TrustNet API Implementation Plan

**Date**: February 2, 2026  
**Priority**: Build API infrastructure BEFORE any modules  
**Rationale**: Modules cannot communicate with blockchain without API  

---

## Architecture Overview

### The Problem

```
❌ WRONG ORDER:
Build Identity Module → No way to talk to blockchain → Module is useless

✅ CORRECT ORDER:
Build API Layer → Modules can talk to blockchain → Identity module works
```

### The Solution: API Gateway

```
┌─────────────────────────────────────────────┐
│  Frontend Modules (Browser)                 │
│  ├── Identity (Vite + JS)                   │
│  ├── Transactions (Vite + JS)               │
│  └── Keys (Vite + JS)                       │
└──────────────┬──────────────────────────────┘
               │ HTTP/Fetch
               ▼
┌─────────────────────────────────────────────┐
│  API Gateway (Python FastAPI)               │
│  ├── Module endpoints (/api/identity/...)   │
│  ├── Cosmos SDK client                      │
│  └── Shared services                        │
└──────────────┬──────────────────────────────┘
               │ RPC/REST
               ▼
┌─────────────────────────────────────────────┐
│  Cosmos SDK Node (Go)                       │
│  ├── Blockchain data                        │
│  ├── Transaction processing                 │
│  └── Consensus                              │
└─────────────────────────────────────────────┘
```

**Key insight**: The API Gateway is the **bridge** between modules and blockchain.

---

## Phase 1: Core API Infrastructure (Week 1)

### Goal
Build the foundational API layer that all modules will use.

### Tasks

#### 1. Cosmos SDK Client Library

Create reusable client for all modules:

```python
# api/lib/cosmos_client.py

import httpx
from typing import Dict, Any, Optional
from dataclasses import dataclass

@dataclass
class CosmosConfig:
    """Cosmos SDK connection configuration"""
    rpc_endpoint: str = "http://localhost:26657"
    api_endpoint: str = "http://localhost:1317"
    grpc_endpoint: str = "localhost:9090"
    chain_id: str = "trustnet-1"
    timeout: int = 30

class CosmosClient:
    """
    Reusable Cosmos SDK client for all modules.
    Handles RPC calls, transactions, queries.
    """
    
    def __init__(self, config: CosmosConfig = None):
        self.config = config or CosmosConfig()
        self.rpc = self.config.rpc_endpoint
        self.api = self.config.api_endpoint
        
    async def health_check(self) -> bool:
        """Check if Cosmos SDK node is reachable"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.rpc}/health",
                    timeout=self.config.timeout
                )
                return response.status_code == 200
        except:
            return False
    
    async def broadcast_tx(self, tx: Dict[str, Any]) -> Dict[str, Any]:
        """
        Broadcast transaction to blockchain.
        
        Args:
            tx: Transaction data
            
        Returns:
            Transaction result with hash, height, code
        """
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.rpc}/broadcast_tx_commit",
                json={"tx": tx},
                timeout=self.config.timeout
            )
            
            if response.status_code != 200:
                raise CosmosSDKError(f"Broadcast failed: {response.text}")
            
            result = response.json()
            
            # Check for transaction errors
            if result.get("check_tx", {}).get("code", 0) != 0:
                raise TransactionFailedError(
                    result["check_tx"]["log"]
                )
            
            if result.get("deliver_tx", {}).get("code", 0) != 0:
                raise TransactionFailedError(
                    result["deliver_tx"]["log"]
                )
            
            return {
                "hash": result["hash"],
                "height": result["height"],
                "code": result["deliver_tx"]["code"],
                "log": result["deliver_tx"]["log"],
                "data": result["deliver_tx"]["data"]
            }
    
    async def query(self, path: str, params: Dict = None) -> Dict[str, Any]:
        """
        Query blockchain state via REST API.
        
        Args:
            path: API path (e.g., "/cosmos/auth/v1beta1/accounts/{address}")
            params: Query parameters
            
        Returns:
            Query result
        """
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.api}{path}",
                params=params or {},
                timeout=self.config.timeout
            )
            
            if response.status_code == 404:
                return None
            
            if response.status_code != 200:
                raise CosmosSDKError(f"Query failed: {response.text}")
            
            return response.json()
    
    async def get_account(self, address: str) -> Optional[Dict]:
        """Get account information"""
        return await self.query(f"/cosmos/auth/v1beta1/accounts/{address}")
    
    async def get_balance(self, address: str, denom: str = "stake") -> int:
        """Get account balance"""
        result = await self.query(
            f"/cosmos/bank/v1beta1/balances/{address}/{denom}"
        )
        return int(result["balance"]["amount"]) if result else 0
    
    async def get_latest_block(self) -> Dict:
        """Get latest block information"""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.rpc}/block")
            return response.json()

class CosmosSDKError(Exception):
    """Base exception for Cosmos SDK errors"""
    pass

class TransactionFailedError(CosmosSDKError):
    """Transaction broadcast failed"""
    pass
```

**Deliverable**: Reusable Cosmos SDK client for all modules.

---

#### 2. API Gateway Structure

Create main API gateway:

```python
# api/main.py

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from lib.cosmos_client import CosmosClient, CosmosConfig
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("trustnet-api")

# Global Cosmos client
cosmos: CosmosClient = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events"""
    global cosmos
    
    # Startup
    logger.info("🚀 TrustNet API Gateway starting...")
    
    # Initialize Cosmos SDK client
    cosmos = CosmosClient(CosmosConfig(
        rpc_endpoint="http://localhost:26657",
        api_endpoint="http://localhost:1317",
        chain_id="trustnet-1"
    ))
    
    # Verify connection
    if not await cosmos.health_check():
        logger.error("❌ Cannot connect to Cosmos SDK node")
        logger.error("   Make sure Cosmos SDK is running on localhost:26657")
    else:
        logger.info("✅ Connected to Cosmos SDK node")
    
    yield
    
    # Shutdown
    logger.info("⚠️  TrustNet API Gateway shutting down...")

# Initialize FastAPI
app = FastAPI(
    title="TrustNet API Gateway",
    version="1.0.0",
    description="API bridge between TrustNet modules and Cosmos SDK",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://trustnet.local",
        "http://localhost:5173",  # Vite dev server
        "http://localhost:3000"   # Alternative dev server
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================
# Core API Endpoints
# ============================================

@app.get("/api/health")
async def health_check():
    """
    Health check endpoint.
    Tests API gateway and Cosmos SDK connectivity.
    """
    cosmos_healthy = await cosmos.health_check()
    
    return {
        "success": True,
        "data": {
            "status": "healthy" if cosmos_healthy else "degraded",
            "api": "operational",
            "cosmos": cosmos_healthy,
            "version": "1.0.0"
        }
    }

@app.get("/api/status")
async def get_status():
    """
    Get blockchain status.
    Returns latest block, chain ID, node info.
    """
    try:
        block = await cosmos.get_latest_block()
        
        return {
            "success": True,
            "data": {
                "chain_id": cosmos.config.chain_id,
                "latest_block_height": block["block"]["header"]["height"],
                "latest_block_time": block["block"]["header"]["time"],
                "node_info": {
                    "rpc": cosmos.rpc,
                    "api": cosmos.api
                }
            }
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))

# ============================================
# Module Registration
# ============================================

# Modules will register their routes here
# Example: app.include_router(identity_router, prefix="/api/identity")

# This will be done in each module's routes.py

# ============================================
# Error Handlers
# ============================================

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    """Handle HTTP exceptions with standard format"""
    return {
        "success": False,
        "error": {
            "code": f"HTTP_{exc.status_code}",
            "message": exc.detail
        }
    }

# ============================================
# Run (development only)
# ============================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8080,
        reload=True,
        log_level="info"
    )
```

**Deliverable**: Main API gateway with health checks and Cosmos SDK integration.

---

#### 3. Shared Utilities

Create utilities all modules can use:

```python
# api/lib/utils.py

import uuid
from datetime import datetime
from typing import Any, Dict

def generate_request_id() -> str:
    """Generate unique request tracking ID"""
    return f"req-{uuid.uuid4()}"

def generate_did() -> str:
    """Generate Decentralized Identifier (DID)"""
    unique_id = str(uuid.uuid4())[:8]
    return f"did:trustnet:{unique_id}"

def success_response(data: Any, request_id: str = None) -> Dict:
    """
    Standard success response format.
    
    Args:
        data: Response data
        request_id: Optional request tracking ID
        
    Returns:
        Standardized response dictionary
    """
    return {
        "success": True,
        "data": data,
        "meta": {
            "timestamp": datetime.utcnow().isoformat(),
            "requestId": request_id or generate_request_id()
        }
    }

def error_response(
    code: str,
    message: str,
    details: Dict = None,
    request_id: str = None
) -> Dict:
    """
    Standard error response format.
    
    Args:
        code: Error code (e.g., "IDENTITY_NOT_FOUND")
        message: Human-readable error message
        details: Additional error details
        request_id: Optional request tracking ID
        
    Returns:
        Standardized error response dictionary
    """
    return {
        "success": False,
        "error": {
            "code": code,
            "message": message,
            "details": details or {}
        },
        "meta": {
            "timestamp": datetime.utcnow().isoformat(),
            "requestId": request_id or generate_request_id()
        }
    }

def validate_did(did: str) -> bool:
    """Validate DID format"""
    return did.startswith("did:trustnet:") and len(did) > 13

def validate_cosmos_address(address: str) -> bool:
    """Validate Cosmos SDK address format"""
    return address.startswith("cosmos1") and len(address) == 45
```

**Deliverable**: Shared utilities for all modules.

---

#### 4. Module Template

Create template showing how modules integrate:

```python
# api/modules/example/routes.py

from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from api.lib.cosmos_client import CosmosClient
from api.lib.utils import success_response, error_response
from api.main import cosmos

router = APIRouter()

# ============================================
# Models
# ============================================

class ExampleRequest(BaseModel):
    """Request model for example endpoint"""
    field1: str
    field2: int

class ExampleResponse(BaseModel):
    """Response model for example endpoint"""
    id: str
    result: str

# ============================================
# Routes
# ============================================

@router.get("/health")
async def module_health():
    """Module-specific health check"""
    return success_response({
        "module": "example",
        "status": "healthy"
    })

@router.post("/action")
async def perform_action(request: ExampleRequest):
    """Example action endpoint"""
    try:
        # 1. Validate input (Pydantic does this)
        
        # 2. Interact with blockchain via cosmos client
        tx = {
            "type": "trustnet/ExampleAction",
            "value": {
                "field1": request.field1,
                "field2": request.field2
            }
        }
        
        result = await cosmos.broadcast_tx(tx)
        
        # 3. Return success response
        return success_response({
            "id": result["hash"],
            "result": "Action completed",
            "txHash": result["hash"],
            "height": result["height"]
        })
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=error_response(
                code="ACTION_FAILED",
                message=str(e)
            )
        )

@router.get("/items")
async def list_items():
    """Example query endpoint"""
    try:
        # Query blockchain state
        result = await cosmos.query("/trustnet/example/items")
        
        return success_response({
            "items": result.get("items", []),
            "total": len(result.get("items", []))
        })
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

**To use in main.py**:
```python
from api.modules.example.routes import router as example_router
app.include_router(example_router, prefix="/api/example", tags=["Example"])
```

**Deliverable**: Module integration template.

---

## Phase 2: Testing Infrastructure (Week 1)

### Goal
Ensure API works before building modules.

### Test Suite

```python
# api/tests/test_cosmos_client.py

import pytest
from api.lib.cosmos_client import CosmosClient, CosmosConfig

@pytest.fixture
async def cosmos_client():
    """Create test Cosmos client"""
    config = CosmosConfig(
        rpc_endpoint="http://localhost:26657",
        api_endpoint="http://localhost:1317"
    )
    return CosmosClient(config)

@pytest.mark.asyncio
async def test_health_check(cosmos_client):
    """Test Cosmos SDK connectivity"""
    healthy = await cosmos_client.health_check()
    assert healthy == True

@pytest.mark.asyncio
async def test_get_latest_block(cosmos_client):
    """Test fetching latest block"""
    block = await cosmos_client.get_latest_block()
    assert "block" in block
    assert "header" in block["block"]

@pytest.mark.asyncio
async def test_query_account(cosmos_client):
    """Test account query"""
    # Test with known address
    address = "cosmos1..."  # Replace with test address
    account = await cosmos_client.get_account(address)
    # Should return account or None
```

```python
# api/tests/test_main.py

import pytest
from fastapi.testclient import TestClient
from api.main import app

client = TestClient(app)

def test_health_endpoint():
    """Test API health check"""
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["success"] == True

def test_status_endpoint():
    """Test blockchain status"""
    response = client.get("/api/status")
    assert response.status_code == 200
    data = response.json()["data"]
    assert "chain_id" in data
    assert "latest_block_height" in data

def test_cors_headers():
    """Test CORS middleware"""
    response = client.get(
        "/api/health",
        headers={"Origin": "https://trustnet.local"}
    )
    assert "access-control-allow-origin" in response.headers
```

**Deliverable**: Comprehensive API test suite.

---

## Directory Structure

```
api/
├── main.py                 # Main FastAPI app
├── lib/
│   ├── cosmos_client.py    # Cosmos SDK client
│   └── utils.py            # Shared utilities
├── modules/
│   ├── __init__.py
│   └── example/            # Example module template
│       ├── __init__.py
│       ├── routes.py       # Module routes
│       └── models.py       # Pydantic models
├── tests/
│   ├── test_cosmos_client.py
│   ├── test_main.py
│   └── conftest.py
└── requirements.txt        # Python dependencies
```

---

## Requirements File

```txt
# api/requirements.txt

# Core
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.0

# HTTP client for Cosmos SDK
httpx==0.26.0

# Testing
pytest==7.4.3
pytest-asyncio==0.21.1

# Cosmos SDK integration
cosmospy==6.0.0        # Cosmos SDK Python client
mospy==2.0.0           # Transaction builder

# Utilities
python-multipart==0.0.6
python-jose[cryptography]==3.3.0  # JWT tokens
passlib[bcrypt]==1.7.4             # Password hashing
```

---

## Development Workflow

### 1. Install Dependencies

```bash
cd api/
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Start Cosmos SDK (Mock/Test)

```bash
# Option 1: Use local Cosmos SDK test node
./start-cosmos-testnet.sh

# Option 2: Use mock server for development
./start-mock-cosmos.sh
```

### 3. Run API

```bash
# Development mode (hot reload)
uvicorn api.main:app --reload --host 0.0.0.0 --port 8080

# Access:
# - API: http://localhost:8080/api/health
# - Docs: http://localhost:8080/api/docs
# - ReDoc: http://localhost:8080/api/redoc
```

### 4. Test API

```bash
# Run tests
pytest api/tests/

# Test health endpoint
curl http://localhost:8080/api/health

# Test status endpoint
curl http://localhost:8080/api/status
```

---

## Success Criteria

### Week 1 Deliverables

- [ ] Cosmos SDK client library working
- [ ] API gateway running (main.py)
- [ ] Health check endpoints responding
- [ ] Cosmos SDK connectivity verified
- [ ] CORS configured for frontend
- [ ] Shared utilities available
- [ ] Module integration template created
- [ ] Test suite passing
- [ ] API documentation auto-generated (Swagger)
- [ ] Ready for Identity module integration

---

## Next Steps After API

Once API infrastructure is complete:

1. **Build dev-sync.sh** - Sync modules to VM
2. **Build Identity module** - Uses API
3. **Test complete flow** - Frontend → API → Cosmos SDK
4. **Add more modules** - Transactions, Keys, etc.

---

## Module Integration Pattern

Once API is built, modules follow this pattern:

```python
# modules/identity/api/routes.py
from fastapi import APIRouter
from api.lib.cosmos_client import CosmosClient
from api.lib.utils import success_response

router = APIRouter()

@router.post("/register")
async def register_identity(name: str, email: str):
    # Use shared cosmos client
    from api.main import cosmos
    
    # Create transaction
    tx = create_identity_tx(name, email)
    
    # Broadcast via API
    result = await cosmos.broadcast_tx(tx)
    
    return success_response({
        "did": result["data"]["did"],
        "txHash": result["hash"]
    })

# Register in main.py:
# from modules.identity.api.routes import router as identity_router
# app.include_router(identity_router, prefix="/api/identity")
```

---

## Summary

**Phase 1**: Build API infrastructure (Week 1)
- Cosmos SDK client library
- Main API gateway
- Shared utilities
- Module integration template
- Test suite

**Phase 2**: Build modules (Week 2+)
- Identity module (uses API)
- Transaction module (uses API)
- All modules share same API infrastructure

**Benefits**:
- ✅ Modules can communicate with blockchain
- ✅ Shared code (no duplication)
- ✅ Consistent patterns
- ✅ Easy testing
- ✅ Automatic documentation

---

*Document created: February 2, 2026*  
*Priority: Implement API infrastructure FIRST*  
*Next: Build Cosmos SDK client and API gateway*

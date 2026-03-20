# TrustNet iOS ↔ Node Communication Protocol

**Date**: March 19, 2026  
**Phase**: 4 (Extended) - Identity Registration & Blockchain Integration  
**Status**: Protocol Definition & Implementation Planning

---

## Executive Summary

The iOS app serves as a **secure NFC input layer** for government ID verification. Once identity data is collected and validated locally on the device, it's transferred to the user's local TrustNet node for:

1. **Server-side validation** (MRZ authentication, document expiry, etc.)
2. **Blockchain recording** (create immutable identity on Cosmos SDK blockchain)
3. **Unique identity assignment** (one person ↔ one DID - Decentralized Identifier)
4. **Return user credentials** (private keys, DID, blockchain address)

```
┌─────────────────────────────────┐
│  iOS Device                      │
│  ├─ NFC: Read gov ID            │
│  ├─ Local: Validate MRZ         │
│  ├─ Local: Generate keys        │
│  └─ Queue: Ready for transfer   │
└────────────┬────────────────────┘
             │ HTTPS POST
             ▼
┌─────────────────────────────────┐
│  Local TrustNet Node (LAN)      │
│  ├─ Receive registration data   │
│  ├─ Server-side validate        │
│  ├─ Create DID                  │
│  ├─ Record on blockchain        │
│  └─ Return user credentials     │
└────────────┬────────────────────┘
             │ HTTPS Response
             ▼
┌─────────────────────────────────┐
│  iOS Device (Finalize)          │
│  ├─ Receive DID + credentials   │
│  ├─ Store in Keychain           │
│  └─ Complete registration       │
└─────────────────────────────────┘
```

---

## Architecture Decisions (from TrustNet whitepapers)

### 1. Identity Model: Hybrid Approach ✅

**Decision**: Identity + Keys generated together during registration

**Why chosen** (from IDENTITY_VS_KEYS_DECISION.md):
- ✅ Best UX - Single registration step
- ✅ Self-sovereign - User gets keys immediately
- ✅ Keys generated client-side (secure, no server access)
- ✅ Recovery options - User can backup encrypted keys
- ✅ Progressive disclosure - Complexity hidden

**What gets created**:
1. **DID** (Decentralized Identifier) - `did:trustnet:{unique-id}`
2. **Blockchain Account** - Derived from public key (Cosmos SDK standard)
3. **Key Pair** - EC P-256 (Apple standard, fast)
4. **Trust Score** - Starts at 100/100 (from TRUST_SYSTEM.md)

---

### 2. Blockchain Platform: Cosmos SDK ✅

(From ARCHITECTURE.md)

**Why Cosmos SDK**:
- Built-in transaction processing
- Tendermint BFT consensus (fast, finality in seconds)
- RESTful API + RPC + gRPC options
- Perfect for identity/trust system
- Used by major projects (Osmosis, Evmos, Thorchain)

**Available endpoints on TrustNet node**:
- RPC: `http://localhost:26657`
- REST: `http://localhost:1317`
- gRPC: `localhost:9090`

**Chain ID**: `trustnet-1` (configurable)

---

### 3. Communication Layer: HTTPS + REST API ✅

(From API_IMPLEMENTATION_PLAN.md)

**Architecture**:
```
iOS App ─HTTPS─→ API Gateway (Python FastAPI)
                     ↓ RPC/REST
                  Cosmos SDK Node
```

**Why HTTPS**:
- ✅ Encryption in transit (protects privacy)
- ✅ Mutual TLS (if needed for later device linking)
- ✅ Certificate pinning (prevent MITM attacks)
- ✅ Standard for mobile apps

**Why REST API endpoints**:
- ✅ Lingua franca (works from any device/language)
- ✅ Self-documenting (OpenAPI/Swagger)
- ✅ Easy debugging (cURL, Postman)
- ✅ Mobile-friendly (no gRPC complexity)

---

## Communication Protocol Definition

### Phase 1: Pre-Registration (iOS App Only)

**User actions** (Days 3-8):
1. ✅ Scan government ID with NFC
2. ✅ Read MRZ (Machine Readable Zone) from passport
3. ✅ Validate MRZ locally (ICAO 9303 checksum)
4. ✅ Display confirmation screen (name, DOB, ID#)
5. ✅ User confirms OR corrects
6. ✅ Generate key pair locally (EC P-256)
7. ✅ Store private key in Keychain (encrypted)
8. ✅ Queue registration payload for sending

**Data prepared** (not yet sent):
```swift
struct RegistrationPayload: Codable {
    let governmentID: GovernmentIDData
    let firstName: String
    let lastName: String
    let email: String
    let dateOfBirth: Date
    let mrzData: ICAO9303Data           // Raw MRZ from NFC
    let publicKey: String               // Public key (hex encoded)
    let signatureVerification: String   // Self-signed proof of device ownership
}
```

---

### Phase 2: Transfer to Node (iOS → TrustNet Node)

**Endpoint**: `POST /api/identity/register`

**Request** (from iOS app):
```json
{
  "governmentID": {
    "type": "passport",
    "country": "US",
    "number": "Z1234567",
    "expiryDate": "2032-06-15"
  },
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "dateOfBirth": "1990-05-20",
  "mrzData": {
    "line1": "P<USADOE<<JOHN<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<",
    "line2": "Z123456785USA9005208M3206154<<<<<<<<<<<<<<<<<<<<<<<<<<<<<14",
    "checkDigit": "4"
  },
  "publicKey": "0x48656c6c6f202068747470733a2f2f...", // EC P-256 public key as hex
  "deviceInfo": {
    "platform": "iOS",
    "osVersion": "16.4",
    "appVersion": "1.0.0",
    "deviceID": "unique-device-identifier"
  }
}
```

**Request headers**:
```
POST /api/identity/register HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Content-Length: {length}
Accept: application/json

[JSON body above]
```

**Processing on Node** (API Gateway):
```python
# api/routes/identity.py

from fastapi import APIRouter, HTTPException
from typing import Dict, Any
import httpx
from datetime import datetime

router = APIRouter(prefix="/api/identity")

@router.post("/register")
async def register_identity(payload: RegistrationPayload) -> Dict[str, Any]:
    """
    Register a new user identity on TrustNet.
    
    Steps:
    1. Validate MRZ data (ICAO 9303)
    2. Verify government ID not already registered
    3. Generate DID (Decentralized Identifier)
    4. Create blockchain account from public key
    5. Record identity on blockchain (immutable)
    6. Return user credentials
    """
    
    # Step 1: Validate MRZ
    if not validate_icao9303_mrz(payload.mrzData):
        raise HTTPException(400, "Invalid government ID data")
    
    # Step 2: Check uniqueness (one person ↔ one identity)
    existing = await cosmos_client.query(
        "/trustnet/identity/v1/find_by_government_id",
        {
            "country": payload.governmentID.country,
            "number": payload.governmentID.number
        }
    )
    
    if existing:
        raise HTTPException(409, "Government ID already registered")
    
    # Step 3: Generate DID
    did = generate_did(
        first_name=payload.firstName,
        last_name=payload.lastName,
        date_of_birth=payload.dateOfBirth
    )
    # Result: did:trustnet:john-doe-1990-05-20-abc123
    
    # Step 4: Derive blockchain account from public key
    blockchain_address = derive_cosmos_address(payload.publicKey)
    # Result: cosmos1abc123xyz...
    
    # Step 5: Build blockchain transaction
    tx = {
        "did": did,
        "publicKey": payload.publicKey,
        "blockchainAddress": blockchain_address,
        "governmentID": {
            "country": payload.governmentID.country,
            "type": payload.governmentID.type,
            "number": payload.governmentID.number,
            "expiryDate": payload.governmentID.expiryDate
        },
        "personalData": {
            "firstName": payload.firstName,
            "lastName": payload.lastName,
            "email": payload.email,
            "dateOfBirth": payload.dateOfBirth
        },
        "registeredAt": datetime.utcnow().isoformat(),
        "trustScore": 100  # From TRUST_SYSTEM.md - all new verified users start at 100
    }
    
    # Step 6: Broadcast to blockchain (via Cosmos SDK)
    result = await cosmos_client.broadcast_tx(tx)
    
    if result["code"] != 0:
        raise HTTPException(500, f"Blockchain error: {result['log']}")
    
    # Step 7: Return credentials to iOS app
    return {
        "success": true,
        "did": did,
        "blockchainAddress": blockchain_address,
        "blockchainHash": result["hash"],
        "blockchainHeight": result["height"],
        "trustScore": 100,
        "message": "Identity registered successfully"
    }
```

---

### Phase 3: Response from Node (TrustNet Node → iOS)

**Response** (200 OK):
```json
{
  "success": true,
  "did": "did:trustnet:john-doe-1990-05-20-abc123",
  "blockchainAddress": "cosmos1abc123xyz789...",
  "blockchainHash": "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
  "blockchainHeight": 12345,
  "trustScore": 100,
  "message": "Identity registered successfully",
  "timestamp": "2026-03-19T15:30:00Z"
}
```

**Response codes**:
- `200` - Identity registered successfully
- `400` - Invalid data (bad MRZ, malformed request)
- `409` - Government ID already registered (identity already exists)
- `500` - Blockchain error or server error
- `503` - Node not available (offline)

---

### Phase 4: Finalize on iOS (Store Credentials)

**iOS App actions**:
1. ✅ Receive response from node
2. ✅ Verify blockchain hash (optional - can be done later)
3. ✅ Store credentials in Keychain:
   - DID (Decentralized Identifier)
   - Blockchain address
   - Public key
   - Trust score
4. ✅ Update UI (success screen with identity confirmed)
5. ✅ Keep private key in Keychain (already stored)

**Keychain structure**:
```swift
struct UserIdentity: Codable {
    let did: String                     // did:trustnet:...
    let blockchainAddress: String       // cosmos1...
    let publicKey: String               // hex encoded EC P-256
    let privateKey: String              // encrypted in Keychain
    let trustScore: Int                 // 100 at registration
    let registeredAt: Date
    let governmentID: GovernmentIDData
}

// Stored in Keychain under service: "com.trustnet.identity"
// Item key: "did:\(userIdentity.did)"
```

---

## Network Assumptions

### Scenario 1: Same Network (LAN)
✅ **Recommended for Phase 4**

**Assumptions**:
- iOS device and TrustNet node on same WiFi LAN
- Node address: `https://192.168.1.100:8080` (local IP)
- No internet required for registration
- Works offline once registered

**Certificate handling**:
```swift
// For self-signed localhost certificate during development
URLSessionConfiguration.default.waitsForConnectivity = true

// For local IP address (192.168.x.x), use:
// - Self-signed cert with local IP in SAN
// - Or disable SSL verification in development (NOT production)
```

---

### Scenario 2: Remote Node (Internet)
⏳ **Future Phase**

**Assumptions**:
- TrustNet node behind public domain (trustnet.node.example.com)
- Valid SSL certificate (Let's Encrypt)
- Mobile app discovers node via:
  - QR code scan
  - Manual URL entry
  - DNS service discovery (mDNS)
  - Network directory service

---

## Error Handling

### Connection Errors

```swift
enum NodeConnectionError: Error {
    case nodeUnreachable(String)        // Node is offline
    case invalidSSLCertificate(String)  // SSL validation failed
    case invalidURL                     // Malformed URL
    case networkTimeout                 // Request timeout (30s)
}
```

**Recovery strategy**:
1. Show error message to user
2. Offer retry button
3. After 3 failures, suggest:
   - "Check if node is running"
   - "Check WiFi connection"
   - "Check node address"

---

### Validation Errors

```swift
enum RegistrationError: Error {
    case invalidMRZ                     // Bad MRZ checksum
    case idAlreadyRegistered            // User already in system
    case insufficientData               // Missing required fields
    case nodeError(String)              // Node returned error
}
```

**Recovery strategy**:
1. Display specific error message
2. For "already registered":
   - "This government ID was already used to create an identity"
   - "If you're the same person, log in with your existing identity"
3. For validation errors:
   - Highlight the problematic field
   - Offer to try again

---

### Blockchain Errors

```swift
enum BlockchainError: Error {
    case transactionFailed(String)      // TX rejected by consensus
    case insufficientFunds              // Node ran out of fees (not our problem)
    case blockHeightMismatch            // Chain reorganization
}
```

**Recovery strategy**:
1. These are rare (blockchain is consistent)
2. Show raw error message
3. Suggest contact support
4. Log for debugging

---

## Security Considerations

### 1. Private Key Management

**Never send private key over network**:
- ✅ Generated on iOS device
- ✅ Never sent to node
- ✅ Only public key sent for registration
- ✅ Stored encrypted in Keychain

---

### 2. TLS/SSL

**For localhost connections** (Phase 4):
```swift
// Allow self-signed certs on localhost only
let session = URLSession(configuration: .default, delegate: TrustPinningDelegate(), delegateQueue: .main)

class TrustPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Only for localhost development
        if challenge.protectionSpace.host == "localhost" ||
           challenge.protectionSpace.host.hasPrefix("192.168.") {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
```

**For production** (future):
- Use proper SSL certificates
- Implement certificate pinning
- Validate domain names

---

### 3. Request Signing

**Optional enhancement** (for future device linking):
```swift
// Sign request with private key to prove device ownership
let signature = signData(
    data: requestBody,
    privateKey: userPrivateKey
)

headers["X-Signature"] = signature
headers["X-Public-Key"] = userPublicKey
```

---

## Implementation Roadmap

### Days 3-4: View Binding (No network changes needed)
- ✅ Update 6 UI screens with @ObservedObject
- ✅ Wire form fields to ViewModel
- ✅ Display validation errors

### Days 5: ValidationEngine (Local only)
- ✅ Complete local validation (email, name, passport)
- ✅ Display real-time validation errors
- ✅ Prepare RegistrationPayload

### Days 6-11: Security Layer + HTTP Client
- ⭐ **NEW**: Implement TrustNetNodeClient (similar to Cosmos SDK client)
  - Setup URLSession with SSL handling
  - Implement POST to `/api/identity/register`
  - Handle response parsing
  - Error mapping (400/409/500 → user-friendly messages)
- ✅ Complete KeychainManager
- ✅ Complete BiometricHasher
- ✅ Complete KeyGenerator

### Days 12-15: Integration Testing
- ✅ **Unit tests** for TrustNetNodeClient
  - Mock responses
  - Error scenarios (400, 409, 500)
  - Connection failures
- ✅ **Integration tests** (requires running node)
  - Full registration flow
  - Verify blockchain recording
  - Verify credentials returned
- ✅ **End-to-end test**
  - iOS app ↔ Real TrustNet node
  - Verify immutable identity creation
  - Verify unique identity assignment

---

## Deliverables (Extended Phase 4)

### Code Files

1. **TrustNetNodeClient.swift** (300 lines)
   - HTTP client for node communication
   - Request/response models
   - Error handling
   - URLSession setup with SSL

2. **NodeAPIModels.swift** (200 lines)
   - `RegistrationPayload` struct
   - `RegistrationResponse` struct
   - `NodeError` enum

3. **RegistrationViewModel+Node.swift** (150 lines)
   - Enhanced ViewModel with submitToNode() method
   - Handle node response
   - Map credentials to Keychain storage

4. **TrustNetNodeClientTests.swift** (250 lines)
   - Mock node responses
   - Test error scenarios
   - Test request formatting

### Documentation

1. **NODE_COMMUNICATION_PROTOCOL.md** (this file)
2. **TRUSTNET_API_SPECIFICATION.md** (node-side API docs)
3. **TESTING_WITH_LOCAL_NODE.md** (how to test integration)

---

## Next Steps

**Before we code, confirm**:

1. ✅ **Network setup**: Use LAN with self-signed cert? (Yes/No)
2. ✅ **Node URL**: Hardcoded or user-discoverable? 
   - Option A: Hardcode to `https://192.168.1.100:8080`
   - Option B: QR code scan to set node URL
   - Option C: DNS discovery (mDNS)
3. ✅ **SSL handling**: Allow self-signed on localhost? (Yes/dev only)
4. ✅ **Timeline**: Complete all Days 3-15 work before testing with real node?

Once confirmed, I'll implement:
1. TrustNetNodeClient
2. Integration into RegistrationViewModel
3. Error recovery flows
4. Full test suite

---

**Status**: Ready to implement on your confirmation ✅

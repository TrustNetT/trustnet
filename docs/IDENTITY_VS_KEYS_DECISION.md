# Identity vs Keys: Architectural Decision

**Date**: February 2, 2026  
**Question**: Do we need keys to register an identity?  
**Impact**: Determines which module to build first  

---

## The Core Question

**In TrustNet, what's the relationship between identity and keys?**

```
Option A: Keys → Identity
User generates key pair first
Key is used to sign identity registration
Identity is tied to public key

Option B: Identity → Keys
User registers identity first (name, email)
System generates DID
Keys added later for transactions

Option C: Identity + Keys Together
Identity registration auto-generates key pair
User gets both DID and keys at once
```

---

## Blockchain Context (Cosmos SDK)

### How Cosmos SDK Works

In Cosmos SDK:
1. **Account** = Public key address (e.g., `cosmos1abc123...`)
2. **Transactions** = Signed with private key
3. **Identity** = Optional metadata (not required by blockchain)

**Example**:
```
Alice wants to use TrustNet:

Traditional blockchain:
1. Generate key pair (private/public key)
2. Derive address from public key: cosmos1abc123
3. Use address for everything (no "identity")

With TrustNet identity layer:
Option A - Keys first:
1. Generate key pair
2. Register identity: "Alice" → cosmos1abc123
3. Identity linked to blockchain address

Option B - Identity first:
1. Register identity: "Alice" → did:trustnet:alice-123
2. DID exists on blockchain (separate from keys)
3. Later: Add keys for signing transactions

Option C - Together:
1. Register "Alice" → System generates:
   - DID: did:trustnet:alice-123
   - Key pair: private/public key
   - Blockchain account: cosmos1abc123
2. Everything linked together
```

---

## Analysis of Each Option

### Option A: Keys First (Ethereum-Style)

**Flow**:
```javascript
// 1. User generates key pair first
const keyPair = generateKeyPair()
// privateKey: 0x1234...
// publicKey: 0x5678...
// address: cosmos1abc123...

// 2. Register identity using that key
registerIdentity({
  name: "Alice",
  email: "alice@example.com",
  publicKey: keyPair.publicKey
})
// Result: Identity "Alice" linked to cosmos1abc123
```

**Pros**:
✅ **User controls keys** - Private key never leaves device  
✅ **True decentralization** - No server generates keys  
✅ **Standard blockchain pattern** - How Ethereum, Bitcoin work  
✅ **Security** - Keys generated on user's device  
✅ **Self-sovereignty** - User owns identity via key ownership  

**Cons**:
❌ **Complexity** - User must manage keys from day 1  
❌ **Key loss** = **Identity loss** - Lose key, lose identity  
❌ **UX friction** - Extra step before registration  
❌ **Mobile challenge** - Key management on phones is hard  

**Modules needed**:
1. **Key Management** (FIRST) - Generate, store, backup keys
2. **Identity Registration** (SECOND) - Register using generated key

---

### Option B: Identity First (DID-Style)

**Flow**:
```javascript
// 1. Register identity (no key needed)
const identity = await registerIdentity({
  name: "Alice",
  email: "alice@example.com"
})
// Result: DID created: did:trustnet:alice-123
// Stored on blockchain (signed by TrustNet system key)

// 2. Later: Add keys for transactions
const keyPair = generateKeyPair()
await addKeyToIdentity({
  did: "did:trustnet:alice-123",
  publicKey: keyPair.publicKey
})
```

**Pros**:
✅ **Simple UX** - Name + email = identity (like web2)  
✅ **Key management optional** - Only needed for transactions  
✅ **Easy onboarding** - Lower barrier to entry  
✅ **Identity ≠ Key** - Can rotate keys without losing identity  
✅ **Recovery** - Identity exists even if keys lost  

**Cons**:
❌ **Centralization risk** - Who signs initial identity registration?  
❌ **Not true self-sovereign** - TrustNet system controls initial identity  
❌ **Trust assumption** - Users trust TrustNet to create their DID  
❌ **Blockchain question** - How is identity stored without user's key?  

**Modules needed**:
1. **Identity Registration** (FIRST) - Create DID, store on blockchain
2. **Key Management** (SECOND) - Add keys to existing identity

---

### Option C: Identity + Keys Together (Hybrid)

**Flow**:
```javascript
// 1. Register identity - system auto-generates everything
const result = await registerIdentity({
  name: "Alice",
  email: "alice@example.com"
})

// Result:
// - DID: did:trustnet:alice-123
// - Key pair generated
// - Private key: 0x1234... (encrypted with password)
// - Public key: 0x5678...
// - Blockchain account: cosmos1abc123
// - All linked together

// 2. User downloads encrypted key backup
downloadKeyBackup(result.did)
```

**Pros**:
✅ **Best UX** - One step registration  
✅ **Self-sovereign** - User gets keys immediately  
✅ **Standard blockchain** - Keys generated client-side  
✅ **Recovery options** - Can backup keys  
✅ **Progressive disclosure** - User doesn't see complexity upfront  

**Cons**:
❌ **Key generation must be secure** - Client-side crypto required  
❌ **Backup critical** - User must save keys (may not understand)  
❌ **Complexity hidden** - Users may not realize they have keys  

**Modules needed**:
1. **Identity Registration** (FIRST) - Includes key generation
   - Frontend: Generate key pair client-side
   - Backend: Store public key on blockchain
   - User: Downloads encrypted backup

---

## Use Cases Comparison

### Use Case 1: New User Registration

**Option A (Keys first)**:
```
1. Click "Get Started"
2. → "First, generate your keys" (⚠️ intimidating)
3. → Download key backup (⚠️ confusing)
4. → "Now register your identity"
5. → Enter name, email
6. → Done

Steps: 6 | User friction: High | Security: Excellent
```

**Option B (Identity first)**:
```
1. Click "Get Started"
2. → Enter name, email
3. → Identity created! (DID: did:trustnet:...)
4. → Done

(Keys needed later for transactions)

Steps: 4 | User friction: Low | Security: Depends on system
```

**Option C (Together)**:
```
1. Click "Get Started"
2. → Enter name, email
3. → Identity + keys created
4. → Download backup (can skip)
5. → Done

Steps: 5 | User friction: Medium | Security: Good
```

---

### Use Case 2: Making a Transaction

**Option A**:
- ✅ User already has keys (registered with identity)
- ✅ Can sign transaction immediately
- ✅ No extra steps

**Option B**:
- ❌ User needs to generate keys first
- ❌ "Before you can transact, generate keys"
- ❌ Extra step when needed

**Option C**:
- ✅ User already has keys (auto-generated)
- ✅ Can sign transaction immediately
- ⚠️ User may have forgotten/lost backup

---

### Use Case 3: Key Recovery

**Option A**:
- User loses key → **Identity lost** (key = identity)
- No recovery possible
- Must create new identity

**Option B**:
- User loses key → **Identity preserved** (DID still exists)
- Can generate new key
- Link new key to existing DID
- Identity intact

**Option C**:
- User loses key → **Depends on implementation**
- If backup exists → Restore key
- If no backup → Similar to Option B (generate new key)

---

## Recommendation for TrustNet

### 🎯 Option C: Identity + Keys Together (Recommended)

**Rationale**:

1. **Best user experience**:
   - Simple registration (like web2)
   - Blockchain security (keys generated)
   - Progressive disclosure (backup optional initially)

2. **Blockchain-native**:
   - Keys generated client-side (secure)
   - Public key stored on blockchain
   - User controls private key

3. **Flexible**:
   - Can add key rotation later
   - Can add recovery mechanisms
   - Can separate identity from keys if needed

4. **Mobile-friendly**:
   - Works on iPad/Android (PWA)
   - Biometric encryption for keys
   - Easy backup via QR code

### Implementation

**Module to build FIRST**: **Identity Registration**

**Why identity first (not keys)**:
- Identity module **includes** key generation
- Keys are generated **during** identity registration
- One module handles both (simpler)

**Architecture**:

```javascript
// modules/identity/frontend/register.js

async function registerIdentity(name, email) {
  // 1. Generate key pair CLIENT-SIDE (Web Crypto API)
  const keyPair = await window.crypto.subtle.generateKey(
    {
      name: "ECDSA",
      namedCurve: "P-256"
    },
    true,  // extractable
    ["sign", "verify"]
  )
  
  // 2. Derive public key
  const publicKey = await exportPublicKey(keyPair.publicKey)
  
  // 3. Call backend API
  const response = await fetch('/api/identity/register', {
    method: 'POST',
    body: JSON.stringify({
      name,
      email,
      publicKey
    })
  })
  
  const { did } = await response.json()
  
  // 4. Encrypt private key with password
  const password = await promptUserForPassword()
  const encryptedKey = await encryptPrivateKey(keyPair.privateKey, password)
  
  // 5. Store encrypted key locally
  localStorage.setItem(`trustnet:key:${did}`, encryptedKey)
  
  // 6. Prompt user to download backup
  downloadKeyBackup(did, encryptedKey)
  
  return { did, publicKey }
}
```

**Backend** (Python FastAPI):
```python
@app.post("/api/identity/register")
async def register_identity(request: RegisterRequest):
    # 1. Validate public key
    validate_public_key(request.publicKey)
    
    # 2. Generate DID
    did = f"did:trustnet:{generate_unique_id()}"
    
    # 3. Create blockchain transaction
    tx = {
        'type': 'trustnet/RegisterIdentity',
        'value': {
            'did': did,
            'name': request.name,
            'email': request.email,
            'publicKey': request.publicKey
        }
    }
    
    # 4. Sign with system key (temporary until user has own key)
    # OR: User signs client-side and sends signed tx
    
    # 5. Broadcast to Cosmos SDK
    result = await broadcast_transaction(tx)
    
    return {
        'success': True,
        'data': {
            'did': did,
            'publicKey': request.publicKey,
            'txHash': result.hash
        }
    }
```

---

## Alternative: Start Simple, Add Complexity

**Phase 1 (Week 1)**: Simple identity registration
```javascript
// Just name + email, no keys yet
registerIdentity({ name: "Alice", email: "alice@example.com" })
// → DID created, stored on blockchain
```

**Phase 2 (Week 2)**: Add key generation
```javascript
// Auto-generate keys during registration
registerIdentity({ name: "Alice", email: "alice@example.com" })
// → DID + keys created
// → User downloads backup
```

**Phase 3 (Week 3)**: Add key management
```javascript
// Rotate keys, add multiple keys, recovery
rotateKeys(did, newPublicKey)
addKey(did, newPublicKey)
```

This approach lets you ship fast and iterate.

---

## Decision Matrix

| Criterion | Keys First | Identity First | Together |
|-----------|-----------|----------------|----------|
| **User onboarding** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Security** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Decentralization** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |
| **Development speed** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Mobile UX** | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Recovery** | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Blockchain native** | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |

**Winner**: Option C (Together) - Best balance

---

## Final Recommendation

### Build Identity Module First (includes key generation)

**Why**:
1. **Keys are part of identity registration** - Not separate
2. **Client-side key generation** - Secure, no server involvement
3. **One module does both** - Simpler than two modules
4. **Better UX** - One-step registration
5. **Standard pattern** - How most blockchain apps work

**What the identity module includes**:
- ✅ Identity registration form (name, email)
- ✅ Client-side key generation (Web Crypto API)
- ✅ Key encryption (password-based)
- ✅ Local storage (encrypted key)
- ✅ Backup download (encrypted key file)
- ✅ Blockchain integration (store DID + public key)

**Key Management module comes later**:
- Key rotation
- Multiple keys per identity
- Key recovery
- Hardware key support (Ledger, etc.)

---

## Implementation Plan

### Week 1: Identity Module (with embedded key generation)

**Frontend**:
```
modules/identity/frontend/
├── register.html           # Registration form
├── register.js             # Key gen + API call
├── crypto.js               # Web Crypto API wrapper
└── backup.js               # Key backup download
```

**Backend**:
```
modules/identity/api/
├── main.py                 # FastAPI app
├── routes.py               # /register, /lookup
└── cosmos.py               # Cosmos SDK integration
```

**Features**:
- Register identity (name + email)
- Auto-generate key pair (client-side)
- Store public key on blockchain
- Download encrypted backup
- Display DID

### Week 2-3: Key Management Module (advanced features)

**Features**:
- View keys
- Rotate keys
- Add multiple keys
- Import/export keys
- Hardware wallet support

---

## Summary

**Question**: Do we need keys to register identity?

**Answer**: **Yes, but they're generated during registration** (Option C)

**First module to build**: **Identity Registration**
- Includes client-side key generation
- One-step process for users
- Keys embedded in identity module

**Second module**: **Key Management** (advanced features later)

**Benefits**:
- ✅ Simple UX (one-step registration)
- ✅ Secure (client-side key generation)
- ✅ Blockchain-native (keys stored client-side)
- ✅ Fast development (one module, not two)
- ✅ Mobile-friendly (works on iPad/Android PWA)

---

*Document created: February 2, 2026*  
*Decision: Identity module first (includes key generation)*  
*Next: Implement identity registration with embedded crypto*

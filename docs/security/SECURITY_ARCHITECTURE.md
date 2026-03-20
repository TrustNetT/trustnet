# TrustNet Security Architecture

**Date Created:** March 11, 2026  
**Version:** 1.0  
**Status:** Design Phase - For Implementation Design  
**Author:** Security Architecture Team

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Security Principles](#security-principles)
3. [Threat Model](#threat-model)
4. [Identity Verification Security](#identity-verification-security)
5. [Registration Flow Security](#registration-flow-security)
6. [Biometric Registry Security](#biometric-registry-security)
7. [Key Management](#key-management)
8. [Data Encryption](#data-encryption)
9. [Network Security](#network-security)
10. [Age Segmentation Security](#age-segmentation-security)
11. [Youth Protection Mechanisms](#youth-protection-mechanisms)
12. [Audit & Compliance](#audit--compliance)
13. [Security Decision Log](#security-decision-log)

---

## Executive Summary

TrustNet's security architecture is built on the principle: **"One Person = One Identity"**—enforced globally with zero exceptions through a distributed biometric registry, government ID verification, encryption-first design, and multi-layered protection.

**Critical Design Decision**: Security is not a feature—it is the foundation. One security breach destroys the entire trust system. All decisions prioritize security over convenience.

---

## Security Principles

### 1. One Person = One Identity (PARAMOUNT)
- **Principle**: Global enforcement across all network segments
- **Implementation**: Distributed Biometric Registry using SHA-256 hashes
- **Verification**: NFC government ID reading (ICAO 9303 standard)
- **Exception Policy**: NONE. No exceptions, no workarounds, no temporary allowances
- **Impact**: Prevents Sybil attacks, reputation gaming, vote manipulation, duplicate accounts

### 2. Security-First Design
- **Principle**: Security decisions take precedence over feature velocity
- **Implementation**: All features design with security constraints first
- **Cost**: Development velocity slower than insecure systems (acceptable trade-off)
- **Benefit**: System remains trustworthy at scale

### 3. Zero-Trust Architecture
- **Principle**: Never trust anything by default—verify everything
- **Implementation**: 
  - All requests require cryptographic proof of identity
  - All data encrypted in transit (TLS 1.3) and at rest (AES-256-GCM)
  - All actions logged and auditable
- **No Exceptions**: No backdoors, no administrative bypass, no "just this once"

### 4. Privacy by Design
- **Principle**: Collect minimum data, encrypt by default, delete when done
- **Implementation**:
  - Biometric data never transmitted (only SHA-256 hashes)
  - Government ID data encrypted locally before any transmission
  - One-way hashing for all sensitive identifiers
  - User consent required for any data retention
- **GDPR Compliance**: Right to erasure, data portability, transparency

### 5. Client-Side Security
- **Principle**: Never trust server with plaintext secrets
- **Implementation**:
  - Key generation on user device (Web Crypto API)
  - Encryption/decryption in browser (never transmitted keys)
  - Digital signatures from client
- **Implication**: Users responsible for key backup (no recovery if lost)

### 6. Cryptographic Proof Over Trust
- **Principle**: Replace social trust with mathematical proof
- **Implementation**:
  - All identity claims verified cryptographically
  - All transactions digitally signed
  - All reputation claims auditable on blockchain
- **Benefit**: No reliance on central authority

---

## Threat Model

### High-Severity Threats (Must Prevent)

#### T1: Sybil Attacks (Identity Duplication)
- **Threat**: Attacker creates unlimited fake accounts to manipulate reputation/voting
- **Impact**: Destroys system integrity—"one person = one identity" violated
- **Prevention**:
  - NFC government ID verification (biometric + government signature validation)
  - SHA-256 biometric hash registry (prevents duplicate registration)
  - Cross-segment global registry (prevents re-registration on different networks)
- **Detection**: Duplicate hash detection during registration rejection

#### T2: Government ID Forgery
- **Threat**: Attacker forges government ID to bypass identity verification
- **Impact**: Bypasses primary identity verification mechanism
- **Prevention**:
  - Validate government signature on NFC passport/ID per ICAO 9303 standard
  - Public key infrastructure from governments (EF_SOD - Data Group Hash)
  - Offline verification (no reliance on external services)
- **Detection**: Invalid signature rejection + incident logging
- **Certificate Management**: Government certificates pinned in code, updates via consensus

#### T3: Biometric Hash Collision Attack
- **Threat**: Attacker finds collision in SHA-256 biometric hashes (mathematically near-impossible)
- **Impact**: Could duplicate identity in registry
- **Prevention**: SHA-256 used for registry; primary security is government ID verification
- **Fallback**: If collision detected, both accounts flagged for manual review

#### T4: Key Theft
- **Threat**: Attacker steals user's private key (via malware, phishing, device compromise)
- **Impact**: Can impersonate user, transfer assets, change identity claims
- **Prevention**:
  - Keys held locally only (never copied to server)
  - Browser-based key storage (encrypted by browser)
  - Optional hardware wallet integration (Ledger, Trezor)
- **Detection**: Duplicate signing activity, geographic anomalies
- **Recovery**: None (user responsible for key backup). Design recovery with community (not technical)

#### T5: Man-in-the-Middle (MITM) Attack
- **Threat**: Attacker intercepts network traffic to steal credentials or modify data
- **Impact**: Credential theft, registration hijacking, data modification
- **Prevention**:
  - TLS 1.3 everywhere (enforced, no downgrade)
  - Certificate pinning for identity verification endpoints
  - End-to-end encryption (TLS + AES-256-GCM)
- **Detection**: TLS handshake failure, certificate validation errors

#### T6: Underage Account Creation
- **Threat**: Child creates account on adult (TrustNet 20+) network or bypasses age segmentation
- **Impact**: Child safety violation, regulatory non-compliance
- **Prevention**:
  - Age from government ID (read during NFC verification)
  - Automatic network assignment (KidsNet 0-12, TeenNet 13-19, TrustNet 20+)
  - Cannot manually override due date (forced automatic transition)
- **Detection**: Age verification failure, automatic network rejection
- **Enforcement**: Blockchain enforces automatic transitions (no administrative override)

#### T7: Youth Network Unauthorized Access (Adult Impersonation)
- **Threat**: Adult pretends to be child to access youth networks (predatory behavior)
- **Impact**: Child safety violation, predatory access to protected communities
- **Prevention**:
  - Age from government ID (cryptographically verified)
  - Adult observers (90+ reputation, flagged as adults in UI)
  - Reputation-based (new accounts start at 0, must earn reputation to access sensitive functions)
  - Network-level access control (transactions rejected if sender age > network max_age)
- **Detection**: Age mismatch during ID verification, reputation anomalies, behavioral heuristics

#### T8: Reputation Manipulation
- **Threat**: Attacker artificially inflates reputation through sybils, fake transactions, or collusion
- **Impact**: Undeserving accounts gain access/privileges (especially youth moderators)
- **Prevention**:
  - Sybil prevention (one person = one identity, prevents fake accounts)
  - All reputation transactions immutable on blockchain
  - Moderator election requires geographic/network diversity (anti-collusion)
  - Reputation decay for inactive accounts
- **Detection**: Statistical analysis, sudden reputation spikes, geographic clustering

#### T9: Registration Database Compromise
- **Threat**: Attacker gains access to registration database (hacked servers, insider threat)
- **Impact**: Privacy violation, potential identity theft
- **Prevention**:
  - Minimal data stored: Only SHA-256(biometric), age, government ID signature timestamp
  - All PII encrypted at rest (AES-256-GCM)
  - Distributed registry (no single point of failure)
  - Immutable on blockchain (tamper-evident)
- **Detection**: Integrity checks, hash verification on retrieval
- **Incident Response**: Alert users, enable key rotation, provide identity monitoring

#### T10: Smart Contract Vulnerability
- **Threat**: Bug in Cosmos SDK modules allows unauthorized identity changes, reputation manipulation, or fund theft
- **Impact**: System-wide compromise
- **Prevention**:
  - Code audits by professional security firm before mainnet
  - Formal verification where possible (Coq, Lean for critical paths)
  - Gradual rollout (testnet → staged mainnet → full rollout)
  - Emergency pause mechanism (requires 75% validator consensus)
- **Detection**: Anomaly detection, transaction analysis, user reports
- **Recovery**: Rollback transactions if detected before finality

### Medium-Severity Threats (Should Mitigate)

#### T11: Phishing / Social Engineering
- **Threat**: Attacker tricks user into revealing recovery codes or clicking bad links
- **Impact**: Account compromise, credential theft
- **Prevention**:
  - User education (in-app warnings, guides)
  - Recovery codes encrypted (not plaintext)
  - Multi-factor authentication (birthdate + security question + backup code)
- **Detection**: Behavioral heuristics, user reports
- **Recovery**: Account recovery via multi-factor authentication

#### T12: Side-Channel Attack (Timing/Power Analysis)
- **Threat**: Attacker analyzes timing or power consumption to extract cryptographic keys
- **Impact**: Could potentially extract keys from hardware
- **Prevention**:
  - Use constant-time cryptographic libraries (libsodium, NaCl)
  - Hardware wallet integration for advanced users
  - No optimized-for-speed implementations with side channels
- **Detection**: Security audits, penetration testing
- **Cost**: Slightly slower cryptography (acceptable)

#### T13: Distributed Denial of Service (DDoS)
- **Threat**: Attacker floods network with traffic, rendering services unavailable
- **Impact**: Service unavailability (trust network unreachable)
- **Prevention**:
  - Proof-of-work rate limiting on registration (prevents free spam)
  - Network-level DDoS protection (Cloudflare, AWS Shield)
  - Distributed node infrastructure (reduces single point of failure)
- **Detection**: Traffic spike detection, anomaly monitoring
- **Recovery**: Automatic failover to backup infrastructure

### Low-Severity Threats (Monitor)

#### T14: Account Enumeration
- **Threat**: Attacker tries usernames/emails to determine if account exists
- **Impact**: Privacy leakage (user enumeration)
- **Prevention**:
  - Don't distinguish between "user not found" and "invalid password"
  - Return same response time for both (prevent timing attacks)
  - Rate limit login attempts
- **Detection**: Login attempt monitoring

#### T15: Information Disclosure (Error Messages)
- **Threat**: Error messages reveal system details (stack traces, SQL queries, config)
- **Impact**: Information leak aids attackers
- **Prevention**:
  - Generic error messages in production ("Something went wrong")
  - Detailed logs on server side (not exposed to client)
  - Exception handling review in security audit
- **Detection**: Code review, penetration testing

---

## Identity Verification Security

### NFC Government ID Verification

#### Process Overview
1. User scans government-issued NFC ID (passport, national ID card)
2. Extract biometric (fingerprint or facial features) + government signature
3. Validate government signature against public key (ICAO 9303 standard)
4. Hash biometric with salt (SHA-256) → registry lookup
5. If unique: Generate identity key → proceed  
   If duplicate: Reject registration → user appeal process

#### Security Requirements

**1. NFC Chip Authentication**
```
Input: NFC passport/ID
Process:
  - Read EF_SOD (Security Object Data Group) + government signature
  - Validate signature against government public key (pinned in code)
  - Verify integrity of biometric data
Output: Verified identity claim OR rejection
```

**Decision**: Use ICAO 9303 standard (international passport standard).
- **Rationale**: Governments already using this, cryptographic signatures validated by national authorities
- **Cost**: Requires ICAO 9303 library (libadlcp or equivalent)
- **Benefit**: Zero cost to users (only NFC reader needed), validates government signature offline

**2. Biometric Extraction**
```
Input: NFC passport/ID biometric data
Process:
  - Extract raw fingerprint or facial features (ICAO binary format)
  - Apply preprocessing (noise reduction, normalization)
  - Hash with salt: SHA-256(biometric || salt) → registry_hash
Output: Registry hash (stored), biometric (encrypted and deleted after hash)
```

**Decision**: Store only SHA-256 hash in registry (never raw biometric).
- **Rationale**: Privacy protection, GDPR compliance, cannot reverse-engineer biometric from hash
- **Tradeoff**: Cannot use for authentication later (one-way hash), creates new identity key instead
- **Implication**: Identity tied to government ID, not biometric match

**3. Salt Management**
```
Decision: Use per-user random salt (generated during registration)
  - Salt stored encrypted in user's local storage (browser)
  - Never transmitted to server
  - User can export salt for backup/recovery
  
Rationale:
  - Different salt = different hash even for same biometric
  - Prevents pre-computed rainbow table attacks
  - User controls salt (can recreate account if needed)
```

**4. Government Public Key Management**
```
Decision: Pin government certificates in code (hardcoded)
  - Initial set: Major countries' government signing keys
  - Updates via blockchain governance (validator voting)
  - Fallback: Manual update in app release
  
Rationale:
  - No external dependency on certificate authorities
  - Prevents MITM attacks on key distribution
  - Blockchain ensures all nodes have same keys
```

**5. Duplicate Detection**
```
Process:
  1. User registers → calculate registry_hash
  2. Query global biometric registry: "Does this hash exist?"
  3. If YES: Registration rejected + user notified
  4. If NO: Create new identity → proceed

Decision: Registry lookup must be cryptographically verified
  - Query signed by node (Tendermint consensus)
  - Response includes block height (can verify on chain)
  - Cannot forge "not found" response
```

---

## Registration Flow Security

### Complete Registration Sequence

```
PHASE 1: CLIENT-SIDE PREPARATION
├─ User scans government NFC ID
├─ Extract & hash biometric locally (never transmitted)
├─ Generate identity keypair (Web Crypto API)
├─ Create recovery codes (BIP39-like format)
├─ Encrypt recovery codes with passphrase
└─ Ready for registration

PHASE 2: REGISTRATION TRANSACTION
├─ Query: "Is biometric hash unique?" (global registry)
├─ If duplicate: REJECT + "Account already exists"
├─ If unique: Create registration transaction
│  └─ TX contents:
│     ├─ Biometric hash (SHA-256)
│     ├─ Age (from government ID)
│     ├─ Network assignment (KidsNet/TeenNet/TrustNet)
│     ├─ Government signature (ICAO 9303)
│     ├─ Public identity key
│     ├─ Timestamp
│     └─ Digital signature (signed with identity key)
├─ Sign transaction on client (Web Crypto API)
├─ Submit to blockchain network
└─ Wait for consensus

PHASE 3: BLOCKCHAIN VALIDATION
├─ Node receives registration transaction
├─ Validation:
│  ├─ Signature valid? (verify against public key in TX)
│  ├─ Government signature valid? (verify against pinned cert)
│  ├─ Age valid range? (0-150, sanity check)
│  ├─ Biometric unique? (query registry for hash)
│  ├─ Nonce fresh? (prevent replay attacks)
│  └─ Proof-of-work solved? (prevent spam)
├─ If valid: Accept → add to mempool → broadcast
├─ If invalid: Reject → respond with reason
└─ Consensus reaches finality (6 seconds)

PHASE 4: POST-REGISTRATION
├─ User receives confirmation
├─ Identity key stored locally (encrypted in browser)
├─ Backup codes displayed (user must save)
├─ Account ready to use
└─ Can begin earning reputation
```

### Security Decisions for Registration

**1. Proof-of-Work for Registration**
```
Decision: Require proof-of-work before accepting registration
  
Process:
  - Client must solve moderate PoW (adjust difficulty)
  - PoW difficulty: ~10-30 seconds on commodity hardware
  - Prevents free mass registration / spam
  - Attacker cost: Real computational resources
  
Tradeoff:
  + Spam prevention with economic cost
  - Slightly slower user registration experience
  
Implementation: Use Argon2 or scrypt (not SHA-256 PoW)
  - Reason: Memory-hard prevents GPU/ASIC optimization
```

**2. Time-Lock for Biometric Registration**
```
Decision: Require minimum time between registration attempts
  
Process:
  - After failed registration: Lock account for 5 minutes
  - After 3 failed attempts: Lock for 1 hour
  - Prevents brute-force biometric matching
  
Rationale:
  - Government ID may have issues (damaged chip, wrong format)
  - Time-lock prevents spamming
  - Gives user time to troubleshoot
```

**3. Multi-Factor Registration Confirmation**
```
Decision: Require second factor at registration (not just biometric)
  
Process:
  - Factor 1: Government ID biometric (NFC)
  - Factor 2: User passphrase (something user knows)
  - Factor 3: Recovery code backup acknowledgment
  
Rationale:
  - Biometric alone could be compromised (NFC chip forgery)
  - Passphrase ensures user agency
  - Recovery codes as third factor
```

**4. Recovery Code Generation & Storage**
```
Decision: BIP39-like recovery codes (12-word mnemonic)
  
Process:
  1. Generate 12 random words (256 bits entropy)
  2. Display during registration
  3. User must transcribe (confirmed)
  4. Encrypt with passphrase → store locally
  5. Never transmitted to server
  
Encryption:
  - AES-256-GCM with PBKDF2-derived key
  - Passphrase: Min 8 chars, complexity required
  - Salt: Random, included in encrypted payload
  
Recovery Flow:
  - User lost private key? Ask for recovery codes
  - Validate codes → re-derive original key
  - Or: Create new key with same biometric (identity reset)
```

**5. Identity Key Generation**
```
Decision: EdDSA (Ed25519) for signing, X25519 for encryption
  
Process:
  - Generate keypair locally (Web Crypto API)
  - Private key: Stored encrypted in browser storage
  - Public key: Published in registration TX
  
Tradeoff:
  + EdDSA faster, smaller signatures, simpler security
  - Less flexible than RSA
  
No RSA: Reason: 2048-bit RSA = slower, larger, less security/byte
```

**6. Age Verification Immutability**
```
Decision: Age set at registration (cannot be changed manually)
  
Process:
  - Age extracted from government ID during registration
  - Stored in identity record (blockchain)
  - Network assignment automatic (age → network)
  - Transitions automatic on birthday (smart contract)
  
Rationale:
  - Prevents age fraud (adult claiming to be child)
  - Prevents manual override (no admin bypass)
  - Birthday enforcement via time-lock smart contracts
  
Technical: Smart contract checks block timestamp >= birthday → auto-transition
```

---

## Biometric Registry Security

### Global Biometric Registry Design

#### Purpose
Prevent Sybil attacks by enforcing "one person = one identity" globally across all TrustNet segments.

#### Data Structure
```
Registry Entry:
{
  biometric_hash: SHA-256(fingerprint || salt),  // Identifies unique person
  age: 25,                                        // User's age
  network: "TrustNet",                           // Assigned network (KidsNet/TeenNet/TrustNet)
  identity_key: "Ed25519PublicKey",              // Public signing key
  created_at: 1709964000,                        // Registration timestamp (block height)
  government_verified: true,                     // ICAO signature valid
  registration_segment: "trustnet-uk.com"        // Which segment they registered on
}
```

#### Security Properties

**1. Immutability**
- Registry stored on blockchain (Tendermint consensus)
- Once added: Cannot be deleted or modified
- Tamper evidence: Any change detected immediately
- Historical record: All changes auditable

**2. Privacy**
- Only stores hash (not biometric)
- Age stored (required for network assignment)
- Cannot reverse-engineer biometric from hash
- User can verify their own entry (knows their biometric)

**3. Accessibility**
- Public read: Anyone can check "is this hash registered?"
- No authentication required for lookups
- Encourages external audits
- Prevents collusion (transparent)

**4. Distributed**
- Every node has full registry copy
- No single point of failure
- Network resilience improves with more nodes
- Prevents registry censorship

#### Duplicate Detection Protocol

```
REGISTRATION ATTEMPT
├─ User submits: biometric_hash
├─ Query: registry.contains(biometric_hash)?
├─ Network broadcasts query → all nodes
├─ Nodes respond with: FOUND / NOT_FOUND (Tendermint consensus)
├─ If FOUND:
│  ├─ Respond with: existing_entry details
│  ├─ User receives: "Account already exists"
│  ├─ Option: Account recovery (if knows recovery codes)
│  └─ REJECT registration
├─ If NOT_FOUND:
│  ├─ Continue registration
│  ├─ Add new entry to PENDING pool
│  ├─ Wait for consensus (~6 seconds)
│  └─ CONFIRM registration
└─ RESPONSE sent to user
```

#### Handling Collisions (Near-Impossible)

If SHA-256 collision detected (mathematically near-impossible):
```
Response: Both accounts flagged for MANUAL REVIEW
├─ Alert: "Collision detected"
├─ Action: Human investigator reviews
├─ Options:
│  ├─ Verify with government ID directly
│  ├─ Phone interview to confirm identity
│  ├─ Grant access to legitimate user
│  └─ Reject fraudulent account
└─ Result: One account confirmed, one rejected
```

#### Cross-Segment Verification

TrustNet segments all share global biometric registry:
```
Segment A registers user → hash added to global registry
Segment B attempts same user → lookup finds duplicate → REJECT

This prevents:
✓ Same person creating accounts on multiple segments
✓ Sybil attacks across segment boundaries
✓ Reputation manipulation through multi-segment accounts
```

---

## Key Management

### Identity Key Lifecycle

#### Generation (Registration)
```
1. User device generates keypair (Web Crypto API)
   - Algorithm: EdDSA (Ed25519)
   - Entropy: 256 bits cryptographic random
   - Isolated: Cannot export keys from generation process

2. Private key stored locally:
   - Encrypted: AES-256-GCM
   - Key derivation: PBKDF2(passphrase, salt, iterations=100k)
   - Salt: 16 bytes random
   - Storage: Browser IndexedDB (encrypted)

3. Public key published:
   - Sent to blockchain (registration TX)
   - Immutable after registration
   - Cannot be changed (prevents key reset attacks)
```

#### Key Derivation
```
masterKey = Ed25519.generateKeys()
publicKey = masterKey.publicKey
privateKey = masterKey.privateKey

encryption_key = PBKDF2(
  password=user_passphrase,
  salt=random_16_bytes,
  iterations=100000,
  hash_algorithm="SHA-256"
)

encrypted_privateKey = AES-256-GCM(
  plaintext=privateKey,
  key=encryption_key,
  iv=random_12_bytes,
  aad=user_public_key  // Additional authenticated data
)

storage = {
  encrypted_key: encrypted_privateKey,
  salt: salt,
  iv: iv,
  iterations: 100000,
  algorithm: "AES-256-GCM"
}
```

#### Usage (Signing Transactions)
```
1. User wishes to sign transaction:
   - Send passphrase to browser (not to server)
   - Browser derives encryption_key (PBKDF2)
   - Decrypt private key (AES-256-GCM)
   - Sign transaction with private key
   - Clear private key from memory
   - Send signed transaction to blockchain

2. Blockchain validates:
   - Verify signature against public key
   - Accept if valid
```

#### Key Loss / Recovery

**Scenario: User has forgotten passphrase**
```
Recovery Process:
1. User provides recovery codes (BIP39 mnemonic)
2. Verify recovery codes (stored encrypted locally)
3. Option:
   - Generate new private key tied to same identity?
     NO - Never do this (breaks non-repudiation)
     
   - Create new identity with new biometric scan?
     MAYBE - Only with government ID re-verification
     
   - Access account locked?
     YES - User must prove identity (phone call, in-person)
```

**Scenario: Device lost**
```
Recovery Process:
1. User accesses TrustNet from new device
2. System detects: "New device, unknown location"
3. Challenge:
   - Provide recovery codes (12-word mnemonic)
   - Provide passphrase (decrypt codes locally)
   - Verify government ID (NFC scan again)
4. If verified: Move account to new device
5. If insufficient: User appeal to community moderators
```

**Scenario: Compromised Device (Malware)**
```
Prevention:
- Keys never leave device (cannot steal without physical access)
- Passphrase required for every signing (cannot batch-sign)

Detection:
- Monitor for: Unusual signing pattern, new locations, high activity
- Alert user: "Signing activity detected from unknown location"

Recovery:
- User: Move to new device
- Old device: Revoke keys? (Not possible - keys immutable on chain)
- Mitigation: Community can ban account (reputation vote)
- This is a loss - Design UX to warn about backups
```

### Hardware Wallet Integration (Optional)

For advanced users wanting maximum security:
```
Supported: Ledger Nano, Trezor, etc.
Process:
1. User connects hardware wallet
2. Hardware generates & holds keypair (never leaves device)
3. For signing: Send TX to hardware wallet → user approves → hardware signs → return signature
4. Browser submits signed TX to blockchain

Benefit:
+ Private key never touches computer (immune to malware)
+ Hardware validates transaction details before signing
- Requires additional hardware purchase
- Requires USB connection or wireless
```

---

## Data Encryption

### Encryption Standards

**In Transit (TLS)**
```
Standard: TLS 1.3 (minimum)
Configuration:
  ✓ 256-bit symmetric encryption (ChaCha20-Poly1305 or AES-256-GCM)
  ✓ 384-bit elliptic curve keys (P-384 / secp384r1)
  ✓ FORWARD SECRECY: DH ephemeral keys (PFS)
  ✓ Certificate pinning: Pin CA certs for identity services
  ✓ HSTS: Strict-Transport-Security header
  ✗ TLS 1.2 or lower: Not allowed (too old)
  ✗ NULL encryption: Not allowed

Certificate Validation:
  - Hostname verification (prevent MITM)
  - Certificate chain validation
  - Revocation checking (OCSP stapling)
  - Public pinning for critical services
```

**At Rest (Database/Storage)**
```
Standard: AES-256-GCM (Galois/Counter Mode)
Configuration:
  ✓ 256-bit keys (32 bytes)
  ✓ 96-bit IV (12 bytes, random each encryption)
  ✓ Authenticated encryption (GCM provides auth)
  ✓ No "ECB mode" (insecure)
  ✓ No "CBC mode without MAC" (authentication bypass)

Key Management:
  - Keys stored in HSM (Hardware Security Module) if available
  - Fallback: Encrypted keyfile + strong passphrase
  - Rotate keys annually
  - Generate unique IV per encryption (never reuse with same key)

Data Classification:
  Encrypt:
    ✓ Private keys
    ✓ Recovery codes
    ✓ Government ID data (even though already hashed)
    ✓ User passphrases
    ✓ Personal information (profile data)
    
  Hash Only (SHA-256):
    ✓ Biometric data (one-way, cannot reverse)
    ✓ Email addresses (verified but not modified)
    ✓ Account identifiers
    
  No Encryption:
    ✓ Public blockchain data (immutable anyway)
    ✓ Public keys
    ✓ Reputation scores
    ✓ Timestamps
```

### Hashing Standards

**Biometric Registry**
```
Standard: SHA-256
Function: SHA-256(biometric_data || salt)

Why SHA-256:
  ✓ Cryptographically secure (no known preimage attack)
  ✓ Output: 256 bits (collision-resistant)
  ✓ Standard: NIST approved
  ✓ Wide support (available in all languages)

Why One-Way:
  ✓ Biometric cannot be recovered from hash
  ✓ Prevents misuse if database compromised
  ✓ GDPR compliant (reduced PII retention)

Salt Usage:
  ✓ Random 16+ bytes per user
  ✓ Different salt = different hash (prevents rainbow tables)
  ✓ User controls salt (backed up locally)
```

**Password Hashing (Passphrase)**
```
Standard: PBKDF2 (or Argon2 if available)
Configuration:
  Algorithm: PBKDF2
  Hash Function: SHA-256
  Iterations: 100,000 (minimum, increase over time)
  Salt: 16+ bytes random
  Output: 256 bits

Rationale:
  ✓ OWASP/NIST recommended
  ✓ Slows down brute force (100k iterations = ~100ms per attempt)
  ✓ Resistant to GPU acceleration
  ✓ Well-tested (standard algorithm)

Alternative: Argon2
  ✓ Memory-hard (prevents GPU/ASIC optimization)
  ✓ Newer, slightly better resistance
  ✗ Less library support
```

---

## Network Security

### Transport Layer

**Configuration**
```
Protocol: TLS 1.3 only (no downgrades)
Cipher Suites (preferred order):
  1. TLS_CHACHA20_POLY1305_SHA256
  2. TLS_AES_256_GCM_SHA384
  3. (No others allowed)

Certificate Validation:
  ✓ HSTS (Strict-Transport-Security)
    - max-age=31536000 (1 year)
    - includeSubDomains
    - preload (domain submitted to HSTS preload list)
  
  ✓ Certificate Pinning (for identity endpoints)
    - Pin issuing CA certificate
    - Pin leaf certificate
    - Backup pin (secondary cert for rollover)
  
  ✓ Must-Staple
    - OCSP stapling required
    - Prevents certificate revocation bypass
```

**API Endpoints**
```
All endpoints protected:
  ✓ POST /api/register - TLS 1.3 + rate limiting
  ✓ POST /api/sign-transaction - TLS 1.3 + authentication
  ✓ GET /api/registry-lookup - TLS 1.3 (no auth needed)
  ✓ GET /api/identity/:id - TLS 1.3 + authentication
  
  ✗ No HTTP (always HTTPS)
  ✗ No mixed content (no HTTP resources)
```

### API Security

**Rate Limiting**
```
Endpoint: /api/register
  - Limit: 1 registration per hour per IP
  - Limit: 1 registration per hour per potential user (before registration)
  - Requires proof-of-work submission
  - Increases delay on repeated attempts

Endpoint: /api/registry-lookup
  - Limit: 100 lookups per minute per IP
  - Reason: Public endpoint (high load expected)
  - No authentication required

Endpoint: /api/sign-transaction
  - Limit: 10 signatures per minute per authenticated user
  - Reason: User-specific rate limiting
  - Prevents spam/DoS from compromised account
```

**Authentication**
```
Method: JWT (JSON Web Token) signed with Ed25519

Token Structure:
{
  header: {
    alg: "EdDSA",
    typ: "JWT"
  },
  payload: {
    sub: "user_public_key",           // Subject (user's identity key)
    iat: 1709964000,                  // Issued at
    exp: 1709964900,                  // Expires (15 minutes)
    nonce: "random_unique_value",     // Prevent replay
    device_fingerprint: "hash"         // Detect device changes
  },
  signature: "Ed25519_signature(...)" 
}

Lifetime: 15 minutes (short-lived)
Refresh: Must re-authenticate (sign challenge)
No Automatic Refresh: Forces user to stay engaged

Why Not OAuth2:
  ✗ Requires external provider (centralization)
  ✗ Complex spec (attack surface)
  
Why JWT:
  ✓ Self-contained (verifiable without server state)
  ✓ Cryptographically signed
  ✓ Standard (widely supported)
```

**Device Fingerprinting** (Secondary)
```
Not Primary Auth (too unstable), but Secondary Detection

Fingerprint Includes:
  - Browser User Agent
  - Screen resolution
  - Timezone
  - Language preferences
  - WebGL Info
  - Canvas fingerprinting (controversial but optional)
  
Use Case:
  - User location changes dramatically → flag for review
  - Multiple devices → warn user or require re-auth
  - Device becomes dormant → expire session
  
NOT Used For:
  ✗ Tracking (privacy violation)
  ✗ Fingerprinting users across sites
  ✗ Identifying users without consent
  
User Control:
  ✓ User can see list of devices
  ✓ User can revoke device access
  ✓ User can set "trusted device" flag
```

---

## Age Segmentation Security

### Automatic Network Assignment

**Process**
```
Registration:
  1. User scans government ID (NFC)
  2. Extract date_of_birth from ID
  3. Calculate age: current_year - birth_year
  4. Assign network based on age:
     - Age 0-12: KidsNet
     - Age 13-19: TeenNet
     - Age 20+: TrustNet
  5. Store in registration TX (immutable)

Blockchain Enforcement:
  - Smart contract validates age in registration TX
  - If invalid age → reject registration
  - If valid → store on chain
```

**Birthday Transitions** (Automatic)
```
Smart Contract Timer:
  - Birthday stored: birth_date (timestamp)
  - Network transitions on birthday (automatic)
  - No admin override possible
  
Example:
  User born: 2010-03-11
  At 2022-03-11 (age 12 → 13): Auto-transition KidsNet → TeenNet
  At 2030-03-11 (age 19 → 20): Auto-transition TeenNet → TrustNet
  
Technical Implementation:
  - Smart contract: If (block_timestamp >= user.next_birthday) → update_network()
  - Triggered on first transaction after birthday
  - Or: Background job queries for users with upcoming birthdays
```

**Age Fraud Prevention**
```
1. Birth Date Immutability
   - Cannot change age after registration
   - Setting wrong age = fraud (cannot fix)
   - Incentivizes honest registration
   
2. Government Verification
   - Age comes from government ID (not user input)
   - Cannot fake government ID (signature validation)
   - Border security already validates IDs

3. Cross-Segment Verification
   - If registered as age 25 on Segment A
   - Cannot register as age 15 on Segment B
   - Global biometric registry prevents re-registration

4. Moderator Appeals
   - If birthday documented wrong (e.g., typo)
   - Youth moderators + adults can vote to correct
   - Requires 75% consensus (prevents manipulation)
```

---

## Youth Protection Mechanisms

### Access Control by Age

**Network Tiers**
```
KidsNet (0-12 years)
├─ Moderators: Elected from ages 10-12 (voted by peers)
├─ Adult Observers: 90+ reputation, no children in account
├─ Features: Limited messaging, monitored groups, safe games
├─ Access: Only ages 0-12 (auto-enforced at TX validation)
└─ Protection: Heavy moderation, content filtering, no external links

TeenNet (13-19 years)
├─ Moderators: Elected from ages 16-19 (voted by peers)
├─ Adult Observers: 90+ reputation, no children in account
├─ Features: Social messaging, school groups, age-appropriate content
├─ Access: Only ages 13-19 (auto-enforced at TX validation)
└─ Protection: Peer moderation, opt-in content filtering, counseling access

TrustNet (20+ years)
├─ Moderators: Elected from adult community
├─ Adult Observers: Not needed
├─ Features: Full features, professional networks, market access
├─ Access: Only ages 20+ (auto-enforced at TX validation)
└─ Protection: Community voting, reputation-based access
```

**Enforced at Blockchain Level**
```
Transaction Validation:
  ├─ Check: Sender age > network.max_age?
  │  Yes → REJECT transaction
  │  No → Accept
  │
  └─ Check: Sender age < network.min_age?
     Yes → REJECT transaction
     No → Accept

This prevents:
  ✓ Child accessing adult network (age < 20 cannot post on TrustNet)
  ✓ Adult masquerading as child (age >= 13 cannot post on KidsNet)
  ✓ Invalid transitions (automatic on birthday, no manual override)
```

### Moderator Election (Youth Networks)

**KidsNet Governance (Ages 10-12)**
```
Moderator Role: Elected by peer vote every 3 months
Requirements:
  - Must be ages 10-12
  - Must have reputation > 10 (community tested, trustworthy)
  - Commitment: Moderate 1-2 hours/week

Election Process:
  1. Nomination: Any KidsNet member nominates candidate
  2. Verification: Candidate confirms willingness
  3. Voting: All KidsNet members vote (1 vote each)
  4. Selection: Top candidates (by vote count) become moderators
  5. Term: 3 months, then re-election

Limitations:
  - Cannot ban users (only escalate to adults)
  - Cannot modify user profiles
  - Cannot access private messages (privacy)
  - Can flag content as inappropriate
  - Can temporarily mute user (24 hours)

Adult Advisor:
  - Assigned adult (90+ reputation, no children)
  - Reviews moderator decisions
  - Mentors young moderators
  - Only intervenes if abuse detected
  - Builds leadership skills in children
```

**TeenNet Governance (Ages 16-19)**
```
Moderator Role: Similar to KidsNet, more authority
Differences:
  - Age: 16-19 years
  - Reputation threshold: 20 (higher trust needed)
  - Authority: Can temporarily suspend accounts (48 hours)
  - Scope: Moderation over larger communities
  - Mentorship: Adult advisor optional (less needed)
  
Benefits:
  - Teens learn governance through real responsibility
  - Peer trust more authentic than adult authority
  - Prepares for adult leadership roles
```

### Adult Observer System

**Role & Limitations**
```
Adult Observer: High-reputation (90+) adult assigned to youth networks

Responsibilities:
  ✓ Mentoring young moderators
  ✓ Reviewing escalated situations
  ✓ Providing professional guidance
  ✓ Emergency intervention (safety threats)
  
Limitations:
  ✗ Cannot read private messages (except safety investigation)
  ✗ Cannot see profiles without permission
  ✗ Cannot vote on moderators
  ✗ Cannot make unilateral decisions (must consult moderators)
  ✗ No "veto" power (consensus-based)
  
Safety Intervention (Only):
  - If child reports: "Contact me outside"
  - If child reports: "Abuse or harassment"
  - If threats detected: "Self-harm indicators"
  - Process: Document, inform parents, involve counselors

Transparency:
  - All actions logged
  - Available for audit
  - Community can vote to remove noncompliant observer
```

### Professional Support Network

**Credentials & Verification**
```
Types of Professionals:
  1. Counselors (licensed, background-checked)
  2. Legal Advisors (bar certified)
  3. Educators (verified credentials)
  4. Law Enforcement (authorized, protocols)

Verification Process:
  - Government-issued credential (license, certification)
  - Background check (no history of abuse/fraud)
  - Community voting (75% approval required)
  - Right to appeal rejection
  - Annual re-verification

Profile Visibility:
  - Credentials displayed (license type, issuer, date)
  - Service area (e.g., "UK Mental Health")
  - Availability (hours of operation)
  - Specialization (e.g., "Teen Counseling")
```

**Service Provision**
```
In Youth Networks (KidsNet/TeenNet):
  - Voluntary (not charged)
  - Young people initiate contact
  - Professional provides guidance
  - Parents notified (unless safety risk)
  - No enforcement of advice

In TrustNet (Adult Network):
  - Can charge fees
  - Professional business model
  - Reputation affects pricing
  - Verified credentials visible

Boundaries:
  ✓ Therapeutic support (guidance)
  ✗ Therapy (requires proper licensure & location)
  ✓ Legal education (general info)
  ✗ Legal representation (requires attorney licensing)
  ✗ Medical treatment (requires physician licensing)
```

---

## Audit & Compliance

### Logging & Audit Trail

**What Gets Logged**
```
Event Logging:
  ✓ Registration attempt (success/failure, reason)
  ✓ ID verification (result, government signature status)
  ✓ Transaction signing (user, timestamp, TX hash)
  ✓ Authentication (login attempt, success/failure)
  ✓ Access control (permission check, allow/deny)
  ✓ Data access (user viewed profile, accessed data)
  ✓ Administrative actions (moderator actions, appeals)
  ✓ Security events (failed signatures, anomalies)

What NOT Logged:
  ✗ Raw biometric data
  ✗ Private keys
  ✗ Passphrases
  ✗ Recovery codes
  ✗ Personal identifiable information (PII)

Log Retention:
  - Immutable logs (write-once, read-many)
  - Retain 7 years (most compliance requirements)
  - Encrypted at rest (AES-256-GCM)
  - Distributed (multiple nodes, no single point of failure)
```

**Log Protection**
```
Requirements:
  1. Tamper-evident (detect unauthorized changes)
     - Hash-linked log entries (each entry hashes previous)
     - Blockchain storage (immutable)
     - Cryptographic signatures
  
  2. Access control
     - Only audit team can read logs
     - All log access logged (recursive audit trail)
     - Encryption in transit (TLS 1.3)
  
  3. Regular verification
     - Weekly audit (check for tampering)
     - Monthly reports (compliance verification)
     - Annual deep audit (external firm)
```

### Compliance Standards

**GDPR (EU, UK, Similar)**
```
Requirements Addressed:
  ✓ Lawful basis: Identity verification (regulatory requirement)
  ✓ Consent: Explicit at registration ("Do you agree to this privacy policy")
  ✓ Purpose limitation: Only use data for account identity
  ✓ Data minimization: Store only necessary data (biometric hash, age, ID signature)
  ✓ Accuracy: Allow users to request data correction (appeal process)
  ✓ Storage limitation: Delete after account deletion
  ✓ Integrity & confidentiality: Encryption, access control
  ✓ DPIA: Data Protection Impact Assessment filed
  ✓ Right to erasure: Users can request account deletion (data removed except logs)
  ✓ Data portability: Export data in standard format
  ✓ Breach notification: Notify users within 72 hours of discovery
  ✓ DPO: Designate Data Protection Officer

Tradeoff:
  - Cannot store biometric (only hash)
  - No behavioral tracking
  - No third-party data sharing
```

**Child Protection Laws**
```
COPPA (Children's Online Privacy Protection Act - USA):
  ✓ Compliant (KidsNet designed for ages 0-12)
  ✓ Parental consent (required for under 13, via email verification)
  ✓ Limited data collection (age, identity only)
  ✓ Opt-in to marketing (default no)

UK Online Safety Bill:
  ✓ Compliant (age verification prevents children on wrong network)
  ✓ Duty of care (moderators, observers, professional support)
  ✓ Transparency (publish moderation decisions)
  ✓ Appeals (users can appeal moderation)

Australia eSafety Commissioner:
  ✓ Compliant (age verification, content reporting)
  ✓ Removal process (remove harmful content within timeframe)
```

**Financial Regulations (Crypto)**
```
Approach: Clarify regulatory treatment upfront

AML/KYC (Anti-Money Laundering / Know Your Customer):
  - Government ID verification (natural KYC step)
  - Identity tied to NFC verification
  - Transaction monitoring (suspicious patterns detected)
  - Reporting (file SARs [Suspicious Activity Reports] for violations)

Securities Regulations (If TrustCoin classified as security):
  - Determine: Is TRUST a security or commodity?
  - If commodity: Minimal compliance
  - If security: Full SEC/FCA compliance required
  - Initial assessment: Likely commodity (utility token, no investment contract)

Monitoring:
  - Transaction surveillance (network analysis)
  - AML scoring (risk categorization per user)
  - Sanctions screening (OFAC, EU, UN lists)
  - Transaction limits (anti-structuring: prevent $9,999 deposits)
```

---

## Security Decision Log

### Decision Format

```
DECISION: [Number]
TITLE: [Short title]
DATE: [Date made]
STATUS: [Active / Proposed / Rejected / Superseded]
PRIORITY: [Critical / High / Medium / Low]

BACKGROUND:
[Context and reasons for considering this decision]

OPTIONS CONSIDERED:
1. [Option A with pros/cons]
2. [Option B with pros/cons]
3. [Option C with pros/cons]

DECISION:
[Which option selected and why]

RATIONALE:
[Detailed reasoning]

IMPLICATIONS:
[Impact on architecture, performance, user experience]

SECURITY IMPACT:
[Security benefits and tradeoffs]

REVIEW DATE:
[When to re-evaluate]

OWNER:
[Responsible person/team]
```

### Recorded Decisions

#### DECISION-001: EdDSA for Identity Key Signatures
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: Critical
- **DECISION**: Use EdDSA (Ed25519) for all identity key operations
- **RATIONALE**: 
  - Faster than RSA, smaller signatures (32 bytes vs 256+ bytes)
  - Simpler security properties, harder to use wrong
  - Sufficient for 256-bit security level
- **SECURITY IMPACT**: Strong, modern algorithm; reduced attack surface vs RSA

#### DECISION-002: SHA-256 for Biometric Registry
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: Critical
- **DECISION**: Use SHA-256 (one-way hash) for biometric registry, never store raw biometric
- **RATIONALE**:
  - Cryptographically secure (no known preimage attack)
  - Prevents recovery of biometric if database compromised
  - GDPR compliant (reduced PII retention)
- **SECURITY IMPACT**: Excellent privacy; prevents misuse if compromised
- **TRADEOFF**: Cannot use biometric for later authentication (user generates new key at registration)

#### DECISION-003: NFC Government ID Verification
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: Critical
- **DECISION**: Use NFC-based government ID reading with ICAO 9303 signature validation
- **RATIONALE**:
  - Government already validates identity (delegated trust)
  - Zero cost to users (just NFC reader)
  - Cryptographic signature prevents forgery
  - Offline verification (no external service dependency)
- **SECURITY IMPACT**: Strong identity assurance; government backing
- **IMPLEMENTATION**: Library required (libadlcp or equivalent)

#### DECISION-004: No Private Key Recovery (By Design)
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: Critical
- **DECISION**: If user loses private key, cannot recover account (by design)
- **RATIONALE**:
  - If server could recover keys = server could impersonate users
  - Users responsible for backup (recovery codes)
  - This is a security feature, not a bug
- **USER IMPACT**: Forces users to back up recovery codes
- **MITIGATION**: Design UX to emphasize backup importance
- **APPEAL PROCESS**: Users can appeal to community if needed

#### DECISION-005: Immutable Age at Registration
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: High
- **DECISION**: Age set at registration (from government ID), cannot be manually changed
- **RATIONALE**:
  - Prevents adult impersonating child (safety)
  - Prevents child lying about age (fraud)
  - Automatic transitions on birthday (no admin override)
- **SECURITY IMPACT**: Strong age fraud prevention
- **ACCESSIBILITY**: Appeals process for data entry errors (moderator vote)

#### DECISION-006: TLS 1.3 Mandatory
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: High
- **DECISION**: All connections must use TLS 1.3 minimum (no downgrades)
- **RATIONALE**:
  - TLS 1.2 has known weaknesses (POODLE, etc.)
  - TLS 1.3 faster & simpler than 1.2
  - No legitimate reason for older TLS versions
- **PERFORMANCE IMPACT**: Positive (1.3 faster than 1.2)
- **COMPATIBILITY**: All modern browsers/clients support 1.3

#### DECISION-007: Proof-of-Work for Registration
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: High
- **DECISION**: Require moderate proof-of-work (10-30 seconds) for registration
- **RATIONALE**:
  - Prevents spam/mass registration
  - Computational cost deters attackers
  - User experiences slight delay (acceptable)
- **UX IMPACT**: ~20 second delay during registration (acceptable, one-time)
- **SPAM PREVENTION**: Significantly raises cost for mass attacks

#### DECISION-008: No Shared Passphrases (Authentication)
- **DATE**: March 11, 2026
- **STATUS**: Active
- **PRIORITY**: High
- **DECISION**: Each user has unique government ID (no shared identity), cannot have "backup" account
- **RATIONALE**:
  - "Backup account" = duplicate identity = Sybil attack vector
  - Enforces "one person = one identity" principle
  - Globally verified via biometric registry
- **SECURITY IMPACT**: Prevents Sybil attacks
- **USER IMPACT**: Must choose account carefully (affects reputation portability)

---

## Implementation Priority

### Phase 1 (Foundation) - Months 1-2
1. ✓ NFC government ID verification (ICAO 9303)
2. ✓ EdDSA key generation & storage
3. ✓ SHA-256 biometric registry
4. ✓ Age extraction & enforcement
5. ✓ TLS 1.3 endpoint security

### Phase 2 (Protection) - Months 3-4
1. Biometric duplicate detection
2. Registration proof-of-work
3. Identity immutability enforcement
4. Birthday transition smart contract

### Phase 3 (Youth Protection) - Months 5-6
1. Age segmentation networks
2. Moderator election system
3. Adult observer framework
4. Professional support integration

### Phase 4 (Compliance) - Months 7+
1. GDPR compliance verification
2. AML/KYC monitoring
3. Audit trail implementation
4. Third-party security audit

---

## Review & Updates

**Document Version**: 1.0  
**Last Updated**: March 11, 2026  
**Next Review**: April 11, 2026  
**Owner**: Security Architecture Team

**Change Log**:
- v1.0 (March 11): Initial comprehensive security architecture

---

**This document MUST be updated weekly as decisions are made during implementation.**


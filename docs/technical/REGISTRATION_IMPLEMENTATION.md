# TrustNet Registration Implementation Design

**Date Created:** March 11, 2026  
**Version:** 1.0  
**Status:** Design Phase - Ready for Implementation  
**Related Document**: SECURITY_ARCHITECTURE.md (Read first!)

---

## Overview

This document specifies the **registration functionality** for TrustNet, implementing the security decisions documented in SECURITY_ARCHITECTURE.md. 

**Principle**: Every decision references the security architecture—no security assumptions without documented justification.

---

## Registration Flow (High Level)

```
USER PERSPECTIVE:

1. "Start Registration" (Website or App)
   ↓
2. "Scan Government ID (NFC)"
   ↓
3. "Create Passphrase" (for key encryption)
   ↓
4. "Save Recovery Codes" (user must back up)
   ↓
5. "Solve Proof-of-Work" (prevents spam)
   ↓
6. "Confirm" (submit to blockchain)
   ↓
7. "Account Created!" (wait 6 seconds for consensus)
```

---

## Phase 1: Client-Side Preparation

### 1.1 NFC ID Scanning

**Component**: NFCReader.tsx

```typescript
interface NFCScanResult {
  // Government ID data (extracted from NFC)
  document_number: string;        // Passport/ID number
  country_code: string;           // Issuing country (C in ICAO)
  date_of_birth: Date;            // User's birth date
  full_name: string;              // Name on ID
  gender: 'M' | 'F' | 'X';        // From government data
  expiry_date: Date;              // ID expiration
  
  // Biometric (raw, will be hashed)
  biometric_data: ArrayBuffer;    // Fingerprint or facial features (ICAO format)
  biometric_type: 'fingerprint' | 'facial'; // Type of biometric
  
  // Cryptographic proof (government signature)
  government_signature: ArrayBuffer;  // EF_SOD signature
  hash_algorithm: string;             // Algorithm used (SHA-256, etc)
  
  // For validation
  raw_nfc_payload: ArrayBuffer;   // Full NFC read (for debugging)
}

async function scanGovernmentID(): Promise<NFCScanResult> {
  // 1. Request NFC reader access
  const nfc = new NDEFReader();
  
  // 2. Scan NFC chip
  const { records } = await nfc.scan();
  
  // 3. Parse ICAO 9303 format
  const parsedData = parseICAO9303(records);
  
  // 4. Extract biometric & signature from EF_SOD
  const sod = extractSecurityObject(parsedData);
  
  // 5. Validate signature (see below)
  const signatureValid = await validateGovernmentSignature(sod);
  
  if (!signatureValid) {
    throw new Error('Invalid government signature - ID may be forged');
  }
  
  return parsedData;
}
```

**Validation: Government Signature**

```typescript
// Government public keys (pinned in code)
const GOVERNMENT_CERTIFICATES = {
  'US': {
    issuer: 'US State Department CSCA',
    public_key: 'MFwwDQYJKoZIhvcNAQEBBQADSw...',
    fingerprint: 'A1:B2:C3:D4:E5...',
    expires: '2027-12-31'
  },
  'GB': {
    issuer: 'UK HMPO PKD',
    public_key: 'MIGfMA0GCSqGSIb3DQEBAQUAA4Gn...',
    fingerprint: 'F1:E2:D3:C4:B5...',
    expires: '2027-06-30'
  },
  // ... more countries
};

async function validateGovernmentSignature(
  sod: SecurityObjectData
): Promise<boolean> {
  // 1. Get country code from ID
  const country = sod.country_code; // e.g., "US"
  
  // 2. Look up government's public key (pinned)
  const govCert = GOVERNMENT_CERTIFICATES[country];
  if (!govCert) {
    throw new Error(`Unsupported country: ${country}`);
  }
  
  // 3. Verify signature on EF_SOD
  try {
    const isValid = await window.crypto.subtle.verify(
      'RSASSA-PKCS1-v1_5',
      govCert.public_key,
      sod.signature,
      sod.signed_data_to_verify
    );
    return isValid;
  } catch (e) {
    console.error('Signature validation failed:', e);
    return false;
  }
}

// Update government certificates via blockchain governance
async function updateGovernmentCertificates(
  update: GovernmentCertificateUpdate
) {
  // Process: Validators vote to approve certificate update
  // Once 66%+ validators approve, broadcast new certs to all clients
  // Clients cannot downgrade certs (security)
  const validated = await fetch('/api/verify-certificate-update', {
    method: 'POST',
    body: JSON.stringify({
      update,
      block_height: currentBlockHeight,
      validator_signatures: [...], // Validators who approved
    })
  });
  
  if (validated.ok) {
    // Save to local storage (encrypted)
    await encryptedStorage.set('government-certs', update.new_certs);
  }
}
```

**Security Decision**: Why ICAO 9303?
- ✓ International standard (used by 195+ countries)
- ✓ Government validates signature (delegated trust)
- ✓ Cryptographically signed (forgery-resistant)
- ✓ Offline verification (no external service)
- See: SECURITY_ARCHITECTURE.md - "Government ID Verification"

---

### 1.2 Biometric Hashing

**Component**: BiometricProcessor.ts

```typescript
interface BiometricHash {
  hash: string;                    // SHA-256 hash (hex string)
  salt: Uint8Array;                // Random salt (saved by user)
  algorithm: 'SHA-256';
  timestamp: number;               // When hashed (block timestamp)
}

async function hashBiometric(
  biometricData: ArrayBuffer,
  userSalt?: Uint8Array
): Promise<BiometricHash> {
  // 1. Generate salt if not provided (new registration)
  let salt = userSalt;
  if (!salt) {
    salt = window.crypto.getRandomValues(new Uint8Array(16));
  }
  
  // 2. Combine biometric + salt
  const combined = new Uint8Array(biometricData.byteLength + salt.length);
  combined.set(new Uint8Array(biometricData), 0);
  combined.set(salt, biometricData.byteLength);
  
  // 3. Hash with SHA-256
  const hashBuffer = await window.crypto.subtle.digest('SHA-256', combined);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  
  // 4. Return hash + salt (salt needed for later reference)
  return {
    hash: hashHex,
    salt: salt,
    algorithm: 'SHA-256',
    timestamp: Date.now()
  };
}

// Store salt locally (encrypted with user passphrase, never sent to server)
async function saveBiometricSalt(
  userID: string,
  salt: Uint8Array,
  passphrase: string
) {
  // Encrypt salt with passphrase (so user can recover it)
  const encryptedSalt = await encryptWithPassphrase(salt, passphrase);
  
  // Store in browser's local storage (encrypted)
  const storage = await indexedDB.open('trustnet');
  const tx = storage.transaction('biometric', 'readwrite');
  await tx.objectStore('biometric').put({
    user_id: userID,
    encrypted_salt: encryptedSalt,
    created_at: Date.now()
  });
}
```

**Security Decision**: Why One-Way Hash?
- ✓ Biometric cannot be recovered from hash
- ✓ GDPR compliant (reduced PII)
- ✓ Prevents misuse if database compromised
- ✗ Cannot authenticate using biometric later (must use key)
- See: SECURITY_ARCHITECTURE.md - "Biometric Registry Security"

---

### 1.3 Identity Key Generation

**Component**: KeyGenerator.ts

```typescript
interface IdentityKeyPair {
  publicKey: CryptoKey;             // Ed25519 public key
  privateKey: CryptoKey;             // Ed25519 private key (encrypted)
  publicKeyHex: string;              // Hex for blockchain
  algorithm: 'EdDSA';                // Always EdDSA
  generated_at: number;              // Timestamp
}

async function generateIdentityKeyPair(): Promise<IdentityKeyPair> {
  // Generate EdDSA keypair (256-bit security)
  const keyPair = await window.crypto.subtle.generateKey(
    'Ed25519',                       // Algorithm
    true,                           // extractable (needed to save)
    ['sign', 'verify']              // Usage
  );
  
  // Export public key to hex (for blockchain)
  const publicKeyRaw = await window.crypto.subtle.exportKey(
    'raw',
    keyPair.publicKey
  );
  const publicKeyHex = Array.from(new Uint8Array(publicKeyRaw))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  
  return {
    publicKey: keyPair.publicKey,
    privateKey: keyPair.privateKey,  // Will be encrypted before storage
    publicKeyHex: publicKeyHex,
    algorithm: 'EdDSA',
    generated_at: Date.now()
  };
}

// Encrypt and store private key
async function encryptAndStorePrivateKey(
  privateKey: CryptoKey,
  passphrase: string,
  publicKeyHex: string
) {
  // 1. Export private key (raw bytes)
  const privateKeyRaw = await window.crypto.subtle.exportKey('pkcs8', privateKey);
  
  // 2. Derive encryption key from passphrase
  const encryptionKey = await deriveKeyFromPassphrase(passphrase);
  
  // 3. Encrypt private key with AES-256-GCM
  const iv = window.crypto.getRandomValues(new Uint8Array(12)); // 96-bit IV
  const encrypted = await window.crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv,
      additionalData: new TextEncoder().encode(publicKeyHex)
    },
    encryptionKey,
    privateKeyRaw
  );
  
  // 4. Store encrypted key in IndexedDB
  const storage = await indexedDB.open('trustnet');
  const tx = storage.transaction('keys', 'readwrite');
  await tx.objectStore('keys').put({
    public_key: publicKeyHex,
    encrypted_private_key: new Uint8Array(encrypted),
    iv: iv,
    algorithm: 'AES-256-GCM',
    created_at: Date.now(),
    key_derivation: {
      algorithm: 'PBKDF2',
      hash_function: 'SHA-256',
      iterations: 100000
    }
  });
}

// Derive encryption key from passphrase (PBKDF2)
async function deriveKeyFromPassphrase(passphrase: string): Promise<CryptoKey> {
  // 1. Import passphrase as key
  const passphraseKey = await window.crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(passphrase),
    'PBKDF2',
    false,  // not extractable
    ['deriveBits', 'deriveKey']
  );
  
  // 2. Derive 256-bit key using PBKDF2
  const derivedKey = await window.crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      hash: 'SHA-256',
      salt: GLOBAL_REGISTRATION_SALT, // Same salt for all users (different salt per key at encryption)
      iterations: 100000  // ~100ms on modern hardware
    },
    passphraseKey,
    {
      name: 'AES-GCM',
      length: 256
    },
    true,  // extractable (needed for local verification)
    ['encrypt', 'decrypt']
  );
  
  return derivedKey;
}
```

**Security Decision**: Why EdDSA (Ed25519)?
- ✓ Fast, 256-bit security
- ✓ Simpler than RSA (harder to misuse)
- ✓ Standard in modern cryptography
- ✗ Less flexible than RSA (but not needed)
- See: SECURITY_ARCHITECTURE.md - "Identity Key Generation"

---

### 1.4 Recovery Codes Generation

**Component**: RecoveryCodeGenerator.ts

```typescript
interface RecoveryCode {
  mnemonic: string[];              // 12-word BIP39 mnemonic
  encrypted: string;               // Encrypted with passphrase
  backup_instructions: string;     // How to back up
  expiry: number;                  // When wallet resets (days until unused)
}

async function generateRecoveryCodes(): Promise<RecoveryCode> {
  // 1. Generate 128 bits random entropy (12 words with BIP39)
  const entropy = window.crypto.getRandomValues(new Uint8Array(16));
  
  // 2. Convert to BIP39 mnemonic
  const mnemonic = entropyToMnemonic(entropy);
  
  // 3. Instructions for user
  const backup_instructions = `
    Your 12-word recovery code is your key to account access.
    
    SAVE THIS SAFELY:
    1. Write on paper (no photos, no digital copies)
    2. Store in safe location (safe deposit box)
    3. Don't share with anyone
    
    ORDER MATTERS: Write words in exact order
    
    IF YOU LOSE ACCESS:
    - Provide these 12 words + your passphrase
    - System verifies + grants access
    - Your identity key is recreated
  `;
  
  return {
    mnemonic: mnemonic,
    encrypted: '', // Will be encrypted with user's passphrase
    backup_instructions: backup_instructions,
    expiry: Date.now() + (365 * 24 * 60 * 60 * 1000) // 1 year
  };
}

// Encrypt recovery codes with user's passphrase
async function encryptRecoveryCodes(
  mnemonic: string[],
  passphrase: string
): Promise<string> {
  const mnemonicString = mnemonic.join(' ');
  const encryptionKey = await deriveKeyFromPassphrase(passphrase);
  
  const iv = window.crypto.getRandomValues(new Uint8Array(12));
  const encrypted = await window.crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv,
      additionalData: new TextEncoder().encode('recovery-codes')
    },
    encryptionKey,
    new TextEncoder().encode(mnemonicString)
  );
  
  // Return encrypted + IV (IV needed for decryption)
  const result = {
    encrypted: Array.from(new Uint8Array(encrypted))
      .map(b => b.toString(16).padStart(2, '0'))
      .join(''),
    iv: Array.from(iv)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')
  };
  
  return JSON.stringify(result);
}

// Store encrypted recovery codes
async function storeRecoveryCodes(
  publicKeyHex: string,
  encryptedCodes: string
) {
  const storage = await indexedDB.open('trustnet');
  const tx = storage.transaction('recovery', 'readwrite');
  await tx.objectStore('recovery').put({
    public_key: publicKeyHex,
    encrypted_codes: encryptedCodes,
    created_at: Date.now(),
    accessed_count: 0  // Track if recovery codes have been used
  });
}
```

**Security Decision**: Why BIP39 Mnemonic?
- ✓ User-friendly (12 English words)
- ✓ International standard (crypto wallets use this)
- ✓ Entropy: 128 bits = 2^128 possible combinations
- ✓ Error detection (checksum validates)
- See: SECURITY_ARCHITECTURE.md - "Recovery Code Generation"

---

### 1.5 Proof-of-Work Generation

**Component**: ProofOfWork.ts

```typescript
interface ProofOfWorkChallenge {
  challenge: string;               // Random challenge
  difficulty: number;              // Number of leading zeros required
  timestamp: number;               // Challenge issued at
  expires: number;                 // Expires after (prevent replay)
}

interface ProofOfWorkProof {
  challenge: string;               // Original challenge
  nonce: number;                   // Solution nonce
  difficulty: number;              // Difficulty at time of solution
  time_taken_ms: number;           // How long to solve
}

async function generateProofOfWorkChallenge(): Promise<ProofOfWorkChallenge> {
  // 1. Generate random challenge
  const randomBytes = window.crypto.getRandomValues(new Uint8Array(32));
  const challenge = Array.from(randomBytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  
  // 2. Set difficulty (adjust based on system load)
  // Difficulty 4 = ~10-30 seconds on commodity hardware
  const difficulty = 4;
  
  return {
    challenge: challenge,
    difficulty: difficulty,
    timestamp: Date.now(),
    expires: Date.now() + (10 * 60 * 1000) // Valid for 10 minutes
  };
}

async function solveProofOfWorkChallenge(
  challenge: string,
  difficulty: number
): Promise<ProofOfWorkProof> {
  // Solve: Find nonce where SHA-256(challenge || nonce) starts with N zeros
  // This is computationally expensive (by design - prevents spam)
  
  const startTime = Date.now();
  let nonce = 0;
  
  while (true) {
    // Compute hash(challenge + nonce)
    const toHash = `${challenge}${nonce}`;
    const hashBuffer = await window.crypto.subtle.digest(
      'SHA-256',
      new TextEncoder().encode(toHash)
    );
    
    // Convert to hex
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
    
    // Check if leading zeros match difficulty
    const leadingZeros = hashHex.match(/^0*/)[0].length;
    if (leadingZeros >= difficulty) {
      // Found solution!
      return {
        challenge: challenge,
        nonce: nonce,
        difficulty: difficulty,
        time_taken_ms: Date.now() - startTime
      };
    }
    
    nonce++;
    
    // Update UI every 1000 iterations (show progress)
    if (nonce % 1000 === 0) {
      updateProgressUI(`Computing proof-of-work: ${nonce} attempts`);
      // Allow UI to update
      await new Promise(resolve => setTimeout(resolve, 0));
    }
  }
}

// Verify proof-of-work (server-side, during registration)
async function verifyProofOfWork(proof: ProofOfWorkProof): Promise<boolean> {
  // 1. Check challenge not expired
  if (proof.timestamp < Date.now() - 10 * 60 * 1000) {
    return false; // Expired
  }
  
  // 2. Verify hash(challenge + nonce) has required leading zeros
  const toHash = `${proof.challenge}${proof.nonce}`;
  const hashBuffer = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(toHash)
  );
  
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  
  const leadingZeros = hashHex.match(/^0*/)[0].length;
  return leadingZeros >= proof.difficulty;
}
```

**Security Decision**: Why Proof-of-Work?
- ✓ Prevents spam (attacker must spend CPU)
- ✓ No rate-limiting needed (economic cost)
- ✗ Slightly slower user experience (~20 seconds)
- Trade-off: Security > convenience
- See: SECURITY_ARCHITECTURE.md - "Proof-of-Work for Registration"

---

## Phase 2: Registration Transaction

### 2.1 Build Registration TX

**Component**: RegistrationTX.ts

```typescript
interface RegistrationTransaction {
  // Identity claim
  public_key: string;              // User's Ed25519 public key (hex)
  

  // Age verification (from government ID)
  age: number;                     // Calculated from birth date
  network: 'KidsNet' | 'TeenNet' | 'TrustNet'; // Auto-assigned
  
  // Biometric claim
  biometric_hash: string;          // SHA-256(fingerprint || salt)
  
  // Government verification
  government_signature: string;    // ICAO 9303 signature (hex)
  government_country: string;      // Country code (C in ICAO)
  
  // Proof of work
  proof_of_work: {
    challenge: string;
    nonce: number;
  };
  
  // Anti-replay protection
  nonce: number;                   // Unique per transaction
  created_at: number;              // Block timestamp
  
  // Signature (user signs entire TX with private key)
  signature: string;               // Ed25519 signature (hex)
}

async function buildRegistrationTransaction(
  userData: {
    publicKey: string;
    age: number;
    biometricHash: string;
    governmentSignature: string;
    governmentCountry: string;
    proofOfWork: ProofOfWorkProof;
  },
  privateKey: CryptoKey
): Promise<RegistrationTransaction> {
  // 1. Auto-assign network based on age
  const network = assignNetwork(userData.age);
  if (!network) {
    throw new Error(`Invalid age: ${userData.age}`);
  }
  
  // 2. Build transaction object
  const tx: RegistrationTransaction = {
    public_key: userData.publicKey,
    age: userData.age,
    network: network,
    biometric_hash: userData.biometricHash,
    government_signature: userData.governmentSignature,
    government_country: userData.governmentCountry,
    proof_of_work: {
      challenge: userData.proofOfWork.challenge,
      nonce: userData.proofOfWork.nonce
    },
    nonce: Math.floor(Math.random() * 2**32), // Random nonce
    created_at: Math.floor(Date.now() / 1000),
    signature: ''  // Will be filled in next step
  };
  
  // 3. Sign transaction with private key
  const txString = JSON.stringify(tx, Object.keys(tx).sort()); // Canonical JSON
  const signatureBuffer = await window.crypto.subtle.sign(
    'Ed25519',
    privateKey,
    new TextEncoder().encode(txString)
  );
  
  tx.signature = Array.from(new Uint8Array(signatureBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
  
  return tx;
}

function assignNetwork(age: number): 'KidsNet' | 'TeenNet' | 'TrustNet' | null {
  if (age < 0 || age > 150) return null;  // Sanity check
  if (age >= 0 && age <= 12) return 'KidsNet';
  if (age >= 13 && age <= 19) return 'TeenNet';
  if (age >= 20) return 'TrustNet';
  return null;
}
```

---

### 2.2 Submit to Blockchain

**Component**: RegistrationSubmit.ts

```typescript
interface RegistrationResult {
  success: boolean;
  tx_hash: string;           // Blockchain TX hash
  block_height: number;      // When finalized
  message: string;           // User-friendly message
  identity_key: string;      // User's public key (confirmation)
}

async function submitRegistration(
  tx: RegistrationTransaction
): Promise<RegistrationResult> {
  // 1. Submit to blockchain node
  const response = await fetch(
    `${BLOCKCHAIN_NODE_URL}/tx`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        type: 'registration',
        tx: tx
      })
    }
  );
  
  if (!response.ok) {
    const error = await response.json();
    return {
      success: false,
      tx_hash: '',
      block_height: 0,
      message: `Registration failed: ${error.reason}`,
      identity_key: tx.public_key
    };
  }
  
  const result = await response.json();
  
  // 2. Wait for consensus (6 seconds on Tendermint)
  // Poll blockchain for confirmation
  const confirmed = await waitForConfirmation(result.tx_hash, maxAttempts=12);
  
  if (confirmed) {
    return {
      success: true,
      tx_hash: result.tx_hash,
      block_height: result.block_height,
      message: 'Account created successfully! Welcome to TrustNet.',
      identity_key: tx.public_key
    };
  } else {
    return {
      success: false,
      tx_hash: result.tx_hash,
      block_height: 0,
      message: 'Registration submitted but not confirmed. Please try again.',
      identity_key: tx.public_key
    };
  }
}

async function waitForConfirmation(
  txHash: string,
  maxAttempts: number = 12
): Promise<boolean> {
  for (let i = 0; i < maxAttempts; i++) {
    try {
      const response = await fetch(
        `${BLOCKCHAIN_NODE_URL}/tx?hash=${txHash}`
      );
      
      if (response.status === 200) {
        // TX found in blockchain
        return true;
      }
    } catch (e) {
      console.log('Waiting for confirmation...');
    }
    
    // Wait 1 second before retry
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  // Timeout
  return false;
}
```

---

## Phase 3: Blockchain Validation

### 3.1 Validator Node Registration Logic

**Component**: blockchain/modules/registration/keeper.go (Cosmos SDK)

```go
package registration

import (
    "crypto/sha256"
    "encoding/hex"
    
    sdk "github.com/cosmos/cosmos-sdk/types"
    "trustnet/x/registry"
)

// ValidateRegistrationTX - Check registration is valid
func (k Keeper) ValidateRegistrationTX(
    ctx sdk.Context,
    tx RegistrationTransaction,
) error {
    // 1. Validate signature (TX signed with claimed public key)
    if !verifyEdDSASignature(tx.PublicKey, tx.Signature, tx) {
        return fmt.Errorf("invalid signature: TX not signed by claimed key")
    }
    
    // 2. Validate government signature (ICAO 9303)
    govCert := k.GetGovernmentCertificate(ctx, tx.GovernmentCountry)
    if govCert == nil {
        return fmt.Errorf("unsupported country: %s", tx.GovernmentCountry)
    }
    if !verifyGovernmentSignature(govCert, tx.GovernmentSignature) {
        return fmt.Errorf("invalid government signature: ID may be forged")
    }
    
    // 3. Validate age (sanity check)
    if tx.Age < 0 || tx.Age > 150 {
        return fmt.Errorf("invalid age: %d", tx.Age)
    }
    
    // 4. Validate age-to-network assignment
    expectedNetwork := assignNetwork(tx.Age)
    if tx.Network != expectedNetwork {
        return fmt.Errorf("invalid network for age %d: expected %s, got %s", 
            tx.Age, expectedNetwork, tx.Network)
    }
    
    // 5. Check biometric uniqueness (registry lookup)
    exists := k.BiometricRegistry.Has(ctx, tx.BiometricHash)
    if exists {
        return fmt.Errorf("biometric already registered: identity may be duplicate")
    }
    
    // 6. Validate nonce (prevent replay attacks)
    if k.Nonces.Has(ctx, tx.Nonce) {
        return fmt.Errorf("nonce already used: replay attack detected")
    }
    
    // 7. Verify proof-of-work
    if !verifyProofOfWork(tx.ProofOfWork) {
        return fmt.Errorf("invalid proof-of-work")
    }
    
    // 8. Check timestamp (not too old/future)
    blockTime := ctx.BlockTime()
    if txTime.After(blockTime.Add(5*time.Minute)) {
        return fmt.Errorf("TX timestamp too far in future")
    }
    if txTime.Before(blockTime.Add(-1*time.Hour)) {
        return fmt.Errorf("TX timestamp too old")
    }
    
    return nil
}

// ExecuteRegistrationTX - Add to biometric registry
func (k Keeper) ExecuteRegistrationTX(
    ctx sdk.Context,
    tx RegistrationTransaction,
) error {
    // 1. Add to biometric registry
    registryEntry := RegistryEntry{
        BiometricHash: tx.BiometricHash,
        PublicKey: tx.PublicKey,
        Age: tx.Age,
        Network: tx.Network,
        Timestamp: uint64(ctx.BlockHeight()),
        GovernmentVerified: true,
    }
    
    k.BiometricRegistry.Set(ctx, tx.BiometricHash, registryEntry)
    
    // 2. Create identity record (for later reference)
    identity := Identity{
        PublicKey: tx.PublicKey,
        CreatedAt: uint64(ctx.BlockHeight()),
        Age: tx.Age,
        Network: tx.Network,
        Reputation: 0,  // Start with zero reputation
    }
    
    k.IdentityStore.Set(ctx, tx.PublicKey, identity)
    
    // 3. Mark nonce as used (prevent replay)
    k.Nonces.Set(ctx, tx.Nonce, true)
    
    // 4. Emit event (for notifications)
    ctx.EventManager().EmitEvent(
        sdk.NewEvent(
            "registration",
            sdk.NewAttribute("public_key", tx.PublicKey),
            sdk.NewAttribute("network", string(tx.Network)),
            sdk.NewAttribute("block_height", fmt.Sprintf("%d", ctx.BlockHeight())),
        ),
    )
    
    return nil
}
```

---

## Phase 4: Post-Registration

### 4.1 Account Ready

**Component**: AccountSetup.tsx

```typescript
interface RegistrationComplete {
  account_ready: boolean;
  identity_key: string;
  network: 'KidsNet' | 'TeenNet' | 'TrustNet';
  next_steps: string[];
  backup_reminder: string;
}

async function postRegistration(
  result: RegistrationResult
): Promise<RegistrationComplete> {
  // 1. Verify account on blockchain
  const verified = await verifyAccountOnBlockchain(result.tx_hash);
  
  if (!verified) {
    return {
      account_ready: false,
      identity_key: result.identity_key,
      network: 'TrustNet',
      next_steps: ['Please wait a moment and refresh the page'],
      backup_reminder: 'Remember to save your recovery codes!'
    };
  }
  
  // 2. Clear temporary data from memory
  clearPasswordFromMemory();
  clearBiometricFromMemory();
  
  // 3. Prepare next steps
  const nextSteps = [
    '✅ Account created',
    '✅ Identity verified',
    '⏳ Wait for network consensus (6 seconds)',
    '✅ Account ready to use',
    'START: Explore your network, complete profile, build reputation'
  ];
  
  return {
    account_ready: true,
    identity_key: result.identity_key,
    network: 'TrustNet',  // or KidsNet/TeenNet
    next_steps: nextSteps,
    backup_reminder: '⚠️ BACKUP REMINDER: You saved your recovery codes, right?'
  };
}

// Display success screen with important reminders
function displaySuccessScreen(completion: RegistrationComplete) {
  return <> {/* React component */}
    <h1>🎉 Welcome to {completion.network}!</h1>
    
    <div className="success-message">
      <p>Your account has been created and verified on the blockchain.</p>
      <p>🔑 Identity Key: {completion.identity_key.substring(0, 16)}...</p>
      <p>🌐 Network: {completion.network}</p>
    </div>
    
    <div className="reminders">
      <h2>⚠️ IMPORTANT REMINDERS</h2>
      <ul>
        <li>✅ Did you save your recovery codes?</li>
        <li>✅ Did you remember your passphrase?</li>
        <li>✅ Did you back up your salt locally?</li>
        <li>❌ NEVER share your recovery codes</li>
        <li>❌ NEVER share your passphrase</li>
        <li>❌ NEVER store recovery codes digitally</li>
      </ul>
    </div>
    
    <button onClick={() => navigate('/profile')}>
      Complete Your Profile
    </button>
  </>;
}
```

---

## Error Handling

### Registration Failure Scenarios

| Scenario | Error | Recovery |
|----------|-------|----------|
| Invalid NFC chip | "Cannot read NFC data" | Try again, check chip |
| Forged ID (bad signature) | "Government signature invalid" | Contact support (fraud alert) |
| Expired ID | "ID has expired" | Renew government ID |
| Duplicate account | "Biometric already registered" | Try account recovery or contact support |
| Failed PoW submission | "Proof-of-work invalid" | Try registration again |
| Network error | "Cannot connect to blockchain" | Check internet, try again |
| Invalid age | "Age outside valid range" | Check ID data, contact support |

### Error Messages (User-Friendly)

```typescript
// DO NOT leak system details
❌ "TypeError: Cannot read property 'X' of undefined"
❌ "SQL query failed: SELECT * FROM users WHERE..."
❌ "Buffer overflow detected in crypto library"

// DO provide helpful guidance
✅ "NFC scan failed. Please ensure your ID chip is readable."
✅ "Government signature could not be verified. Your ID may be counterfeit."
✅ "An account already exists for this person (biometric match)."
```

---

## Security Checklist

Before registration launches:

- [ ] All cryptographic keys stored only in browser (never transmitted)
- [ ] NFC signature validation works for all supported countries
- [ ] Biometric hashing one-way (cannot reverse)
- [ ] Recovery codes encrypted with user's passphrase
- [ ] Proof-of-work prevents spam but completes in <30 seconds
- [ ] Registration TX immutable once on blockchain
- [ ] Age immutable (cannot be changed later)
- [ ] All data encrypted in transit (TLS 1.3)
- [ ] Audit logs capture all registration attempts
- [ ] Error messages never leak system details
- [ ] Database encrypted at rest (AES-256-GCM)

---

## Testing Plan

### Unit Tests
- EdDSA key generation
- SHA-256 hashing (one-way property)
- PBKDF2 key derivation
- Proof-of-work validation
- Age validation

### Integration Tests
- Full registration flow (NFC → blockchain)
- Duplicate detection
- Network assignment
- Error handling

### Security Tests
- Signature validation (valid/invalid cases)
- Proof-of-work spam resistance
- Key encryption/decryption
- Recovery code recovery

### Load Tests
- 1000+ registrations per second
- Blockchain consensus latency
- PoW difficulty scaling

---

## Implementation Roadmap

**Week 1**: Components (NFC, key generation, hashing)
**Week 2**: Transaction building & validation
**Week 3**: Blockchain integration
**Week 4**: Testing and hardening

---

**DOCUMENTATION**: Every implementation decision must reference the security architecture document above. Never make assumptions—document, review, decide.


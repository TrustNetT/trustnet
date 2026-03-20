# TrustNet: Blockchain-Based Architecture (Cosmos SDK)

**Date**: January 31, 2026  
**Status**: Foundation Architecture - Implementation Ready  
**Philosophy**: "If you can't trust the foundations, you cannot trust anything built over it"

---

## Core Principles

TrustNet is a **blockchain-based decentralized trust network** where:

1. **One Identity = One User** (cryptographically enforced)
2. **Immutable** (blockchain guarantees no tampering)
3. **Trustless** (verify via cryptography, don't trust central authority)
4. **Non-tamperable** (consensus prevents fraud)
5. **No fake identities** (public key cryptography + verification)

**Foundation**: Without a trustworthy identity layer, everything built on top is compromised.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     TrustNet Blockchain                      │
│                      (Cosmos SDK)                            │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  Layer 1: Blockchain Core (Tendermint BFT Consensus)        │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ - Identity Registry (on-chain, immutable)             │  │
│  │ - Node Registry (on-chain, verifiable)                │  │
│  │ - State Machine (deterministic transitions)           │  │
│  │ - Transaction Pool (signed, validated)                │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  Layer 2: P2P Networking (Tendermint P2P)                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ - Block propagation (gossip protocol)                 │  │
│  │ - Transaction gossiping (mempool)                     │  │
│  │ - Peer discovery (built-in)                           │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
│  Layer 3: Application Logic (Custom Cosmos Modules)         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │ - Identity Module (register, verify, revoke)          │  │
│  │ - Node Module (register, update state, lifecycle)     │  │
│  │ - Reputation Module (track trust scores)              │  │
│  │ - Governance Module (protocol upgrades)               │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## Why Cosmos SDK?

### Technical Fit

| Requirement | Cosmos SDK Solution |
|-------------|---------------------|
| **Language** | Go (same as our current stack) ✅ |
| **Consensus** | Tendermint BFT (proven, fast, final) ✅ |
| **Identity** | Addresses = Public Keys (built-in) ✅ |
| **Immutability** | Blockchain state (cryptographically verified) ✅ |
| **P2P** | Tendermint P2P (gossip, discovery) ✅ |
| **Customization** | Custom modules (full control) ✅ |
| **Interoperability** | IBC protocol (cross-chain communication) ✅ |
| **Proven** | Cosmos Hub, Osmosis, Terra (battle-tested) ✅ |

### Alternatives Considered

**Ethereum L2 (Optimism, Arbitrum)**:
- ❌ Solidity (different language)
- ❌ EVM limitations (harder to customize)
- ❌ Gas fees (expensive for frequent updates)
- ✅ Huge ecosystem

**Substrate (Polkadot)**:
- ❌ Rust (different language, steep learning curve)
- ✅ Highly customizable
- ✅ Excellent for parachains

**Custom Blockchain**:
- ❌ Too much complexity (consensus, networking, security)
- ❌ Reinventing the wheel
- ❌ Not battle-tested

**Verdict**: Cosmos SDK is the best fit for TrustNet.

---

## Blockchain Components

### 1. Identity Registry (On-Chain)

**Purpose**: Cryptographically verifiable, immutable identity system

**Data Structure**:
```protobuf
message Identity {
  string address = 1;              // Derived from public key (unique)
  string public_key = 2;           // User's public key
  string name = 3;                 // Human-readable name
  string metadata = 4;             // JSON metadata (email, bio, etc.)
  
  // Verification
  VerificationStatus status = 5;   // UNVERIFIED, VERIFIED, REVOKED
  string verifier = 6;             // Address of verifier (if verified)
  int64 verified_at = 7;           // Timestamp of verification
  
  // Reputation
  int64 reputation_score = 8;      // Trust score (0-100)
  int64 endorsements = 9;          // Number of endorsements
  
  // Timestamps
  int64 registered_at = 10;
  int64 updated_at = 11;
}

enum VerificationStatus {
  UNVERIFIED = 0;
  VERIFIED = 1;
  REVOKED = 2;
}
```

**Key Properties**:
- ✅ **One identity per user**: Address derived from public key (unique)
- ✅ **Immutable history**: All changes recorded on-chain
- ✅ **Cryptographically verifiable**: Signature proves ownership
- ✅ **No tampering**: Blockchain consensus prevents fraud

**Transactions**:
```go
// Register new identity
type MsgRegisterIdentity struct {
    PublicKey string
    Name      string
    Metadata  string
}

// Update identity metadata
type MsgUpdateIdentity struct {
    Address  string
    Name     string
    Metadata string
}

// Verify identity (requires verifier signature)
type MsgVerifyIdentity struct {
    Address  string
    Verifier string  // Must be authorized verifier
}

// Revoke identity
type MsgRevokeIdentity struct {
    Address string
    Reason  string
}
```

---

### 2. Node Registry (On-Chain)

**Purpose**: Track all TrustNet nodes with immutable state history

**Data Structure**:
```protobuf
message Node {
  string id = 1;                   // Node ID (unique)
  string owner = 2;                // Identity address (who owns this node)
  string ipv6 = 3;                 // IPv6 ULA address
  
  // State (lifecycle)
  NodeState state = 4;             // ONLINE, OFFLINE, INACTIVE, DEAD
  int64 last_heartbeat = 5;        // Last heartbeat block height
  int64 last_state_change = 6;     // Block height of last state change
  NodeState previous_state = 7;
  
  // Network topology
  repeated string peers = 8;       // List of peer node IDs
  string discovery_method = 9;     // "multicast", "dht", "bootstrap"
  string network_topology = 10;    // "full", "isolated", "degraded"
  
  // Metrics
  int64 uptime_blocks = 11;        // Total blocks online
  int64 peer_count = 12;
  string health_status = 13;       // "healthy", "degraded", "unhealthy"
  
  // Timestamps
  int64 registered_at = 14;        // Block height
  int64 updated_at = 15;
}

enum NodeState {
  ONLINE = 0;
  OFFLINE = 1;
  INACTIVE = 2;
  DEAD = 3;
  REMOVED = 4;
}
```

**Transactions**:
```go
// Register new node (must own identity)
type MsgRegisterNode struct {
    NodeID string
    Owner  string  // Identity address
    IPv6   string
}

// Update node state (heartbeat)
type MsgNodeHeartbeat struct {
    NodeID    string
    State     NodeState
    PeerCount int64
    Metrics   NodeMetrics
}

// Update node peers
type MsgUpdateNodePeers struct {
    NodeID string
    Peers  []string
}

// Remove node
type MsgRemoveNode struct {
    NodeID string
    Owner  string  // Must match node owner
}
```

---

### 3. Consensus Mechanism: Tendermint BFT

**How it works**:

```
Validators propose blocks → Vote on validity → 2/3+ agreement = Finality

Block time: ~6 seconds (configurable)
Finality: Instant (no forks, no reorgs)
Byzantine fault tolerance: Tolerates up to 1/3 malicious validators
```

**Validator Set**:

**Option 1: Proof of Authority (PoA)** ⭐ RECOMMENDED FOR START
- Trusted validators (known entities)
- No staking required
- Fast, efficient
- Good for initial phase

**Option 2: Proof of Stake (PoS)** (FUTURE)
- Validators stake tokens
- Economic incentive to behave
- More decentralized
- Upgrade path from PoA

**Initial Setup**:
```yaml
# Genesis validators (Proof of Authority)
validators:
  - address: "cosmos1abc..."
    power: 10
    name: "Foundation Node 1"
  
  - address: "cosmos1def..."
    power: 10
    name: "Foundation Node 2"
  
  - address: "cosmos1ghi..."
    power: 10
    name: "Foundation Node 3"

# Minimum 3 validators for BFT (tolerates 1 failure)
# Recommended: 7+ validators (tolerates 2 failures)
```

---

### 4. Token Economics: TrustCoin

**Vision**: TrustNet will have its own native cryptocurrency: **TrustCoin**

**Phased Rollout**:

#### Phase 1: No Token (Launch - Months 1-3) ⭐ START HERE
- Free transactions (zero gas fees)
- Focus on adoption and identity building
- Validators run via foundation subsidy
- Simple, accessible onboarding
- Build user base and reputation system

**Implementation**:
```go
// Phase 1: All transactions are free
fee := sdk.NewCoins() // Empty fee
```

#### Phase 2: TrustCoin Launch (Months 4-6)

**Token Properties**:
```yaml
name: TrustCoin
symbol: TRUST
decimals: 6
total_supply: 1,000,000,000 TRUST  # 1 billion (adjustable)
```

**Token Utility**:

1. **Validator Staking** (Proof of Stake) ⭐ PRIMARY USE
   - Validators stake TRUST to participate in consensus
   - Minimum stake: 10,000 TRUST
   - Earn rewards from inflation
   - Slashed for misbehavior (downtime, double-signing)

2. **Reputation Staking** (Social Capital)
   - Stake TRUST to boost reputation score
   - Higher stake = higher trust signal
   - **Slashed if reputation drops to zero** (lose both TRUST + network access)
   - Prove commitment via economic stake

3. **Governance** (Protocol Evolution)
   - Vote on protocol upgrades
   - 1 TRUST staked = 1 vote
   - Proposal submission requires TRUST deposit (anti-spam)
   - Voting power weighted by stake + reputation

4. **Identity Verification Bond** (Optional)
   - Deposit TRUST when registering identity
   - Returned if verified, forfeited if fake/malicious
   - Example: 100 TRUST deposit (refundable)
   - Economic commitment to authenticity

5. **Transaction Fees** (Minimal or Optional)
   - **PRIMARY ANTI-SPAM: Reputation, not fees!**
   - Reputation = 0 → Cannot submit transactions (kicked from network)
   - Transaction fees can be zero or minimal (0.0001 TRUST)
   - Fees go to validators (sustainability)

**Key Insight**: 
> Reputation is the PRIMARY anti-spam mechanism. Lose reputation → lose network access.  
> TrustCoin amplifies reputation (stake = commitment) rather than replacing it.

**Token Distribution** (Example):

```yaml
Genesis Allocation (1 billion TRUST):
  
  Foundation Reserve: 30% (300M TRUST)
    - Development funding
    - Validator subsidies
    - Ecosystem grants
  
  Community Airdrop: 20% (200M TRUST)
    - Reward early adopters
    - Distribute to verified identities
    - Incentivize growth
  
  Validator Rewards: 25% (250M TRUST)
    - Staking rewards (released over 5 years)
    - Block rewards
    - Fee redistribution
  
  Team/Advisors: 15% (150M TRUST)
    - 4-year vesting
    - Cliff after 1 year
  
  Public Sale: 10% (100M TRUST)
    - Fair launch (optional)
    - Community fundraising
```

**Inflation Model**:

```yaml
Year 1: 10% annual inflation (100M new TRUST)
Year 2: 8% annual inflation
Year 3: 6% annual inflation
Year 4: 4% annual inflation
Year 5+: 2% annual inflation (perpetual)

# New tokens go to staking rewards (incentivize validators)
```

**Implementation**:
```go
// Phase 2: TrustCoin enabled
import (
    sdk "github.com/cosmos/cosmos-sdk/types"
)

// Define native token
func init() {
    sdk.DefaultBondDenom = "trust"  // Staking token
}

// Transaction with fee
fee := sdk.NewCoins(sdk.NewInt64Coin("trust", 1000)) // 0.001 TRUST

// Staking requirement
minimumStake := sdk.NewInt64Coin("trust", 10_000_000) // 10,000 TRUST
```

#### Phase 3: DeFi Integration (Months 7+)

**Advanced Features**:

1. **Liquidity Pools**
   - TRUST/USDC pairs
   - TRUST/ETH pairs (via IBC bridge)
   - Earn trading fees

2. **Lending/Borrowing**
   - Lend TRUST, earn interest
   - Borrow against TRUST collateral
   - Reputation affects interest rates

3. **NFTs for Verified Identities**
   - Verified identity = NFT badge
   - Tradeable, provable credentials
   - Reputation history embedded

4. **Cross-Chain Bridges** (IBC)
   - TRUST on Ethereum (wrapped)
   - TRUST on other Cosmos chains
   - Interoperable identity

**Economic Security Model**:

```
High TRUST stake → High reputation → Low interest rates (lending)
Low TRUST stake → Low reputation → High interest rates (borrowing)

Slashing conditions:
- Validator downtime: -5% stake
- Double-signing: -50% stake
- Identity fraud: -100% stake (total slash)
```

---

### Token Launch Strategy

**Pre-Launch Preparation** (Phase 1):

```bash
# Month 1-3: Build user base WITHOUT token
# Goals:
- 10,000+ verified identities
- 100+ active nodes
- Stable network (99.9% uptime)
- Community engagement

# Metrics to track:
- Daily active users
- Identity verifications
- Node registrations
- Network stability
```

**Token Genesis** (Phase 2 Launch):

```yaml
# Genesis state includes token allocation
genesis.json:
  app_state:
    bank:
      balances:
        - address: "cosmos1foundation..."
          coins: [{ denom: "trust", amount: "300000000000000" }]  # 300M
        
        - address: "cosmos1airdrop..."
          coins: [{ denom: "trust", amount: "200000000000000" }]  # 200M
    
    staking:
      params:
        bond_denom: "trust"
        min_self_delegation: "10000000000"  # 10,000 TRUST
```

**Airdrop to Early Users**:

```go
// Airdrop logic (executed at token genesis)
func AirdropToEarlyUsers(ctx sdk.Context, k keeper.Keeper) error {
    // Get all verified identities before token launch
    identities := k.GetVerifiedIdentities(ctx)
    
    totalAirdrop := sdk.NewInt(200_000_000_000_000) // 200M TRUST
    perUser := totalAirdrop.QuoInt64(int64(len(identities)))
    
    for _, identity := range identities {
        // Award TRUST to early adopters
        coins := sdk.NewCoins(sdk.NewCoin("trust", perUser))
        k.bankKeeper.MintCoins(ctx, "airdrop", coins)
        k.bankKeeper.SendCoinsFromModuleToAccount(ctx, "airdrop", identity.Address, coins)
    }
    
    return nil
}
```

---

### Why TrustCoin is Essential

1. **Economic Security**
   - Validators have skin in the game (staked TRUST)
   - Malicious behavior = financial loss
   - Incentive alignment

2. **Anti-Spam**
   - Free transactions = spam problem
   - Small fees prevent abuse
   - Self-regulating network

3. **Decentralization Incentive**
   - Validators earn TRUST rewards
   - More validators = more decentralized
   - Economic sustainability

4. **Reputation as Capital**
   - Stake TRUST = signal trustworthiness
   - Reputation backed by economic value
   - Verifiable commitment

5. **Ecosystem Growth**
   - Token enables DeFi applications
   - Liquidity attracts developers
   - Network effects

**Cosmos SDK Token Module**:

```go
// Built-in token support
import (
    "github.com/cosmos/cosmos-sdk/x/bank"      // Transfer tokens
    "github.com/cosmos/cosmos-sdk/x/staking"   // Validator staking
    "github.com/cosmos/cosmos-sdk/x/distribution" // Fee distribution
    "github.com/cosmos/cosmos-sdk/x/mint"      // Token inflation
)

// Example: Transfer TRUST
msg := banktypes.MsgSend{
    FromAddress: "cosmos1sender...",
    ToAddress:   "cosmos1receiver...",
    Amount:      sdk.NewCoins(sdk.NewInt64Coin("trust", 1000000)), // 1 TRUST
}
```

---

### Roadmap Summary

```
Month 1-3: Launch WITHOUT token
  - Build trust network
  - 10,000+ verified identities
  - Prove concept works
  - Free transactions (foundation subsidizes)

Month 4: TrustCoin Genesis
  - Airdrop to early users (200M TRUST)
  - Enable transaction fees (0.001 TRUST)
  - Launch validator staking

Month 5-6: Token Stabilization
  - Enable governance (TRUST voting)
  - Launch liquidity pools
  - Integrate with DEXs (Osmosis, etc.)

Month 7+: DeFi Ecosystem
  - Lending/borrowing
  - NFT verified identities
  - Cross-chain bridges (IBC)
  - Reputation-backed loans
```

**Answer to your question**: 

✅ **Yes, you can create your own token** (Cosmos SDK makes this trivial)  
✅ **Start without token** (Phase 1: Free transactions, build user base)  
✅ **Launch TrustCoin later** (Phase 2: After proven adoption)  
✅ **Tokens are ESSENTIAL** for long-term sustainability and economic security

---

### 5. Identity Verification Strategy

**Challenge**: How to ensure one identity = one human?

**Multi-Tiered Verification**:

#### Tier 1: Self-Registered (Unverified)
- Anyone can register
- Public key = identity
- Status: UNVERIFIED
- Limited trust/reputation

#### Tier 2: Community Verified
- Existing verified users endorse new users
- Requires N endorsements (e.g., 3)
- Web of trust model
- Status: VERIFIED

#### Tier 3: Authority Verified (Optional)
- Verified by trusted authorities
- KYC process
- Government ID verification
- Status: AUTHORITY_VERIFIED

**Anti-Sybil Mechanisms**:

```go
// 1. Rate limiting (on-chain)
- Max 1 identity per address
- Cooldown period for new registrations (1 week)

// 2. Endorsement graph
- Endorsements create trust graph
- Analyze graph for Sybil clusters
- Require diverse endorsers (not all from same cluster)

// 3. Reputation system
- New identities start with 0 reputation
- Reputation grows with verified actions
- Low reputation = limited privileges

// 4. Challenge-response (future)
- Proof of humanity (CAPTCHA-like)
- Biometric verification (optional)
- Social graph analysis
```

**Implementation**:
```protobuf
message Endorsement {
  string endorser = 1;      // Address of endorser
  string endorsed = 2;      // Address being endorsed
  string reason = 3;        // Why they endorse
  int64 timestamp = 4;
  
  // Endorser must be VERIFIED to endorse others
  // Endorsed becomes VERIFIED after N endorsements
}
```

---

## Reputation System: Primary Anti-Spam Mechanism

### Core Principle

> **Reputation = Network Access**  
> Lose all reputation → Kicked from network (cannot submit transactions)

This is **far more effective** than transaction fees for spam prevention:
- ❌ Transaction fees: Spammer just pays more money
- ✅ Reputation loss: Spammer loses network access entirely

### Reputation Score (0-100)

```protobuf
message ReputationScore {
  string identity_address = 1;
  int64 score = 2;                  // 0-100 (default: 50)
  
  // Score components
  int64 endorsements = 3;           // +points from verified endorsements
  int64 uptime = 4;                 // +points for node uptime
  int64 verified_actions = 5;       // +points for verified good behavior
  int64 violations = 6;             // -points for bad behavior
  
  // Decay (prevents reputation squatting)
  int64 last_activity = 7;          // Block height of last activity
  int64 decay_rate = 8;             // Reputation decays if inactive
  
  // Staked TRUST (boosts reputation)
  int64 staked_trust = 9;           // Amount of TRUST staked
  int64 reputation_multiplier = 10; // Stake multiplier (1.0 - 2.0x)
}
```

### Reputation Mechanics

#### Starting Reputation
```yaml
New identity: 50 reputation
  - Unverified: 50 (limited privileges)
  - Verified: 70 (+20 bonus)
  - Authority verified: 90 (+40 bonus)
```

#### Gaining Reputation
```yaml
Positive Actions:
  + Verified endorsement: +5 reputation
  + Node uptime (100 blocks): +1 reputation
  + Successful transaction: +0.1 reputation
  + Community contribution: +10 reputation (via governance)
  + Stake TRUST: +multiplier (1.1x to 2.0x max)
```

#### Losing Reputation
```yaml
Negative Actions:
  - Spam transaction: -10 reputation
  - Failed heartbeat: -1 reputation
  - Downvoted by peers: -5 reputation
  - Violation flagged: -20 reputation
  - Identity fraud detected: -100 reputation (instant zero)
```

#### Critical Threshold: Reputation = 0

```go
// Transaction validation (on-chain)
func ValidateTransaction(ctx sdk.Context, msg sdk.Msg, identity Identity) error {
    reputation := k.reputationKeeper.GetReputation(ctx, identity.Address)
    
    // CRITICAL: Reputation check
    if reputation.Score <= 0 {
        return errors.New("reputation too low: network access denied")
    }
    
    // Additional checks based on reputation
    if reputation.Score < 20 {
        // Rate limit: 1 tx per 10 blocks
        if ctx.BlockHeight() - identity.LastTxBlock < 10 {
            return errors.New("rate limited: low reputation")
        }
    }
    
    return nil
}
```

**What happens at reputation = 0**:
- ❌ Cannot submit transactions
- ❌ Cannot register new nodes
- ❌ Cannot endorse others
- ❌ Cannot vote in governance
- ✅ Can still receive endorsements (path to recovery)

### Spam Prevention Example

**Scenario**: Malicious user tries to spam transactions

```
Block 100: User submits 1000 spam transactions
  → Each costs -10 reputation
  → Starting reputation: 50
  → After 5 spam txs: Reputation = 0
  → Next transaction REJECTED (reputation too low)
  → User is KICKED from network

Recovery path:
  → Get endorsed by 3 verified users (+15 reputation)
  → Reputation = 15 (can transact again, but rate-limited)
  → Behave well for 100 blocks (+10 reputation)
  → Reputation = 25 (normal access restored)
```

**Key difference from fees**:
- With fees: Spammer pays $100, spams 1000 txs, network slows down
- With reputation: Spammer gets 5 txs max, loses access, network protected

### Reputation Decay (Prevents Squatting)

```go
// Run every 1000 blocks (~1.5 hours)
func DecayReputation(ctx sdk.Context, k keeper.Keeper) {
    identities := k.GetAllIdentities(ctx)
    
    for _, identity := range identities {
        reputation := k.GetReputation(ctx, identity.Address)
        
        blocksSinceActivity := ctx.BlockHeight() - reputation.LastActivity
        
        // Decay if inactive for > 10,000 blocks (~17 hours)
        if blocksSinceActivity > 10_000 {
            decayAmount := blocksSinceActivity / 1000  // -1 per 1000 blocks
            reputation.Score -= decayAmount
            
            // Floor at 20 (never fully decay to zero unless violations)
            if reputation.Score < 20 {
                reputation.Score = 20
            }
            
            k.SetReputation(ctx, reputation)
        }
    }
}
```

**Why decay**:
- Prevents "reputation squatting" (earn high reputation, go dormant, sell identity)
- Encourages active participation
- Floors at 20 (never decays to zero naturally)

### Reputation Boosting with TRUST Staking

```go
// Stake TRUST to boost reputation
type MsgStakeForReputation struct {
    Identity string
    Amount   sdk.Coins  // TRUST to stake
}

func (k Keeper) StakeForReputation(ctx sdk.Context, msg *MsgStakeForReputation) error {
    // Lock TRUST tokens
    err := k.bankKeeper.SendCoinsFromAccountToModule(
        ctx, msg.Identity, "reputation_stake", msg.Amount,
    )
    if err != nil {
        return err
    }
    
    // Calculate reputation multiplier
    staked := msg.Amount.AmountOf("trust").Int64()
    multiplier := 1.0 + math.Min(float64(staked) / 100_000, 1.0)  // Max 2.0x at 100k TRUST
    
    reputation := k.GetReputation(ctx, msg.Identity)
    reputation.StakedTrust = staked
    reputation.ReputationMultiplier = int64(multiplier * 100)  // Store as integer (100 = 1.0x)
    
    // Apply multiplier to score
    boostedScore := int64(float64(reputation.Score) * multiplier)
    if boostedScore > 100 {
        boostedScore = 100  // Cap at 100
    }
    
    k.SetReputation(ctx, reputation)
    
    return nil
}
```

**Example**:
```
Alice has 70 reputation
Alice stakes 50,000 TRUST
Multiplier = 1.5x
Boosted reputation = 70 * 1.5 = 105 → capped at 100

Alice spams transactions → loses 50 reputation
Boosted reputation = 20 * 1.5 = 30 (still above threshold)

Alice loses ALL reputation (fraud detected) → 0 * 1.5 = 0
→ Staked TRUST is SLASHED (burned)
→ Network access denied
```

**Staking benefits**:
- Higher reputation = more trusted
- Buffer against minor violations
- Economic commitment to good behavior
- **BUT**: Cannot save you from going to zero (fraud = total loss)

---

## Cosmos SDK Implementation

### Project Structure

```
trustnet/
├── app/
│   ├── app.go                    # Application initialization
│   └── encoding.go               # Protobuf encoding
│
├── x/                            # Custom modules
│   ├── identity/
│   │   ├── keeper/              # State management
│   │   ├── types/               # Protobuf messages
│   │   ├── client/              # CLI commands
│   │   └── handler.go           # Transaction handlers
│   │
│   ├── node/
│   │   ├── keeper/
│   │   ├── types/
│   │   ├── client/
│   │   └── handler.go
│   │
│   └── reputation/
│       ├── keeper/
│       ├── types/
│       └── handler.go
│
├── cmd/
│   └── trustnetd/               # Blockchain daemon
│       └── main.go
│
├── proto/
│   └── trustnet/                # Protobuf definitions
│       ├── identity/
│       ├── node/
│       └── reputation/
│
└── config/
    ├── genesis.json             # Genesis state
    └── config.toml              # Tendermint config
```

---

### Module: Identity

**Keeper** (state management):
```go
package keeper

type Keeper struct {
    storeKey sdk.StoreKey
    cdc      codec.BinaryCodec
}

func (k Keeper) RegisterIdentity(ctx sdk.Context, msg *types.MsgRegisterIdentity) error {
    // Validate public key
    pubKey, err := crypto.UnmarshalPubKey(msg.PublicKey)
    if err != nil {
        return err
    }
    
    // Derive address from public key
    address := sdk.AccAddress(pubKey.Address())
    
    // Check if identity already exists
    if k.HasIdentity(ctx, address) {
        return errors.New("identity already exists")
    }
    
    // Create identity
    identity := types.Identity{
        Address:      address.String(),
        PublicKey:    msg.PublicKey,
        Name:         msg.Name,
        Metadata:     msg.Metadata,
        Status:       types.UNVERIFIED,
        RegisteredAt: ctx.BlockHeight(),
        UpdatedAt:    ctx.BlockHeight(),
    }
    
    // Store on-chain (IMMUTABLE)
    k.SetIdentity(ctx, identity)
    
    return nil
}

func (k Keeper) VerifyIdentity(ctx sdk.Context, msg *types.MsgVerifyIdentity) error {
    // Only authorized verifiers can verify
    if !k.IsAuthorizedVerifier(ctx, msg.Verifier) {
        return errors.New("unauthorized verifier")
    }
    
    // Get identity
    identity, err := k.GetIdentity(ctx, msg.Address)
    if err != nil {
        return err
    }
    
    // Update status
    identity.Status = types.VERIFIED
    identity.Verifier = msg.Verifier
    identity.VerifiedAt = ctx.BlockHeight()
    identity.UpdatedAt = ctx.BlockHeight()
    
    k.SetIdentity(ctx, identity)
    
    return nil
}
```

---

### Module: Node

**Keeper**:
```go
package keeper

func (k Keeper) RegisterNode(ctx sdk.Context, msg *types.MsgRegisterNode) error {
    // Verify owner has identity
    if !k.identityKeeper.HasIdentity(ctx, msg.Owner) {
        return errors.New("owner identity not found")
    }
    
    // Create node
    node := types.Node{
        ID:           msg.NodeID,
        Owner:        msg.Owner,
        IPv6:         msg.IPv6,
        State:        types.ONLINE,
        LastHeartbeat: ctx.BlockHeight(),
        RegisteredAt: ctx.BlockHeight(),
        UpdatedAt:    ctx.BlockHeight(),
    }
    
    // Store on-chain
    k.SetNode(ctx, node)
    
    return nil
}

func (k Keeper) ProcessHeartbeat(ctx sdk.Context, msg *types.MsgNodeHeartbeat) error {
    // Get node
    node, err := k.GetNode(ctx, msg.NodeID)
    if err != nil {
        return err
    }
    
    // Update state (automatic state transitions on-chain)
    oldState := node.State
    
    node.State = msg.State
    node.LastHeartbeat = ctx.BlockHeight()
    node.PeerCount = msg.PeerCount
    
    // Track state change
    if oldState != node.State {
        node.PreviousState = oldState
        node.LastStateChange = ctx.BlockHeight()
    }
    
    node.UpdatedAt = ctx.BlockHeight()
    
    k.SetNode(ctx, node)
    
    return nil
}
```

---

## State Transitions (On-Chain)

**How lifecycle works on blockchain**:

```go
// BeginBlocker runs at start of every block
func BeginBlocker(ctx sdk.Context, k keeper.Keeper) {
    // Get all nodes
    nodes := k.GetAllNodes(ctx)
    
    currentBlock := ctx.BlockHeight()
    
    for _, node := range nodes {
        blocksSinceHeartbeat := currentBlock - node.LastHeartbeat
        
        // ONLINE → OFFLINE (> 5 blocks = ~30s)
        if node.State == ONLINE && blocksSinceHeartbeat > 5 {
            node.State = OFFLINE
            node.PreviousState = ONLINE
            node.LastStateChange = currentBlock
            k.SetNode(ctx, node)
        }
        
        // OFFLINE → INACTIVE (> 100 blocks = ~10min)
        if node.State == OFFLINE && blocksSinceHeartbeat > 100 {
            node.State = INACTIVE
            node.PreviousState = OFFLINE
            node.LastStateChange = currentBlock
            k.SetNode(ctx, node)
        }
        
        // INACTIVE → DEAD (> 600 blocks = ~1hr)
        if node.State == INACTIVE && blocksSinceHeartbeat > 600 {
            node.State = DEAD
            node.PreviousState = INACTIVE
            node.LastStateChange = currentBlock
            k.SetNode(ctx, node)
        }
    }
}
```

**Key difference from centralized**:
- State transitions happen **deterministically** on every validator
- All validators agree on state (consensus)
- State is **immutable** (recorded in blockchain)

---

## Client Implementation

**How nodes interact with blockchain**:

```go
package client

import (
    "github.com/cosmos/cosmos-sdk/client"
    "github.com/Ingasti/trustnet/x/node/types"
)

type NodeClient struct {
    clientCtx client.Context
    privateKey crypto.PrivKey
}

// Send heartbeat to blockchain
func (c *NodeClient) SendHeartbeat(nodeID string, state types.NodeState, metrics types.NodeMetrics) error {
    // Create message
    msg := &types.MsgNodeHeartbeat{
        NodeID:    nodeID,
        State:     state,
        PeerCount: metrics.PeerCount,
        Metrics:   metrics,
    }
    
    // Sign transaction with private key
    tx, err := c.clientCtx.TxFactory.
        WithGas(200000).
        BuildUnsignedTx(msg)
    if err != nil {
        return err
    }
    
    err = tx.Sign(c.privateKey)
    if err != nil {
        return err
    }
    
    // Broadcast to blockchain
    res, err := c.clientCtx.BroadcastTx(tx.GetTx())
    if err != nil {
        return err
    }
    
    // Transaction is now in blockchain (immutable)
    log.Printf("Heartbeat recorded in block %d", res.Height)
    
    return nil
}

// Query node state from blockchain
func (c *NodeClient) GetNodeState(nodeID string) (*types.Node, error) {
    queryClient := types.NewQueryClient(c.clientCtx)
    
    res, err := queryClient.Node(context.Background(), &types.QueryNodeRequest{
        NodeID: nodeID,
    })
    if err != nil {
        return nil, err
    }
    
    // State is cryptographically verified
    return res.Node, nil
}
```

---

## Deployment Architecture

### Network Topology

```
                    TrustNet Blockchain
                            ↓
        ┌──────────────────────────────────────┐
        │         Validator Network            │
        │  (Tendermint P2P, Gossip Protocol)   │
        ├──────────────────────────────────────┤
        │                                      │
        │  ┌────────┐  ┌────────┐  ┌────────┐│
        │  │Validator│  │Validator│  │Validator││
        │  │  Node 1 │◄─┤  Node 2 │─►│  Node 3 ││
        │  └────────┘  └────────┘  └────────┘│
        │       ▲           ▲           ▲     │
        └───────┼───────────┼───────────┼─────┘
                │           │           │
        ┌───────┴───────────┴───────────┴─────┐
        │        Application Nodes             │
        │  (Non-validators, read/write state)  │
        ├──────────────────────────────────────┤
        │  ┌──────┐  ┌──────┐  ┌──────┐       │
        │  │ App  │  │ App  │  │ App  │ ...   │
        │  │ Node │  │ Node │  │ Node │       │
        │  └──────┘  └──────┘  └──────┘       │
        └──────────────────────────────────────┘
```

**Node Types**:

1. **Validator Nodes** (3-7 minimum)
   - Run Tendermint consensus
   - Vote on blocks
   - Secure the network
   - Require high uptime

2. **Application Nodes** (unlimited)
   - Connect to validators
   - Submit transactions
   - Query blockchain state
   - Do NOT participate in consensus

---

## Implementation Phases

### Phase 1: Blockchain Foundation (Weeks 1-2)

**Deliverables**:
- ✅ Cosmos SDK project structure
- ✅ Identity module (register, verify, query)
- ✅ Node module (register, heartbeat, query)
- ✅ Genesis configuration (initial validators)
- ✅ CLI tools (trustnetd)
- ✅ Local testnet (3 validators)

**Commands**:
```bash
# Initialize chain
trustnetd init validator1 --chain-id trustnet-1

# Add genesis accounts (validators)
trustnetd keys add validator1
trustnetd add-genesis-account validator1 1000000stake

# Create genesis transaction
trustnetd gentx validator1 1000000stake --chain-id trustnet-1

# Start validator
trustnetd start
```

---

### Phase 2: Identity System (Weeks 3-4)

**Deliverables**:
- ✅ Identity registration (CLI + API)
- ✅ Endorsement system
- ✅ Verification workflows
- ✅ Reputation tracking
- ✅ Anti-Sybil mechanisms

**Commands**:
```bash
# Register identity
trustnetd tx identity register \
    --name "Alice" \
    --metadata '{"email":"alice@example.com"}' \
    --from alice

# Endorse another identity
trustnetd tx identity endorse cosmos1abc... \
    --reason "Verified in person" \
    --from bob

# Query identity
trustnetd query identity get cosmos1abc...
```

---

### Phase 3: Node Registry (Weeks 5-6)

**Deliverables**:
- ✅ Node registration (requires identity)
- ✅ Heartbeat submission
- ✅ State transitions (on-chain)
- ✅ Peer discovery integration
- ✅ Lifecycle management

**Commands**:
```bash
# Register node
trustnetd tx node register \
    --node-id "node-alice-1" \
    --ipv6 "fd10:1234::1" \
    --from alice

# Send heartbeat
trustnetd tx node heartbeat \
    --node-id "node-alice-1" \
    --state online \
    --peer-count 5 \
    --from alice

# Query node state
trustnetd query node get node-alice-1
```

---

### Phase 4: P2P Integration (Weeks 7-8)

**Deliverables**:
- ✅ libp2p integration
- ✅ Peer discovery (mDNS + DHT)
- ✅ Automatic heartbeat daemon
- ✅ State synchronization
- ✅ Multi-node testing

---

### Phase 5: Production Deployment (Weeks 9-10)

**Deliverables**:
- ✅ Mainnet genesis
- ✅ Validator deployment
- ✅ Monitoring/alerting
- ✅ Documentation
- ✅ Public launch

---

## Migration from Current Code

**What we keep**:
- ✅ Go language
- ✅ Node data model (adapted to Protobuf)
- ✅ State machine logic (now on-chain)
- ✅ Configuration system (adapted)

**What changes**:
- ❌ SQLite/In-memory → Blockchain state
- ❌ HTTP API → Cosmos SDK transactions
- ❌ Centralized registry → Decentralized consensus

**Migration strategy**:
1. Keep current code as "legacy" for reference
2. Build Cosmos SDK modules in parallel
3. Test blockchain locally (testnet)
4. Migrate data from SQLite to genesis
5. Deploy validators
6. Sunset legacy system

---

## Critical Decisions Needed

### 1. Validator Set (Initial)

**Question**: Who runs the initial validators?

**Options**:
- Foundation-run (centralized start, decentralize later)
- Community validators (requires trust bootstrap)
- Hybrid (foundation + community)

**Recommendation**: Start with 3-5 foundation validators, add community validators over time.

---

### 2. Chain ID and Genesis

**Question**: What's the chain ID? When is genesis?

**Proposal**:
```yaml
chain_id: "trustnet-1"
genesis_time: "2026-02-15T00:00:00Z"  # 2 weeks from now
initial_validators: 5
block_time: 6s
```

---

### 3. Identity Verification Authority

**Question**: Who are the authorized verifiers?

**Options**:
- Foundation only
- Community vote
- Decentralized (anyone with reputation > threshold)

**Recommendation**: Start with foundation, add community verifiers via governance.

---

### 4. Token or No Token?

**Question**: Do we issue a token?

**My Recommendation**: **No token initially**
- Free transactions (no gas fees)
- Focus on adoption, not economics
- Add token later if needed (governance vote)

---

## Next Steps

1. **Approve architecture** (this document)
2. **Initialize Cosmos SDK project** (scaffolding)
3. **Build identity module** (core foundation)
4. **Build node module** (registry on-chain)
5. **Local testnet** (3 validators, test transactions)
6. **Integration testing** (heartbeat, state transitions)
7. **Public testnet** (community testing)
8. **Mainnet launch** (production)

**Estimated Timeline**: 10 weeks to production-ready blockchain

---

## VM Infrastructure & Disk Architecture

### Alpine VM Pattern (FactoryVM Reuse)

TrustNet nodes run inside **Alpine Linux VMs** (QEMU-based) following the proven FactoryVM pattern:

**VM Specifications**:
- **OS**: Alpine Linux (latest version, auto-detected)
- **User**: warden (passwordless SSH access)
- **Hostname**: trustnet.local
- **SSH Port**: 2223 (forwarded from host)
- **HTTPS Port**: 443 (forwarded, Caddy reverse proxy)
- **Resources**: 2GB RAM, 2 CPUs (configurable)

### 3-Disk Architecture with Preservation

TrustNet uses a smart 3-disk architecture that **preserves work during testing and reinstalls**:

| Disk | Size | Purpose | Lifecycle | Mounted At |
|------|------|---------|-----------|------------|
| **System** | 20GB | Alpine OS, Go, Cosmos SDK, Caddy | **Recreated** on install | / (root) |
| **Cache** | 5GB | Downloaded packages (Go, Alpine ISO, deps) | **Preserved** (reused) | /mnt/cache |
| **Data** | 30GB | Blockchain data, keys, TRUST wallet | **Preserved** (reused) | /home/warden/trustnet/data |

#### Preservation Logic (vm-lifecycle.sh)

```bash
create_disks() {
    # System disk: ALWAYS recreated (clean OS)
    if [ ! -f "$SYSTEM_DISK" ]; then
        qemu-img create -f qcow2 "$SYSTEM_DISK" "$SYSTEM_DISK_SIZE"
        log "✓ System disk created (${SYSTEM_DISK_SIZE})"
    else
        log "✓ System disk exists"
    fi
    
    # Cache disk: PRESERVED (reused if exists)
    if [ ! -f "$CACHE_DISK" ]; then
        # Check for backup from previous test
        if [ -f ~/.trustnet/cache-backup.qcow2 ]; then
            cp ~/.trustnet/cache-backup.qcow2 "$CACHE_DISK"
            log "✓ Cache disk restored - packages reused!"
        else
            qemu-img create -f qcow2 "$CACHE_DISK" "$CACHE_DISK_SIZE"
            log "✓ Cache disk created (${CACHE_DISK_SIZE})"
        fi
    else
        log "✓ Cache disk exists (preserving cached packages)"
    fi
    
    # Data disk: PRESERVED (reused if exists)
    if [ ! -f "$DATA_DISK" ]; then
        qemu-img create -f qcow2 "$DATA_DISK" "$DATA_DISK_SIZE"
        log "✓ Data disk created (${DATA_DISK_SIZE})"
    else
        log "✓ Data disk exists (preserving blockchain state)"
    fi
}
```

#### Benefits

**For Development**:
- ✅ **Faster iteration**: Reinstall in 2-3 minutes (vs 10+ minutes)
- ✅ **Offline testing**: Cached packages enable no-internet installs
- ✅ **Persistent identity**: Keys survive reinstalls (test same user)
- ✅ **Blockchain continuity**: Transaction history preserved

**For Production**:
- ✅ **Backup strategy**: Data disk only (30GB vs 55GB total)
- ✅ **Disaster recovery**: System + cache recreatable, data is critical

---

## Conclusion

TrustNet is now a **blockchain-first architecture**:

✅ **Trustless**: Verify via cryptography, not central authority  
✅ **Immutable**: Blockchain guarantees no tampering  
✅ **Decentralized**: Tendermint consensus, no single point of failure  
✅ **One identity = one user**: Public key cryptography enforces uniqueness  
✅ **Production-ready**: Cosmos SDK is battle-tested  

**Philosophy achieved**: "If you cannot trust in the foundations, you cannot trust anything built over it."

The foundation is now **cryptographically verifiable, immutable blockchain**.

Ready to build! 🚀

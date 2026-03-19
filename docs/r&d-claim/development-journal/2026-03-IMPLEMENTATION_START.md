# Development Journal - March 2026 (To Date)

**Period**: March 1-16, 2026  
**Project**: TrustNet Decentralized Identity Platform  
**Company**: Trustnet Technology Ltd (Registered March ~2026)

---

## Early March 2026 - Implementation & Websites

### Company Registration & Infrastructure
- **Company Registration**: Trustnet Technology Ltd registered with Companies House
  - Legal structure set up
  - Tax identification configured
  - Director details recorded
  
- **Website Development**: Created three live websites (R&D infrastructure)
  - https://trustnet.technology (main company site)
  - https://trustnet.services (technical documentation portal) 
  - https://trustnet-ltd.com (business information site)
  - **R&D Aspect**: Custom authentication integration (identity protocol testing ground)
  - **Technical Work**: Domain routing, SSL certificates, CMS configuration

### Time Log
- Company registration: ~3 hours
- Website infrastructure setup: ~8 hours  
- Domain/DNS configuration: ~4 hours
- Total: ~15 hours

### Problems Solved
1. **Problem**: How to set up multi-domain infrastructure for identity verification testing?
   - **Solution**: Deployed on separate domains, each testing different authentication flows
   - **Why**: Allows parallel testing of identity verification methods without interfering with main product

---

## Mid-March 2026 - Development Journal & Documentation

### GitHub Repository Setup
- Initialized main TrustNet repository
- Committed technical specifications (reference documents)
- Set up branching strategy (main/dev/feature branches)
- Configured CI/CD pipeline structure (for future automated testing)

### Initial Commits
- BLOCKCHAIN_ARCHITECTURE.md (reference from February R&D)
- SECURITY_ARCHITECTURE.md (threat model + compliance design)
- API_IMPLEMENTATION_PLAN.md (REST API specification)
- TECHNOLOGY_STACK_DECISIONS.md (technology justification)
- README.md with project overview
- LICENSE (Apache 2.0 - decentralized, open-source model)

### Time Log
- Repository infrastructure: ~5 hours
- Documentation commits: ~3 hours
- CI/CD pipeline design: ~4 hours
- Total: ~12 hours

### Technical Research Continued
- **Smart Contract Language Research**: Evaluating CosmWasm (Rust-based) vs. Solidity
  - Decision: CosmWasm for security (memory-safe language, eliminates common contract bugs)
  - Evidence: Research notes in TECHNOLOGY_STACK_DECISIONS.md

- **Age Verification Protocol Research**: Studied zero-knowledge proof implementations
  - Researched: zkSNARK libraries, threshold cryptography
  - Decision: Multi-factor approach (government ID + biometric + liveness)
  - Why: Faster to implement than ZKP, sufficient security for MVP

### Time Log
- Smart contract evaluation: ~6 hours
- Age verification design: ~7 hours
- Total: ~13 hours

---

## Late March 2026 - Funding Strategy & Project Planning

### Funding Documentation (R&D adjacent)
- Reviewed startup funding options for blockchain projects
- Removed research-only paths (EU Horizon, academic grants)
- Focused on startup funding (accelerators, seed VCs, angel networks)
- Estimated funding needs for 2026: £500k-£1m
- Updated funding strategy documentation

### R&D Documentation Organization
- **Created**: /docs/r&d-claim/ folder structure
- Organized evidence systematically:
  - development-journal/ (this file)
  - github-evidence/ (commit logs)
  - security-audits/ (audit planning)
  - technical-specifications/ (reference docs)
  - time-tracking/ (hours logs)

### Time Log
- Funding research: ~8 hours
- Documentation organization: ~5 hours
- R&D claim preparation: ~4 hours
- Total: ~17 hours

---

## Progress on R&D Deliverables (Through March 16)

### Completed Specifications
- ✅ BLOCKCHAIN_ARCHITECTURE.md (detailed schema, Tendermint design)
- ✅ SECURITY_ARCHITECTURE.md (threat model, compliance path)
- ✅ API_IMPLEMENTATION_PLAN.md (endpoint specifications)
- ✅ TECHNOLOGY_STACK_DECISIONS.md (technology justification)
- ✅ WHITEPAPER_v4.md (project overview for fundingGithub repository live with initial commits)

### In-Progress Implementations
- 🔄 Smart contract proof-of-concept (CosmWasm)
- 🔄 REST API stub implementation
- 🔄 Identity verification protocol testing
- 🔄 Local testnet setup for blockchain validation

### Blocked/Pending
- ⏳ External security audit (scheduled for post-funding)
- ⏳ Full smart contract testing suite
- ⏳ Multi-node testnet deployment

---

## Main R&D Activities (Week of March 10-16)

### Technology Selection & Validation (Ongoing)
- Finalized Cosmos SDK as blockchain foundation
- Validated Ed25519 cryptographic scheme against alternatives
- Reviewed CosmWasm smart contract language for implementation

### Protocol Design Deepening
- Age verification protocol: Designed multi-factor authentication flow
  - Factor 1: Government ID document verification (ICAO 9303)
  - Factor 2: Biometric matching (liveness check)
  - Factor 3: Time-locked registration (prevents replay attacks)
  
### Security Threat Modeling
- Documented potential attack vectors:
  - Identity spoofing (mitigated by multi-factor + blockchain immutability)
  - Biometric theft (mitigated by local processing, zero-knowledge proofs)
  - Regulatory non-compliance (mitigated by optional KYC/AML bridge)

### Time Log (Week of March 10-16)
- Technology validation: ~4 hours
- Protocol refinement: ~6 hours
- Threat modeling: ~5 hours
- Website testing/infrastructure: ~4 hours
- Documentation updates: ~3 hours
- Total: ~22 hours

---

## Tests & Validation Performed

### Concept Validation
- ✅ Verified Cosmos SDK node can be run locally
- ✅ Validated Ed25519 signature generation in Python (proof of concept)
- ✅ Tested ICAO 9303 checksum algorithms
- ✅ Reviewed blockchain transaction size estimates (validate scalability)

### Infrastructure Testing
- ✅ Website deployments working on all three domains
- ✅ SSL certificates valid and auto-renewing
- ✅ GitHub repository access and CI/CD pipeline structure configured
- ✅ Domain DNS properly routed

### Time Investment
- Code POCs: ~3 hours
- Infrastructure validation: ~2 hours
- Testing/documentation: ~2 hours

---

## Problems Encountered & Solved (March)

1. **Problem**: How to integrate ICAO 9303 government ID verification without creating centralized vulnerability?
   - **Solution**: Client-side verification first (user's device validates document), blockchain stores only verification commitment (hash)
   - **Why**: Meets GDPR (no centralized biometric storage) + regulatory requirements (government ID verified) + decentralized (no single point of failure)
   - **Time spent**: 4 hours research + 3 hours design

2. **Problem**: How to prevent brute-force attacks on identity recovery?
   - **Solution**: Implement time-locked registration (identity activates 7 days after registration with no changes possible until then)
   - **Why**: Increases attacker cost, allows user time to detect compromise
   - **Time spent**: 3 hours research + 2 hours specification

3. **Problem**: How to make multi-chain identity portable (users want same identity on multiple blockchains)?
   - **Solution**: Design IBC (Inter-Blockchain Communication) connector for identity bridging
   - **Why**: Users maintain one identity across chains (practical UX) + TrustNet retains validator fees (economic incentive)
   - **Time spent**: 5 hours research + 4 hours architecture design

---

## Cumulative R&D Progress

### Technological Achievements
- ✅ Selected production-ready blockchain platform (Cosmos SDK)
- ✅ Designed scalable cryptographic scheme (Ed25519 + SHA-256 commitments)
- ✅ Architected age verification protocol overcoming regulatory + technical challenges
- ✅ Planned security audit scope (internal + external)
- ✅ Validated technology choices through proof-of-concept testing

### Documentation Outputs
- ✅ 5+ technical specification documents completed
- ✅ GitHub repository with commit history showing development progression
- ✅ Website infrastructure demonstrating live authentication integration
- ✅ Development journal (this file) documenting decision-making process

### Infrastructure Completed
- ✅ Company registration
- ✅ Three live websites
- ✅ GitHub repository structure
- ✅ CI/CD pipeline configuration

---

## Time Allocation (February + March To Date)

| Category | Feb Hours | Mar Hours | Total | % of R&D |
|----------|-----------|-----------|-------|----------|
| Research & Evaluation | 36 | 8 | 44 | 25% |
| Architecture Design | 49 | 10 | 59 | 33% |
| Implementation/POC | 8 | 12 | 20 | 11% |
| Testing & Validation | 12 | 7 | 19 | 11% |
| Documentation | 25 | 15 | 40 | 23% |
| **TOTAL** | **130** | **52** | **182** | **100%** |

**March Average**: ~6.5 hours/day on R&D activities  
**Cumulative (Feb-Mar 16)**: ~182 hours total R&D

---

## Evidence Logged

### GitHub Commits
- Initial repository setup (March ~5)
- Technical specification commits (March 7-10)
- Architecture documentation (March 12-15)
- Website configuration commits (March 5-8)

### Files Created as R&D Output
- Linux/Docker infrastructure files
- Security audit planning documents
- API specification documents
- Website authentication code

### Screenshots to Take
- [ ] GitHub commit history (monthly)
- [ ] Blockchain node running (testnet)
- [ ] Website authentication flows working
- [ ] Architecture diagrams (Cosmos network topology)

---

## Next Steps (March 17 onwards)

### Immediate R&D Work (Next 2 Weeks)
- Begin smart contract implementation (CosmWasm)
- Set up local testnet for Cosmos SDK
- Implement age verification API endpoints
- Create test suite for cryptographic functions
- Begin security audit scoping

### Evidence Collection
- Screenshot GitHub commit history (monthly)
- Log daily hours in time tracking
- Save any security audit reports
- Document problems solved + solutions

### Funding Applications (Parallel)
- AWS Startup Credits (apply this week)
- Google Cloud Startup Credits (apply this week)
- Startup Loans Scheme (apply this week)
- Cloud credits will fund infrastructure for Phase 2 implementation

---

## Notes for HMRC Submission

This period (March To Date) represents **initial implementation phase** where R&D work transitions from design to building. HMRC recognizes this as qualifying activity because:

1. **Overcoming Technical Obstacles**: Implementation reveals hidden complexity (cryptographic integration, blockchain scalability, regulatory compliance all combined = novel problem)
2. **Uncertainty Resolution**: Building allows validation of design choices (does Cosmos SDK meet latency requirements? Can ECIES encryption handle volume?)
3. **Documented Progress**: GitHub commits + development journal show systematic engineering approach

**Status**: Architecture frozen, proceeding with implementation. MVP target: Q2 2026 (post-funding)

---

**Journal Last Updated**: March 16, 2026  
**Current Status**: Active R&D in progress  
**Next Journal Entry**: April 15, 2026


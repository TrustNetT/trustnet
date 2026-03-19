# Technical Specifications Reference

**Purpose**: Link R&D evidence to technical specification files  
**Status**: Specifications completed (February-March 2026)

---

## R&D Output Documents (Evidence of Work)

All of these files represent **R&D work** that demonstrates technological innovation and problem-solving. Each file is tracked in GitHub (evidence of development).

### Core Technical Specifications Created

#### 1. BLOCKCHAIN_ARCHITECTURE.md
- **Location**: `docs/architecture/BLOCKCHAIN_ARCHITECTURE.md`
- **R&D Value**: Foundation of entire project
- **What it shows HMRC**:
  - Technical decision-making (why Cosmos SDK vs. alternatives)
  - Innovative design (commitment scheme for privacy)
  - Scalability analysis (bandwidth, transaction throughput)
  - Consensus mechanism justification (Tendermint BFT)
- **Hours Invested**: ~15 hours research + 10 hours specification
- **GitHub Evidence**: File created/updated in commits

#### 2. SECURITY_ARCHITECTURE.md
- **Location**: `docs/security/SECURITY_ARCHITECTURE.md`
- **R&D Value**: Demonstrates security R&D work (15% of hours)
- **What it shows HMRC**:
  - Threat model (10+ attack vectors identified)
  - Mitigation strategies (technical solutions)
  - Regulatory compliance design (GDPR, Online Safety Bill, ICAO 9303)
  - Innovation (novel solutions to privacy + decentralization tension)
- **Hours Invested**: ~12 hours research + 8 hours specification
- **GitHub Evidence**: Comprehensive threat analysis in file

#### 3. API_IMPLEMENTATION_PLAN.md
- **Location**: `docs/technical/API_IMPLEMENTATION_PLAN.md`
- **R&D Value**: Shows interface design R&D
- **What it shows HMRC**:
  - API contract specifications (REST endpoints)
  - Authentication/verification flow design
  - Integration patterns with blockchain
  - Error handling and edge cases
- **Hours Invested**: ~8 hours research + 6 hours specification
- **GitHub Evidence**: Technical design visible in commit

#### 4. TECHNOLOGY_STACK_DECISIONS.md
- **Location**: `docs/technical/TECHNOLOGY_STACK_DECISIONS.md`
- **R&D Value**: **Most important for HMRC** - shows technology evaluation
- **What it shows HMRC**:
  - Alternatives evaluated (Ethereum vs. Polkadot vs. Cosmos)
  - Selection rationale (why each chosen/rejected)
  - Technical justification (performance, security, decentralization)
  - Innovation identified (commitment scheme, IBC bridging)
- **Hours Invested**: ~20 hours evaluation + 10 hours documentation
- **GitHub Evidence**: Comparative analysis in file

#### 5. WHITEPAPER_v4.md
- **Location**: `docs/strategy/WHITEPAPER_v4.md`
- **R&D Value**: Market/problem understanding
- **What it shows HMRC**:
  - Problem identification (14.5M undocumented, youth protection gap)
  - Solution architecture (decentralized identity)
  - Market analysis (TAM for identity verification)
  - Technical innovation (age verification without data storage)
- **Hours Invested**: ~15 hours research + 12 hours writing
- **GitHub Evidence**: Comprehensive research document

#### 6. BUSINESS_MODEL.md
- **Location**: `docs/strategy/BUSINESS_MODEL.md`
- **R&D Value**: Commercial R&D (market analysis, regulatory path)
- **What it shows HMRC**:
  - Revenue streams (SaaS hosting, transaction fees, token)
  - Regulatory alignment (KYC/AML, GDPR)
  - Competitive analysis (vs. centralized identity providers)
  - Scalability plan (how to monetize R&D outputs)
- **Hours Invested**: ~10 hours research + 8 hours specification
- **GitHub Evidence**: Business logic specification

---

## How These Link to R&D Tax Relief

### HMRC Wants to Know:
1. **What technical problem were you solving?** → Reference 1-4 above
2. **How complex was it?** → Compare alternatives in TECHNOLOGY_STACK_DECISIONS.md
3. **What's your evidence?** → GitHub commits + these files
4. **Did you overcome uncertainty?** → Threat model, design iterations, decisions documented

### Using These Specs in Your Claim:

#### If HMRC asks: _"What technical innovation did you implement?"_
**Response**: "We designed a decentralized identity system using Cosmos SDK blockchain with commitment-based privacy. See BLOCKCHAIN_ARCHITECTURE.md for architecture details and TECHNOLOGY_STACK_DECISIONS.md for why we selected this tech stack over alternatives like Ethereum or Polkadot."

#### If HMRC asks: _"Why did you spend 40 hours on research?"_
**Response**: "Evaluating blockchain platforms for identity verification revealed technical tradeoffs. Cosmos SDK's Tendermint consensus provides instant finality needed for identity verification, while supporting custom modules for age gating and KYC/AML bridge. See TECHNOLOGY_STACK_DECISIONS.md for full evaluation matrix."

#### If HMRC asks: _"Is this really R&D or just routine development?"_
**Response**: "This is application of novel cryptographic patterns to a new domain. We're using commitment schemes (SHA-256 hashing with salts) instead of traditional encryption to provide privacy while enabling decentralized verification. This pattern doesn't appear in standard codebases. See SECURITY_ARCHITECTURE.md threat model and BLOCKCHAIN_ARCHITECTURE.md technical specification."

---

## Organizing Evidence for HMRC

### File Your Specs Into These Categories:

**Innovation** (proves technological advancement):
- TECHNOLOGY_STACK_DECISIONS.md (tech evaluation)
- BLOCKCHAIN_ARCHITECTURE.md (novel arch)
- SECURITY_ARCHITECTURE.md (novel threat mitigation)

**Complexity** (proves it's not routine):
- API_IMPLEMENTATION_PLAN.md (integration complexity)
- Threat model section of SECURITY_ARCHITECTURE.md

**Business Context** (proves it's necessary):
- WHITEPAPER_v4.md (market problem)
- BUSINESS_MODEL.md (commercial viability)

---

## Keeping Specs Updated

### When to Update Specs (Create New Versions)
- New technical decisions made (e.g., decided to add ZKP)
- Architecture changes (e.g., moved from Mainnet plan to Testnet first)
- Regulatory changes (e.g., GDPR guidance updated)
- Implementation learnings (e.g., performance targets revised)

### How to Update for R&D Evidence
1. Save new version with date: `BLOCKCHAIN_ARCHITECTURE_v2_20260415.md`
2. Document what changed and why (this IS R&D work)
3. Git commit with message: "Update architecture based on performance testing results"
4. This creates audit trail (good for HMRC)

### Don't Lose Specs
- All specs should be in GitHub (version control)
- Specs should be in `/docs/` accessible to HMRC review
- Backup copies in `/docs/r&d-claim/technical-specifications/` for claim filing

---

## Specs as Deliverables (Tangible Output)

### What Counts as R&D "Output" for HMRC
✅ **Specifications** (proof of design work)  
✅ **Code** (proof of implementation)  
✅ **Test results** (proof of validation)  
✅ **Documentation** (proof of learning + decisions)  
✅ **Architecture diagrams** (proof of design thinking)  

**These spec files = significant portion of your R&D deliverable**.

**Why HMRC values them**:
- Shows systematic engineering approach
- Demonstrates overcoming technical obstacles
- Indicates substantial time/cost invested
- Provides audit trail of decisions

---

## Linking Specs to Monthly Hours Claims

### February R&D Hours (130 total)
- Research & Evaluation: 40 hours → Evidence: TECHNOLOGY_STACK_DECISIONS.md
- Architecture Design: 49 hours → Evidence: BLOCKCHAIN_ARCHITECTURE.md
- Documentation: 25 hours → Evidence: WHITEPAPER_v4.md + BUSINESS_MODEL.md
- Testing/Infrastructure: 8 hours → Evidence: POC testing notes
- Security: 8 hours → Evidence: SECURITY_ARCHITECTURE.md

### March R&D Hours (52 total to date)
- Research: 8 hours → Evidence: Continued API research
- Architecture: 10 hours → Evidence: Updates to arch docs
- Infrastructure: 14 hours → Evidence: GitHub repo setup, website infrastructure
- Documentation: 14 hours → Evidence: Development journal (this file)
- Testing: 6 hours → Evidence: POC validation testing

**Total Specs Created**: 5-6 major documents + updates  
**Total Hours**: 180+ hours of R&D work  
**Estimated Tax Relief**: £2,000-£4,000 (depending on final hourly rate)

---

## HMRC Evidence Checklist

When submitting claim, reference these specs:

- [ ] BLOCKCHAIN_ARCHITECTURE.md — Technical innovation
- [ ] TECHNOLOGY_STACK_DECISIONS.md — Technology evaluation (overcoming uncertainty)
- [ ] SECURITY_ARCHITECTURE.md — Security R&D (threat modeling)
- [ ] API_IMPLEMENTATION_PLAN.md — Interface design complexity
- [ ] WHITEPAPER_v4.md — Problem analysis (market R&D)
- [ ] BUSINESS_MODEL.md — Commercial R&D (regulatory compliance)
- [ ] Development journal entries — Process documentation
- [ ] GitHub commits — Proof of output
- [ ] Monthly time logs — Hours allocation

**With all of these**, you have compelling R&D claim evidence.

---

## Quarterly Evidence Audit

### March 2026 (Complete ✅)
- ✅ 5+ spec documents created
- ✅ Documented in GitHub
- ✅ Development journal entries written
- ✅ 180+ hours logged

### June 2026 (Plan)
- [ ] Review specs for updates needed
- [ ] Create new specs if architecture changed
- [ ] Update API implementations based on POC learnings
- [ ] Document any new technical challenges overcome

### September 2026 (Plan)
- [ ] Full mid-year specification review
- [ ] Archive final H1 2026 specs
- [ ] Begin H2 2026 phase (implementation deepening)

### December 2026 (Plan)
- [ ] Final year-end spec review
- [ ] Compile all evidence for HMRC filing
- [ ] Prepare claim submission package

---

## Filing Tips

### When You File (April 2027)
1. **Gather all specs** → Reference them in claim
2. **Reference specific files** → "See BLOCKCHAIN_ARCHITECTURE.md section 3.2 for technical innovation"
3. **Link to GitHub** → "Versions tracked here: [GitHub repo link]"
4. **Summarize hours** → "160 hours research + 180 hours implementation = 340 hours × £45/hour"
5. **Support with evidence** → "Proof of output: GitHub commits + 5 major specification documents + monthly development journal"

### What Makes Strong HMRC Claims
Strong: "Designed blockchain consensus mechanism overcoming technical uncertainty around age verification in decentralized context"  
Weak: "Did R&D"

Strong: "See TECHNOLOGY_STACK_DECISIONS.md for evaluation of 4 blockchain platforms, final selection rationale, and performance justification"  
Weak: "We evaluated tech"

---

## Next Steps

1. **This Month**: Ensure all specs are saved in GitHub + `/docs/` folder
2. **Monthly**: Update specs if implementation reveals needed changes
3. **Quarterly**: Archive specs in dated folder for filing
4. **April 2027**: Gather all specs, reference in HMRC claim with dates/hours

---

**Last Updated**: March 16, 2026  
**Specs Status**: Complete for MVP Phase  
**Filing Reference**: April 2027


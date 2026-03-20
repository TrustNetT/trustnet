# Using Security Skills in TrustNet - Quick Start Guide

## Overview

Your TrustNet project now has:
- ✅ 300+ cybersecurity skills in `.skills/` directory
- ✅ Workspace instructions (see `copilot-instructions.md`)
- ✅ Security assessment instruction (see `.github/instructions/security-assessment.instructions.md`)
- ✅ Security skill router (see `.github/skills/trustnet-security/SKILL.md`)

## Quick Usage Examples

### Example 1: Audit a Smart Contract

**Your Request**:
```
I need to review the Token.sol contract for security vulnerabilities 
before the public launch
```

**What Happens**:
1. AI recognizes: Smart contract security task
2. Auto-loads skill: `trustnet-security` → then `analyzing-ethereum-smart-contract-vulnerabilities`
3. Provides: Vulnerability checklist, code review methodology, test cases

**AI's Response Will Include**:
- Reentrancy vulnerability analysis
- Access control pattern review
- Arithmetic overflow checks
- Storage layout verification
- Proof-of-concept test cases
- Severity scoring (CVSS)
- Remediation code samples

---

### Example 2: Test API Authorization

**Your Request**:
```
Check the /api/user/:id endpoint for IDOR vulnerabilities. 
A user should only access their own data.
```

**What Happens**:
1. AI recognizes: API security / IDOR testing
2. Auto-loads skill: `trustnet-security` → then `exploiting-idor-vulnerabilities`
3. Provides: Testing methodology, exploitation steps, verification

**AI's Response Will Include**:
- Step-by-step OAuth token capture
- User ID enumeration approach
- Authorization bypass techniques
- Evidence collection (request/response logs)
- Proof-of-concept payload
- Recommended fixes (permission validation, data filtering)

---

### Example 3: Harden Docker Configuration

**Your Request**:
```
Use skill: trustnet-security
Review our Dockerfile and docker-entrypoint.sh for production readiness
```

**What Happens**:
1. AI recognizes: Container security assessment
2. Auto-loads skill: `trustnet-security` → then `hardening-docker-containers-for-production`
3. Provides: Container security checklist, best practices, code updates

**AI's Response Will Include**:
- Base image vulnerability analysis
- User privilege elevation review
- Capability restriction recommendations
- Secrets management validation
- Layer optimization
- Supply chain verification
- Specific Dockerfile changes needed

---

### Example 4: Threat Model A New Feature

**Your Request**:
```
We're adding a marketplace feature that handles escrow payments. 
What are the security threats we need to mitigate?
```

**What Happens**:
1. AI recognizes: Threat modeling task
2. Auto-loads skill: `trustnet-security` → then `threat-modeling-with-mitre-attack`
3. Provides: MITRE ATT&CK mapping, risk assessment, control recommendations

**AI's Response Will Include**:
- Asset identification (smart contract, escrow wallet, user profiles)
- Threat actor analysis (external attacker, insider threat, protocol bugs)
- MITRE ATT&CK tactic mapping
- Attack tree visualization
- Recommended security controls per NIST CSF
- Capital allocation for controls

---

## How to Trigger Skills

### Method 1: Automatic (Recommended)
Just describe your security need naturally:

```
"Find security issues in api/routes/auth.go"
→ AI auto-loads: trustnet-security skills

"Audit the smart contract before deployment"
→ AI auto-loads: analyzing-ethereum-smart-contract-vulnerabilities

"Hardening checklist for Kubernetes deployment"
→ AI auto-loads: hardening-kubernetes-pod-security-standards
```

### Method 2: Explicit Skill Request
Reference the skill directly:

```
Use skill: trustnet-security

Then request: "Analyze Token.sol for reentrancy"
```

### Method 3: Domain-Based Request
Ask by security domain:

```
"Smart contract audit"
→ AI loads contract-specific skills

"API penetration testing"
→ AI loads: conducting-api-security-testing

"Infrastructure hardening"
→ AI loads: hardening-* skills for containers/k8s
```

---

## Available Skills by Domain

### Smart Contracts
```
Use skill: analyzing-ethereum-smart-contract-vulnerabilities
Use skill: exploiting-vulnerabilities-with-metasploit-framework
Use skill: performing-cryptographic-audit-of-application
```

### API Security
```
Use skill: conducting-api-security-testing
Use skill: testing-for-broken-object-level-authorization
Use skill: exploiting-idor-vulnerabilities
Use skill: testing-for-sql-injection-vulnerabilities
Use skill: testing-for-xss-vulnerabilities
```

### Container & Kubernetes
```
Use skill: hardening-docker-containers-for-production
Use skill: auditing-kubernetes-cluster-rbac
Use skill: implementing-network-segmentation-with-firewall-zones
```

### Cryptography & TLS
```
Use skill: configuring-tls-1-3-for-secure-communications
Use skill: implementing-aes-encryption-for-data-at-rest
Use skill: implementing-jwt-signing-and-verification
```

### Threat Modeling & Incident Response
```
Use skill: threat-modeling-with-mitre-attack
Use skill: building-incident-response-playbook
Use skill: investigating-ransomware-attack-artifacts
```

### Cloud Security
```
Use skill: auditing-aws-s3-bucket-permissions
Use skill: auditing-kubernetes-cluster-rbac
Use skill: implementing-aws-iam-permission-boundaries
```

---

## Workflow: Full Security Assessment

### Step 1: Discovery
```
"List all APIs and smart contracts in TrustNet"
→ Skill: performing-api-inventory-and-discovery
→ Output: Asset inventory
```

### Step 2: Threat Model
```
"Create a threat model for the payment escrow feature"
→ Skill: threat-modeling-with-mitre-attack
→ Output: MITRE ATT&CK mapping, asset hierarchy, attack trees
```

### Step 3: Code Review
```
"Audit the escrow smart contract"
→ Skill: analyzing-ethereum-smart-contract-vulnerabilities
→ Output: Vulnerability report with severity scores
```

### Step 4: Testing
```
"Test the /api/escrow/* endpoints for authorization flaws"
→ Skill: conducting-api-security-testing + testing-for-broken-object-level-authorization
→ Output: PoC tests, evidence, remediation recommendations
```

### Step 5: Hardening
```
"Provide Dockerfile hardening for escrow service"
→ Skill: hardening-docker-containers-for-production
→ Output: Security checklist, updated Dockerfile, verification commands
```

### Step 6: Verification
```
"Confirm all vulnerabilities are fixed"
→ Skill: performing-vulnerability-scanning-with-nessus
→ Output: Remediation confirmation report
```

---

## File Organization for Security Work

When working on security features, organize in:

```
trustnet-wip/
├── api/
│   └── contracts/
│       └── Token.sol          # Smart contract
├── core/
│   └── security/
│       ├── encryption.go      # Crypto implementations
│       └── validation.go      # Input validation
├── infrastructure/
│   ├── Dockerfile             # Container config
│   └── k8s/
│       └── pod-security.yaml  # Kubernetes security
├── .github/
│   ├── instructions/
│   │   └── security-assessment.instructions.md  # This triggers automatically
│   └── skills/
│       └── trustnet-security/
│           └── SKILL.md       # Security skill router
└── .skills/                    # 300+ cybersecurity skills reference
```

---

## Security Review Checklist Before Commit

When committing security-critical code:

```
[ ] "Run security assessment on this code"
    → AI auto-loads relevant skills

[ ] Smart contract?
    [ ] Analyzed for reentrancy
    [ ] Checked access control
    [ ] Verified arithmetic safety
    
[ ] API endpoint?
    [ ] Tested for IDOR/authorization flaws
    [ ] Validated input/output
    [ ] Checked authentication
    
[ ] Infrastructure?
    [ ] Docker hardened (non-root, minimal base)
    [ ] Kubernetes RBAC configured
    [ ] TLS 1.3 enabled
    [ ] Secrets not in code/env
```

---

## Common Issues & Solutions

### Q: How do I access specific skills?

**A**: Skills are in `.skills/[skill-name]/SKILL.md`

To use a skill:
```
"Use skill: [folder-name-from-.skills]"
Then: describe what you need
```

### Q: AI isn't triggering the security skill automatically?

**A**: Explicitly request it:
```
"Use skill: trustnet-security to analyze this code"
```

Or try:
```
"Security review needed for: [file path]"
```

### Q: Can I create custom skills for TrustNet-specific patterns?

**A**: Yes! Add to `.github/skills/` or `.skills/` with this format:
```
Skills/my-custom-skill/
├── SKILL.md          # Skill definition
├── templates/        # Code templates
└── examples/         # Example usage
```

Then reference: `"Use skill: my-custom-skill"`

### Q: How do I know which skill to use?

**A**: Describe the **problem**, not the skill:
```
INSTEAD OF:
"Use skill: analyzing-ethereum-smart-contract-vulnerabilities"

TRY THIS:
"Find security vulnerabilities in Token.sol"
→ AI auto-selects the right skill
```

---

## Integration Examples

### In Code Comments
```go
// Security: This endpoint requires IDOR testing
// Refer: exploiting-idor-vulnerabilities from .skills/
// Manual review required: Verify user_id ownership
func (h *Handler) GetUserData(userID string) {
    // Validate user owns userID
    currentUser := getCurrentUser()
    if currentUser.ID != userID {
        return nil, ErrUnauthorized
    }
    // ... fetch data
}
```

### In Commit Messages
```
commit a3f8d92
Add escrow contract security audit

Fixes: Smart contract reentrancy vulnerability
Reference: analyzing-ethereum-smart-contract-vulnerabilities
CVSS: 9.8 Critical
Status: ✓ Remediated

- Added checks-effects-interactions pattern
- Added reentrancy guard mutex
- Verified in unit tests
```

### In Code Reviews
```
@security-team, can you run:
"Use skill: trustnet-security"
"Audit this API endpoint for IDOR"

File: api/routes/user.go
Concern: updateUserProfile() might allow privilege escalation
```

---

## Key Resources

| Resource | Location | Purpose |
|----------|----------|---------|
| **Workspace Instructions** | `copilot-instructions.md` | Project-wide security guidelines |
| **Security Assessment Guide** | `.github/instructions/security-assessment.instructions.md` | How to conduct assessments |
| **Security Skill Router** | `.github/skills/trustnet-security/SKILL.md` | Select appropriate skills |
| **Documentation Index** | `operations/SECURITY_SKILLS_INDEX.md` | Navigation guide for all docs |
| **Cybersecurity Skills** | `.skills/` | 300+ reference implementations |

---

## Next Steps

1. **Start a security task**: "Review the Token.sol contract"
   - AI auto-loads skills and guides you

2. **Reference a specific domain**: "I need smart contract security expertise"
   - AI suggests and loads relevant skills

3. **Create a security incident response plan**: "Build an incident response playbook"
   - Skill: building-incident-response-playbook

4. **Set up continuous security scanning**: "Configure CI/CD security scanning"
   - Skills: implementing-secrets-scanning-in-ci-cd, implementing-sast-into-github-actions-pipeline

---

**Last Updated**: March 16, 2026  
**Questions?** See `copilot-instructions.md` or `.github/instructions/security-assessment.instructions.md`

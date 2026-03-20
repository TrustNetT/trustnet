# TrustNet Security Skills Integration Architecture

## System Overview

```
┌───────────────────────────────────────────────────────────────┐
│                         User Request                          │
│           (e.g., "Audit this smart contract")                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌───────────────────────────────────────────────────────────────┐
│            VS Code AI Agent (GitHub Copilot)                  │
│  • Detects security context                                   │
│  • Evaluates workspace instructions                           │
│  • Matches to applicable instructions/skills                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ▼                ▼                ▼
    ┌─────────┐  ┌──────────────┐  ┌─────────────┐
    │Workspace│  │Instructions  │  │  Skills     │
    │Config   │  │              │  │  Router     │
    └─────────┘  └──────────────┘  └─────────────┘
        │              │                 │
        │              │                 │
  File:copilot-│ File:.github/    File:.github/skills/
   instructions.md  instructions/   trustnet-security/
        │         security-assessment  SKILL.md
        │              .instructions.md    │
        │                  │               │
        │                  │        ┌──────┴──────┐
        │                  │        │             │
        └──────────────────┼────────┼─────────────┘
                           │        │
                           ▼        ▼
                  ┌──────────────────────────┐
                  │  Cybersecurity Skills    │
                  │  Router to 300+ skills   │
                  │  in .skills/ directory   │
                  └──────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
   Smart Contract    API Security      Infrastructure
   Security Skills   Skills            Security Skills
   
   E.g.:             E.g.:              E.g.:
   • analyzing-      • conducting-api-  • hardening-
     ethereum-smart-   security-testing   docker-
     contract-vul.    • testing-for-    • auditing-
   • exploiting-      broken-object-    kubernetes-
     vulnerabilities  level-auth        cluster-rbac
```

## File Structure & Purpose

### Core Configuration Files

**1. `copilot-instructions.md` (Workspace Root)**
- **Purpose**: Project-wide AI guidelines
- **Scope**: Applies to all interactions
- **Contains**:
  - Project overview
  - Security-first development philosophy
  - Link to security skills
  - Usage guidelines
  - When NOT to use AI
  - References to detailed docs

**2. `.github/instructions/security-assessment.instructions.md`**
- **Purpose**: Auto-triggered security instruction set
- **Scope**: Applies to security-related files (*.sol, api/*, docker*, etc.)
- **Contains**:
  - Detailed security assessment workflow
  - Step-by-step assessment methodology
  - Skill mapping for common tasks
  - Threat model integration
  - MITRE ATT&CK mapping
  - Output format specifications

**3. `.github/skills/trustnet-security/SKILL.md`**
- **Purpose**: Gateway/router to 300+ cybersecurity skills
- **Scope**: On-demand, when explicitly requested or auto-triggered by context
- **Contains**:
  - Skill taxonomy organized by domain
  - End-to-end workflows
  - Component-specific integration guides
  - Tool integration recommendations
  - Critical vulnerability escalation procedures

### Quick Reference File

**4. `operations/SECURITY_SKILLS_QUICK_START.md`**
- **Purpose**: Easy-to-understand usage guide
- **Audience**: Developers new to the security skills
- **Contains**:
  - Real-world examples
  - Common usage patterns
  - FAQ
  - Troubleshooting

---

## Execution Flow: Request → Skill Loading

### Flow 1: Automatic Detection (Recommended)

```
User: "Find vulnerabilities in Token.sol"
   │
   ├─ Copilot recognizes: smart contract + security context
   │
   ├─ Loads: copilot-instructions.md (project guidelines)
   │
   ├─ Loads: security-assessment.instructions.md (auto-trigger)
   │   └─ Evaluates: file in `**/*security*` or `**/*.sol` pattern? YES
   │
   ├─ Routes to: trustnet-security skill
   │
   ├─ trustnet-security selects: analyzing-ethereum-smart-contract-vulnerabilities
   │
   ├─ SKILL.md provides:
   │   • Reentrancy check methodology
   │   • Access control pattern review
   │   • Arithmetic overflow validation
   │   • Test case templates
   │   • CVSS scoring guidance
   │
   └─ Output: Vulnerability report with recommendation
```

### Flow 2: Explicit Skill Request

```
User: "Use skill: trustnet-security"
      "Audit the Payment.sol contract"
   │
   ├─ Copilot loads: trustnet-security SKILL.md immediately
   │
   ├─ User provides context: Payment.sol audit
   │
   ├─ Skill routes to: analyzing-ethereum-smart-contract-vulnerabilities
   │
   └─ Output: Structured vulnerability assessment
```

### Flow 3: Domain-Based Request

```
User: "I need API security review for user endpoints"
   │
   ├─ Copilot recognizes: API + security assessment
   │
   ├─ Matches patterns: `**/api/**` files mentioned
   │
   ├─ Loads: security-assessment.instructions.md
   │
   ├─ Routes to: conducting-api-security-testing skill
   │
   ├─ Provides checklists:
   │   • Authentication bypass
   │   • Authorization flaws (IDOR, BOLA)
   │   • Data exposure
   │   • Injection vulnerabilities
   │
   └─ Output: API security assessment with PoC tests
```

---

## Instruction Precedence & Layering

When you request security analysis, the AI loads instructions in this order:

**Layer 1: Workspace Defaults**
- File: `copilot-instructions.md`
- Applies to: All interactions
- Content: Project guidelines, security philosophy

**Layer 2: File-Specific Instructions**
- File: `.github/instructions/security-assessment.instructions.md`
- Applies to: When file matches pattern (security*, threat*, api/*, *.sol, etc.)
- Content: Detailed methodology, workflow, tool integration

**Layer 3: Skill Routing**
- File: `.github/skills/trustnet-security/SKILL.md`
- Applies to: When security task explicitly requested or auto-detected
- Content: 300+ skill mappings, taxonomies, output formats

**Layer 4: External Skills**
- Directory: `.skills/` (300+ cybersecurity domains)
- Applies to: When specific security domain skill loads
- Content: Domain-specific methodology, tool use, attack patterns

---

## Integration Points with TrustNet Components

### Smart Contract Security

**Workflow**:
```
File: api/contracts/Token.sol
├─ Pattern: *.sol matches trigger
├─ Loads: security-assessment.instructions.md
├─ Routes to: analyzing-ethereum-smart-contract-vulnerabilities
├─ Checks:
│  ├─ Reentrancy (calls to untrusted addresses)
│  ├─ Access control (who can call functions)
│  ├─ Arithmetic safety (overflow/underflow)
│  ├─ Storage layout (proxy patterns)
│  └─ State mutation order (checks-effects-interactions)
└─ Output: Vulnerability report + test cases + fixes
```

**Reference**: `api/contracts/SECURITY_AUDIT.md` (future doc)

### API Security

**Workflow**:
```
Directory: api/routes/
├─ Pattern: api/** matches trigger
├─ Loads: security-assessment.instructions.md
├─ Routes to: conducting-api-security-testing
├─ Tests:
│  ├─ Authentication (valid tokens required?)
│  ├─ Authorization (user owns resource?)
│  ├─ Input validation (SQL injection, XSS?)
│  ├─ Output encoding (data leakage?)
│  └─ Rate limiting (DOS protection?)
├─ Tools: Burp Suite, Postman, curl
└─ Output: OWASP Top 10 assessment + PoCs
```

**Reference**: `core/api/SECURITY_TESTING.md` (future doc)

### Infrastructure Security

**Workflow**:
```
File: Dockerfile or k8s/*.yaml
├─ Pattern: docker*, k8s/** matches trigger
├─ Loads: security-assessment.instructions.md
├─ Routes to: hardening-docker-containers-for-production
        OR: hardening-kubernetes-pod-security-standards
├─ Checks:
│  ├─ Base image vulnerabilities (trivy scan)
│  ├─ User permissions (non-root execution)
│  ├─ Container capabilities (drop unnecessary)
│  ├─ Secrets management (no hardcoded values)
│  ├─ Network policies (isolate pods)
│  └─ RBAC configuration (least privilege)
└─ Output: Hardening checklist + updated configs
```

**Reference**: `infrastructure/SECURITY_HARDENING.md` (future doc)

### Threat Modeling

**Workflow**:
```
Context: New feature added (e.g., marketplace)
├─ Request: "Threat model for marketplace"
├─ Loads: threat-modeling-with-mitre-attack
├─ Analysis:
│  ├─ Asset identification (contracts, wallets, data)
│  ├─ Threat actor modeling (external, insider, protocol)
│  ├─ MITRE ATT&CK mapping (tactics & techniques)
│  ├─ Attack tree construction
│  └─ Control recommendations (detective, preventive)
└─ Output: Threat register (SECURITY_ARCHITECTURE.md update)
```

---

## Skill Loading Patterns

### Pattern 1: Automatic File-Based Trigger

**When**: User edits/references a file matching pattern

| File Pattern | Auto-Trigger | Loads |
|--------------|--------------|-------|
| `*.sol` | ✅ | analyzing-ethereum-smart-contract-vulnerabilities |
| `api/routes/*.go` | ✅ | conducting-api-security-testing |
| `Dockerfile*` | ✅ | hardening-docker-containers-for-production |
| `k8s/*.yaml` | ✅ | hardening-kubernetes-pod-security-standards |
| `*security*.md` | ✅ | trustnet-security (router) |
| `*threat*.md` | ✅ | threat-modeling-with-mitre-attack |

### Pattern 2: Keyword-Based Trigger

**When**: User uses security keywords

| Keyword | Triggers | Loads |
|---------|----------|-------|
| "vulnerability" | ✅ | trustnet-security router |
| "audit" | ✅ | security-assessment.instructions.md |
| "penetration test" | ✅ | conducting-api-security-testing |
| "threat model" | ✅ | threat-modeling-with-mitre-attack |
| "hardening" | ✅ | infrastructure security skills |

### Pattern 3: Explicit Skill Request

**When**: User explicitly requests skill

```
"Use skill: trustnet-security"
"Use skill: analyzing-ethereum-smart-contract-vulnerabilities"
"Use skill: hardening-docker-containers-for-production"
```

---

## Output Standardization

All security assessments follow consistent format:

```markdown
# Security Assessment Report
[Date] | [Component] | [Assessor: AI + Human Review]

## Executive Summary
[1-2 paragraphs of key findings]

## Risk Matrix
| Severity | Count | Status |
|----------|-------|--------|
| Critical | 0 | ✓ |
| High | 2 | ⚠️ |
| Medium | 5 | ⚠️ |

## Detailed Findings
### Finding 1: [Title]
- **CWE**: [CWE-94]
- **CVSS**: [8.5]
- **Evidence**: [Code snippet]
- **Impact**: [Business impact]
- **Recommendation**: [Fix]
- **Verification**: [Test case]

## Remediation Roadmap
1. Critical (24h): Fix #1
2. High (1 week): Fix #2-3
3. Medium (1 sprint): Fix #4-8

## Compliance Mapping
- OWASP Top 10: A01:2021, A02:2021
- CWE Top 25: CWE-94, CWE-79

## References
- [CWE-94](https://cwe.mitre.org/data/definitions/94.html)
- [OWASP](https://owasp.org/)
```

---

## Tool Integration

### Automated Scanning (CI/CD)

**Dockerfile Security**:
```bash
trivy image trustnet:$BUILD_NUMBER
```

**Dependencies**:
```bash
snyk test --file=go.mod
pnpm audit
```

**Secrets**:
```bash
truffleHog filesystem . --regex
gitleaks detect --source filesystem
```

### Manual Testing Tools

**API Testing**:
```bash
# Burp Suite
# Postman (collections in tests/api/)
# curl (manual requests)
```

**Container Testing**:
```bash
docker run --rm -it trustnet:latest /bin/sh
# Manual exploration of surface
```

**Network Analysis**:
```bash
tcpdump -i eth0 -w capture.pcap
wireshark capture.pcap
```

---

## Customization & Extension

### Adding Project-Specific Skills

If you need custom skills (e.g., TrustNet blockchain-specific analysis):

```
.github/skills/trustnet-blockchain-analysis/
├── SKILL.md              # Skill definition
├── templates/
│   ├── contract-audit.yaml
│   └── threat-model.json
└── examples/
    └── solana-exploit-examples/
```

**Usage**:
```
"Use skill: trustnet-blockchain-analysis"
"Analyze this Solana program for common bugs"
```

### Customizing Instructions

Edit `.github/instructions/security-assessment.instructions.md` to add:
- Project-specific vulnerability checks
- Integration with your internal tools
- Custom escalation procedures
- Team-specific guidelines

---

## Troubleshooting

### Q: Skills not loading automatically?

**A**: Check file patterns match:
- Smart contract: File named `*.sol`? Yes → Should load
- API: File in `api/routes/`? Yes → Should load
- Double-check filename and directory names

**Solution**: Explicitly request:
```
"Use skill: trustnet-security"
Then describe task
```

### Q: Wrong skill loaded?

**A**: Be more specific in request:
```
Instead of: "Security review"
Try: "API authorization audit for /user endpoint"
```

### Q: Instructions not appearing?

**A**: Verify YAML frontmatter:
```yaml
---
name: trustnet-security-assessment
description: "Use when: ..."
applyTo: "**/*pattern*"   # Must be string, not array
---
```

### Q: Need help finding a specific cybersecurity skill?

**A**: Search in `.skills/` directory or ask:
```
"List security skills for [domain]"
"What skills do you have for [topic]?"
```

---

## Integration Roadmap

**Phase 1** (Done): Basic skill registration
- ✅ Workspace instructions
- ✅ Security assessment instruction
- ✅ Security skill router

**Phase 2** (Recommended): Continuous security
- [ ] CI/CD security scanning (automated)
- [ ] Pre-commit security hooks
- [ ] Security metrics dashboard
- [ ] Automated vulnerability tracking

**Phase 3** (Future): Advanced automation
- [ ] Custom TrustNet security skills
- [ ] Blockchain analysis automation
- [ ] Threat intelligence integration
- [ ] Automated incident response

---

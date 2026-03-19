# TrustNet Security Skills: Setup & Maintenance Guide

## Table of Contents
1. [What Was Set Up](#what-was-set-up)
2. [Initial Setup Steps](#initial-setup-steps)
3. [File Structure Overview](#file-structure-overview)
4. [Adding New Skills](#adding-new-skills)
5. [Customizing Existing Skills](#customizing-existing-skills)
6. [Testing & Validation](#testing--validation)
7. [Troubleshooting](#troubleshooting)
8. [Updates & Maintenance](#updates--maintenance)

---

## What Was Set Up

The TrustNet project now has a complete **security skills integration framework** that connects your existing 300+ cybersecurity skills (in `.skills/` directory) to the VS Code AI agent through a series of configuration files.

### Components Created

| File | Purpose | Type | Location |
|------|---------|------|----------|
| `copilot-instructions.md` | Workspace-wide AI guidelines | Instruction | Root |
| `security-assessment.instructions.md` | Security-specific methodology | Instruction | `.github/instructions/` |
| `trustnet-security/SKILL.md` | Security skill router/gateway | Skill | `.github/skills/trustnet-security/` |
| `SECURITY_SKILLS_QUICK_START.md` | Developer quick reference | Documentation | operations/ |
| `SECURITY_SKILLS_INTEGRATION.md` | Technical architecture | Documentation | operations/ |
| `SECURITY_SKILLS_SETUP_MAINTENANCE.md` | This file | Documentation | operations/ |

### Why This Approach?

**Problem**: 300+ cybersecurity skills exist in `.skills/` but weren't connected to the AI agent.

**Solution**: Created a 3-layer instruction system:
1. **Layer 1**: Workspace instructions (project guidelines)
2. **Layer 2**: File-specific instructions (auto-trigger on security work)
3. **Layer 3**: Skill router (gateway to 300+ skills)

**Result**: Security skills now auto-load when needed, and developers can explicitly request skills.

---

## Initial Setup Steps

This section documents what was done to set up the skills integration. If you need to replicate this for another project, follow these steps.

### Step 1: Create Directory Structure

```bash
cd /path/to/project

# Create instruction directory
mkdir -p .github/instructions

# Create skills directory with security gateway
mkdir -p .github/skills/trustnet-security
```

### Step 2: Create Workspace Instructions

**File**: `copilot-instructions.md` (project root)

**Purpose**: Define project-wide AI guidelines

**Contains**:
- Project overview
- Security-first philosophy
- Link to available security skills
- Usage guidelines
- When NOT to use AI

**Key Sections**:
```markdown
# Project Overview
# Security-First Development
# Available Security Skills
# How to Use Security Skills
# When NOT to Use AI for Security
# Referencing Skills in Code Comments
```

**Why**: The `copilot-instructions.md` file is automatically loaded by VS Code and applies globally to all AI interactions in the project.

### Step 3: Create Security Assessment Instruction

**File**: `.github/instructions/security-assessment.instructions.md`

**Purpose**: Auto-trigger detailed security assessment methodology

**Frontmatter** (YAML):
```yaml
---
name: trustnet-security-assessment
description: "Use when: analyzing code for security vulnerabilities, auditing smart contracts, testing API endpoints, hardening infrastructure, threat modeling, or any security review task in TrustNet"
applyTo: "**/*{security,threat,vulnerability}*"
---
```

**Key Frontmatter Rules**:
- `name`: Must match folder name (if in files/ structure)
- `description`: Include "Use when:" keywords for AI to detect
- `applyTo`: Glob pattern for auto-triggering (must be string, not array)
- Quote descriptions containing colons

**Contains**:
- Security assessment workflow (5 steps)
- Vulnerability pattern checklist
- Threat model integration
- MITRE ATT&CK mapping
- Output format specifications

**Why**: This file auto-triggers when:
- Editing files with `security`, `threat`, or `vulnerability` in the name
- Working in security-related directories
- Explicitly requesting security assessment

### Step 4: Create Security Skill Router

**File**: `.github/skills/trustnet-security/SKILL.md`

**Purpose**: Gateway routing to 300+ cybersecurity skills

**Frontmatter**:
```yaml
---
name: trustnet-security
description: "Use when: performing security assessments, vulnerability analysis, threat modeling, or auditing any part of TrustNet (smart contracts, APIs, infrastructure, cryptography). References the extensive cybersecurity skills library in .skills/ directory."
---
```

**Contains**:
- Skill taxonomy by domain (3-5 pages)
- End-to-end workflows (discovery → testing → remediation)
- Component-specific integration guides
- Tool integration recommendations
- Escalation procedures for critical vulns

**Why**: Acts as a router that:
- Categorizes 300+ skills by domain
- Provides decision logic for skill selection
- Supplies domain-specific methodology
- Integrates with TrustNet components

### Step 5: Create Supporting Documentation

Create these files in operations/ folder for developers:

**A. `operations/SECURITY_SKILLS_QUICK_START.md`** (~300 lines)
- Quick examples of common usage
- Real-world scenarios with expected output
- Troubleshooting FAQ
- File organization tips
- Common issues & solutions

**B. `operations/SECURITY_SKILLS_INTEGRATION.md`** (~400 lines)
- System architecture diagrams
- Execution flow from request → skill loading
- Instruction precedence & layering
- Integration points with TrustNet components
- Customization & extension points

**C. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md`** (this file)
- What was set up and why
- Setup steps (for replication)
- How to add/customize skills
- Testing & troubleshooting
- Maintenance procedures

### Step 6: Verify Setup

Test that skills are loading:

```bash
# 1. Check file structure
ls -R .github/instructions/
ls -R .github/skills/
cat copilot-instructions.md | head -50

# 2. Validate YAML frontmatter (no errors)
# Editor should show no lint errors in frontmatter section

# 3. Test auto-trigger
# View a *.sol file → Should suggest security assessment

# 4. Test explicit skill request
# Ask: "Use skill: trustnet-security"
# Should load and suggest security domains
```

### Step 7: Document in README

Add to project `README.md`:

```markdown
## Security

This project integrates 300+ cybersecurity skills to support security-first development.

### Quick Start
- See `operations/SECURITY_SKILLS_QUICK_START.md` for usage examples
- See `copilot-instructions.md` for project guidelines
- See `operations/SECURITY_SKILLS_INTEGRATION.md` for technical details

### Using Security Skills
```
Use skill: trustnet-security
Then: request a security assessment or choose a domain
```

### For Security-Specific Tasks
Work on `.sol` files, `api/` endpoints, or `Dockerfile` → skills auto-load
```

---

## File Structure Overview

After setup, your project has this structure:

```
trustnet-wip/
│
├── .github/                              ← VS Code AI configuration
│   │
│   ├── instructions/                     ← Auto-trigger instructions
│   │   └── security-assessment.instructions.md   [NEW]
│   │       ├── Frontmatter (YAML)
│   │       ├── Security Assessment Workflow
│   │       ├── Common Security Tasks
│   │       └── MITRE ATT&CK Mapping
│   │
│   └── skills/                           ← Skill routing
│       └── trustnet-security/            [NEW]
│           └── SKILL.md
│               ├── Frontmatter (YAML)
│               ├── Skill Taxonomy (300+ skills)
│               ├── End-to-End Workflows
│               └── Tool Integration
│
├── .skills/                              ← Cybersecurity skills reference
│   ├── analyzing-ethereum-smart-contract-vulnerabilities/
│   ├── hardening-docker-containers-for-production/
│   ├── conducting-api-security-testing/
│   ├── threat-modeling-with-mitre-attack/
│   └── ... 300+ more skills
│
├── copilot-instructions.md               [NEW - Root]
│   ├── Project Overview
│   ├── Security-First Development Philosophy
│   ├── Available Security Skills Quick Reference
│   ├── How to Use Security Skills
│   └── When NOT to Use AI for Security
│
├── operations/                           [NEW - Documentation folder]
│   ├── SECURITY_SKILLS_QUICK_START.md        [NEW]
│   │   ├── Overview
│   │   ├── Quick Usage Examples (4+ scenarios)
│   │   ├── Skill Triggering Methods
│   │   ├── Available Skills by Domain
│   │   ├── Workflow: Full Security Assessment
│   │   └── Troubleshooting
│   │
│   ├── SECURITY_SKILLS_INTEGRATION.md        [NEW]
│   │   ├── System Overview (with diagram)
│   │   ├── Execution Flow
│   │   ├── Instruction Precedence & Layering
│   │   ├── Integration Points with Components
│   │   ├── Skill Loading Patterns
│   │   ├── Output Standardization
│   │   └── Customization & Extension
│   │
│   ├── SECURITY_SKILLS_SETUP_MAINTENANCE.md  [NEW, THIS FILE]
│   │   ├── What Was Set Up
│   │   ├── Initial Setup Steps
│   │   ├── File Structure Overview
│   │   ├── Adding New Skills
│   │   ├── Customizing Existing Skills
│   │   ├── Testing & Validation
│   │   └── Troubleshooting & Maintenance
│   │
│   ├── SECURITY_SKILLS_QUICK_REFERENCE.md    [NEW]
│   │   ├── Quick Cheat Sheet
│   │   ├── File Locations
│   │   └── Common Tasks
│   │
│   └── SECURITY_SKILLS_INDEX.md              [NEW]
│       ├── Documentation Roadmap
│       ├── By-User-Role Guides
│       ├── By-Topic Guides
│       └── Cross-References
│
└── api/, core/, etc.
    └── Existing project files
```

### File Purposes at a Glance

| File | Audience | When to Read | Updates |
|------|----------|--------------|---------|
| `copilot-instructions.md` | All developers | Setup / onboarding | Update for project changes |
| `operations/SECURITY_SKILLS_QUICK_START.md` | Developers | First time using skills | Add new examples as needed |
| `operations/SECURITY_SKILLS_INTEGRATION.md` | Tech leads / maintainers | Understanding system | Update when architecture changes |
| `security-assessment.instructions.md` | AI agent / advanced users | Security work | Update methodologies periodically |
| `trustnet-security/SKILL.md` | AI agent / security team | Security assessments | Update skill taxonomy as skills added |

---

## Adding New Skills

When you need to add new or custom security skills to the project, follow these procedures.

### Scenario 1: Add a Skill from `.skills/` Directory

Your `.skills/` directory already has 300+ skills. To activate one:

#### Option A: Reference in Skill Router (Recommended)

Edit: `.github/skills/trustnet-security/SKILL.md`

Find the appropriate domain section and add:

```markdown
### [Domain Name]

- `existing-skill-name/` → Description
- `new-skill-name-to-add/` → What this skill does    [NEW]
```

**Example**: Adding a new blockchain domain

```markdown
### Blockchain-Specific Security (Solana/Rust)

- `analyzing-ethereum-smart-contract-vulnerabilities/` → Solidity patterns
- `analyzing-solana-program-security/` → Rust contracts (NEW)
- `performing-cryptographic-audit-of-application/` → Crypto implementations
```

Then update the **Workflow** or **Integration Points** section to reference the new skills in context.

#### Option B: Create a Skill Taxonomy Reference

If adding many new skills, create a dedicated file:

**File**: `.github/skills/trustnet-security/SKILL_TAXONOMY.md`

```markdown
# TrustNet Security Skill Taxonomy

## Version: 1.0
## Last Updated: [Date]

### Smart Contract Security
- analyzing-ethereum-smart-contract-vulnerabilities
- analyzing-solana-program-security
- exploiting-vulnerabilities-with-metasploit-framework
- performing-cryptographic-audit-of-application

### API Security  
- conducting-api-security-testing
- testing-for-broken-object-level-authorization
- [Add more as needed]

...
```

Then reference in main SKILL.md:

```markdown
For complete taxonomy, see: SKILL_TAXONOMY.md
```

### Scenario 2: Create a Custom TrustNet-Specific Skill

For capabilities beyond the generic cybersecurity skills (e.g., TrustNet-specific blockchain analysis):

#### Step 1: Create Skill Directory

```bash
mkdir -p .github/skills/trustnet-blockchain-analysis

cd .github/skills/trustnet-blockchain-analysis
```

#### Step 2: Create SKILL.md

```markdown
---
name: trustnet-blockchain-analysis
description: "Use when: analyzing TrustNet smart contracts for blockchain-specific vulnerabilities, evaluating token economics, or performing cryptographic security review"
---

# TrustNet Blockchain Analysis Skill

## Purpose

Specialized security analysis for TrustNet blockchain components:
- Smart contract vulnerabilities (reentrancy, access control, etc.)
- Token economics and incentive mechanisms
- Cryptographic implementation review
- Solana program security (Rust-specific patterns)

## When to Use This Skill

- Auditing `api/contracts/` smart contracts
- Reviewing token transfer logic
- Analyzing payment flows and escrow mechanisms
- Evaluating network incentive models

## Analysis Steps

### Step 1: Contract Identification
- [ ] Type: Solana program (Rust) or Ethereum contract (Solidity)?
- [ ] Purpose: Token, escrow, governance, etc.?
- [ ] Dependencies: External libraries or contracts?

### Step 2: Vulnerability Assessment
- [ ] Reentrancy (recursive calls)
- [ ] Access control (permission validation)
- [ ] Arithmetic safety (overflow checks)
- [ ] Owner privileges (centralization risk)
- [ ] Economic incentives (alignment with design)

### Step 3: Reporting

Generate report:
```
## Security Assessment: [Contract Name]

### Severity Summary
| Level | Count |
|-------|-------|
| Critical | X |
| High | X |
| Medium | X |

### Findings
1. [Finding 1 with CWE]
...

### Recommendations
- [Fix 1]
...
```

## References

- [CWE Top 25](https://cwe.mitre.org/)
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [Anchor (Solana Framework)](https://docs.rs/anchor-lang/)
```

#### Step 3: Create Templates Directory (Optional)

```bash
mkdir -p .github/skills/trustnet-blockchain-analysis/templates

# Create reusable templates
cat > contract-audit.yaml << 'EOF'
contract_name: "[Contract Name]"
type: "solidity|rust"
purpose: "token|escrow|governance"
checklist:
  reentrancy: "[ ] Checked"
  access_control: "[ ] Checked"
  arithmetic: "[ ] Checked"
severity_summary:
  critical: 0
  high: 0
  medium: 0
findings: []
recommendations: []
EOF
```

#### Step 4: Update Main Skill Router

Edit: `.github/skills/trustnet-security/SKILL.md`

Add reference:

```markdown
### TrustNet-Specific Skills

The following custom skills provide TrustNet-specific security analysis:

- `trustnet-blockchain-analysis/` → Specialized blockchain & smart contract analysis
  - Use when: Auditing TrustNet contracts or analyzing token economics
  - Reference: `.github/skills/trustnet-blockchain-analysis/SKILL.md`
```

#### Step 5: Test the New Skill

```bash
# Ask the AI assistant:
"Use skill: trustnet-blockchain-analysis"
"Analyze the Token.sol contract"

# OR reference it in copilot-instructions.md for auto-discovery
```

### Scenario 3: Add Skills for a New Project Component

If TrustNet adds a new component (e.g., machine learning integration), follow this workflow:

#### Step 1: Identify Security Domain

Example: ML-based risk scoring

```
Domain: "Machine Learning Security"
Components: Training data, model inference, model storage
Threats: Model poisoning, adversarial attacks, data leakage
```

#### Step 2: Find Applicable `.skills/`

Search in `.skills/` directory:

```bash
ls .skills/ | grep -i "machine\|ml\|ai\|model"
# or
grep -r "machine learning" .skills/ | head -5
```

#### Step 3: Register in Skill Router

Update `.github/skills/trustnet-security/SKILL.md`:

```markdown
### Machine Learning Security

- `securing-machine-learning-models/` → Model poisoning & adversarial attacks
- `performing-ml-model-security-audit/` → Training data & inference security
- `detecting-ai-bias-in-models/` → Fairness & bias assessment
```

#### Step 4: Create Custom Skill if Needed

If no generic skill exists for your specific use case, create one in `.github/skills/trustnet-ml-security/SKILL.md`

---

## Customizing Existing Skills

### Modify Security Assessment Instructions

**File**: `.github/instructions/security-assessment.instructions.md`

#### Add New Vulnerability Checks

Find section: **"Common Security Tasks"**

Add new task:

```markdown
### Machine Learning Model Security

**Vulnerability Patterns**:
- Poisoned training data (invalid samples)
- Adversarial input examples (intentional mis-classification)
- Model extraction (reverse-engineering the model)
- Data leakage (training data in predictions)

**Skill Reference**:
```
Use skill: securing-machine-learning-models
Tool: Model validation framework, adversarial testing
Example: Generate adversarial examples with FGSM attack
```
```

#### Update MITRE ATT&CK Mappings

Find section: **"MITRE ATT&CK Mapping"**

Add new attack pattern:

```markdown
## MITRE Mapping Examples

[Existing patterns...]

**ML Security Example**:
```
Vulnerability: Poisoned training data in risk model
MITRE Tactic: Persistence (TA0003)
MITRE Technique: T1578 (Modify Cloud Compute Infrastructure)
Mitigation: Data validation, integrity monitoring, access controls
```
```

### Modify Skill Router

**File**: `.github/skills/trustnet-security/SKILL.md`

#### Add New Domain Section

Insert new domain before "Tool Integration":

```markdown
### [New Domain Name]

**Purpose**: [Description of domain]

**When to Use**:
- Scenario 1
- Scenario 2

**Applicable Skills**:
- `skill-name-1/` → Description
- `skill-name-2/` → Description

**Tools**: Tool A, Tool B

**Example Workflow**:
```
Request: "Your request here"
Skills: skill-1 → skill-2
Output: What the assessment produces
```
```

#### Add New Workflow

In section: **"Workflow: End-to-End Security Assessment"**

Add new phase or component:

```markdown
### [Component Name] Security Workflow

**Files**: List of files/directories

**Skills Used**:
- `skill-1/` - Purpose
- `skill-2/` - Purpose

**Checks**:
- [ ] Check 1
- [ ] Check 2

**Output**: What gets produced
```

### Extend Output Format

**File**: `.github/instructions/security-assessment.instructions.md`

Find section: **"## Output Format"**

Customize for your needs:

```markdown
## Output Format

All security assessments include:

1. **Executive Summary** - High-level findings (1-2 paragraphs)
   - [Add custom requirement]
2. **Risk Matrix** - Severity vs likelihood grid
3. **Detailed Findings** - Each vulnerability with evidence
   - [Add custom fields]
4. **Remediation Roadmap** - Priority order, effort estimates
5. **Testing Evidence** - Proof-of-concept, screenshots, logs
6. **References** - CVE/CWE links, OWASP Top 10 mappings
   - [Add custom reference types]
```

---

## Testing & Validation

### Test 1: Verify File Structure

```bash
# Check that all files exist
test -f copilot-instructions.md && echo "✓ copilot-instructions.md"
test -f .github/instructions/security-assessment.instructions.md && echo "✓ security-assessment.instructions.md"
test -f .github/skills/trustnet-security/SKILL.md && echo "✓ trustnet-security SKILL.md"
test -f operations/SECURITY_SKILLS_QUICK_START.md && echo "✓ SECURITY_SKILLS_QUICK_START.md"
test -f operations/SECURITY_SKILLS_INTEGRATION.md && echo "✓ SECURITY_SKILLS_INTEGRATION.md"
```

### Test 2: Validate YAML Frontmatter

Each instruction/skill file should have valid YAML:

```bash
# Check for syntax errors
head -10 .github/instructions/security-assessment.instructions.md
# Should show:
# ---
# name: trustnet-security-assessment
# description: "Use when: ..."
# applyTo: "**/*pattern*"
# ---
```

**Common YAML errors to avoid**:
- ❌ Unquoted colons in values: `description: Use when: foo` → ✅ `description: "Use when: foo"`
- ❌ Tabs instead of spaces → Use spaces only
- ❌ `applyTo` as array: `["*.sol"]` → Use string: `"**/*.sol"`
- ❌ Name doesn't match file/folder name

### Test 3: Test Auto-Triggering

**Test A: Smart Contract Files**

```bash
# Create test file
echo "contract Test {}" > test.sol

# In VS Code AI chat:
# "Review test.sol for vulnerabilities"
# 
# Expected: AI loads security assessment instruction
# Actual: [Check if loaded]
```

**Test B: API Files**

```bash
# In VS Code, open api/routes/user.go
# Ask: "Security review of this endpoint"
#
# Expected: Auto-loads API security testing
# Actual: [Check if loaded]
```

**Test C: Dockerfile**

```bash
# In VS Code, open Dockerfile
# Ask: "Hardening checklist"
#
# Expected: Auto-loads infrastructure security
# Actual: [Check if loaded]
```

### Test 4: Test Explicit Skill Request

In VS Code AI chat:

```
"Use skill: trustnet-security"
"Audit the Token.sol contract for reentrancy"

Expected Output:
✓ Recognizes smart contract audit request
✓ Suggests reentrancy checking methodology
✓ Provides code examples & test cases
✓ References analyzing-ethereum-smart-contract-vulnerabilities
```

### Test 5: Test Custom Skill (If Added)

```
"Use skill: trustnet-blockchain-analysis"
"Analyze token economics"

Expected:
✓ Skill loads and provides blockchain-specific methodology
✓ References project components (api/contracts/)
✓ Outputs structured assessment
```

### Test 6: Validation Checklist

Create this checklist and work through it:

```markdown
## Security Skills Setup Validation

- [ ] All 5 configuration files exist
- [ ] YAML frontmatter syntax is valid (no colons unquoted)
- [ ] File paths are correct in all references
- [ ] Skill descriptions contain "Use when:" keywords
- [ ] applyTo patterns are strings (not arrays)
- [ ] Auto-trigger works for *.sol files
- [ ] Auto-trigger works for api/** files
- [ ] Auto-trigger works for Dockerfile
- [ ] Explicit skill: trustnet-security loads
- [ ] Output format matches specification
- [ ] Skills in .skills/ directory are accessible
- [ ] Custom skills (if added) load correctly
- [ ] No lint errors in YAML frontmatter
- [ ] All crossreferences between files work
- [ ] Documentation is up-to-date
```

---

## Troubleshooting

### Problem 1: Skills Not Auto-Loading

**Symptom**: You edit a `*.sol` file but security instruction doesn't load

**Causes & Solutions**:

| Cause | Solution |
|-------|----------|
| Filename doesn't match pattern | Check: File is `*.sol` or in `api/` directory? |
| YAML syntax error in `applyTo` | Use string: `applyTo: "**/*.sol"` not array |
| Wrong file location | Move to `.github/instructions/` not `.github/` |
| Typo in filename | Name must match: `security-assessment.instructions.md` |
| VS Code cache | Reload: Cmd/Ctrl+Shift+P → "Reload Window" |

**Debug**:
```bash
# Verify file exists and is readable
ls -la .github/instructions/security-assessment.instructions.md

# Check YAML is valid
head -5 .github/instructions/security-assessment.instructions.md
# Should show valid YAML frontmatter
```

### Problem 2: Skill Doesn't Load When Requested

**Symptom**: "Use skill: trustnet-security" doesn't work

**Causes**:

| Cause | Solution |
|-------|----------|
| Typo in skill name | Name must match: `trustnet-security` (folder name) |
| SKILL.md missing | Create: `.github/skills/trustnet-security/SKILL.md` |
| YAML error in SKILL.md | Check frontmatter syntax |
| Path incorrect | Correct path: `.github/skills/trustnet-security/` |

**Debug**:
```bash
# Verify SKILL.md exists
test -f .github/skills/trustnet-security/SKILL.md && echo "✓ Found" || echo "✗ Missing"

# Check YAML frontmatter
head -10 .github/skills/trustnet-security/SKILL.md
```

### Problem 3: Wrong Skill Loaded

**Symptom**: Asked for smart contract audit, got API testing skill

**Solution**: Be more specific in request

```
Instead of: "Security review"
Try: "Audit the Token.sol smart contract for reentrancy"
     "Analyze ethereum contract vulnerabilities"
```

### Problem 4: applyTo Pattern Not Working

**Common Mistakes**:

```yaml
# ❌ WRONG: Array syntax
applyTo: ["**/*.sol", "**/api/**"]

# ✅ RIGHT: Single string with glob pattern
applyTo: "**/{*.sol,api/**}"

# ❌ WRONG: Colons unquoted in description
description: Use when: analyzing code

# ✅ RIGHT: Quote the description
description: "Use when: analyzing code for security"
```

### Problem 5: Skills Not Found in `.skills/` Directory

**If a skill doesn't exist**:

1. Search alternatives:
```bash
ls .skills/ | grep -i keyword
grep -r "vulnerability" .skills/ | head -5
```

2. Create custom skill:
```bash
mkdir -p .github/skills/custom-skill
# Create SKILL.md
```

3. Reference external resources in documentation

---

## Updates & Maintenance

### Monthly Review

**First Friday of each month**:

1. **Review Threat Landscape**
   - Any new CVE/CWE affecting TrustNet?
   - Update threat model in `SECURITY_ARCHITECTURE.md`
   - Flag new skills needed in `.skills/`

2. **Check Skill Coverage**
   - Run audit on project components
   - Verify appropriate skills exist for:
     - Smart contracts (api/contracts/)
     - APIs (api/routes/)
     - Infrastructure (Dockerfile, k8s/)

3. **Update Documentation**
   - Add new examples to `operations/SECURITY_SKILLS_QUICK_START.md`
   - Update skill taxonomy in `trustnet-security/SKILL.md`
   - Note lessons learned

### When Adding New TrustNet Feature

**Checklist**:

- [ ] Identify security domain (contracts, APIs, infrastructure)
- [ ] Search `.skills/` for applicable skills
- [ ] Add to `trustnet-security/SKILL.md` taxonomy
- [ ] Update workflow in `security-assessment.instructions.md`
- [ ] Create custom skill if needed (`.github/skills/custom-*/`)
- [ ] Test auto-trigger on new files
- [ ] Document in `operations/SECURITY_SKILLS_QUICK_START.md`
- [ ] Update `SECURITY_ARCHITECTURE.md` threat model

### When Skills Deprecated or Updated

If a skill in `.skills/` becomes outdated:

1. **Find references**:
   ```bash
   grep -r "skill-name" .github/ operations/
   ```

2. **Update references**:
   - Remove from `trustnet-security/SKILL.md`
   - Update workflows in instructions
   - Add note about deprecation

3. **Document migration**:
   - Create file: `.github/skills/MIGRATION_LOG.md`
   - Note: Old skill → New skill / Custom replacement

**Example**:
```markdown
## Skill Migrations

### 2026-03-16
- Deprecated: analyzing-old-contract-pattern
- Replaced with: trustnet-blockchain-analysis (custom skill)
- Files affected: .github/skills/trustnet-security/SKILL.md
- Reason: Added TrustNet-specific analysis requirements
```

### Quarterly Training

**Every Quarter** - Update team:

```markdown
## Q1 2026 Security Skills Review

### New Skills Added
- [Skill 1]: Use case
- [Skill 2]: Use case

### Updated Workflows
- Component 1: New security checks added

### New Custom Skills
- [custom-skill]/: Purpose

### Team Training
- Date: [Date]
- Topics: [Topics]
- Lab: [Lab exercise]
```

---

## Version Control & Git Workflow

### Committing Changes to Skills

```bash
# Stage configuration files
git add .github/instructions/security-assessment.instructions.md
git add .github/skills/trustnet-security/SKILL.md

# Stage documentation
git add operations/SECURITY_SKILLS_QUICK_START.md
git add copilot-instructions.md

# Commit with descriptive message
git commit -m "docs: Add security skill router and auto-trigger instructions

- Create security-assessment.instructions.md for auto-triggering
- Add trustnet-security skill router to .github/skills/
- Document quick start and integration architecture
- Enables automatic skill loading for security assessments"

# Push to remote
git push
```

### Documenting in Code Comments

When using security skills in actual code reviews:

```go
// Security: API authorization check
// Skill Reference: conducting-api-security-testing
// Checked: endpoint requires user ownership validation
// Issue: IDOR risk if user_id not validated
func UpdateUserProfile(userID string) error {
    currentUser := GetCurrentUser()
    if currentUser.ID != userID {
        return ErrUnauthorized  // ✓ Fixed
    }
    // ...
}
```

### Pre-Commit Hook (Optional)

Create `.git/hooks/pre-commit` to validate YAML:

```bash
#!/bin/bash
# Validate YAML frontmatter in security instructions

echo "Validating YAML syntax..."

# Check all instruction files
for file in .github/instructions/*.md .github/skills/*/*.md; do
    if [[ -f "$file" ]]; then
        # Simple check: frontmatter exists
        if head -1 "$file" | grep -q "^---"; then
            echo "✓ $file"
        else
            echo "✗ $file - Missing frontmatter"
            exit 1
        fi
    fi
done

echo "✓ All files valid"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## Quick Reference: Common Maintenance Tasks

### Add New Skill to Router
```
1. Edit: .github/skills/trustnet-security/SKILL.md
2. Find domain section
3. Add: `- `skill-name/` → Description`
4. Test with: "Use skill: trustnet-security"
```

### Create Custom Skill
```
1. mkdir -p .github/skills/skill-name
2. Create: .github/skills/skill-name/SKILL.md
3. Add YAML frontmatter (name, description)
4. Add content with methodology
5. Reference in: trustnet-security/SKILL.md
```

### Add Auto-Trigger Pattern
```
1. Edit: .github/instructions/security-assessment.instructions.md
2. Update: applyTo: "**/*{pattern1,pattern2}*"
3. Add step-by-step methodology
4. Test auto-trigger
```

### Update Documentation
```
1. Edit: operations/SECURITY_SKILLS_QUICK_START.md (examples)
2. Edit: operations/SECURITY_SKILLS_INTEGRATION.md (architecture)
3. Update: copilot-instructions.md (guidelines)
4. Commit with: git add && git commit -m "docs: ..."
```

---

## Support & Resources

### Internal Resources
- **Threat Model**: `SECURITY_ARCHITECTURE.md`
- **Quick Examples**: `operations/SECURITY_SKILLS_QUICK_START.md`
- **Architecture**: `operations/SECURITY_SKILLS_INTEGRATION.md`
- **Workspace Guidelines**: `copilot-instructions.md`

### External Resources
- **Cybersecurity Skills Repo**: `.skills/` (300+ skills)
- **OWASP**: https://owasp.org/
- **MITRE ATT&CK**: https://attack.mitre.org/
- **CWE/CVSS**: https://cwe.mitre.org/

### Getting Help

For questions about:
- **Usage**: See `operations/SECURITY_SKILLS_QUICK_START.md`
- **Architecture**: See `operations/SECURITY_SKILLS_INTEGRATION.md`
- **Adding Skills**: See section "Adding New Skills" (this file)
- **Troubleshooting**: See section "Troubleshooting" (this file)

---

## Checklist: Initial Setup Verification

After setting up, verify everything works:

```markdown
## Setup Verification Checklist

### Files Created
- [ ] copilot-instructions.md (root)
- [ ] .github/instructions/security-assessment.instructions.md
- [ ] .github/skills/trustnet-security/SKILL.md
- [ ] operations/SECURITY_SKILLS_QUICK_START.md
- [ ] operations/SECURITY_SKILLS_INTEGRATION.md
- [ ] operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md (THIS FILE)

### YAML Validation
- [ ] No tabs (spaces only)
- [ ] All colons quoted in descriptions
- [ ] No unquoted special characters
- [ ] Name fields match filenames

### Auto-Trigger Testing
- [ ] *.sol files trigger instruction
- [ ] api/** files trigger instruction
- [ ] docker* files trigger instruction
- [ ] security/* files trigger instruction

### Explicit Request Testing
- [ ] "Use skill: trustnet-security" works
- [ ] Skill lists appropriate domains
- [ ] Can navigate to specific skill types

### Documentation
- [ ] README.md references security skills
- [ ] operations/SECURITY_SKILLS_QUICK_START.md has examples
- [ ] copilot-instructions.md visible to developers
- [ ] All links between docs work

### Team Communication
- [ ] Developers notified of new skills
- [ ] Usage examples shared
- [ ] Support contact identified
- [ ] Training scheduled (if needed)
```

---

**Last Updated**: March 16, 2026  
**Version**: 1.0  
**Maintained By**: TrustNet Security Team  
**Next Review**: April 16, 2026 (Monthly check)

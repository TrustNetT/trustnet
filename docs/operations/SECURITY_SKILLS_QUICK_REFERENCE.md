# Security Skills Quick Reference Card

**Print this or bookmark it for quick access**

---

## 🚀 Usage Cheat Sheet

### Auto-Trigger (Recommended)
Just work on security tasks:
```
Edit Token.sol → AI auto-loads smart contract security skills
Edit api/routes/auth.go → AI auto-loads API security skills
Edit Dockerfile → AI auto-loads container hardening skills
Ask "find vulnerabilities" → AI auto-loads relevant skills
```

### Explicit Request
```
"Use skill: trustnet-security"
Then: describe what you need
```

---

## 📁 File Locations Reference

| What | Where | When Updated |
|------|-------|--------------|
| **Workspace Rules** | `copilot-instructions.md` | When project changes |
| **Auto-Trigger Logic** | `.github/instructions/security-assessment.instructions.md` | When adding new file types |
| **Skill Router** | `.github/skills/trustnet-security/SKILL.md` | When adding new skills |
| **Examples** | `operations/SECURITY_SKILLS_QUICK_START.md` | When new patterns emerge |
| **Architecture** | `operations/SECURITY_SKILLS_INTEGRATION.md` | When system design changes |
| **Setup** | `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` | When procedures change |

---

## 🔧 Common Tasks

### Add Skill to the Router
```bash
cd .github/skills/trustnet-security/

# Edit SKILL.md
# Find domain section
# Add line: - `skill-folder-name/` → Description

# Save and test
```

### Create New Custom Skill
```bash
mkdir -p .github/skills/my-skill

cat > .github/skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: "Use when: [your trigger phrase here]"
---

# [Skill Title]

## Purpose
[What this skill does]

## Steps
1. [Step 1]
2. [Step 2]
...
EOF
```

### Test Auto-Trigger
```bash
# Edit a triggering file
echo "// test" >> api/routes/test.go

# In VS Code AI chat:
# "Security review of this endpoint"
# 
# Should load security-assessment instruction
```

### Fix YAML Errors
```yaml
# ❌ Wrong
description: Use when: analyzing code
applyTo: ["*.sol"]

# ✅ Right  
description: "Use when: analyzing code"
applyTo: "**/*.sol"
```

---

## 🐛 Quick Troubleshooting

| Problem | Check | Fix |
|---------|-------|-----|
| Skill not loading | File exists? | Verify path and filename |
| Wrong skill loads | Description specific? | Add more keywords |
| YAML error | Tab characters? | Use spaces only |
| Pattern not triggering | File matches pattern? | Check glob syntax |

---

## 📝 File Structure You Need

```
.github/
├── instructions/
│   └── security-assessment.instructions.md
└── skills/
    └── trustnet-security/
        └── SKILL.md

copilot-instructions.md
operations/
├── SECURITY_SKILLS_QUICK_START.md
├── SECURITY_SKILLS_INTEGRATION.md
├── SECURITY_SKILLS_SETUP_MAINTENANCE.md
├── SECURITY_SKILLS_QUICK_REFERENCE.md
└── SECURITY_SKILLS_INDEX.md
```

---

## 🎯 Skills Organized by Use Case

### Smart Contracts
```
"Audit smart contract"
→ analyzing-ethereum-smart-contract-vulnerabilities
→ exploiting-vulnerabilities-with-metasploit-framework
```

### APIs
```
"Review API security"
→ conducting-api-security-testing
→ testing-for-broken-object-level-authorization
```

### Docker
```
"Harden Dockerfile"
→ hardening-docker-containers-for-production
```

### Kubernetes
```
"Audit Kubernetes RBAC"
→ auditing-kubernetes-cluster-rbac
→ hardening-kubernetes-pod-security-standards
```

### Threats
```
"Create threat model"
→ threat-modeling-with-mitre-attack
```

---

## ✅ Verification Checklist

After setup or changes:
- [ ] All 5 configuration files exist
- [ ] YAML has no syntax errors (quotes around colons)  
- [ ] Auto-trigger works for *.sol files
- [ ] Auto-trigger works for api/** files
- [ ] "Use skill: trustnet-security" loads
- [ ] Can navigate skill domains
- [ ] Documentation links work

---

## 📅 Maintenance Calendar

| When | Task |
|------|------|
| **Monthly** | Review new threats, update docs |
| **Quarterly** | Team training, skill audit |
| **New Feature** | Add security checks to skill router |
| **CVE Alert** | Update threat model + add skills |
| **Deprecated Skill** | Create migration log, update docs |

---

## 🔗 Key Documents

**For Getting Started**:
→ `operations/SECURITY_SKILLS_QUICK_START.md`

**For Architecture**:
→ `operations/SECURITY_SKILLS_INTEGRATION.md`

**For Setup/Maintenance**:
→ `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md`

**For Project Guidelines**:
→ `copilot-instructions.md`

---

## 💡 Pro Tips

1. **Be specific in requests** - "Audit Token.sol for reentrancy" > "Security review"
2. **Check for existing skills** - Before creating custom, search `.skills/` 
3. **Comment in code** - Reference skills in security-critical code comments
4. **Keep docs updated** - Add examples as you discover patterns
5. **Test after changes** - Verify YAML syntax and auto-triggers work

---

## 🆘 Getting Help

**Question About**: → **See Section**
- Usage | `operations/SECURITY_SKILLS_QUICK_START.md`
- Architecture | `operations/SECURITY_SKILLS_INTEGRATION.md`  
- Adding skills | `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` > "Adding New Skills"
- Troubleshooting | `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` > "Troubleshooting"
- Project rules | `copilot-instructions.md`

---

## 📊 Skills Directory Map

```
.skills/
├── analyzing-* (50+)        → Code analysis & auditing
├── building-* (30+)         → System architecture
├── conducting-* (40+)       → Testing & assessment
├── configuring-* (25+)      → System hardening
├── detecting-* (50+)        → Threat detection
├── exploiting-* (35+)       → Vulnerability testing
├── implementing-* (45+)     → Security controls
├── hunting-* (30+)          → Threat hunting
├── performing-* (60+)       → Operations & response
└── ... (300+ total skills)
```

---

## 🚨 Critical Remember-Its

| ⚠️ Do This | ❌ Don't Do This |
|----------|------------------|
| Quote descriptions | Use colons unquoted: `Use when: foo` |
| Use spaces in YAML | Mix spaces and tabs |
| Match name to folder | Have mismatched names |
| Test after changes | Assume it works |
| Keep docs updated | Leave outdated examples |
| Review monthly | Ignore threat landscape changes |

---

**Last Updated**: March 16, 2026  
**Use This**: As desktop reference card (print/bookmark)  
**Related**: See `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` for full guide

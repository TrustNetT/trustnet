# TrustNet Security Skills Documentation Index

**Start here** to find the right guide for what you need.

---

## 📚 Documentation Roadmap

```
You want to... → Read This File → Time to read
────────────────────────────────────────────────
Get started using skills → operations/SECURITY_SKILLS_QUICK_START.md → 5 min
Understand how it works → operations/SECURITY_SKILLS_INTEGRATION.md → 15 min
Add/modify skills → operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md → 20 min
Quick reference (print!) → operations/SECURITY_SKILLS_QUICK_REFERENCE.md → 2 min
Project guidelines → copilot-instructions.md → 10 min
This index → SECURITY_SKILLS_INDEX.md ← You are here
```

---

## 🎯 By User Role

### 👨‍💻 **Developers** (Using security skills in daily work)

**Start with**:
1. `operations/SECURITY_SKILLS_QUICK_START.md` - How to request security assessments
2. `operations/SECURITY_SKILLS_QUICK_REFERENCE.md` - Keep bookmarked for quick lookup

**Then explore**:
- `copilot-instructions.md` - Project security guidelines
- `operations/SECURITY_SKILLS_INTEGRATION.md` - Optional: understand system architecture

---

### 👨‍💼 **Project Leads** (Managing security for the project)

**Start with**:
1. `operations/SECURITY_SKILLS_INTEGRATION.md` - System architecture
2. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` - How to maintain and extend

**Then configure**:
- `copilot-instructions.md` - Update for your project
- `.github/instructions/security-assessment.instructions.md` - Customize workflows

---

### 🔒 **Security Team** (Reviewing & extending skills)

**Essential**:
1. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` - Section: "Adding New Skills"
2. `operations/SECURITY_SKILLS_INTEGRATION.md` - Skill taxonomy and workflows
3. `.github/skills/trustnet-security/SKILL.md` - Current skill inventory

**Reference**:
- `.skills/` directory - 300+ existing skills
- `SECURITY_ARCHITECTURE.md` - Threatmodel integration

---

### 🏗️ **Infrastructure/DevOps** (Setting up security tools)

**Read**:
1. `operations/SECURITY_SKILLS_INTEGRATION.md` - Section: "Tool Integration"
2. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` - Section: "Testing & Validation"

**Implement**:
- `.github/instructions/security-assessment.instructions.md` - Tool recommendations
- `.github/skills/trustnet-security/SKILL.md` - Infrastructure security workflows

---

## 📖 By Topic

### Getting Started
- **"How do I use the security skills?"**
  → `operations/SECURITY_SKILLS_QUICK_START.md` (Examples section)

- **"What security assessments can I request?"**
  → `operations/SECURITY_SKILLS_INTEGRATION.md` (Skill Taxonomy section)

- **"How do I know which skill to use?"**
  → `operations/SECURITY_SKILLS_QUICK_REFERENCE.md` (Skills Organized by Use Case)

---

### Setting Up

- **"How was this set up?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (section: Initial Setup Steps)

- **"I want to replicate this for another project"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Initial Setup Steps - step by step)

- **"What files do I need?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (File Structure Overview)

---

### Adding/Customizing Skills

- **"How do I add a new skill?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (section: Adding New Skills)

- **"I want to create a custom TrustNet-specific skill"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Scenario 2: Custom Skills)

- **"How do I modify existing security checks?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (section: Customizing Existing Skills)

- **"What's the skill taxonomy?"**
  → `operations/SECURITY_SKILLS_INTEGRATION.md` (Skill Taxonomy section) OR
  → `.github/skills/trustnet-security/SKILL.md` (Full listing)

---

### Troubleshooting

- **"Skills aren't loading automatically"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Troubleshooting: Problem 1)

- **"YAML syntax errors"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Troubleshooting: Problem 4)

- **"I got the wrong skill"**
  → `operations/SECURITY_SKILLS_QUICK_START.md` (Troubleshooting section)

- **"How do I validate the setup?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (section: Testing & Validation)

---

### Maintaining

- **"How often should I update skills?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Updates & Maintenance section)

- **"What's the monthly checklist?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Monthly Review)

- **"A skill is deprecated, what do I do?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (When Skills Deprecated)

- **"How do I document changes?"**
  → `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (Version Control & Git Workflow)

---

### Understanding System Design

- **"How does the system work?"**
  → `operations/SECURITY_SKILLS_INTEGRATION.md` (System Overview section)

- **"What's the execution flow from request to skill loading?"**
  → `operations/SECURITY_SKILLS_INTEGRATION.md` (Execution Flow section)

- **"How do instructions layer and take precedence?"**
  → `operations/SECURITY_SKILLS_INTEGRATION.md` (Instruction Precedence & Layering)

- **"How do I integrate skills with TrustNet components?"**
  → `operations/SECURITY_SKILLS_INTEGRATION.md` (Integration Points section)

---

## 📋 File-by-File Breakdown

### `copilot-instructions.md` (Root)
**What**: Workspace guidelines for AI agent  
**Audience**: All developers  
**Length**: ~300 lines  
**Update Frequency**: When project changes  
**Contains**:
- Project overview
- Security-first philosophy  
- How to use skills (high level)
- When NOT to use AI
- Code commenting patterns

**Start Reading When**: Onboarding to project

---

### `operations/SECURITY_SKILLS_QUICK_START.md`
**What**: Development guide with examples  
**Audience**: Developers (primary), all (secondary)  
**Length**: ~400 lines  
**Update Frequency**: When new patterns emerge  
**Contains**:
- How to trigger skills (3 methods)
- Real-world examples with outputs
- Skills by domain reference
- Troubleshooting & FAQ
- Workflow patterns
- File organization tips

**Start Reading When**: First time using security skills

---

### `operations/SECURITY_SKILLS_INTEGRATION.md`
**What**: Technical architecture & design  
**Audience**: Tech leads, maintainers, architects  
**Length**: ~500 lines  
**Update Frequency**: When system design changes  
**Contains**:
- System overview with diagrams
- Execution flow (request → skill)
- Instruction layering & precedence
- Integration with TrustNet components
- Skill loading patterns
- Output standardization
- Tool integration
- Customization & extension
- Troubleshooting
- Roadmap

**Start Reading When**: Need to understand how system works

---

### `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md`
**What**: Complete setup & maintenance procedures  
**Audience**: Project leads, security team, maintainers  
**Length**: ~1000 lines  
**Update Frequency**: When procedures change  
**Contains**:
- What was set up & why
- Initial setup (step-by-step replication)
- File structure overview
- Adding new skills (3 scenarios)
- Customizing existing skills
- Testing & validation (6 tests)
- Troubleshooting (5 problems)
- Updates & maintenance procedures
- Git workflow for skills
- Quick reference for common tasks
- Support & resources
- Verification checklist

**Start Reading When**:
- Setting up for another project
- Adding custom skills
- Maintaining/updating system
- Troubleshooting issues

---

### `operations/SECURITY_SKILLS_QUICK_REFERENCE.md`
**What**: One-page cheat sheet (print/bookmark)  
**Audience**: All developers  
**Length**: ~100 lines  
**Update Frequency**: Rarely  
**Contains**:
- Usage cheat sheet
- File locations
- Common tasks (copy-paste ready)
- Quick troubleshooting
- Skills by use case
- Verification checklist
- Maintenance calendar
- Pro tips

**Start Reading When**: Need quick lookup (print it!)

---

### `.github/instructions/security-assessment.instructions.md`
**What**: Auto-triggered security methodology  
**Audience**: AI agent (primary), humans (secondary)  
**Length**: ~500 lines  
**Update Frequency**: When adding new assessment types  
**Contains**:
- Security assessment workflow (5 steps)
- Threat model integration
- MITRE ATT&CK mapping
- Common security tasks by type
- Output format specification
- Escalation procedures
- Tool integration

**Purpose**: Auto-loads when working on `*.sol`, `api/**`, etc.

---

### `.github/skills/trustnet-security/SKILL.md`
**What**: Skill router & taxonomy  
**Audience**: AI agent (primary), humans (secondary)  
**Length**: ~600 lines  
**Update Frequency**: When adding new skills  
**Contains**:
- Skill taxonomy (organized by domain)
- End-to-end workflows (5+ scenarios)
- Component-specific integration guides
- Tool recommendations by skill type
- Output format guidelines
- Critical vulnerability escalation

**Purpose**: Routes to 300+ skills, provides domain organization

---

### `operations/SECURITY_SKILLS_INDEX.md` (Root - THIS FILE)
**What**: Navigation guide for all documentation  
**Audience**: All (first stop!)  
**Length**: ~300 lines  
**Update Frequency**: When docs updated  
**Contains**:
- Documentation roadmap
- By-user-role guides
- By-topic guides
- File-by-file breakdown
- Cross-references
- Update instructions

**Purpose**: Help you find the right document

---

## 🔗 Cross-Reference Map

```
Question              | Primary Doc              | Secondary Docs
──────────────────────|─────────────────────────|──────────────────
Using skills?         | QUICK_START             | Quick Ref
How to add skills?    | SETUP_MAINTENANCE       | Integration
System design?        | INTEGRATION             | Setup_Maintenance
Project guidelines?   | copilot-instructions    | QUICK_START
Troubleshooting?      | SETUP_MAINTENANCE       | INTEGRATION
Setting up project?   | SETUP_MAINTENANCE       | All docs
Which file exists?    | SETUP_MAINTENANCE       | Integration
Testing setup?        | SETUP_MAINTENANCE       | Quick_Ref
Maintenance calendar? | SETUP_MAINTENANCE       | Quick_Ref
Which skill for task? | INTEGRATION or router   | QUICK_START
```

---

## ✨ Documentation Philosophy

This documentation set is organized around **user workflows**, not file structure:

1. **Developers** start with QUICK_START (examples first)
2. **Maintainers** start with SETUP_MAINTENANCE (procedures)
3. **Architects** start with INTEGRATION (system design)
4. **Everyone** uses QUICK_REFERENCE for quick lookup
5. **This index** helps route to the right doc

---

## 🎓 Reading Tracks

### Track 1: "I'm a developer getting started" (20 min)
1. This file (2 min) ← You are here
2. `operations/SECURITY_SKILLS_QUICK_START.md` (10 min)
3. `operations/SECURITY_SKILLS_QUICK_REFERENCE.md` (2 min) - Print it!
4. `copilot-instructions.md` (5 min) - Skim guidelines

**Outcome**: Can request security skills, know best practices

### Track 2: "I'm maintaining the system" (45 min)
1. This file (5 min) ← You are here
2. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (25 min)
3. `operations/SECURITY_SKILLS_INTEGRATION.md` (15 min)
4. `.github/skills/trustnet-security/SKILL.md` (10 min)

**Outcome**: Can add/modify skills, understand architecture

### Track 3: "I'm setting up for a new project" (60 min)
1. This file (5 min) ← You are here
2. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` > "Initial Setup Steps" (30 min)
3. `operations/SECURITY_SKILLS_INTEGRATION.md` (15 min)
4. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` > "Testing & Validation" (10 min)

**Outcome**: Can replicate setup for new project

### Track 4: "I need to dig into architecture" (90 min)
1. This file (5 min) ← You are here  
2. `operations/SECURITY_SKILLS_INTEGRATION.md` (30 min)
3. `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md` (30 min)
4. `.github/skills/trustnet-security/SKILL.md` (15 min)
5. `.github/instructions/security-assessment.instructions.md` (10 min)

**Outcome**: Complete understanding of system design & implementation

---

## 📞 Quick Support Map

| Help Needed | Quick Link | Detailed Reference |
|-------------|-----------|-------------------|
| How to use? | `operations/QUICK_START` Examples | `operations/INTEGRATION` Skill Taxonomy |
| Add skill? | `operations/SETUP_MAINTENANCE` Scenario 2 | Full "Adding New Skills" section |
| Not working? | `operations/QUICK_REFERENCE` Troubleshooting | `operations/SETUP_MAINTENANCE` Troubleshooting |
| Print card? | `operations/QUICK_REFERENCE.md` | Print as A4 or bookmark |
| Project setup? | `operations/SETUP_MAINTENANCE` Initial Steps | Step-by-step section |

---

## 📊 Documentation Statistics

| Document | Lines | Sections | Audience | Update Freq |
|----------|-------|----------|----------|------------|
| copilot-instructions.md | 250 | 8 | Developers | As needed |
| operations/QUICK_START.md | 400 | 12 | Developers | Monthly |
| operations/INTEGRATION.md | 500 | 15 | Architects | Quarterly |
| operations/SETUP_MAINTENANCE.md | 1000 | 20 | Maintainers | Quarterly |
| operations/QUICK_REFERENCE.md | 100 | 10 | Everyone | Rarely |
| operations/INDEX.md (THIS FILE) | 300 | 12 | Everyone | Quarterly |

**Total**: ~2500 lines of documentation across 6 files

---

## 🔄 Update Workflow

### When Adding New Skill
```
1. Update: .github/skills/trustnet-security/SKILL.md
2. Test: operations/SETUP_MAINTENANCE > Testing & Validation  
3. Document: Add example to operations/QUICK_START.md
4. Notify: Update operations/QUICK_REFERENCE.md if methodology changes
5. Commit: git add && git commit -m "docs: Add X skill"
```

### When Project Changes
```
1. Update: copilot-instructions.md (guidelines)
2. Update: operations/SETUP_MAINTENANCE.md (procedures)
3. Update: This index if structure changes
4. Announce: Team communication
```

### When System Design Changes
```
1. Update: operations/INTEGRATION.md (architecture)
2. Update: operations/SETUP_MAINTENANCE.md (setup steps)
3. Update: .github instructions (if needed)
4. Review: Cross-references in all docs
```

---

## ✅ Verification Checklist

Before publishing documentation updates:

```markdown
- [ ] All files are correctly linked
- [ ] No broken internal references
- [ ] YAML frontmatter is valid (no tabs, quotes around colons)
- [ ] Examples run successfully  
- [ ] File locations are accurate
- [ ] No outdated procedures
- [ ] Team has been notified
- [ ] Index has been updated
```

---

## 🎯 Next Steps

Based on your role, read these in order:

**👨‍💻 If you're a developer**: Start with `operations/SECURITY_SKILLS_QUICK_START.md`

**👨‍💼 If you're maintaining**: Start with `operations/SECURITY_SKILLS_SETUP_MAINTENANCE.md`

**🏗️ If you're understanding design**: Start with `operations/SECURITY_SKILLS_INTEGRATION.md`

**📚 If you need a quick reference**: Use `operations/SECURITY_SKILLS_QUICK_REFERENCE.md`

---

**Last Updated**: March 16, 2026  
**Version**: 1.0  
**Next Review**: April 16, 2026  
**Maintained By**: TrustNet Documentation Team

# GitHub Evidence Archive

**Purpose**: Catalog GitHub commits as proof of R&D development work  
**Repository**: https://github.com/TrustNetT/trustnet-wip  
**Updated**: Monthly for HMRC submission

---

## Key Commits Log

### Early February 2026 - Research Phase
```
[Placeholder - screenshots to be taken monthly]
- Commit hashes documenting research initial setup
- Technical specification draft commits
- Architecture decision documentation
```

### Mid-Late February 2026 - Architecture Design
```
- BLOCKCHAIN_ARCHITECTURE.md initial commit
- SECURITY_ARCHITECTURE.md specification
- API_IMPLEMENTATION_PLAN.md API contract design
- TECHNOLOGY_STACK_DECISIONS.md rationale documentation
```

### Early March 2026 - Repository Launch
```
- Repository initialization
- README.md and project overview
- LICENSE (Apache 2.0) for open-source decentralized model
- Initial documentation structure
```

### Mid-March 2026 - Website & Infrastructure
```
- Website domain configuration
- SSL certificate setup
- Authentication infrastructure code
- Development environment setup
```

---

## How to Extract GitHub Commit History

### Command to Get Full Commit Log
```bash
cd /path/to/trustnet-wip
git log --oneline --all > commits_full.txt
git log --pretty=fuller > commits_detailed.txt
```

### Command to Get Commits by Author
```bash
git log --oneline --author="Your Name" > commits_by_author.txt
```

### Command to Get Commits in Date Range
```bash
git log --oneline --since="2026-02-01" --until="2026-04-01" > commits_feb_march.txt
```

### Screenshots to Take Quarterly
1. GitHub repository overview page
2. Commit graph showing activity over time
3. Key files changed (BLOCKCHAIN_ARCHITECTURE.md, etc.)
4. Pull request activity (if applicable)
5. Release/tag history

---

## Commit Categories for HMRC Purposes

### Core R&D Work (Evidence for 65% of hours)
- Blockchain architecture specification
- Cryptographic implementation specifications
- Smart contract design
- API endpoint design
- Identity verification logic

### Infrastructure R&D (Evidence for 10% of hours)
- Docker/container configuration
- CI/CD pipeline setup
- Development environment automation
- Deployment infrastructure design

### Testing & Validation (Evidence for 5% of hours)
- Unit test specifications
- Integration test design
- Security test planning
- Performance test specifications

### Security & Compliance (Evidence for 20% of hours)
- Threat model documentation
- Security audit planning
- Regulatory compliance documentation
- Cryptographic security specifications

---

## Correlation Between Commits & Time Logs

**February R&D Commits**:
- Should show ~130 hours of work across 4 weeks
- Average 6-7 commits per week
- File changes showing progression from research → design → specification

**March R&D Commits** (to date):
- Should show ~52 hours through March 16
- Average 3-4 commits per week
- File changes showing progression from specification → implementation

---

## Evidence Preservation Instructions

### For Monthly Updates
1. Run `git log` commands monthly (around the 25th of each month)
2. Save output to text files in `github-evidence/`
3. Take 2-3 screenshots showing GitHub UI
4. Note any significant milestones or breakthroughs

### Before HMRC Submission (April 2027)
1. Export full year's commit history (Feb 2026 - Dec 2026)
2. Create summary document showing:
   - Commit frequency (consistency indicator)
   - File changes (output documentation)
   - Contributors (developer hours)
3. Attach to R&D claim as supporting evidence

### HMRC May Request
- Clarification on specific commits (e.g., "What technical problem was solved here?")
- Connection between commits and claimed hours
- Evidence that work was undertaken for R&D purposes (not routine maintenance)

**Preparation**: Keep development journal entries aligned with commit dates so you can reference them if HMRC asks for details.

---

## Key Files as R&D Evidence

| File | Purpose | First Created | Last Modified | Commits |
|------|---------|---------------|---------------|---------|
| BLOCKCHAIN_ARCHITECTURE.md | R&D specification | Feb 2026 | Mar 2026 | ~5 |
| SECURITY_ARCHITECTURE.md | Security R&D | Feb 2026 | Mar 2026 | ~4 |
| API_IMPLEMENTATION_PLAN.md | API design R&D | Feb 2026 | On-going | ~3+ |
| TECHNOLOGY_STACK_DECISIONS.md | Tech evaluation | Feb 2026 | Mar 2026 | ~2 |
| Smart contract stubs | Implementation R&D | Mar 2026 | On-going | TBD |

**Evidence Value**: Each file represents hours of research + decision-making, visible through git history.

---

## Tips for Maximum HMRC Evidence

### DO:
- ✅ Make commits frequently (~3-4 per week during active R&D)
- ✅ Use clear commit messages ("Add ICAO 9303 verification specification" is better than "update")
- ✅ Include technical details in commit descriptions
- ✅ Reference problems solved in commit messages ("Resolved scalability concern by...")
- ✅ Keep documentation in same repository as code
- ✅ Use branches for experimental work (shows iterative development)

### AVOID:
- ❌ Long gaps with no commits (makes hours claim look suspicious)
- ❌ Generic commit messages ("update files", "minor fix")
- ❌ Commits that are clearly non-R&D (e.g., "fix typo", "update license")
- ❌ Moving all code at once (appears less like development, more like upload)
- ❌ Mixing R&D with routine maintenance at high commit volume

---

## Quarterly Screenshots Checklist

### March 2026 (Completed)
- [ ] GitHub repository overview
- [ ] Commit history graph (Feb-Mar)
- [ ] List of active files created
- [ ] Branches showing experimental work
- [ ] File change statistics

### June 2026 (Plan)
- [ ] Screenshot showing Feb-Jun commit activity
- [ ] Updated README or project status visible
- [ ] Implementation progress visible in code changes

### September 2026 (Plan)
- [ ] Full 6-month commit history screenshot
- [ ] Updated architecture documents visible
- [ ] Test file creation visible

### December 2026 (Plan)
- [ ] Full year's commit history screenshot
- [ ] Release tags or version history
- [ ] Major milestones achieved

---

## Archive Location

Save all GitHub evidence extracts to:
- `/docs/r&d-claim/github-evidence/commits_[MONTH]_[YEAR].txt`
- `/docs/r&d-claim/github-evidence/screenshots_[MONTH]_[YEAR]/`

This allows easy compilation when submitting to HMRC.

---

**Next Update**: April 25, 2026 (monthly export)  
**HMRC Submission Ready**: April 2027 (full year's evidence)


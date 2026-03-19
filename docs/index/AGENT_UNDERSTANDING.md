# TrustNet Project Structure Understanding

## Current Date
February 11, 2026

## Project Architecture
Based on PMO guidelines for dual-repo workflow:

### Symlink Structure (in ~/GitProjects/)
```
~/GitProjects/TrustNet/
├── trustnet-wip → /home/jcgarcia/wip/priv/trustnet-wip/ (SOURCE OF TRUTH - WIP REPO)
├── trustnet-org → /home/jcgarcia/wip/priv/trustnet-wip/ (duplicate symlink)
└── TrustNet → /home/jcgarcia/wip/pub/TrustNet (PUBLIC DISTRIBUTION)
```

### Correct Workflow
1. **EDIT**: Work in `/home/jcgarcia/GitProjects/TrustNet/trustnet-wip/`
2. **COMMIT**: Push changes to trustnet-wip GitHub repository
3. **PUBLISH**: Use publish script to sync to public distribution repo
4. **TEST**: On macOS, clone trustnet-wip repo (NOT separate ios-app repo)
5. **NAVIGATE**: Go to trustnet-wip/ios subdirectory for iOS app

### ERROR MADE
- Cloned `TrustNetT/ios-app.git` separately on macOS
- This created a divergent code branch not tracked in trustnet-wip
- Should have cloned/used `TrustNetT/trustnet-wip.git` instead
- iOS app is a COMPONENT within trustnet-wip, not a separate project

### iOS App Location
- **Local WIP**: `/home/jcgarcia/GitProjects/TrustNet/trustnet-wip/ios/`
- **macOS should use**: Clone/pull from trustnet-wip repo → navigate to ios/ subdirectory
- **Current mistake**: macOS has separate ios-app repo not connected to trustnet-wip

### Files Involved
- App.swift: Located at `trustnet-wip/ios/TrustNetValidator/App.swift`
- Status: Has splash screen implementation but NOT in GitHub yet
- LoginView.swift
- RegistrationView.swift  
- SplashScreenView.swift

## Next Steps
1. Understand why ios folder is marked as "untracked" in trustnet-wip
2. Check .gitignore to see if ios/ is intentionally ignored
3. Properly commit iOS changes to trustnet-wip repository
4. Push to GitHub
5. On macOS: Use trustnet-wip clone, navigate to ios subdirectory
6. Rebuild and test app with correct code path

## GOLDEN RULE VIOLATED
❌ Did not maintain changes in version control tied to WIP repo
❌ Made changes directly on macOS without committing to GitHub
❌ Did not document work in activity/ folder of WIP repo
❌ Did not follow single source of truth principle (all changes scattered)

## CORRECTIONS NEEDED
✓ Commit all iOS changes to trustnet-wip repository
✓ Document work in trustnet-wip/activity/
✓ Ensure macOS clone points to trustnet-wip (not separate ios-app)
✓ All future edits in ~/GitProjects/TrustNet/trustnet-wip/ios/
✓ Never edit directly on macOS without committing to GitHub first

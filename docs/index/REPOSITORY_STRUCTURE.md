# TrustNet Repository Structure

**Updated**: February 8, 2026

---

## Architecture Overview

TrustNet uses a dual-repository model matching the PMO workflow pattern:

```
GitHub Repositories:
├── trustnet-wip (environment hub - CI/CD, docs, planning)
├── ios-app (clean iOS native code)
└── android-app (clean Android native code)

Physical Locations:
├── ~/wip/pub/ios-app/ (iOS git repo)
├── ~/wip/pub/android-app/ (Android git repo)
└── ~/GitProjects/TrustNet/trustnet-wip/ (WIP environment hub)
    ├── ios → symlink to ~/wip/pub/ios-app
    └── android → symlink to ~/wip/pub/android-app
```

---

## Repository Purposes

### trustnet-wip (Environment Hub)
**Location**: `~/GitProjects/TrustNet/trustnet-wip` (symlink to `~/wip/priv/trustnet-wip`)  
**GitHub**: https://github.com/TrustNetT/trustnet-wip  
**Purpose**: 
- Project planning and documentation
- Development environment configuration
- CI/CD and build orchestration
- Architecture decisions
- Activity tracking and sprints

**Contents**:
- `activity/` - Sprint planning, development logs
- `docs/` - Architecture, design, specifications
- `aws/` - Infrastructure as code
- `api/`, `core/`, `modules/` - Shared backend services
- `ios/` → symlink to ios-app repo
- `android/` → symlink to android-app repo

**Git Remote**:
```bash
cd ~/GitProjects/TrustNet/trustnet-wip
git remote -v
# origin git@github.com:TrustNetT/trustnet-wip.git
```

---

### ios-app (iOS Application)
**Location**: `~/wip/pub/ios-app`  
**GitHub**: https://github.com/TrustNetT/ios-app  
**Purpose**: Clean, minimal iOS native app repository

**Contents**:
```
ios-app/
├── .git/
├── Sources/           # Swift source code
│   ├── PassportValidator.swift
│   └── NFCReader.swift
├── Tests/            # Swift test files
│   └── PassportValidatorTests.swift
├── Package.swift     # Swift Package manifest
└── README.md
```

**Build Environment**: macOS (via `ssh macosx`)  
**Symlinked in trustnet-wip**: `ios/`

**Development Workflow**:
```bash
# On Ubuntu (edit code)
# Code lives in ~/wip/pub/ios-app/
# Access via symlink: ~/GitProjects/TrustNet/trustnet-wip/ios/

# On Ubuntu terminal (build via SSH)
ssh macosx "cd ~/ios-app && swift build"
ssh macosx "cd ~/ios-app && swift test"
```

---

### android-app (Android Application)
**Location**: `~/wip/pub/android-app`  
**GitHub**: https://github.com/TrustNetT/android-app  
**Purpose**: Clean, minimal Android native app repository

**Contents**:
```
android-app/
├── .git/
├── app/
│   ├── src/main/
│   │   ├── java/com/trustnet/
│   │   └── res/
│   └── src/test/
├── build.gradle
├── settings.gradle
└── README.md
```

**Build Environment**: lfactory (via `ssh lfactory`)  
**Symlinked in trustnet-wip**: `android/`

**Development Workflow**:
```bash
# On Ubuntu (edit code)
# Code lives in ~/wip/pub/android-app/
# Access via symlink: ~/GitProjects/TrustNet/trustnet-wip/android/

# On Ubuntu terminal (build via SSH)
ssh lfactory "cd ~/android-app && gradle build"
ssh lfactory "cd ~/android-app && gradle test"
```

---

## Development Workflow

### Single Development Environment (Ubuntu)

All editing happens on Ubuntu in VS Code:

```
Ubuntu (VS Code)
├─ Edit ~/GitProjects/TrustNet/trustnet-wip/ios/...
│  └─ Actually: ~/wip/pub/ios-app/...
├─ Edit ~/GitProjects/TrustNet/trustnet-wip/android/...
│  └─ Actually: ~/wip/pub/android-app/...
└─ Git operations on Ubuntu
```

### Build Environments

**macOS** (`ssh macosx`):
- Swift 6.0.3
- Xcode Command Line Tools
- Clones: `~/ios-app` (synced from Ubuntu)
- Builds iOS with `swift build`
- Tests with `swift test`

**lfactory** (`ssh lfactory`):
- Java 21, Android SDK 34+, Gradle
- Clones: `~/android-app` (synced from Ubuntu)
- Builds Android with `gradle build`
- Tests with `gradle test`

---

## Git Workflow

### iOS App (ios-app)

**On Ubuntu** (trustnet-wip directory):
```bash
# Edit code via symlink
cd ~/GitProjects/TrustNet/trustnet-wip

# Code changes are actually in ~/wip/pub/ios-app/
nano ios/Sources/PassportValidator.swift

# Git operations in the ios-app directory
cd ios  # This is a symlink
git status
git add Sources/PassportValidator.swift
git commit -m "Feb 9 2026: Implement signature validation"
git push origin main
```

**On macOS** (build):
```bash
# macOS syncs when needed
cd ~/ios-app
git pull origin main
swift build
swift test
```

### Android App (android-app)

**On Ubuntu** (trustnet-wip directory):
```bash
# Edit code via symlink
cd ~/GitProjects/TrustNet/trustnet-wip

# Code changes are actually in ~/wip/pub/android-app/
nano android/app/src/main/java/com/trustnet/PassportValidator.kt

# Git operations in the android-app directory
cd android  # This is a symlink
git status
git add app/src/main/java/...
git commit -m "Feb 9 2026: Implement signature validation"
git push origin main
```

**On lfactory** (build):
```bash
# lfactory syncs when needed
cd ~/android-app
git pull origin main
gradle build
gradle test
```

### trustnet-wip (Hub)

**Commit planning docs, architecture notes**:
```bash
cd ~/GitProjects/TrustNet/trustnet-wip

# Edit docs (NOT in ios/ or android/ symlinks)
nano docs/architecture/DESIGN.md
nano activity/sprints/2026-02-09_kickoff.md

# Commit hub changes
git add docs/ activity/
git commit -m "Feb 9 2026: Architecture documentation"
git push origin main
```

---

## Important Notes

### Symlinks Are Real Git Repositories

- `ios/` is a symlink to a real git repo (`~/wip/pub/ios-app/.git`)
- `android/` is a symlink to a real git repo (`~/wip/pub/android-app/.git`)
- Both have their own `.git` directory and remote tracking
- Operations inside symlinks affect the actual repository

**Example**:
```bash
cd ~/GitProjects/TrustNet/trustnet-wip/ios
git remote -v
# Shows ios-app remote, not trustnet-wip remote

cd ~/GitProjects/TrustNet/trustnet-wip
git remote -v
# Shows trustnet-wip remote
```

### File Synchronization

**Ubuntu → macOS**:
```bash
# After git push on Ubuntu, sync to macOS
scp -r ~/wip/pub/ios-app/ macosx:~/
# OR
rsync -avz ~/wip/pub/ios-app/ macosx:~/ios-app/
```

**Ubuntu → lfactory**:
```bash
# After git push on Ubuntu, sync to lfactory
git -C ~/wip/pub/android-app push origin main
# Then on lfactory:
# cd ~/android-app && git pull origin main
```

### Each Repository Is Independent

- **trustnet-wip** has its own CI/CD, deployment scripts
- **ios-app** is pure Swift code, builds on macOS
- **android-app** is pure Kotlin code, builds on lfactory
- No dependencies between them (clean separation)

---

## Quick Reference

| Task | Location | Command |
|------|----------|---------|
| Edit iOS code | Ubuntu | Edit `~/GitProjects/TrustNet/trustnet-wip/ios/Sources/` |
| Edit Android code | Ubuntu | Edit `~/GitProjects/TrustNet/trustnet-wip/android/app/` |
| Build iOS | macOS | `ssh macosx "cd ~/ios-app && swift build"` |
| Build Android | lfactory | `ssh lfactory "cd ~/android-app && gradle build"` |
| Commit iOS | Ubuntu | `cd ~/GitProjects/TrustNet/trustnet-wip/ios && git push` |
| Commit Android | Ubuntu | `cd ~/GitProjects/TrustNet/trustnet-wip/android && git push` |
| Commit hub docs | Ubuntu | `cd ~/GitProjects/TrustNet/trustnet-wip && git push` |

---

## Directory Map

```
Ubuntu:
  ~/GitProjects/TrustNet/trustnet-wip/
    ├── ios → ~/wip/pub/ios-app  [SYMLINK]
    ├── android → ~/wip/pub/android-app  [SYMLINK]
    ├── activity/
    ├── docs/
    ├── .git (trustnet-wip repo)
    └── ...

Physical Repos:
  ~/wip/pub/
    ├── ios-app/
    │   ├── Sources/
    │   ├── Tests/
    │   ├── .git (ios-app repo)
    │   └── README.md
    └── android-app/
        ├── app/
        ├── .git (android-app repo)
        └── README.md

Build Servers:
  macOS: ~/ios-app (cloned after sync)
  lfactory: ~/android-app (cloned after sync)
```

---

## Troubleshooting

### "Is the symlink pointing to the right place?"
```bash
ls -la ~/GitProjects/TrustNet/trustnet-wip/ios
# Should show: ios -> /home/jcgarcia/wip/pub/ios-app
```

### "Which repo am I in?"
```bash
pwd
# If includes "trustnet-wip/ios" → you're in ios-app but via symlink
# If includes "wip/pub/ios-app" → you're in ios-app directly
```

### "Git status shows nothing but I made changes"
```bash
# Check if you're in the symlink
cd ~/GitProjects/TrustNet/trustnet-wip/ios
git status  # Shows ios-app status

# OR check the physical location
cd ~/wip/pub/ios-app
git status  # Same result (it's the same repo)
```

---

**Last Updated**: February 8, 2026  
**Created**: February 8, 2026  

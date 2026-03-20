# iOS App Recovery & Build Guide
## Complete Troubleshooting Reference 

**Created**: February 9, 2026  
**Status**: Clean Slate Implementation Complete  
**Reference Commit**: bd41044

---

## Executive Summary

This document captures the complete iOS app recovery journey—from corrupted code to successful simulator deployment. **Purpose**: Prevent repeating these errors. Reference this before starting any iOS development work.

---

## Part 1: WHAT WENT WRONG

### Core Issue #1: Code Corruption (ContentView.swift)
**Symptom**: Line 190 had syntax error: `"expected expression"`  
**Root Cause**: Corrupted file, Xcode caching issues from previous edits  
**Impact**: Build failed, tests failed, impossible to fix with incremental changes  

### Core Issue #2: Repository Contamination
**Symptom**: GitHub contained old corrupted code; VM cloned wrong version  
**Root Cause**: Trying to fix files incrementally instead of deleting and starting fresh  
**Impact**: Fresh code commit wasn't pushed before VM pull—misalignment across systems  

### Core Issue #3: Invalid Xcode Project Configuration
**Symptoms**:
- pbxproj referenced non-existent files (ContentView.swift)
- Duplicate file paths (TrustNetValidator/TrustNetValidator/App.swift)
- Info.plist appearing in multiple build phases
- Unclosed/malformed plist syntax in build settings

**Root Cause**: Auto-generated pbxproj from Python script included references to files that were deleted but not removed from project configuration  
**Impact**: Build failed with "pbxproj is damaged" error; plist parsing errors; duplicate output file conflicts  

### Core Issue #4: iOS 14 Compatibility Issues
**Symptom**: `#Preview` directive not recognized  
**Root Cause**: #Preview is iOS 17+ only; app targets iOS 14  
**Impact**: Swift compiler error; build failed  

### Core Issue #5: File Path Organization
**Symptom**: Build looked for `/Users/jcgarcia/ios-app/TrustNetValidator/TrustNetValidator/App.swift`  
**Root Cause**: Group structure in pbxproj had both group path and file path incorrectly configured  
**Impact**: Build couldn't find files even though they existed  

---

## Part 2: THE GOLDEN RULES (LEARNED THE HARD WAY)

### Rule #1: NEVER Reuse Corrupted Code
**What We Did Wrong**: Tried to fix ContentView.swift line by line instead of deleting it  
**What Worked**: Deleted ALL corrupted files completely, started from scratch  
**Lesson**: If code is corrupted, deleting it completely and rewriting is faster than debugging

### Rule #2: CLEAN SLATE Means COMPLETELY FRESH
**What We Did Wrong**: Deleted files locally but Git history still had old commits; VM cloned old versions  
**What Worked**:
1. Delete corrupted files locally
2. Delete entire GitHub repository
3. Recreate fresh GitHub repository (truly empty)
4. Clone fresh on VM
5. Then create new code

**Lesson**: "Clean slate" is not partial—it's complete deletion and recreation

### Rule #3: ONE System at a Time
**What We Did Wrong**: Tried to sync between local → GitHub → VM while things were still broken  
**What Worked**:
1. Get local working first (commit, push)
2. Then pull/test on VM
3. Never push incomplete work hoping VM will fix it

**Lesson**: Local → GitHub → VM is a one-way street. Must be clean at each step

### Rule #4: Match the Deployment Target
**What We Did Wrong**: Copied #Preview from iOS 17+ code; didn't check iOS 14 requirements  
**What Worked**: Removed iOS 17+ features; used only iOS 14+ compatible APIs  
**Lesson**: Read the app's minimum iOS version (Info.plist) before copying code

### Rule #5: Xcode Project == Configuration System, Not Source
**What We Did Wrong**: Tried to auto-generate pbxproj and hoped it would be correct  
**What Worked**: Manually fixed pbxproj to match actual file structure  
**Lesson**: pbxproj must match reality. If files don't exist, remove references. If paths are wrong, fix them.

---

## Part 3: STEP-BY-STEP RECOVERY (What We Did)

### Phase 1: Repository Cleanup

#### Step 1.1: Delete Corrupted Local Files
```bash
cd ~/GitProjects/TrustNet/trustnet-wip/ios
rm -rf TrustNetValidator/  # Delete entire directory
rm -rf iOS-App.xcodeproj/ # Delete Xcode project
git add -A
git commit -m "CLEAN SLATE: Delete all old corrupted files"
git push origin main
```

**Why This First**: Can't build if corrupted files exist locally

#### Step 1.2: Delete GitHub Repository Completely
```bash
cd ~/GitProjects/TrustNet
gh repo delete ios-app --confirm
```

**Why This**: GitHub still had old corrupted repository; need truly fresh state

#### Step 1.3: Recreate Fresh GitHub Repository
```bash
gh repo create ios-app --public --source=. --remote=origin --push
```

**Why This**: Now repository is empty, no old code history

#### Step 1.4: Fresh Clone on macOS VM
```bash
ssh macosx "rm -rf ~/ios-app && git clone https://github.com/TrustNetT/ios-app.git ~/ios-app"
```

**Why This**: VM now has fresh repository, no old cached files

### Phase 2: Minimal MVP Creation

#### Step 2.1: Create App.swift (Complete Dashboard UI)
**File**: `TrustNetValidator/App.swift` (162 lines)  
**Contains**: 
- @main struct TrustNetApp
- ContentView() with SwiftUI
- Purple-to-blue gradient background
- 4 card-based display sections (Status, Reputation, Balance, Refresh)

**Why Single File**: 
- Avoids file reference errors
- All UI logic in one place
- Easy to test and verify

#### Step 2.2: Create Assets Catalog
```
TrustNetValidator/Assets.xcassets/
├── AppIcon.appiconset/
│   └── Contents.json (8 icon slots)
└── Contents.json (catalog metadata)
```

**Why This**: iOS apps require asset catalog structure; Xcode validates on build

#### Step 2.3: Create Info.plist Bundle Configuration
**File**: `TrustNetValidator/Info.plist`  
**Contains**: Standard iOS app configuration keys:
```xml
CFBundleIdentifier: com.trustnet.validator
CFBundleVersion: 1
MinimumOSVersion: iOS 14.0
UIMainStoryboardFile: (none, using SwiftUI)
UISceneConfigurations: (standard scene manifests)
```

**Why This**: iOS requires Info.plist; Xcode uses INFOPLIST_FILE build setting to find it

### Phase 3: Xcode Project Configuration

#### Step 3.1: Create Minimal pbxproj
Generated by Python script; contains:
- File references (App.swift, PassportValidator.swift, Assets, Info.plist)
- Groups (TrustNetValidator, Sources)
- Build phases (Sources, Frameworks, Resources)
- Build settings (compiler flags, SDK paths, bundle ID)
- Configurations (Debug, Release)

#### Step 3.2: Fix pbxproj File References
**Issue #1**: Referenced non-existent `ContentView.swift`
```diff
- FA0001B12BD5A1C40027F4A6 /* ContentView.swift */
+ (REMOVED)
```

**Issue #2**: Duplicate directory paths
```diff
- path = "TrustNetValidator/App.swift"  // WRONG: doubled the directory
+ path = "App.swift"                    // CORRECT: path relative to group
```

**Issue #3**: Duplicate Info.plist in build phases
```diff
- Resources build phase: {files = (Assets, Info.plist)}
- INFOPLIST_FILE build setting: "Info.plist"
+ Resources build phase: {files = (Assets)}  // REMOVED from here
+ INFOPLIST_FILE build setting: "Info.plist" // KEPT here
```
(Only one location can process Info.plist)

**Issue #4**: Malformed plist syntax in Info.plist reference
```diff
- INFOPLIST_KEY_UIApplicationSceneManifest = "{UIApplicationSceneManifestDelegateClassName = ""; ...}"
+ (REMOVED - causes plist parser errors)
```

**Issue #5**: iOS 14 compatibility
```diff
- #Preview { ContentView() }  // iOS 17+, not available in iOS 14
+ (REMOVED)
```

### Phase 4: Build & Deploy

#### Step 4.1: Build on VM
```bash
xcodebuild -project iOS-App.xcodeproj \
  -scheme TrustNetValidator \
  -destination 'platform=iOS Simulator,name=iPhone 14 Pro Max' \
  clean build
```

**Expected Output**: `** BUILD SUCCEEDED **`

#### Step 4.2: Install on Simulator
```bash
xcrun simctl install booted \
  /Users/jcgarcia/Library/Developer/Xcode/DerivedData/iOS-App-gcmnptmkiudxotgqrnsareaxzjrf/Build/Products/Debug-iphonesimulator/TrustNetValidator.app
```

#### Step 4.3: Launch App
```bash
xcrun simctl launch booted com.trustnet.validator
```

**Verification**: Process appears in `ps aux | grep TrustNetValidator`

---

## Part 4: ROOT CAUSES (Why These Happened)

### Cause #1: Golden Rule Violation - Incremental Fixes
**What Happened**: Tried to fix corrupted ContentView.swift line-by-line  
**Why It Failed**: 
- File corruption goes beyond syntax (Xcode cache issues)
- Each "fix" left the file in uncertain state
- Xcode cache held old versions; fresh builds still saw old code

**Prevention**: Delete and rewrite, don't incrementally fix corruption

### Cause #2: Partial Clean-Up
**What Happened**: Deleted files locally but didn't clean GitHub or VM  
**Why It Failed**:
- GM history still had corrupted commits
- VM cloned old version before new code was pushed
- Systems got out of sync (local ahead of remote)

**Prevention**: Delete repository, recreate, THEN create new code

### Cause #3: Auto-Generated Configuration Without Validation
**What Happened**: Python script generated pbxproj; didn't verify it matched actual files  
**Why It Failed**:
- Script had hardcoded file references (ContentView.swift)
- Script assumed file paths that didn't match group structure
- No post-generation validation

**Prevention**: Always validate generated files. Check pbxproj references real files.

### Cause #4: Copying Code Without Checking Target Requirements
**What Happened**: Used #Preview directive from iOS 17+ template  
**Why It Failed**: #Preview not available until iOS 17; app targets iOS 14

**Prevention**: Read Info.plist first. Know your minimum iOS target before coding.

### Cause #5: Complex File Organization
**What Happened**: Created separate ContentView.swift, expecting modular structure  
**Why It Failed**:
- More files = more references to configure
- Each new file added pbxproj reference points (bugs)
- Single-file approach simpler for MVP

**Prevention**: Start simple (single file). Add modules only when needed.

---

## Part 5: THE FIX (Technical Details)

### Build Error #1: "Old-style plist parser: missing semicolon"
```
Error: CFPropertyListCreateFromXMLData(): Old-style plist parser: 
missing semicolon in dictionary on line 32
Path: iOS-App.xcodeproj/project.pbxproj
```

**Root Cause**: Unescaped quotes in pbxproj `INFOPLIST_KEY_UIApplicationSceneManifest`:
```
INFOPLIST_KEY_UIApplicationSceneManifest = "{UIApplicationSceneManifestDelegateClassName = ""; ...}"
                                           ^ ^ unescaped quotes caused plist parser to break
```

**Fix**: Remove the malformed build setting entirely
```
- INFOPLIST_KEY_UIApplicationSceneManifest = "{...}";
+ (REMOVED)
```

Use Info.plist file instead for scene configuration.

### Build Error #2: "Multiple commands produce '/...'/Info.plist"
```
error: Multiple commands produce '.../Info.plist'
  - ProcessInfoPlistFile ...
  - Info.plist in Resources
(in target 'TrustNetValidator')
```

**Root Cause**: Info.plist being processed by two build phases:
1. "Info.plist in Resources" build phase (explicit file)
2. INFOPLIST_FILE setting (automatic processing)

**Fix**: Remove from Resources, keep only via INFOPLIST_FILE:
```
Resources build phase:
- Before: files = (Assets, Info.plist)
+ After:  files = (Assets)
```

### Build Error #3: "Build input file cannot be found"
```
error: Build input file cannot be found: 
'/Users/jcgarcia/ios-app/TrustNetValidator/TrustNetValidator/App.swift'
```

**Root Cause**: File path duplicating directory structure:
```
Actual file:    ~/ios-app/TrustNetValidator/App.swift
Xcode looking: ~/ios-app/TrustNetValidator/TrustNetValidator/App.swift
                                           ^^^^^^^^^^^^^^^^^ DOUBLED
```

**Fix**: Correct pbxproj file reference path:
```
Before: path = "TrustNetValidator/App.swift"  (when group already has TrustNetValidator)
After:  path = "App.swift"                    (relative to parent group)
```

### Build Error #4: "error: use of unknown directive '#Preview'"
```
/Users/jcgarcia/ios-app/TrustNetValidator/App.swift:164:1: 
error: use of unknown directive '#Preview'
#Preview {
^
```

**Root Cause**: #Preview is iOS 17+ only; app targets iOS 14.0  
**Fix**: Remove the #Preview block:
```diff
- #Preview {
-     ContentView()
- }
```

(Xcode 14.3 doesn't support #Preview; need canvas or run app directly for preview)

---

## Part 6: VERIFICATION CHECKLIST

### Before Starting Development
- [ ] Read this document
- [ ] Check Info.plist for minimum iOS version
- [ ] Know which APIs are available in that iOS version
- [ ] Test that GitHub → VM clone works
- [ ] Build locally first, then VM

### After Making Changes
- [ ] `git status` shows expected files
- [ ] `xcodebuild` completes without errors
- [ ] App launches on simulator without crashes
- [ ] Check device logs: `ps aux | grep TrustNetValidator` shows running process
- [ ] If pbxproj changed, verify all file references exist

### Commit Checklist
- [ ] No debugging code left in (print statements, etc.)
- [ ] No commented-out code
- [ ] Info.plist targets correct iOS version
- [ ] Build settings match actual file structure
- [ ] All referenced files actually exist in repository

---

## Part 7: FILES REFERENCE (Current Working State)

### Core Application Files
```
TrustNetValidator/
├── App.swift (162 lines)
│   ├── @main struct TrustNetApp
│   ├── struct ContentView
│   ├── LinearGradient(purple → blue)
│   ├── VStack with 4 cards
│   └── @State for refresh animation
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   │   ├── Contents.json (8 icon definitions)
│   │   └── (actual image files go here)
│   └── Contents.json (catalog metadata)
└── Info.plist (iOS bundle config)
    ├── CFBundleIdentifier: com.trustnet.validator
    ├── CFBundleVersion: 1
    └── MinimumOSVersion: 14.0
```

### Build System Files
```
iOS-App.xcodeproj/
└── project.pbxproj (Xcode project configuration)
    ├── File References (App.swift, PassportValidator, Assets, Info.plist)
    ├── Source Build Phase (App.swift, PassportValidator)
    ├── Resources Build Phase (Assets only - NOT Info.plist)
    ├── Build Settings
    │   ├── INFOPLIST_FILE = "TrustNetValidator/Info.plist"
    │   ├── PRODUCT_BUNDLE_IDENTIFIER = "com.trustnet.validator"
    │   └── (other standard iOS settings)
    └── Configurations (Debug, Release)
```

### Supporting Files
```
Sources/
└── PassportValidator.swift (validation library)
Tests/
└── main.swift (test entry)
Package.swift (Swift package manifest)
generate-pbxproj.py (auto-generation script)
```

---

## Part 8: IF THIS HAPPENS AGAIN (Emergency Recovery)

### Symptom: pbxproj parse errors
1. Open `iOS-App.xcodeproj/project.pbxproj` in text editor
2. Search for unescaped quotes or missing semicolons
3. Check that every file reference (FA0001B0, etc.) points to a file that exists
4. Remove any references to deleted files
5. Verify group structure matches file paths

### Symptom: Build cannot find file
1. Check actual file location: `find . -name "App.swift"`
2. Check pbxproj: `grep -n "App.swift" iOS-App.xcodeproj/project.pbxproj`
3. Compare: pbxproj path should be relative to group, not absolute
4. Fix pbxproj paths to match actual structure

### Symptom: Xcode compilation error after file changes
1. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/iOS-App*`
2. Delete Xcode cache: `rm -rf .swiftpm`
3. Rebuild: `xcodebuild clean build`

### Symptom: Local works, VM fails
1. Verify all files pushed: `git log --oneline | head -5`
2. Verify VM pulled latest: `ssh macosx "cd ~/ios-app && git log --oneline | head -5"`
3. If commits don't match: `git push -f origin main` then `ssh macosx "cd ~/ios-app && git pull origin main"`
4. Clean derived data on VM: `ssh macosx "rm -rf ~/Library/Developer/Xcode/DerivedData/*"`

---

## Part 9: KEY LEARNINGS FOR FUTURE iOS DEVELOPMENT

1. **Start Simple**: Single file (App.swift) beats modular organization for MVP
2. **Know Your Dependencies**: Check iOS target before using any API
3. **Validate Generated Files**: Auto-generated pbxproj ≠ error-free pbxproj
4. **Clean Slate Means Clean**: Partial cleanup causes sync issues
5. **One Direction**: Local → GitHub → VM. Never reverse.
6. **Test at Each Step**: Build locally, commit, push, pull VM, rebuild VM
7. **Assets Matter**: AppIcon + asset catalog required for valid iOS app
8. **Info.plist is Configuration**: Not in Resources; it's a build setting
9. **Avoid Xcode Cache**: Delete DerivedData when switching between builds
10. **Document as You Go**: This saves 10 hours of debugging later

---

## Reference Commits

| Commit | Message | Status |
|--------|---------|--------|
| 76daa43 | CLEAN SLATE: Delete corrupted files | Starting point |
| 4b35228 | Fresh start: Minimal MVP Dashboard | Working code |
| f3a24b9 | Add Info.plist configuration | Working code |
| 39c9472 | Remove #Preview for iOS 14 | Working code |
| bd41044 | Document successful build | FINAL ✅ |

---

**Last Updated**: February 9, 2026  
**Status**: Reference Complete - Use for all future iOS development

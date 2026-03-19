# TrustNet iOS & Android App - Build & Test Guide

Quick reference for manual builds on the respective build servers.

---

## iOS Build & Test (macosx server)

### Quick Build & Test (7 Steps)

```bash
ssh macosx "cd ~/ios-app && git pull origin main"
ssh macosx "cd ~/ios-app && xcodebuild clean -scheme TrustNetValidator -configuration Debug"
ssh macosx "cd ~/ios-app && xcodebuild build -scheme TrustNetValidator -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/TrustNetBuild"
ssh macosx "xcrun simctl uninstall 'iPhone 14 Pro Max' com.trustnet.validator 2>/dev/null || true && sleep 2"
ssh macosx "xcrun simctl install 'iPhone 14 Pro Max' /tmp/TrustNetBuild/Build/Products/Debug-iphonesimulator/TrustNetValidator.app"
ssh macosx "xcrun simctl launch 'iPhone 14 Pro Max' com.trustnet.validator"
```

### One-Liner iOS Build & Deploy

```bash
ssh macosx "cd ~/ios-app && git pull origin main && xcodebuild clean -scheme TrustNetValidator -configuration Debug && xcodebuild build -scheme TrustNetValidator -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/TrustNetBuild && xcrun simctl uninstall 'iPhone 14 Pro Max' com.trustnet.validator 2>/dev/null || true && sleep 2 && xcrun simctl install 'iPhone 14 Pro Max' /tmp/TrustNetBuild/Build/Products/Debug-iphonesimulator/TrustNetValidator.app && xcrun simctl launch 'iPhone 14 Pro Max' com.trustnet.validator"
```

**Expected**: App launches on simulator showing white splash screen with TrustNet logo (120x120), 3-second display time.

---

## Android Build & Test (lfactory server)

### Quick Build & Test (5 Steps)

```bash
ssh lfactory "cd ~/trustnet-wip/android && git pull origin main"
ssh lfactory "cd ~/trustnet-wip/android && ./gradlew clean"
ssh lfactory "cd ~/trustnet-wip/android && ./gradlew assembleDebug"
ssh lfactory "cd ~/trustnet-wip/android && adb install -r app/build/outputs/apk/debug/app-debug.apk"
ssh lfactory "adb shell am start -n com.trustnet.app/.SplashActivity"
```

### One-Liner Android Build & Deploy

```bash
ssh lfactory "cd ~/trustnet-wip/android && git pull origin main && ./gradlew clean assembleDebug && adb install -r app/build/outputs/apk/debug/app-debug.apk && adb shell am start -n com.trustnet.app/.SplashActivity"
```

**Expected**: App launches showing white splash screen with TrustNet logo (120x120), 3-second display time.

---

## Troubleshooting

### iOS Build Issues

```bash
# Check Xcode build log for errors
ssh macosx "xcodebuild build -scheme TrustNetValidator -configuration Debug -destination 'generic/platform=iOS Simulator' 2>&1 | grep -i error"

# Force clean of Xcode cache
ssh macosx "rm -rf ~/Library/Developer/Xcode/DerivedData/*"

# Check simulator status
ssh macosx "xcrun simctl list devices"
```

### Android Build Issues

```bash
# Gradle build with verbose output
ssh lfactory "cd ~/trustnet-wip/android && ./gradlew assembleDebug --info 2>&1 | tail -100"

# Check connected devices
ssh lfactory "adb devices -l"

# View app logs
ssh lfactory "adb logcat | grep trustnet"

# Uninstall before reinstalling
ssh lfactory "adb uninstall com.trustnet.app && sleep 2 && adb install app/build/outputs/apk/debug/app-debug.apk"
```

---

## Build Servers

| Platform | Server | Location | Repository |
|----------|--------|----------|-------------|
| iOS | macosx | Remote | ~/ios-app (separate repo) |
| Android | lfactory | Local network | ~/trustnet-wip/android |

---

## Splash Screen Specifications

Both versions now have identical visual appearance:

| Feature | iOS | Android |
|---------|-----|---------|
| Background | White (Color.white) | White (#ffffff) |
| Logo | Image("Logo") 120x120 | @drawable/trustnet_logo 120x120dp |
| Display Time | 3 seconds | 3 seconds |
| Text | "TrustNet" black | "TrustNet" black |

---

**Last Updated**: February 11, 2026

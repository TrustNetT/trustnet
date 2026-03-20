# TrustNet Mobile Strategy

**Date**: February 2, 2026  
**Frontend Choice**: Vite + Modern JS  
**Target Platforms**: iPad, Android tablets/phones  

---

## The Challenge

TrustNet users need to:
- Register identities on the go
- View transactions from mobile devices
- Manage blockchain keys securely
- Access TrustNet from tablets and phones

**Question**: How do we support mobile without maintaining separate codebases?

---

## Mobile App Options

### Option 1: Progressive Web App (PWA) ⭐ RECOMMENDED

**What it is**:
- Your existing web app with extra features
- Works in mobile browser + installable as "app"
- Same codebase for desktop, iPad, Android
- No app store approval needed

**How it works**:
```javascript
// Add to vite.config.js
import { VitePWA } from 'vite-plugin-pwa'

export default {
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      manifest: {
        name: 'TrustNet',
        short_name: 'TrustNet',
        description: 'Decentralized blockchain network',
        theme_color: '#1a202c',
        icons: [
          {
            src: 'icon-192.png',
            sizes: '192x192',
            type: 'image/png'
          },
          {
            src: 'icon-512.png',
            sizes: '512x512',
            type: 'image/png'
          }
        ]
      },
      workbox: {
        // Cache TrustNet modules
        globPatterns: ['**/*.{js,css,html,ico,png,svg}']
      }
    })
  ]
}
```

**User Experience**:

**On iPad**:
1. User visits `https://trustnet.local` in Safari
2. Safari shows "Add to Home Screen" prompt
3. User taps "Add" → TrustNet icon appears on home screen
4. Tap icon → Opens like native app (no Safari UI)
5. Works offline (cached with Service Worker)

**On Android**:
1. User visits `https://trustnet.local` in Chrome
2. Chrome shows "Install TrustNet" banner
3. User taps "Install" → Icon added to home screen
4. Tap icon → Opens in standalone window
5. Works offline, can receive push notifications

**Features You Get**:

✅ **Installable**:
- Add to home screen on iOS/Android
- Launch without browser chrome
- Full-screen experience

✅ **Offline Support**:
- Service Worker caches app shell
- View cached transactions offline
- Queue actions, sync when online

✅ **Native-like**:
- Splash screen on launch
- App icon and name
- Works in portrait/landscape
- System notifications (with permission)

✅ **Automatic Updates**:
- Users always get latest version
- No app store delays
- Update on next visit

✅ **One Codebase**:
- Desktop, iPad, Android - same code
- Test once, works everywhere
- Same Vite + Modern JS stack

**Pros**:

✅ **Zero extra work** - Add PWA plugin, done  
✅ **Same codebase** - Desktop and mobile identical  
✅ **No app stores** - Deploy via web, users install directly  
✅ **Instant updates** - Push update, users get it immediately  
✅ **Cross-platform** - iOS, Android, desktop from one build  
✅ **Responsive design** - Already needed for web anyway  
✅ **Works with Vite** - Perfect integration  

**Cons**:

❌ **Limited native features**:
- No NFC (for key exchange)
- Limited Bluetooth
- No background sync (iOS restrictions)

❌ **iOS limitations**:
- Service Worker restrictions
- No push notifications (iOS Safari limitation)
- 50MB cache limit

❌ **Not in app store**:
- Users must know URL first
- Can't discover in App Store/Play Store
- No "official" app store presence

**Implementation**:

```bash
# Install PWA plugin
pnpm add -D vite-plugin-pwa

# Update vite.config.js (add PWA config)

# Create icons (192x192, 512x512)

# Test on mobile device
```

**Bundle size**: Same as desktop (~15-30KB + PWA runtime ~10KB)

---

### Option 2: Capacitor (Native Container)

**What it is**:
- Wraps your web app in native iOS/Android shell
- Access to native device APIs
- Publish to App Store and Play Store
- Still uses your Vite + Modern JS code

**How it works**:
```bash
# Install Capacitor
pnpm add @capacitor/core @capacitor/cli
pnpm add @capacitor/ios @capacitor/android

# Initialize
npx cap init TrustNet com.trustnet.app

# Build web app
pnpm build

# Copy to native projects
npx cap copy

# Open in Xcode/Android Studio
npx cap open ios
npx cap open android
```

**Architecture**:
```
Your Vite App (HTML/CSS/JS)
         ↓
  Capacitor Bridge
         ↓
    Native APIs
    ├── Camera
    ├── Biometric Auth (Face ID, fingerprint)
    ├── Secure Storage
    ├── NFC
    ├── Bluetooth
    └── Background Tasks
```

**Features You Get**:

✅ **Full Native APIs**:
```javascript
import { Camera } from '@capacitor/camera'
import { BiometricAuth } from '@capacitor/biometric-auth'

// Scan QR code for identity
const image = await Camera.getPhoto({
  quality: 90,
  source: CameraSource.Camera
})

// Secure key storage with Face ID
const result = await BiometricAuth.authenticate()
if (result.success) {
  await SecureStorage.set({ key: 'privateKey', value: key })
}
```

✅ **App Store Presence**:
- Listed in App Store / Play Store
- Official app downloads
- Update via app stores

✅ **Better Performance**:
- Native scrolling
- Faster animations
- Better resource management

✅ **Push Notifications** (iOS too!):
```javascript
import { PushNotifications } from '@capacitor/push-notifications'

await PushNotifications.register()
// Receive transaction notifications
```

✅ **Offline Database**:
```javascript
import { CapacitorSQLite } from '@capacitor-community/sqlite'

// Full SQLite database on device
await db.execute('INSERT INTO identities ...')
```

**Pros**:

✅ **App store presence** - Official TrustNet app  
✅ **Native device features** - Camera, biometrics, NFC  
✅ **Better UX** - Native performance and animations  
✅ **Push notifications** - Works on iOS  
✅ **Same codebase** - Still Vite + Modern JS  
✅ **Offline database** - Full SQLite support  

**Cons**:

❌ **More complexity**:
- Need Xcode (macOS) for iOS builds
- Need Android Studio for Android builds
- Two native projects to maintain

❌ **App store process**:
- Apple Developer account ($99/year)
- Google Play account ($25 one-time)
- App review process (Apple takes days)
- Update delays (users must update manually)

❌ **Larger bundle**:
- Native app wrapper adds ~20MB
- App download size: ~30-40MB

❌ **Build requirements**:
- macOS needed for iOS builds
- Android SDK for Android builds
- More complex CI/CD

**Implementation**:

```bash
# Week 1: Setup
pnpm add @capacitor/core @capacitor/cli @capacitor/ios @capacitor/android
npx cap init

# Week 2: iOS app
npx cap add ios
npx cap copy ios
npx cap open ios
# Build in Xcode, test on iPhone/iPad

# Week 3: Android app
npx cap add android
npx cap copy android
npx cap open android
# Build in Android Studio, test on device

# Week 4: Native features
# Add camera, biometrics, secure storage plugins
```

**Bundle size**: ~30-40MB (includes native wrapper)

---

### Option 3: React Native

**What it is**:
- Separate mobile app in React Native
- Completely different codebase from web
- Native iOS/Android components

**Why NOT for TrustNet**:

❌ **Different framework** - We chose Vite + Vanilla JS, not React  
❌ **Separate codebase** - Web app ≠ mobile app  
❌ **Double development** - Build every feature twice  
❌ **More dependencies** - React Native + all its tooling  
❌ **Doesn't leverage your choice** - Throws away Vite decision  

**Verdict**: ❌ Skip this option

---

### Option 4: Native Apps (Swift/Kotlin)

**What it is**:
- Pure native iOS app (Swift)
- Pure native Android app (Kotlin)
- No code sharing with web

**Why NOT for TrustNet**:

❌ **Three codebases** - Web, iOS, Android (triple the work)  
❌ **Different languages** - JavaScript, Swift, Kotlin  
❌ **Three times the bugs** - Each platform has its own issues  
❌ **Slow development** - Every feature takes 3x longer  

**Verdict**: ❌ Definitely skip this

---

## Recommended Strategy: Progressive Enhancement

### Phase 1: PWA First (Week 1-2)

**Start here** - Lowest effort, maximum compatibility:

1. **Add PWA plugin to Vite**:
```javascript
// vite.config.js
import { VitePWA } from 'vite-plugin-pwa'

export default {
  plugins: [
    VitePWA({
      manifest: {
        name: 'TrustNet',
        short_name: 'TrustNet',
        icons: [/* ... */]
      }
    })
  ]
}
```

2. **Make responsive**:
```css
/* Already doing this for desktop responsiveness */
@media (max-width: 768px) {
  .dashboard { 
    grid-template-columns: 1fr; /* Stack on mobile */
  }
}
```

3. **Add touch-friendly UI**:
```css
/* Bigger tap targets for mobile */
button {
  min-height: 44px; /* iOS Human Interface Guidelines */
  min-width: 44px;
}
```

4. **Test on devices**:
```bash
# Start dev server
pnpm dev

# Access from iPad/Android on same network
# Visit https://trustnet.local (if mDNS works)
# Or https://192.168.1.100:5173
```

**Deliverable**: TrustNet works on all mobile browsers, installable as PWA

---

### Phase 2: Enhance for Mobile (Week 3-4)

**Add mobile-specific features**:

1. **Service Worker** (offline support):
```javascript
// Auto-generated by vite-plugin-pwa
// Caches modules, identities, transactions
```

2. **Add to Home Screen prompt**:
```javascript
// Detect iOS
const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent)

if (isIOS) {
  // Show custom "Add to Home Screen" instructions
  showIOSInstallPrompt()
}

// Android auto-prompts via browser
```

3. **Mobile-optimized layouts**:
```javascript
// modules/identity/frontend/main.js

// Detect mobile
const isMobile = window.innerWidth < 768

// Adjust UI accordingly
if (isMobile) {
  // Single column layout
  // Larger buttons
  // Bottom navigation
}
```

4. **Touch gestures**:
```javascript
// Swipe to refresh
let touchStartY = 0

document.addEventListener('touchstart', (e) => {
  touchStartY = e.touches[0].clientY
})

document.addEventListener('touchend', (e) => {
  const touchEndY = e.changedTouches[0].clientY
  if (touchEndY - touchStartY > 100) {
    // User swiped down → refresh
    location.reload()
  }
})
```

**Deliverable**: Polished mobile experience, works offline, feels native

---

### Phase 3: Capacitor (If Needed) (Month 2-3)

**Only add Capacitor if you need**:
- Camera for QR code scanning
- Biometric auth (Face ID, fingerprint)
- NFC for key exchange
- Push notifications on iOS
- App Store presence

**Implementation**:
```bash
# Add Capacitor
pnpm add @capacitor/core @capacitor/cli

# Add platforms
npx cap add ios
npx cap add android

# Build web app
pnpm build

# Sync to native
npx cap sync

# Open in native IDEs
npx cap open ios       # Xcode
npx cap open android   # Android Studio
```

**Native features**:
```javascript
// Add camera plugin
pnpm add @capacitor/camera

// Use in identity module
import { Camera } from '@capacitor/camera'

async function scanQRCode() {
  const photo = await Camera.getPhoto({
    quality: 90,
    source: CameraSource.Camera
  })
  
  // Decode QR code, register identity
}
```

**Deliverable**: Native iOS/Android apps with full device features

---

## Mobile UI Considerations

### Responsive Design Principles

**Breakpoints**:
```css
/* Mobile first (default styles for mobile) */
.dashboard {
  padding: 1rem;
  grid-template-columns: 1fr;
}

/* Tablet (iPad) */
@media (min-width: 768px) {
  .dashboard {
    padding: 2rem;
    grid-template-columns: 1fr 1fr;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .dashboard {
    padding: 3rem;
    grid-template-columns: repeat(3, 1fr);
  }
}
```

**Touch Targets**:
```css
/* Apple Human Interface Guidelines: 44x44pt minimum */
button, a, input {
  min-height: 44px;
  padding: 0.75rem 1.5rem;
}

/* Android Material Design: 48x48dp minimum */
@media (max-width: 768px) {
  button {
    min-height: 48px;
  }
}
```

**Typography**:
```css
/* Larger fonts for mobile readability */
body {
  font-size: 16px; /* iOS won't zoom if 16px or larger */
}

h1 { font-size: 2rem; }    /* Mobile */
h2 { font-size: 1.5rem; }

@media (min-width: 768px) {
  h1 { font-size: 3rem; }  /* Desktop */
  h2 { font-size: 2rem; }
}
```

**Navigation**:
```html
<!-- Desktop: Top navigation -->
<nav class="top-nav desktop-only">
  <a href="/identity">Identity</a>
  <a href="/transactions">Transactions</a>
  <a href="/keys">Keys</a>
</nav>

<!-- Mobile: Bottom navigation (thumb-friendly) -->
<nav class="bottom-nav mobile-only">
  <a href="/identity">
    <svg><!-- icon --></svg>
    <span>Identity</span>
  </a>
  <!-- ... -->
</nav>
```

---

## Module-Specific Mobile Considerations

### Identity Module
- **Camera access** for QR code identity sharing
- **Biometric auth** to protect private keys
- **NFC** for tap-to-share identity (future)

**Implementation**:
```javascript
// modules/identity/frontend/mobile.js
if (isMobile) {
  // Add "Scan QR Code" button
  // Add "Share via NFC" button
  // Use biometric auth before showing private key
}
```

### Transactions Module
- **Pull-to-refresh** for latest transactions
- **Swipe gestures** to delete/archive
- **Push notifications** for new transactions

### Blockchain Module
- **Optimized charts** for small screens
- **Simplified dashboard** (less data density)
- **Dark mode** (OLED battery saving)

### Keys Module
- **Biometric protection** (Face ID, fingerprint)
- **Never show private keys on screenshots** (mark as secure content)
- **QR code export** for key backup

---

## Testing Strategy

### Browser Testing

**iOS (Safari)**:
```bash
# Connect iPad/iPhone to same network
# Get host IP: ifconfig | grep "inet "

# Visit on device
https://192.168.1.100:5173

# Test:
# - Touch interactions
# - Viewport sizes
# - Safari-specific bugs
# - Add to Home Screen
```

**Android (Chrome)**:
```bash
# Same network testing
https://192.168.1.100:5173

# Test:
# - Chrome PWA install
# - Back button behavior
# - Android gestures
# - Notification permissions
```

### Device Testing

**iPad Pro** (large tablet):
- Test multi-column layouts
- Landscape mode support
- Split-screen multitasking

**iPad Mini** (small tablet):
- Ensure readable at smaller size
- Touch targets still accessible

**iPhone** (phone size):
- Single column layout
- Bottom navigation
- Vertical scrolling

**Android Phone**:
- Various screen sizes (Samsung, Pixel)
- Different Android versions
- Chrome vs other browsers

---

## Performance Optimization for Mobile

### Bundle Size
```javascript
// Already small with Vite + Vanilla JS
// PWA adds: ~10KB (Service Worker)
// Total: ~25-40KB per module
```

### Image Optimization
```javascript
// Use WebP for smaller images
<img 
  src="identity.webp" 
  alt="Identity" 
  loading="lazy"  // Lazy load offscreen images
/>

// Responsive images
<img 
  srcset="icon-192.png 192w, icon-512.png 512w"
  sizes="(max-width: 768px) 192px, 512px"
/>
```

### Code Splitting
```javascript
// Lazy load modules
const identityModule = () => import('./modules/identity/main.js')

// Only load when user navigates to /identity
if (route === '/identity') {
  const module = await identityModule()
  module.init()
}
```

### Service Worker Caching
```javascript
// Cache app shell
workbox.routing.registerRoute(
  ({ request }) => request.destination === 'document',
  new workbox.strategies.NetworkFirst()
)

// Cache images
workbox.routing.registerRoute(
  ({ request }) => request.destination === 'image',
  new workbox.strategies.CacheFirst({
    cacheName: 'images',
    plugins: [
      new workbox.expiration.ExpirationPlugin({
        maxEntries: 60,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
      }),
    ],
  })
)
```

---

## Implementation Checklist

### Phase 1: PWA (Week 1-2)

- [ ] Install `vite-plugin-pwa`
- [ ] Configure manifest.json (name, icons, theme)
- [ ] Create app icons (192x192, 512x512)
- [ ] Add Service Worker config
- [ ] Make layouts responsive (mobile-first CSS)
- [ ] Test on iOS Safari (iPad/iPhone)
- [ ] Test on Android Chrome
- [ ] Test "Add to Home Screen" on both platforms
- [ ] Verify offline support works
- [ ] Test on different screen sizes

### Phase 2: Mobile Enhancements (Week 3-4)

- [ ] Add touch-friendly button sizes (44px minimum)
- [ ] Implement bottom navigation for mobile
- [ ] Add pull-to-refresh gesture
- [ ] Create iOS install instructions
- [ ] Add dark mode support
- [ ] Optimize images for mobile (WebP, responsive)
- [ ] Test performance on 3G network
- [ ] Add loading skeletons for slow connections
- [ ] Test battery usage (optimize animations)
- [ ] Verify no horizontal scrolling issues

### Phase 3: Capacitor (If Needed) (Month 2-3)

- [ ] Install Capacitor core
- [ ] Add iOS platform
- [ ] Add Android platform
- [ ] Configure app IDs (com.trustnet.app)
- [ ] Build web app and sync to native
- [ ] Test in iOS Simulator
- [ ] Test on physical iPhone/iPad
- [ ] Test in Android Emulator
- [ ] Test on physical Android device
- [ ] Add camera plugin (QR code scanning)
- [ ] Add biometric auth plugin (Face ID, fingerprint)
- [ ] Configure push notifications
- [ ] Submit to App Store (iOS)
- [ ] Submit to Play Store (Android)

---

## Recommendation

### Start Simple, Scale Up

**Month 1**: PWA
- Add vite-plugin-pwa (1 day)
- Make responsive (2-3 days)
- Test on devices (1-2 days)
- **Result**: Works on all mobile devices, installable

**Month 2**: Enhancements
- Touch optimizations (2-3 days)
- Offline support (2-3 days)
- Mobile-specific features (3-4 days)
- **Result**: Native-like experience in browser

**Month 3+**: Capacitor (only if needed)
- Native camera/biometrics (1 week)
- iOS app build (1 week)
- Android app build (1 week)
- App store submissions (2-4 weeks)
- **Result**: Official App Store/Play Store apps

### Why This Works

✅ **Users get mobile support immediately** (PWA works now)  
✅ **Progressive enhancement** (add features as needed)  
✅ **Same codebase** (Vite + Vanilla JS everywhere)  
✅ **Low risk** (PWA first, Capacitor only if necessary)  
✅ **Fast iteration** (no native build delays)  

---

## Summary

**Chosen Path**: PWA → Enhanced PWA → Capacitor (if needed)

**Technology Stack**:
- Frontend: Vite + Modern JS (confirmed)
- Mobile: PWA (Phase 1)
- Native features: Capacitor (Phase 3, if needed)
- Same codebase for desktop, iPad, Android

**Benefits**:
- ✅ Works on all devices from day 1
- ✅ One codebase to maintain
- ✅ Fast development cycle
- ✅ Easy deployment (no app stores initially)
- ✅ Can upgrade to native later if needed

**Next Steps**:
1. Confirm backend language choice (Go vs Node.js vs Python)
2. Confirm first module to build (Identity vs Transactions vs Keys)
3. Implement dev-sync.sh (Rsync development workflow)
4. Build first module with responsive design
5. Add PWA support
6. Test on mobile devices

---

*Document created: February 2, 2026*  
*Status: Mobile strategy defined, awaiting remaining technology decisions*  
*Next: Choose backend language and first module, then implement*

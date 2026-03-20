# TrustNet Logo Asset Management

**Status**: Logo file recovered and recreated

## Logo File Location

**Primary**: `/docs/images/trustnet-logo.svg`
- Format: SVG (scalable, color-preservable)
- Design: Biometric fingerprint with colored accent circles
- Colors: Teal primary (#0891B2), red (#EF4444), yellow (#FBBF24), pink (#EC4899)
- Use: Web, mobile, documentation, branding

## Where Logo Must Be Deployed (EVERYWHERE)

### 1. Frontend Web Projects (React/Next.js)

- `trustnet-technology-web/public/trustnet-logo.svg` → Header/navbar (primary brand identity)
- `trustnet-services-web/public/trustnet-logo.svg` → Header/navbar (primary brand identity)
- Keep separate copies (don't symlink - avoid publish script conflicts)
- Import into React components: `import logo from '/public/trustnet-logo.svg'`

### 2. iOS Mobile App

- `ios/TrustNetValidator/Assets.xcassets/AppIcon.appiconset/AppIcon.svg` → App icon (display)
- `ios/TrustNetValidator/Assets.xcassets/TrustNetLogo.imageset/TrustNetLogo@1x.svg` → In-app branding 48x48
- `ios/TrustNetValidator/Assets.xcassets/TrustNetLogo.imageset/TrustNetLogo@2x.svg` → In-app branding 96x96  
- `ios/TrustNetValidator/Assets.xcassets/TrustNetLogo.imageset/TrustNetLogo@3x.svg` → In-app branding 144x144
- Dashboard screen top-left corner (app identity)
- Settings screen footer logo

### 3. Android Mobile App (Future)

- `android/app/src/main/res/drawable/trustnet_logo.svg` → In-app branding
- `android/app/src/main/res/mipmap-*/ic_launcher*.png` → App icon (convert SVG → PNG at multiple DPIs)

### 4. Backend Node (Cosmos/Alpine VM)

- `cmd/trustnet/web/static/trustnet-logo.svg` → Node web interface (HTTP API dashboard)
- `cmd/trustnet/web/templates/header.html` → HTML template reference
- Node status page header (operator dashboard access)

### 5. Alpine VM Desktop Environment

- `/etc/trustnet/branding/trustnet-logo.svg` → System-wide branding
- Wallpaper/desktop environment branding
- Console login banner (text-based ASCII variant or small SVG)
- System tray icon (if graphical environment available)

### 6. Documentation & Marketing

- `docs/images/trustnet-logo.svg` → Source of truth (PRIMARY)
- `WHITEPAPER_v3.md` → Referenced in header
- `SPECIFICATIONS.md` → Design section link
- `README.md` → Top-left corner (project branding)
- GitHub repo settings: Upload as project logo/avatar

### 7. Package & Distribution

- `assets/trustnet-logo.svg` → Shared asset folder for all projects
- `assets/trustnet-logo-1024x1024.png` → High-res export (iOS, Android, web favicon)
- `assets/trustnet-logo-512x512.png` → Medium-res (thumbnails, social media)
- `assets/trustnet-logo-256x256.png` → Standard web size
- `assets/trustnet-logo-128x128.png` → Small web/icon use
- `assets/trustnet-logo.ico` → Windows favicon
- `assets/trustnet-logo-transparent.png` → PNG with alpha channel (overlay use)

## Logo Specifications

**Web Usage**:

- Width: 40-48px for navbar
- Height: 40-48px (square aspect ratio)
- Format: SVG or PNG

**iOS Usage**:

- App Icon: 1024x1024px (PNG required)
- In-App: 64x64px to 512x512px (SVG preferred)
- Safe area: Ensure inner fingerprint remains visible at smallest sizes

**Documentation**:

- Full size: 256x256px or larger
- Format: SVG preferred (scales without quality loss)

## Next Steps

1. ✅ Logo file created as SVG
2. ⏳ Convert SVG to PNG at 1024x1024 for iOS app icon
3. ⏳ Copy logo to website project public folders when directories are set up
4. ⏳ Update website HTML/React to reference logo from public folder
5. ⏳ Configure iOS Xcode project to use logo as app icon

## History

- **Session**: Feb 9, 2026 - Logo recovery
- **Previous Reference**: Session log shows logo was used in trustnet-technology-web and trustnet-services-web projects
- **File Status**: Original PNG file was missing; recreated as scalable SVG with identical design

---

**Note**: All copies should be made from `docs/images/trustnet-logo.svg` (source of truth) using publish script or manual copy operations. Never edit copies independently.

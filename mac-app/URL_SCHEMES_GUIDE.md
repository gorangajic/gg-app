# macOS In-App Links Registration Guide

Complete guide for testing and publishing your macOS app with custom URL schemes and Universal Links.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Custom URL Schemes](#custom-url-schemes)
3. [Universal Links](#universal-links)
4. [Testing](#testing)
5. [Publishing Checklist](#publishing-checklist)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

### ✅ What's Already Done

Your app already has:
- ✅ URL handling code in `GGApp.swift`
- ✅ Auth callback parsing in `AuthenticationCoordinator.swift`
- ✅ Info.plist with URL scheme configuration
- ✅ Basic entitlements for app functionality

### 🔧 What You Need to Do

1. Add `Info.plist` to your Xcode project
2. Build and test the URL scheme
3. (Optional) Set up Universal Links
4. Prepare for distribution

---

## Custom URL Schemes

### Configuration

Your app is configured to handle: **`ggapp://`**

**Registered Handler:**
- **URL Scheme:** `ggapp`
- **Identifier:** `com.typewise.ai.auth`
- **Example URL:** `ggapp://auth?token=eyJhbGci...`

### Add Info.plist to Xcode

The `Info.plist` file has been created at `GG/Info.plist`. Now add it to your Xcode project:

1. Open Xcode:
   ```bash
   open GG.xcodeproj
   ```

2. In the Project Navigator, right-click the **GG** folder

3. Select **"Add Files to 'GG'..."**

4. Navigate to `GG/Info.plist`

5. Ensure these options are checked:
   - ✅ **Copy items if needed**
   - ✅ **GG** target is selected

6. Click **Add**

7. Build the project (⌘+B) to verify no errors

### How It Works

When a user clicks `ggapp://auth?token=abc123` in their browser:

1. **macOS launches your app** (or brings it to foreground)
2. **`.onOpenURL` fires** in `GGApp.swift:85`
3. **`handleIncomingURL()` is called** (line 134)
4. **Auth coordinator processes the token** (line 138)
5. **Token is saved to Keychain** via `AuthenticationCoordinator`

**Code Flow:**
```
Browser URL
    ↓
macOS Launch Services
    ↓
GGApp.swift:85 (.onOpenURL)
    ↓
GGApp.swift:134 (handleIncomingURL)
    ↓
AuthenticationCoordinator.swift:51 (handleAuthCallback)
    ↓
Keychain Storage
```

---

## Universal Links

Universal Links allow your app to open HTTPS URLs like `https://yourdomain.com/auth?token=...` instead of custom schemes.

### Benefits

✅ **Works if app isn't installed** (falls back to browser)
✅ **More secure** (verified by Apple)
✅ **Better user experience** (no "Open in app?" dialog)
✅ **Required by some platforms** (iOS, iPadOS)

### Setup Steps

#### 1. Add Associated Domains Entitlement

Already done! Your `GG.entitlements` now includes:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:yourdomain.com</string>
</array>
```

**⚠️ Replace `yourdomain.com` with your actual domain!**

#### 2. Configure Xcode Capability

1. Open your project in Xcode
2. Select the **GG** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Associated Domains**
6. Add your domain: `applinks:yourdomain.com`

#### 3. Host apple-app-site-association File

The file has been created at `server/public/apple-app-site-association`.

**Before deploying, update these values:**

1. Find your **Team ID** at [developer.apple.com](https://developer.apple.com/account)
2. Edit the file:
   ```json
   {
     "applinks": {
       "apps": [],
       "details": [
         {
           "appID": "YOUR_TEAM_ID.gorangajic.GG",
           "paths": ["/auth/*", "/login"]
         }
       ]
     }
   }
   ```

**Important Requirements:**

- ✅ Must be served at `https://yourdomain.com/.well-known/apple-app-site-association`
- ✅ Or at `https://yourdomain.com/apple-app-site-association`
- ✅ Must be served over **HTTPS** with valid certificate
- ✅ Must return `Content-Type: application/json`
- ✅ No redirects or gzip compression
- ✅ File size under 128 KB

The Next.js server has been configured to serve this file correctly.

#### 4. Deploy to Production

```bash
cd server
npm run build
npm start
```

#### 5. Verify Universal Links

Test the apple-app-site-association file:

```bash
# Test local server
curl http://localhost:3000/apple-app-site-association

# Test production
curl https://yourdomain.com/.well-known/apple-app-site-association
```

**Apple's validator:**
https://search.developer.apple.com/appsearch-validation-tool

---

## Testing

### Test Custom URL Schemes

#### Method 1: Terminal
```bash
# Build and run your app first in Xcode
open ggapp://auth?token=test123
```

**Expected Result:** App opens and prints to Xcode console:
```
🔗 Received URL: ggapp://auth?token=test123
```

#### Method 2: HTML Test Page
```html
<!DOCTYPE html>
<html>
<body>
  <h1>Test GG App Links</h1>
  <a href="ggapp://auth?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9">
    Login to GG App
  </a>
</body>
</html>
```

Save as `test.html` and open in Safari.

#### Method 3: Verify LaunchServices Registration

```bash
# Check if macOS knows about ggapp:// scheme
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -dump | grep -i "ggapp"
```

**Expected Output:**
```
ggapp:
    bindings: com.gorangajic.GG
```

### Test Universal Links (After Setup)

```bash
# From Terminal
open https://yourdomain.com/auth?token=test123

# Or use Apple's test tool
xcrun simctl openurl booted https://yourdomain.com/auth?token=test123
```

### Debug Tips

**Enable URL scheme debugging:**

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** → **Arguments**
3. Add environment variable:
   - **Name:** `OS_ACTIVITY_MODE`
   - **Value:** `disable`

**Check Xcode console for:**
```
🔗 Received URL: ggapp://auth?token=...
```

**Common Issues:**

| Issue | Solution |
|-------|----------|
| URL doesn't open app | Rebuild app, check Info.plist is in target |
| App opens but URL not received | Check `.onOpenURL` handler is present |
| Token not saved | Check `AuthenticationCoordinator` logging |
| Universal links don't work | Verify HTTPS, valid certificate, correct Team ID |

---

## Publishing Checklist

### Pre-Release Checklist

- [ ] **Info.plist added to Xcode project**
- [ ] **URL scheme tested and working**
- [ ] **Associated domains configured** (if using Universal Links)
- [ ] **apple-app-site-association file deployed** (if using Universal Links)
- [ ] **Team ID updated** in apple-app-site-association
- [ ] **Valid code signing certificate**
- [ ] **App entitlements reviewed**
- [ ] **Test on clean macOS install**

### Build for Distribution

#### Option 1: Mac App Store

1. **Configure signing:**
   ```bash
   # In Xcode: Signing & Capabilities
   # - Team: Your Apple Developer team
   # - Signing Certificate: Mac App Distribution
   ```

2. **Archive the app:**
   - Product → Archive
   - Organizer → Distribute App
   - Choose "Mac App Store Connect"

3. **Upload to App Store Connect:**
   - Follow Xcode prompts
   - Submit for review

**App Store Review Notes:**
- Mention URL scheme is for authentication
- Provide test account if needed
- Explain accessibility permissions requirement

#### Option 2: Direct Distribution (Notarized)

1. **Build release:**
   ```bash
   xcodebuild -project GG.xcodeproj \
     -scheme GG \
     -configuration Release \
     -archivePath build/GG.xcarchive \
     archive
   ```

2. **Export app:**
   ```bash
   xcodebuild -exportArchive \
     -archivePath build/GG.xcarchive \
     -exportPath build/export \
     -exportOptionsPlist ExportOptions.plist
   ```

3. **Notarize with Apple:**
   ```bash
   # Create app bundle
   ditto -c -k --keepParent build/export/GG.app GG.zip

   # Submit for notarization
   xcrun notarytool submit GG.zip \
     --apple-id "your@email.com" \
     --team-id "YOUR_TEAM_ID" \
     --password "@keychain:AC_PASSWORD" \
     --wait

   # Staple the ticket
   xcrun stapler staple build/export/GG.app
   ```

4. **Verify notarization:**
   ```bash
   spctl -a -vv build/export/GG.app
   ```

**Expected output:**
```
build/export/GG.app: accepted
source=Notarized Developer ID
```

### Post-Release

- [ ] **Test URL scheme on production build**
- [ ] **Verify Universal Links work** (if configured)
- [ ] **Test on multiple macOS versions**
- [ ] **Monitor crash reports**
- [ ] **Update documentation**

---

## Troubleshooting

### URL Scheme Issues

#### Problem: "No application set to open ggapp:// URLs"

**Solutions:**
1. Rebuild and run the app at least once
2. Reset LaunchServices:
   ```bash
   /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user
   ```
3. Verify Info.plist is in the app bundle:
   ```bash
   # After building
   plutil -p ~/Library/Developer/Xcode/DerivedData/GG-*/Build/Products/Debug/GG.app/Contents/Info.plist | grep -A 5 CFBundleURLTypes
   ```

#### Problem: App opens but URL not received

**Solutions:**
1. Check `.onOpenURL` handler exists in `GGApp.swift`
2. Enable environment variable `OS_ACTIVITY_MODE=disable`
3. Add logging:
   ```swift
   .onOpenURL { url in
       print("🔗 URL received: \(url)")
       handleIncomingURL(url)
   }
   ```

#### Problem: Token not being saved

**Solutions:**
1. Check Xcode console for errors
2. Verify URL format: `ggapp://auth?token=VALUE`
3. Check `AuthenticationCoordinator.handleAuthCallback()` logging
4. Verify Keychain access

### Universal Links Issues

#### Problem: Links open in browser instead of app

**Solutions:**
1. **Verify apple-app-site-association file:**
   ```bash
   curl https://yourdomain.com/.well-known/apple-app-site-association
   ```

2. **Check Team ID is correct:**
   ```bash
   # Get your Team ID
   security find-identity -v -p codesigning
   ```

3. **Test with Apple's validator:**
   https://search.developer.apple.com/appsearch-validation-tool

4. **Verify HTTPS certificate is valid:**
   ```bash
   openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
   ```

5. **Reset Universal Links cache:**
   ```bash
   # On macOS
   rm -rf ~/Library/Caches/com.apple.LaunchServices.dv.cache
   killall -HUP universalaccessd
   ```

#### Problem: Universal Links worked before, now they don't

**Solutions:**
1. User may have long-pressed the link and chosen "Open in Browser"
2. macOS remembers this preference per domain
3. Only fix: User must long-press again and choose "Open in App"

### Code Signing Issues

#### Problem: "app is damaged and can't be opened"

**Solutions:**
1. App wasn't notarized
2. Remove quarantine attribute:
   ```bash
   xattr -cr /path/to/GG.app
   ```
3. Properly notarize the app (see Publishing Checklist)

#### Problem: Entitlements not applied

**Solutions:**
1. Verify entitlements file is set in build settings
2. Check code signature:
   ```bash
   codesign -d --entitlements :- /path/to/GG.app
   ```
3. Re-sign if needed:
   ```bash
   codesign --force --sign "Developer ID Application: Your Name" --entitlements GG.entitlements GG.app
   ```

---

## Additional Resources

### Apple Documentation

- [Defining a Custom URL Scheme for Your App](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [Supporting Universal Links in Your App](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)

### Testing Tools

- **Apple's Universal Links Validator:**
  https://search.developer.apple.com/appsearch-validation-tool

- **Branch.io's AASA Validator:**
  https://branch.io/resources/aasa-validator/

### Your App's Configuration

- **Bundle ID:** `gorangajic.GG`
- **URL Scheme:** `ggapp://`
- **URL Handler:** `com.typewise.ai.auth`
- **Code Files:**
  - Main handler: `GGApp.swift:85-141`
  - Auth logic: `AuthenticationCoordinator.swift:51-77`
  - Config: `Info.plist`
  - Entitlements: `GG.entitlements`

---

## Questions?

If you encounter issues not covered in this guide:

1. Check Xcode console for error messages
2. Verify LaunchServices registration: `lsregister -dump | grep ggapp`
3. Test with minimal URL: `open ggapp://test`
4. Review Apple's documentation links above

**Common Success Indicators:**

✅ `lsregister -dump` shows your app for ggapp://
✅ Xcode console shows "🔗 Received URL: ..."
✅ Token appears in Keychain after auth
✅ Universal links validator passes (if using)
✅ App opens when clicking links in Safari

---

**Last Updated:** 2025-11-18
**App Version:** 1.0
**macOS Target:** 13.0+

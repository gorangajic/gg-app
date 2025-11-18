# Browser-Based Authentication Setup

This guide explains how to configure browser-based authentication for the TypeWise AI Mac app.

## How It Works

1. User clicks "Sign In" or "Create Account" in the app
2. App opens the user's default browser to the server's login/register page
3. User enters credentials in the browser
4. On successful authentication, the browser redirects to `ggapp://auth?token=XXX`
5. macOS opens the TypeWise AI app with this URL
6. App extracts the token and authenticates the user

## Setup Instructions

### 1. Register Custom URL Scheme in Xcode

To enable the app to handle `ggapp://` URLs, you need to register the custom URL scheme:

#### Method A: Using Info.plist (Recommended)

1. In Xcode, select the **GG** project in the navigator
2. Select the **GG** target
3. Go to the **Info** tab
4. Expand **URL Types** (or add it if it doesn't exist)
5. Click **+** to add a new URL Type
6. Configure as follows:
   - **Identifier**: `com.typewise.ai.auth`
   - **URL Schemes**: `ggapp`
   - **Role**: `Editor`

#### Method B: Manual Info.plist Edit

If you prefer to edit the Info.plist directly, add this XML inside the `<dict>` tag:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.typewise.ai.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ggapp</string>
        </array>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
    </dict>
</array>
```

### 2. Configure Server URL

By default, the app connects to `http://localhost:3001`. To change this:

1. Run the app
2. Go to Settings
3. Update the "Server URL" field
4. The URL should point to your running server (e.g., `http://localhost:3001` or `https://your-server.com`)

### 3. Test the Authentication Flow

#### Option A: Full Browser Flow

1. Make sure the server is running (`cd server && npm run dev`)
2. In the Mac app, click "Sign In"
3. Browser opens to `http://localhost:3001/login`
4. Enter your credentials and click "Sign In"
5. Browser redirects to `ggapp://auth?token=...`
6. Mac app receives the token and authenticates

#### Option B: Manual Testing with Terminal

You can test the URL handling directly:

```bash
open "ggapp://auth?token=test-token-here"
```

The app should receive this URL and print to console:
```
🔗 Received URL: ggapp://auth?token=test-token-here
```

## Implementation Details

### Files Added/Modified

1. **Server Side:**
   - `/login` - Login page (`server/src/app/login/page.tsx`)
   - `/register` - Registration page (`server/src/app/register/page.tsx`)
   - Both pages redirect to `ggapp://auth?token=XXX` on success

2. **Mac App Side:**
   - `AuthenticationCoordinator.swift` - Manages auth state and browser flow
   - `ServerAPIClient.swift` - HTTP client for server API
   - `ServerAIService.swift` - AI service using server API
   - `GGApp.swift` - URL handling with `.onOpenURL` modifier

### URL Scheme Format

```
ggapp://auth?token=<jwt-token>
```

Where `<jwt-token>` is the JWT authentication token returned by the server.

### Security Considerations

1. **Token Security**: The token is passed via URL, which is visible in browser history. For production:
   - Use HTTPS for the server
   - Consider adding a short expiry time for the token
   - Implement token exchange (receive a short-lived code, exchange for long-lived token)

2. **URL Scheme Security**: Any app can register the `ggapp://` scheme. To improve security:
   - Use associated domains (Universal Links) in addition to custom URL schemes
   - Validate the token server-side before accepting it
   - Implement refresh tokens for long-term access

## Troubleshooting

### App doesn't open from browser

**Check:**
- URL scheme is registered correctly in Xcode (see Step 1 above)
- App is built and installed on the system
- Check Console.app for any error messages from the app

**Fix:**
- Rebuild and reinstall the app
- Try manually opening the URL from Terminal: `open "ggapp://auth?token=test"`

### Token not being saved

**Check:**
- Keychain access is working (check System Preferences > Security & Privacy)
- Console logs show "Successfully signed in!"

**Fix:**
- Grant keychain access to the app if prompted
- Check that `KeychainHelper` has correct service name

### Server not accessible

**Check:**
- Server is running (`npm run dev` in server directory)
- Server URL is correct in app settings
- No firewall blocking the connection

**Fix:**
- Start the server
- Update server URL in app settings
- Check server logs for errors

## Development Workflow

### Running Everything Locally

1. **Start the server:**
   ```bash
   cd server
   npm install
   npm run dev
   ```
   Server runs on http://localhost:3001

2. **Build and run the Mac app:**
   - Open `mac-app/GG.xcodeproj` in Xcode
   - Build and run (Cmd+R)

3. **Test authentication:**
   - Click "Sign In" in the app
   - Browser opens login page
   - Create an account or sign in
   - App receives token automatically

### Using a Remote Server

If deploying the server to production:

1. Deploy server to a hosting provider (Vercel, Railway, Heroku, etc.)
2. Update server URL in Mac app settings to point to production server
3. Ensure HTTPS is enabled on production server
4. Update CORS settings on server to allow requests from app

## Next Steps

- Add authentication UI to ContentView or create a dedicated AuthView
- Show login status in the app
- Add "Sign Out" button
- Switch from OpenAIService to ServerAIService once authenticated
- Add server URL configuration to Settings view

## Additional Resources

- [Apple Documentation: Defining a Custom URL Scheme](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [SwiftUI URL Handling](https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:))

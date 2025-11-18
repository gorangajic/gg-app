# Mac App Integration TODO

This document lists the remaining integration steps to fully enable server-based authentication.

## ✅ Completed

- [x] ServerAPIClient for HTTP communication
- [x] ServerAIService implementing AIServiceProtocol
- [x] AuthenticationCoordinator for auth state management
- [x] AuthenticationView UI component
- [x] URL handling in GGApp.swift
- [x] Keychain storage for tokens

## 🔴 Required to Test

### 1. Register URL Scheme in Xcode (CRITICAL)

**Without this, browser authentication won't work!**

**Steps:**
1. Open `mac-app/GG.xcodeproj` in Xcode
2. Select the **GG** target in the project navigator
3. Click the **Info** tab
4. Scroll to **URL Types** section (or add it)
5. Click **+** to add a new URL Type
6. Configure:
   - **Identifier**: `com.typewise.ai.auth`
   - **URL Schemes**: `ggapp`
   - **Role**: `Editor`
7. Build and run the app

**Test it works:**
```bash
# With app running, execute in terminal:
open "ggapp://auth?token=test-token"

# App should log:
# 🔗 Received URL: ggapp://auth?token=test-token
```

See `BROWSER_AUTH_SETUP.md` for detailed instructions.

## 🟡 Recommended for Full Functionality

### 2. Add Authentication View to UI

The `AuthenticationView` exists but needs to be shown in the app.

**Option A: Add to ContentView**

Edit `ContentView.swift` to show auth status:

```swift
struct ContentView: View {
    @EnvironmentObject var authCoordinator: AuthenticationCoordinator
    // ... existing properties

    var body: some View {
        VStack {
            // Show auth status
            if authCoordinator.isAuthenticated {
                Text("✓ Signed in as \(authCoordinator.currentUser?.email ?? "User")")
                    .foregroundColor(.green)
            } else {
                Button("Sign In") {
                    authCoordinator.openBrowserForLogin()
                }
            }

            // ... existing content
        }
    }
}
```

**Option B: Create Dedicated Auth Window**

Add new window to `GGApp.swift`:

```swift
// Add after Demo window
WindowGroup("Authentication") {
    AuthenticationView()
        .environmentObject(authCoordinator)
}
.windowStyle(.hiddenTitleBar)
.windowResizability(.contentSize)
```

Then add menu item to open it.

### 3. Switch to ServerAIService

Currently using `OpenAIService`, should switch to `ServerAIService` when authenticated.

**Option A: Always Use Server (Recommended)**

Edit `GGApp.swift` init:

```swift
init() {
    // ... existing code

    // Replace this:
    let aiService = OpenAIService(apiKey: "")

    // With this:
    let serverService = ServerAIService()
    let aiService = serverService  // Cast to protocol type

    // ... rest of init
}
```

**Option B: Conditional Based on Auth Status**

Create a factory that returns the appropriate service:

```swift
class AIServiceFactory {
    static func createService(isAuthenticated: Bool) -> AIServiceProtocol {
        if isAuthenticated {
            return ServerAIService()
        } else {
            return OpenAIService(apiKey: "")
        }
    }
}
```

### 4. Add Settings for Server URL

Edit `AISettingsView.swift` to add server configuration:

```swift
@EnvironmentObject var authCoordinator: AuthenticationCoordinator

// Add in settings form:
Section("Server Configuration") {
    TextField("Server URL", text: $authCoordinator.serverURL)
        .textFieldStyle(.roundedBorder)

    Text("Current: \(authCoordinator.isAuthenticated ? "Connected" : "Not connected")")
        .foregroundColor(authCoordinator.isAuthenticated ? .green : .gray)
}
```

### 5. Handle Authentication Errors

Add error handling UI:

```swift
// In AuthenticationCoordinator, add:
@Published var lastError: String?

// In AuthenticationView, show errors:
if let error = authCoordinator.lastError {
    Text(error)
        .foregroundColor(.red)
        .font(.caption)
}
```

## 🟢 Nice to Have

### 6. Add Menu Bar Item

Add menu commands for authentication:

```swift
// In GGApp.swift
var body: some Scene {
    // ... existing windows

    Settings {
        AuthenticationView()
            .environmentObject(authCoordinator)
    }
}

// Add commands:
.commands {
    CommandGroup(replacing: .appInfo) {
        Button("Sign In...") {
            authCoordinator.openBrowserForLogin()
        }
        .disabled(authCoordinator.isAuthenticated)

        Button("Sign Out") {
            Task {
                await authCoordinator.logout()
            }
        }
        .disabled(!authCoordinator.isAuthenticated)
    }
}
```

### 7. Auto-Refresh Tokens

JWT tokens expire after 7 days. Add refresh logic:

```swift
// In AuthenticationCoordinator
func scheduleTokenRefresh() {
    // Refresh token before it expires
    Timer.scheduledTimer(withTimeInterval: 6 * 24 * 3600, repeats: true) { _ in
        Task {
            await self.refreshToken()
        }
    }
}
```

### 8. Offline Mode

Cache recent suggestions for offline use:

```swift
// In ServerAIService
private var cachedSuggestions: [String: SuggestionResponse] = [:]

func generateSuggestions(for text: String, context: AIContext) async throws -> AISuggestionResponse {
    // Try server first
    do {
        let response = try await apiClient.generateSuggestions(...)
        cachedSuggestions[text] = response  // Cache it
        return response
    } catch {
        // Fall back to cache if offline
        if let cached = cachedSuggestions[text] {
            return cached
        }
        throw error
    }
}
```

### 9. Usage Analytics Dashboard

Show user their usage stats:

```swift
// Add endpoint to server: GET /api/usage
// Show in app:
struct UsageStatsView: View {
    @State private var stats: UsageStats?

    var body: some View {
        VStack {
            Text("Suggestions generated: \(stats?.totalSuggestions ?? 0)")
            Text("Tokens used: \(stats?.totalTokens ?? 0)")
            // ... more stats
        }
    }
}
```

## Testing Checklist

Once URL scheme is registered, test this flow:

- [ ] Open app
- [ ] Click "Sign In" (opens browser)
- [ ] Enter credentials in browser
- [ ] Browser redirects to `ggapp://auth?token=...`
- [ ] App receives URL and shows "Successfully signed in!"
- [ ] App stores token in Keychain
- [ ] AI features work with server API
- [ ] Sign out clears token
- [ ] Can sign in again

## Quick Test Command

```bash
# 1. Start server
cd server && npm run dev

# 2. Create test account via curl
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# 3. Get token from response and test URL handling:
open "ggapp://auth?token=YOUR_TOKEN_HERE"
```

## Files to Modify

For full integration, you'll likely need to modify:
- [ ] `ContentView.swift` - Add auth UI
- [ ] `AISettingsView.swift` - Add server config
- [ ] `GGApp.swift` - Switch to ServerAIService
- [ ] Xcode project - Register URL scheme

## Questions?

See the detailed documentation:
- `BROWSER_AUTH_SETUP.md` - URL scheme setup
- `server/SETUP.md` - Server setup
- `server/README.md` - API documentation

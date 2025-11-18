# Claude.md - TypeWise AI / GG App

## Project Overview

TypeWise AI (GG App) is an intelligent writing assistant that provides AI-powered suggestions anywhere you type on macOS. The project is structured as a monorepo containing three main components:

1. **Mac App** - Native macOS application (Swift/SwiftUI)
2. **Server** - Backend API (Next.js/TypeScript)
3. **Browser Extension** - Web browser integration

## Architecture

### High-Level Flow

1. User types in any macOS application
2. Mac app monitors keyboard/text field activity via Accessibility API
3. User triggers AI suggestions manually via floating button
4. Mac app sends authenticated request to server
5. Server processes request using OpenAI API
6. Server returns suggestions (grammar, style, clarity, tone, etc.)
7. Mac app displays suggestions in floating overlay UI
8. User selects suggestion to apply changes

### Security & Privacy

- **Server-Controlled AI**: All OpenAI API interactions happen server-side
- **No Direct Client Access**: API keys never exposed to clients
- **JWT Authentication**: Secure user authentication with token-based sessions
- **Temporary Storage**: Text only stored in memory, never persisted

## Mac App (Swift/SwiftUI)

### Location
`mac-app/GG/`

### Core Modules

#### Module 1: Keyboard Monitoring
- **File**: `KeyboardMonitor.swift`
- **Purpose**: System-wide keystroke capture using CGEventTap
- **Features**:
  - Non-blocking event capture
  - Intelligent text buffering (last 20 words)
  - Smart trigger detection (sentence endings, pauses, Enter key)
  - Delegate pattern for notifications

#### Module 2: Text Field Reader
- **File**: `TextFieldReader.swift`
- **Purpose**: Focused text field monitoring via Accessibility API
- **Features**:
  - Detects focused text fields/areas
  - Reads current content
  - Tracks text changes
  - Provides element position/size for UI placement

#### Module 3: AI Suggestion Engine
- **File**: `AISuggestionEngine.swift`
- **Purpose**: Manages AI suggestion workflow
- **Features**:
  - Manual trigger mode (user-initiated via button)
  - Communicates with server API
  - Processes suggestion responses
  - Applies suggestions to active text field

#### Module 4: Suggestion UI
- **Files**: `SuggestionOverlayWindow.swift`, `SuggestionTriggerButton.swift`
- **Purpose**: Floating UI for triggers and suggestions
- **Features**:
  - Context-aware positioning near text fields
  - Auto-hide timers (8s for button, 10s for overlay)
  - Click-through windows
  - Suggestion application

### Key Components

- **GGApp.swift**: Main app entry point, dependency injection
- **AppDelegate.swift**: Coordinates all modules, handles delegation
- **ContentView.swift**: Main UI window
- **AuthenticationView.swift**: User login/registration
- **AuthenticationCoordinator.swift**: OAuth/auth flow handling
- **AISettingsView.swift**: AI configuration UI
- **ServerAIService.swift**: API client for backend
- **ServerAPIClient.swift**: HTTP client wrapper

### Permissions Required
- Accessibility (for keyboard monitoring and text field reading)
- App sandbox disabled (for system-wide monitoring)

### Settings Storage
- API keys: Keychain (secure)
- Preferences: UserDefaults (non-sensitive)

## Server (Next.js/TypeScript)

### Location
`server/`

### Tech Stack
- Framework: Next.js 14 with App Router
- Language: TypeScript
- Database: PostgreSQL
- ORM: Prisma
- Authentication: JWT with bcryptjs
- AI: OpenAI SDK (GPT-3.5-turbo)

### API Endpoints

#### Authentication (`/api/auth`)
- `POST /api/auth/register` - Create new user
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - End session

#### AI Suggestions (`/api/suggestions`)
- `POST /api/suggestions/generate` - Generate writing suggestions (6 types)
- `POST /api/suggestions/improve-grammar` - Fix grammar/spelling
- `POST /api/suggestions/rewrite` - Rewrite in different styles

### AI Suggestion Types
1. **Grammar**: Subject-verb agreement, tense consistency
2. **Style**: Passive to active voice, word choice
3. **Clarity**: Simplify complex sentences, remove ambiguity
4. **Tone**: Adjust formality, professionalism
5. **Spelling**: Correct misspellings
6. **Conciseness**: Remove redundancy, wordiness

### Rewrite Styles
- Professional, Casual, Formal, Friendly, Concise, Creative

### Database Schema

**Users**
- id, email (unique), password (hashed), name, timestamps

**Sessions**
- id, userId, token (unique), expiresAt, createdAt

### Environment Variables
- `DATABASE_URL` - PostgreSQL connection
- `JWT_SECRET` - JWT signing secret
- `OPENAI_API_KEY` - OpenAI API key
- `AI_MODEL` - Model name (default: gpt-3.5-turbo)
- `AI_MAX_TOKENS` - Token limit (default: 500)
- `AI_TEMPERATURE` - Creativity setting (default: 0.3)

## Development Practices

### Swift/SwiftUI Conventions
- Use `@StateObject` for owned objects
- Use `@ObservedObject` for passed objects
- Delegate pattern for cross-module communication
- NotificationCenter for app-wide events
- Main actor isolation for UI updates
- Async/await for async operations

### TypeScript/Next.js Conventions
- App Router (not Pages Router)
- API route handlers return NextResponse
- Prisma for type-safe database access
- Environment variables validated at startup
- JWT middleware for protected routes

### Git Workflow
- Branch naming: `claude/<description>-<session-id>`
- All development on feature branches
- Push with `-u` flag for tracking
- Descriptive commit messages

## Common Patterns

### Notification Names (Mac App)
```swift
.suggestionTriggered
.textFieldContentChanged
.textFieldLostFocus
.aiSuggestionsGenerated
.aiSuggestionApplied
.aiSuggestionError
.authenticationStateChanged
```

### Delegation Pattern (Mac App)
- `KeyboardMonitorDelegate`
- `TextFieldReaderDelegate`
- `AISuggestionEngineDelegate`
- `SuggestionTriggerDelegate`

### API Response Format (Server)
```typescript
// Success
{ suggestions: [...], processingTime: 1234 }

// Error
{ error: "message" }
```

## Important Files

### Configuration
- `mac-app/GG.xcodeproj` - Xcode project
- `server/.env` - Environment variables
- `server/prisma/schema.prisma` - Database schema
- `package.json` (root) - Monorepo workspace config

### Entry Points
- `mac-app/GG/GGApp.swift` - Mac app main
- `server/src/app/page.tsx` - Server home
- `server/src/app/api/*` - API routes

## Known Limitations

1. **Manual Trigger Only**: Auto-trigger disabled, user must click button
2. **macOS Only**: Desktop app requires macOS with Accessibility permissions
3. **English Focus**: AI prompts optimized for English text
4. **Sandbox Disabled**: Required for system-wide monitoring
5. **Session Expiry**: JWT sessions expire after 7 days

## Testing

### Mac App
- Unit tests: `mac-app/GGTests/`
- UI tests: `mac-app/GGUITests/`
- Manual testing in TextFieldDemo window

### Server
- API testing via HTTP clients (curl, Postman)
- Database testing via Prisma Studio

## Performance Considerations

### Mac App
- Minimal CPU impact via efficient event filtering
- Memory scales with typing activity
- Auto-cleanup of text buffers
- Debounced suggestion requests

### Server
- OpenAI API latency: ~1-2 seconds
- Token limits prevent excessive costs
- Database queries optimized via Prisma
- Session cleanup for expired tokens

## Security Considerations

1. **API Keys**: Server-side only, never exposed
2. **Password Hashing**: bcryptjs with 10 salt rounds
3. **JWT Validation**: All protected routes verified
4. **CORS**: Configure for production
5. **Rate Limiting**: Recommended for production
6. **Input Validation**: Sanitize all user inputs

## Recent Changes

- Fixed actor isolation errors in AISuggestionEngine (PR #15)
- Upgraded Prisma dependencies (PR #13)
- Fixed AIContext ambiguity issues (PR #14)

## Development Setup

### Mac App
1. Open `mac-app/GG.xcodeproj` in Xcode
2. Build and run (Cmd+R)
3. Grant Accessibility permissions in System Preferences
4. Configure server URL and authentication

### Server
1. `cd server && npm install`
2. Copy `.env.example` to `.env` and configure
3. `npm run db:push` to set up database
4. `npm run dev` to start server on port 3001

### Monorepo
- Root `package.json` defines workspaces
- Run `npm install` at root to set up all workspaces

## Useful Commands

### Server
- `npm run dev` - Development server
- `npm run build` - Production build
- `npm run db:studio` - Open Prisma Studio
- `npm run db:migrate` - Create migration
- `npm run db:push` - Push schema changes

### Mac App
- Build: Xcode > Product > Build (Cmd+B)
- Run: Xcode > Product > Run (Cmd+R)
- Test: Xcode > Product > Test (Cmd+U)

## Branch Information

Current branch: `claude/create-claude-md-01VFAUCz9XHLeb9jFdvCf5wQ`

Main branch: (to be determined based on project setup)

## Support & Documentation

- Server API: See `server/README.md`
- Mac App: See `mac-app/README.md`
- GitHub Issues: https://github.com/gorangajic/gg-app/issues

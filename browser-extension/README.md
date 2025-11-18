# TypeWise AI - Chrome Extension

AI-powered writing assistant that provides real-time grammar, style, clarity, and tone suggestions directly in your browser.

## Overview

TypeWise AI Chrome Extension brings the power of AI-assisted writing to every text field in your browser. It monitors your typing and provides intelligent suggestions to improve your writing quality, just like the Mac native app, but with deep integration into web pages and access to browser DOM APIs.

## Features

- ✨ **Real-time AI Suggestions**: Get grammar, style, clarity, tone, spelling, and conciseness suggestions as you type
- 🎯 **Smart Text Detection**: Automatically monitors all text inputs, textareas, and contenteditable elements
- ⚡ **Auto-trigger**: Suggestions appear automatically after sentence endings or typing pauses
- ⌨️ **Keyboard Shortcuts**: Quick access with Ctrl/Cmd + Shift + Space
- 🔐 **Secure Authentication**: Uses the same server authentication as the Mac app
- ⚙️ **Customizable Settings**: Configure auto-trigger, delays, and suggestion limits
- 🎨 **Beautiful UI**: Floating overlay with confidence scores and explanations

## Installation

### Method 1: Load Unpacked Extension (Development)

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" in the top right
3. Click "Load unpacked"
4. Select the `browser-extension` directory
5. The TypeWise AI extension is now installed!

### Method 2: Chrome Web Store (Future)

Once published, the extension will be available on the Chrome Web Store.

## Setup

### Prerequisites

1. **Server Running**: The TypeWise AI server must be running at `http://localhost:3001` (or your configured URL)
2. **Account**: You need a TypeWise AI account (can be created through the extension)

### First Time Setup

1. Click the TypeWise AI extension icon in your Chrome toolbar
2. Sign in with your account or create a new one
3. Once authenticated, the extension will start monitoring your typing
4. Start typing in any text field to see suggestions!

### Adding Icons (Optional)

The extension needs icon files in the `icons/` directory:
- `icon16.png` (16x16 pixels)
- `icon48.png` (48x48 pixels)
- `icon128.png` (128x128 pixels)

You can create these using any graphic design tool or copy them from the Mac app assets.

## Usage

### Automatic Suggestions

1. Focus any text field on a webpage
2. Start typing (minimum 10 characters by default)
3. Suggestions will appear automatically after:
   - Sentence endings (., !, ?)
   - Typing pauses (2 seconds by default)

### Manual Trigger

Press **Ctrl+Shift+Space** (Windows/Linux) or **Cmd+Shift+Space** (Mac) to manually trigger suggestions.

### Applying Suggestions

- **Click** on a suggestion to apply it
- Use **↑/↓ arrows** to navigate suggestions
- Press **Enter** to apply the selected suggestion
- Press **Esc** to close the suggestion overlay

## Configuration

Click the extension icon and select "Settings" to configure:

### Server Configuration
- **Server URL**: URL of your TypeWise AI server (default: `http://localhost:3001`)

### Suggestion Settings
- **Auto-trigger**: Enable/disable automatic suggestions
- **Minimum text length**: Minimum characters before triggering (default: 10)
- **Suggestion delay**: Delay after typing stops (default: 2000ms)
- **Maximum suggestions**: Number of suggestions to display (default: 5)

## Architecture

### Components

1. **manifest.json**: Extension configuration (Manifest V3)
2. **background.js**: Service worker for API communication
3. **content.js**: DOM monitoring and text capture
4. **content.css**: Suggestion overlay styling
5. **popup.html/js/css**: Authentication UI
6. **options.html/js/css**: Settings page

### How It Works

```
┌─────────────────────────────────────────────────────────┐
│                     Web Page                            │
│  ┌────────────────────────────────────────────────┐    │
│  │  Text Field (input/textarea/contenteditable)   │    │
│  └──────────────────┬─────────────────────────────┘    │
│                     │ User types                        │
│                     ▼                                   │
│           ┌──────────────────┐                          │
│           │  content.js      │                          │
│           │  - Monitors DOM  │                          │
│           │  - Captures text │                          │
│           │  - Detects focus │                          │
│           └────────┬─────────┘                          │
└────────────────────┼──────────────────────────────────────┘
                     │
                     ▼ Message
           ┌──────────────────┐
           │  background.js   │
           │  - API client    │
           │  - Auth handler  │
           └────────┬─────────┘
                    │
                    ▼ HTTP POST
           ┌──────────────────┐
           │  TypeWise Server │
           │  - Authentication│
           │  - AI Processing │
           │  - OpenAI GPT    │
           └────────┬─────────┘
                    │
                    ▼ Response
           ┌──────────────────┐
           │  content.js      │
           │  - Show overlay  │
           │  - Display list  │
           │  - Apply changes │
           └──────────────────┘
```

### Data Flow

1. **Text Capture**: Content script monitors text fields and captures input
2. **Trigger Detection**: Auto-trigger on sentence endings or typing pause
3. **API Request**: Background worker sends text to server with context
4. **AI Processing**: Server uses OpenAI to generate suggestions
5. **Display**: Content script shows suggestions in floating overlay
6. **Application**: User clicks to replace text with suggestion

## API Endpoints

The extension communicates with the server using these endpoints:

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout

### AI Suggestions
- `POST /api/suggestions/generate` - Generate suggestions
- `POST /api/suggestions/improve-grammar` - Grammar improvements
- `POST /api/suggestions/rewrite` - Rewrite in different styles

## Privacy & Security

- **Authentication**: JWT tokens stored securely in Chrome sync storage
- **Data**: Text is only sent to the server when suggestions are triggered
- **Server Communication**: All API calls require authentication
- **No Tracking**: Extension does not track or store your typing data
- **Local Processing**: DOM monitoring happens entirely in your browser

## Troubleshooting

### Extension not working
1. Check that you're authenticated (click extension icon)
2. Verify the server is running at the configured URL
3. Check browser console for errors (F12 → Console tab)

### Suggestions not appearing
1. Ensure auto-trigger is enabled in settings
2. Check minimum text length requirement
3. Try manual trigger (Ctrl/Cmd + Shift + Space)
4. Verify network connectivity to server

### Authentication issues
1. Verify server is running
2. Check server URL in settings
3. Try logging out and back in
4. Check server logs for authentication errors

## Development

### File Structure

```
browser-extension/
├── manifest.json          # Extension manifest (Manifest V3)
├── background.js          # Service worker for API calls
├── content.js             # DOM monitoring and text capture
├── content.css            # Overlay styling
├── popup.html             # Authentication popup
├── popup.css              # Popup styling
├── popup.js               # Popup logic
├── options.html           # Settings page
├── options.css            # Settings styling
├── options.js             # Settings logic
├── icons/                 # Extension icons
│   ├── icon16.png
│   ├── icon48.png
│   └── icon128.png
├── package.json           # Extension metadata
└── README.md              # This file
```

### Testing

1. Make changes to the extension files
2. Go to `chrome://extensions/`
3. Click the refresh icon on the TypeWise AI extension
4. Test your changes on any webpage

### Debugging

- **Background Worker**: `chrome://extensions/` → Click "service worker" link
- **Content Script**: Open DevTools on any page (F12) → Console tab
- **Popup**: Right-click extension icon → "Inspect popup"

## Differences from Mac App

| Feature | Mac App | Chrome Extension |
|---------|---------|------------------|
| **Scope** | System-wide monitoring | Web pages only |
| **Text Capture** | CGEventTap keyboard monitoring | DOM event listeners |
| **Field Detection** | macOS Accessibility API | DOM inspection |
| **UI** | Native macOS windows | DOM-based overlays |
| **Storage** | Keychain | Chrome sync storage |
| **Auth Flow** | Browser redirect to `ggapp://` | Direct popup |
| **Permissions** | Accessibility access | Browser permissions |

## Future Enhancements

- [ ] Support for more rewrite styles
- [ ] Offline mode with cached suggestions
- [ ] Custom vocabulary and ignore lists
- [ ] Website-specific settings
- [ ] Integration with popular writing tools
- [ ] Statistics and writing insights
- [ ] Team collaboration features

## Support

For issues, questions, or feature requests, please open an issue in the repository.

## License

MIT License - See LICENSE file for details

## Version History

### 1.0.0 (2025)
- Initial release
- Authentication flow
- Real-time suggestions
- DOM monitoring
- Settings page
- Keyboard shortcuts

# TypeWise AI Chrome Extension - Installation Guide

## Quick Start

### Step 1: Prepare Icons (Important!)

The extension requires icon files. You have two options:

#### Option A: Create Placeholder Icons (Quick)
For testing purposes, you can skip this and Chrome will show a default icon.

#### Option B: Add Proper Icons (Recommended)
Add these PNG files to the `icons/` directory:
- `icon16.png` (16x16 pixels)
- `icon48.png` (48x48 pixels)
- `icon128.png` (128x128 pixels)

You can use the provided `icon.svg` as a template or create your own.

**Quick conversion from SVG (requires ImageMagick):**
```bash
cd icons
convert -background none icon.svg -resize 16x16 icon16.png
convert -background none icon.svg -resize 48x48 icon48.png
convert -background none icon.svg -resize 128x128 icon128.png
```

### Step 2: Load Extension in Chrome

1. Open Chrome browser
2. Navigate to: `chrome://extensions/`
3. Enable **"Developer mode"** toggle (top right corner)
4. Click **"Load unpacked"** button
5. Select the `browser-extension` directory from this repository
6. The extension should now appear in your extensions list!

### Step 3: Start the TypeWise AI Server

The extension requires the TypeWise AI server to be running:

```bash
# From the repository root
cd server
npm install
npm run dev
```

The server should start at `http://localhost:3001`

### Step 4: Authenticate

1. Click the TypeWise AI extension icon in your Chrome toolbar
2. Choose one of the following:
   - **Sign In**: If you already have an account
   - **Create Account**: To register a new account

3. Enter your credentials:
   - Email address
   - Password
   - Name (optional for registration)

4. Click the submit button

Once authenticated, you'll see the "Active" status screen.

### Step 5: Test the Extension

1. Navigate to any website (e.g., Gmail, Google Docs, Twitter)
2. Click on any text input field, textarea, or contenteditable element
3. Start typing (minimum 10 characters)
4. After typing a sentence (ending with `.`, `!`, or `?`) or pausing for 2 seconds, suggestions will appear!

**Manual trigger**: Press `Ctrl+Shift+Space` (or `Cmd+Shift+Space` on Mac) to manually request suggestions.

## Configuration

Click the extension icon → **Settings** to customize:

- **Server URL**: Change if using a different server address
- **Auto-trigger**: Enable/disable automatic suggestions
- **Minimum text length**: Characters required before triggering
- **Suggestion delay**: Milliseconds to wait after typing stops
- **Maximum suggestions**: Number of suggestions to show

## Troubleshooting

### Extension won't load
- **Missing icons**: Chrome might require at least one icon file. See Step 1.
- **Manifest errors**: Check that all files are present in the directory
- **Permissions**: Ensure you have permission to access the directory

### Can't authenticate
- **Server not running**: Make sure the server is running at the configured URL
- **Wrong URL**: Check the server URL in settings (default: `http://localhost:3001`)
- **Network error**: Check browser console (F12) for error messages

### Suggestions not appearing
- **Not authenticated**: Click extension icon to verify you're signed in
- **Text too short**: Default minimum is 10 characters
- **Auto-trigger disabled**: Check settings or use manual trigger (`Ctrl+Shift+Space`)
- **Server error**: Check server logs for API errors

### Overlay not showing
- **Content script error**: Open browser console (F12) and check for errors
- **CSS conflict**: Some websites may have CSS that conflicts with the overlay
- **Check positioning**: The overlay may be off-screen; try a different text field

## Debugging

### Check Background Worker
1. Go to `chrome://extensions/`
2. Find TypeWise AI extension
3. Click "service worker" link
4. View console for background script logs

### Check Content Script
1. Open any webpage
2. Press F12 to open DevTools
3. Go to Console tab
4. Look for "TypeWise AI:" log messages

### Check Popup
1. Right-click the extension icon
2. Select "Inspect popup"
3. View console for popup errors

## Development Mode

### Making Changes

1. Edit the extension files
2. Go to `chrome://extensions/`
3. Click the refresh icon (↻) on the TypeWise AI card
4. Test your changes

### Hot Reload

Changes to content scripts require a page refresh:
1. Make your changes
2. Reload the extension
3. Refresh the webpage you're testing on

Background worker changes:
1. Make your changes
2. Reload the extension (this restarts the service worker)

## Uninstalling

1. Go to `chrome://extensions/`
2. Find TypeWise AI extension
3. Click "Remove"
4. Confirm removal

Your account data remains on the server and can be accessed again by reinstalling.

## Next Steps

- Explore the settings to customize behavior
- Try different text fields on various websites
- Test the keyboard shortcuts
- Check out the [README.md](README.md) for more details on features and architecture

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review server logs for API errors
3. Check browser console for JavaScript errors
4. Open an issue in the repository with details

Happy writing! ✨

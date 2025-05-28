# TypeWise AI - macOS Writing Assistant

A macOS desktop assistant that provides AI-powered writing suggestions anywhere you type.

## Module 1: Keyboard Monitoring ✅

### Features Implemented

- **System-wide Keystroke Capture**: Uses `CGEventTap` to monitor all keyboard input across macOS
- **Intelligent Text Buffering**: Accumulates keystrokes into meaningful text segments
- **Smart Suggestion Triggers**: Automatically detects when to trigger suggestions based on:
  - Sentence endings (periods, exclamation marks, question marks)
  - Typing pauses (1.5 second delay)
  - Return/Enter key presses
- **Real-time Text Display**: Live preview of captured text in the app interface
- **Accessibility Integration**: Proper permission handling for macOS accessibility features

### Setup Instructions

1. **Build the Project**: Open `GG.xcodeproj` in Xcode and build the app
2. **Grant Permissions**: When first launching, the app will request accessibility permissions
3. **System Preferences**: Navigate to System Preferences > Security & Privacy > Accessibility
4. **Enable Access**: Add and enable your built app in the accessibility list

### Architecture

#### `KeyboardMonitor` Class

- **Event Handling**: Captures key events using Core Graphics Event Services
- **Text Processing**: Converts keycodes to characters and manages text buffer
- **Intelligent Triggering**: Uses timers and heuristics to determine optimal suggestion moments
- **Delegate Pattern**: Notifies the app when suggestions should be triggered

#### Key Features

- **Non-blocking**: Keyboard events pass through normally to other apps
- **Memory Efficient**: Maintains rolling buffer of recent text (last 20 words)
- **Privacy Conscious**: Text is only stored temporarily in memory
- **Configurable**: Suggestion delay and trigger conditions can be adjusted

### Testing Module 1

1. Launch the app and grant accessibility permissions
2. Click "Start Monitoring"
3. Type in any application (Notes, TextEdit, Safari, etc.)
4. Watch the "Live Text Buffer" update in real-time
5. Notice suggestion triggers appear after:
   - Completing sentences
   - Pausing while typing
   - Pressing Enter

### Next Steps

Module 1 provides the foundation for:

- **Module 2**: Focused Text Field Reader (using Accessibility API)
- **Module 3**: AI Suggestion Engine (OpenAI integration)
- **Module 4**: Suggestion UI Overlay (floating panels)
- **Module 5**: UX Polish & Settings

### Technical Details

#### Dependencies

- **Carbon Framework**: For keyboard layout and key translation
- **Cocoa Framework**: For accessibility permissions and UI alerts
- **Core Graphics**: For event tapping and monitoring

#### Security Considerations

- App sandbox has been disabled to allow system-wide monitoring
- Accessibility permissions are required and properly requested
- No persistent storage of captured text

#### Performance

- Minimal CPU impact due to efficient event filtering
- Memory usage scales with typing activity
- Automatic cleanup of old text buffer content

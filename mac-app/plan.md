TypeWise AI is a macOS desktop assistant that runs quietly in the background and helps users improve their writing — anywhere they type.

By monitoring system-wide keyboard input and reading the text fields users interact with, the app sends real-time text to an AI-powered backend (e.g., OpenAI API) and offers improved, polished, or context-aware suggestions. These suggestions are displayed via a floating bubble UI near the text field, similar to Grammarly Desktop.

The app is non-intrusive, privacy-conscious (no data stored), and aims to work seamlessly across macOS apps like Mail, Notes, Safari, Slack, Notion, etc.

🎯 What We’re Building – High-Level Plan
🔹 Module 1: Keyboard Monitoring
Capture user keystrokes system-wide using CGEventTap, buffer them into words/sentences, and trigger suggestions intelligently (e.g., after a period or pause).

🔹 Module 2: Focused Text Field Reader
Use the Accessibility API (AXUIElement) to:

Identify the currently focused text field

Extract its text content

Optionally inject new content back into the field

🔹 Module 3: AI Suggestion Engine
Send captured text to an external API (like OpenAI) to:

Improve grammar or tone

Rewrite suggestions

Return a short summary or fix

🔹 Module 4: Suggestion UI Overlay
Create a floating NSPanel or NSWindow near the cursor/text field that:

Displays AI-generated suggestions

Lets the user click to accept or ignore

Automatically hides when not in use

🔹 Module 5: UX Polish & Settings
Add:

User preferences (API key, style, delay)

Enable/disable shortcut

Status bar icon or small control center

✅ Deliverable: A polished, real-time, system-wide writing assistant for macOS that can:
Understand user writing context anywhere

Offer helpful suggestions via AI

Seamlessly integrate with macOS UI without modifying apps directly

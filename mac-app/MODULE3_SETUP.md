# Module 3: AI Suggestion Engine - Setup Guide

## Overview

Module 3 implements the AI-powered suggestion engine that integrates with OpenAI's GPT-3.5-turbo API to provide intelligent writing assistance.

## Setup Instructions

### 1. Get OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the API key (starts with `sk-`)
5. **Important**: Keep this key secure and never share it

### 2. Configure API Key in TypeWise AI

1. Launch the TypeWise AI application
2. Click the **"AI Settings"** button in the main interface
3. In the AI Settings window:
   - Paste your API key in the "API Key" field
   - Click **"Save"** to store the key
   - Click **"Test Connection"** to verify it works
   - You should see "✅ Connection successful!"

### 3. Start the AI Engine

1. In the AI Settings window, click **"Start Engine"**
2. The status should change to "Engine Running" with a green indicator
3. Enable "Auto-generate suggestions" for automatic processing
4. Close the AI Settings window

### 4. Test the AI Features

The AI engine will now:

- Monitor your typing across all macOS applications
- Generate suggestions after you pause typing
- Display suggestions in the main interface
- Allow you to apply suggestions with one click

## AI Settings Configuration

### Engine Controls

- **Start/Stop Engine**: Control whether AI processing is active
- **Auto-generate suggestions**: Toggle automatic suggestion generation
- **Processing indicator**: Shows when AI is analyzing text

### Suggestion Preferences

- **Minimum text length**: Text must be at least this many characters (default: 15)
- **Suggestion delay**: Wait time after typing stops before generating suggestions (default: 2.0s)
- **Max suggestions**: Maximum number of suggestions to display (default: 5)

### Statistics

The interface shows:

- Total suggestions generated
- Total suggestions applied
- Average processing time
- Success rate

## Features

### Suggestion Types

The AI provides 6 types of suggestions:

1. **Grammar**: Fix grammatical errors
2. **Style**: Improve writing style
3. **Clarity**: Make text clearer and more understandable
4. **Tone**: Adjust the tone of writing
5. **Spelling**: Correct spelling mistakes
6. **Conciseness**: Make text more concise

### Quick Actions

- **Generate Now**: Manually trigger suggestion generation
- **Clear Suggestions**: Remove all current suggestions
- **Quick Rewrite**: Rewrite text in different styles (Professional, Casual, Friendly, etc.)

## Troubleshooting

### "API Key Required" Error

- Ensure you've entered a valid OpenAI API key
- Check that the key starts with `sk-`
- Verify the key is active in your OpenAI account

### "Connection Failed" Error

- Check your internet connection
- Verify your OpenAI API key is valid and active
- Ensure you have sufficient OpenAI credits/quota
- Check for any network firewalls blocking the connection

### No Suggestions Generated

- Ensure the AI engine is started (green status)
- Check that auto-generate suggestions is enabled
- Verify the text length meets the minimum requirement
- Wait for the suggestion delay period to complete

### Suggestions Not Applying

- Check that the text field is still focused
- Ensure accessibility permissions are granted
- Try manually copying and pasting the suggestion

## API Usage and Costs

### Token Usage

- The app monitors token usage in the Statistics section
- Each suggestion request uses approximately 100-300 tokens
- Grammar improvements use fewer tokens than complex rewrites

### Cost Optimization

- Increase the minimum text length to reduce API calls
- Increase the suggestion delay to prevent rapid-fire requests
- Disable auto-generation if you prefer manual control

## Privacy and Security

### Data Handling

- Text is sent to OpenAI's API for processing
- No text is stored locally or persistently
- API key is stored securely (in production, use Keychain)
- All communications are encrypted (HTTPS)

### User Control

- Users can disable AI processing at any time
- Text monitoring can be stopped independently
- Individual suggestions can be dismissed
- No automatic text injection without user approval

## Integration with Other Modules

### Module 1: Keyboard Monitor

- Receives typing events and triggers from keyboard monitoring
- Uses keyboard buffer text when text fields aren't available

### Module 2: Text Field Reader

- Receives text field content for more accurate analysis
- Uses accessibility context to improve suggestions
- Provides text injection capabilities for applying suggestions

## Advanced Configuration

### Customizing Prompts

The AI prompts can be customized by modifying the `buildSuggestionPrompt` method in `AIService.swift`.

### Adding New Suggestion Types

Add new types to the `SuggestionType` enum and update the prompt accordingly.

### Performance Tuning

- Adjust `maxTokens` in OpenAIService for longer/shorter responses
- Modify `temperature` for more/less creative suggestions
- Implement caching for repeated text analysis

## Support

If you encounter issues:

1. Check the console logs for detailed error messages
2. Verify all accessibility permissions are granted
3. Test with a simple text editor first
4. Ensure your OpenAI account has sufficient credits

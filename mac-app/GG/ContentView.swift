//
//  ContentView.swift
//  GG
//
//  Created by gole on 28.5.25..
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var keyboardMonitor: KeyboardMonitor
    @ObservedObject var textFieldReader: TextFieldReader
    @ObservedObject var aiSuggestionEngine: AISuggestionEngine
    @ObservedObject var aiService: OpenAIService
    @EnvironmentObject var authCoordinator: AuthenticationCoordinator
    @State private var lastSuggestionText: String = "No suggestions yet"
    @State private var lastTextFieldChange: String = "No text field activity"
    @State private var lastAIActivity: String = "No AI activity"
    @State private var showAuthSheet: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            // Authentication Status Banner
            authenticationBanner

            Divider()

            // Header
            VStack {
                Image(systemName: "brain.head.profile")
                    .imageScale(.large)
                    .foregroundStyle(.purple)
                    .font(.system(size: 40))

                Text("TypeWise AI")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Complete AI-Powered Writing Assistant")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Monitoring Status
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(keyboardMonitor.isMonitoring ? .green : .red)
                        .frame(width: 10, height: 10)

                    Text("Keyboard: \(keyboardMonitor.isMonitoring ? "Monitoring" : "Stopped")")
                        .font(.headline)
                }

                HStack {
                    Circle()
                        .fill(textFieldReader.isActive ? .green : .red)
                        .frame(width: 10, height: 10)

                    Text("Text Fields: \(textFieldReader.isActive ? "Monitoring" : "Stopped")")
                        .font(.headline)
                }

                HStack {
                    Circle()
                        .fill(aiSuggestionEngine.isEnabled ? .green : .red)
                        .frame(width: 10, height: 10)

                    Text("AI Engine: \(aiSuggestionEngine.isEnabled ? "Running" : "Stopped")")
                        .font(.headline)

                    if aiSuggestionEngine.isProcessing {
                        ProgressView()
                            .scaleEffect(0.6)
                    }
                }

                Text("Buffer: \(keyboardMonitor.bufferCharacterCount) chars, \(keyboardMonitor.bufferWordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !textFieldReader.focusedAppName.isEmpty {
                    Text("Focused App: \(textFieldReader.focusedAppName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if aiSuggestionEngine.apiKeyConfigured {
                    Text("AI: \(aiSuggestionEngine.totalSuggestionsGenerated) suggestions generated")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Mode: Manual trigger (button appears near text fields)")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                } else {
                    Text("AI: API key required (⌘I to configure)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            // Main Content Area
            HStack(spacing: 20) {
                // Left Column - Text Monitoring
                VStack(alignment: .leading, spacing: 15) {
                    // Real-time Keyboard Buffer
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Live Keyboard Buffer:")
                            .font(.headline)

                        ScrollView {
                            Text(keyboardMonitor.currentText.isEmpty ? "Start typing anywhere..." : keyboardMonitor.currentText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(keyboardMonitor.currentText.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(height: 120)
                    }

                    // Text Field Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focused Text Field Content:")
                            .font(.headline)

                        ScrollView {
                            Text(textFieldReader.currentText.isEmpty ? "No text field focused..." : textFieldReader.currentText)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(textFieldReader.currentText.isEmpty ? .secondary : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(height: 120)
                    }
                }
                .frame(maxWidth: .infinity)

                // Right Column - AI Suggestions
                VStack(alignment: .leading, spacing: 15) {
                    AISuggestionsView(suggestionEngine: aiSuggestionEngine)
                        .frame(height: 280)
                }
                .frame(maxWidth: .infinity)
            }

            // Last Activities Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Activity:")
                    .font(.headline)

                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Keyboard Trigger:")
                            .font(.caption)
                            .fontWeight(.medium)

                        Text(lastSuggestionText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .padding(6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Text Field Change:")
                            .font(.caption)
                            .fontWeight(.medium)

                        Text(lastTextFieldChange)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.orange)
                            .padding(6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Activity:")
                            .font(.caption)
                            .fontWeight(.medium)

                        Text(lastAIActivity)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.purple)
                            .padding(6)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            // Control Buttons
            HStack(spacing: 15) {
                Button(action: {
                    if keyboardMonitor.isMonitoring {
                        keyboardMonitor.stopMonitoring()
                    } else {
                        keyboardMonitor.startMonitoring()
                    }
                }) {
                    Text(keyboardMonitor.isMonitoring ? "Stop Keyboard" : "Start Keyboard")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    if textFieldReader.isActive {
                        textFieldReader.stopMonitoring()
                    } else {
                        textFieldReader.startMonitoring()
                    }
                }) {
                    Text(textFieldReader.isActive ? "Stop Fields" : "Start Fields")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    if aiSuggestionEngine.isEnabled {
                        aiSuggestionEngine.stopEngine()
                    } else {
                        aiSuggestionEngine.startEngine()
                    }
                }) {
                    Text(aiSuggestionEngine.isEnabled ? "Stop AI" : "Start AI")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)
                .disabled(!aiSuggestionEngine.apiKeyConfigured)

                Button("Clear Buffer") {
                    keyboardMonitor.clearBuffer()
                }
                .buttonStyle(.bordered)

                Button("AI Settings") {
                    openAISettings()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.purple)

                Button("Test Manual Trigger") {
                    aiSuggestionEngine.generateSuggestionsManually()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
                .disabled(!aiSuggestionEngine.isEnabled || !aiSuggestionEngine.apiKeyConfigured)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 800, minHeight: 700)
        .sheet(isPresented: $showAuthSheet) {
            AuthenticationView()
                .environmentObject(authCoordinator)
                .frame(minWidth: 400, minHeight: 300)
        }
        .onReceive(NotificationCenter.default.publisher(for: .suggestionTriggered)) { notification in
            if let text = notification.userInfo?["text"] as? String {
                lastSuggestionText = text
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .textFieldContentChanged)) { notification in
            if let text = notification.userInfo?["text"] as? String,
               let appName = notification.userInfo?["appName"] as? String {
                lastTextFieldChange = "[\(appName)] \(text)"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiSuggestionsGenerated)) { notification in
            if let suggestions = notification.userInfo?["suggestions"] as? [AISuggestion] {
                lastAIActivity = "Generated \(suggestions.count) suggestions"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiSuggestionApplied)) { notification in
            if let success = notification.userInfo?["success"] as? Bool {
                lastAIActivity = success ? "✅ Suggestion applied" : "❌ Application failed"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .aiSuggestionError)) { notification in
            if let error = notification.userInfo?["error"] as? AIServiceError {
                lastAIActivity = "❌ Error: \(error.localizedDescription)"
            }
        }
    }

    private func openAISettings() {
        // Open AI Settings window using NSApplication
        Task { @MainActor in
            guard let app = NSApplication.shared.delegate as? NSApplicationDelegate else { return }

            // Create and show AI Settings window
            let settingsWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 700),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )

            settingsWindow.title = "AI Settings"
            settingsWindow.contentView = NSHostingView(
                rootView: AISettingsView(suggestionEngine: aiSuggestionEngine, aiService: aiService)
            )
            settingsWindow.center()
            settingsWindow.makeKeyAndOrderFront(nil)
        }
    }

    // MARK: - Authentication Banner

    private var authenticationBanner: some View {
        Button(action: {
            showAuthSheet = true
        }) {
            HStack {
                Image(systemName: authCoordinator.isAuthenticated ? "checkmark.circle.fill" : "person.crop.circle.badge.exclamationmark")
                    .foregroundColor(authCoordinator.isAuthenticated ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    if authCoordinator.isAuthenticated {
                        Text("Signed in")
                            .font(.headline)
                            .foregroundColor(.primary)

                        if let user = authCoordinator.currentUser {
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Sign in required for AI features")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Click to authenticate")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if authCoordinator.isAuthenticated {
                    Button("Manage Account") {
                        showAuthSheet = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button("Sign In") {
                        authCoordinator.openBrowserForLogin()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(12)
            .background(authCoordinator.isAuthenticated ? Color.green.opacity(0.1) : Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let keyboardMonitor = KeyboardMonitor()
    let textFieldReader = TextFieldReader()
    let textFieldIntegration = TextFieldIntegration(keyboardMonitor: keyboardMonitor, textFieldReader: textFieldReader)
    let aiService = OpenAIService(apiKey: "test")
    let aiSuggestionEngine = AISuggestionEngine(aiService: aiService, textFieldIntegration: textFieldIntegration)
    let authCoordinator = AuthenticationCoordinator()

    return ContentView(
        keyboardMonitor: keyboardMonitor,
        textFieldReader: textFieldReader,
        aiSuggestionEngine: aiSuggestionEngine,
        aiService: aiService
    )
    .environmentObject(authCoordinator)
}

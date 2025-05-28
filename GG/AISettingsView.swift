//
//  AISettingsView.swift
//  GG
//
//  Created by TypeWise AI
//  Module 3: AI Settings and Configuration
//

import SwiftUI

struct AISettingsView: View {
    @ObservedObject var suggestionEngine: AISuggestionEngine
    @ObservedObject var aiService: OpenAIService
    @State private var apiKey: String = ""
    @State private var showingAPIKeyAlert = false
    @State private var showingTestResults = false
    @State private var testResultMessage = ""
    @State private var isTestingConnection = false

    var body: some View {
        VStack(spacing: 25) {
            // Header
            VStack {
                Image(systemName: "brain.head.profile")
                    .imageScale(.large)
                    .foregroundStyle(.purple)
                    .font(.system(size: 40))

                Text("AI Suggestion Engine")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Configure OpenAI integration and suggestion preferences")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // API Configuration
            GroupBox(label: Label("OpenAI Configuration", systemImage: "key")) {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key:")
                            .font(.headline)

                        HStack {
                            SecureField("Enter your OpenAI API key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)

                            Button("Save") {
                                saveAPIKey()
                            }
                            .disabled(apiKey.isEmpty)
                            .buttonStyle(.borderedProminent)
                        }

                        Text("Get your API key from: https://platform.openai.com/api-keys")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Label(
                            suggestionEngine.apiKeyConfigured ? "API Key Configured" : "API Key Required",
                            systemImage: suggestionEngine.apiKeyConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(suggestionEngine.apiKeyConfigured ? .green : .orange)
                        .font(.caption)

                        Spacer()

                        Button("Test Connection") {
                            testConnection()
                        }
                        .disabled(!suggestionEngine.apiKeyConfigured || isTestingConnection)
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }

            // Engine Controls
            GroupBox(label: Label("Engine Controls", systemImage: "gearshape")) {
                VStack(spacing: 15) {
                    HStack {
                        Label(
                            suggestionEngine.isEnabled ? "Engine Running" : "Engine Stopped",
                            systemImage: suggestionEngine.isEnabled ? "play.circle.fill" : "stop.circle.fill"
                        )
                        .foregroundColor(suggestionEngine.isEnabled ? .green : .red)

                        Spacer()

                        Button(suggestionEngine.isEnabled ? "Stop Engine" : "Start Engine") {
                            toggleEngine()
                        }
                        .disabled(!suggestionEngine.apiKeyConfigured)
                        .buttonStyle(.borderedProminent)
                    }

                    HStack {
                        Toggle("Auto-generate suggestions", isOn: $suggestionEngine.autoTriggerEnabled)
                        Spacer()
                    }

                    if suggestionEngine.isProcessing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Generating suggestions...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding()
            }

            // Suggestion Preferences
            GroupBox(label: Label("Suggestion Preferences", systemImage: "slider.horizontal.3")) {
                VStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Minimum text length:")
                            Spacer()
                            Text("\(suggestionEngine.minimumTextLength) characters")
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(suggestionEngine.minimumTextLength) },
                                set: { suggestionEngine.minimumTextLength = Int($0) }
                            ),
                            in: 5...100,
                            step: 5
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Suggestion delay:")
                            Spacer()
                            Text("\(String(format: "%.1f", suggestionEngine.suggestionDelay))s")
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: $suggestionEngine.suggestionDelay,
                            in: 0.5...10.0,
                            step: 0.5
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Max suggestions:")
                            Spacer()
                            Text("\(suggestionEngine.maxSuggestions)")
                                .foregroundColor(.secondary)
                        }

                        Slider(
                            value: Binding(
                                get: { Double(suggestionEngine.maxSuggestions) },
                                set: { suggestionEngine.maxSuggestions = Int($0) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                    }
                }
                .padding()
            }

            // Statistics
            GroupBox(label: Label("Statistics", systemImage: "chart.bar")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Suggestions Generated:")
                        Spacer()
                        Text("\(suggestionEngine.totalSuggestionsGenerated)")
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Suggestions Applied:")
                        Spacer()
                        Text("\(suggestionEngine.totalSuggestionsApplied)")
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Average Processing Time:")
                        Spacer()
                        Text("\(String(format: "%.2f", suggestionEngine.averageProcessingTime))s")
                            .foregroundColor(.orange)
                    }

                    if suggestionEngine.totalSuggestionsGenerated > 0 {
                        HStack {
                            Text("Success Rate:")
                            Spacer()
                            Text("\(String(format: "%.1f", Double(suggestionEngine.totalSuggestionsApplied) / Double(suggestionEngine.totalSuggestionsGenerated) * 100))%")
                                .foregroundColor(.purple)
                        }
                    }
                }
                .font(.caption)
                .padding()
            }

            // Quick Actions
            HStack(spacing: 15) {
                Button("Generate Now") {
                    suggestionEngine.generateSuggestionsManually()
                }
                .disabled(!suggestionEngine.isEnabled)
                .buttonStyle(.bordered)

                Button("Clear Suggestions") {
                    suggestionEngine.clearCurrentSuggestions()
                }
                .buttonStyle(.bordered)

                Menu("Quick Rewrite") {
                    ForEach(AIRewriteStyle.allCases, id: \.self) { style in
                        Button(style.rawValue) {
                            quickRewrite(style: style)
                        }
                    }
                }
                .disabled(!suggestionEngine.isEnabled)
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 700)
        .alert("API Key Saved", isPresented: $showingAPIKeyAlert) {
            Button("OK") { }
        } message: {
            Text("Your OpenAI API key has been saved securely.")
        }
        .alert("Connection Test", isPresented: $showingTestResults) {
            Button("OK") { }
        } message: {
            Text(testResultMessage)
        }
        .onAppear {
            loadSavedAPIKey()
        }
    }

    // MARK: - Private Methods

    private func saveAPIKey() {
        // Update the AI service with the new API key
        aiService.updateAPIKey(apiKey)
        suggestionEngine.updateAPIKey(apiKey)
        showingAPIKeyAlert = true
        print("💾 API key saved and services updated")
    }

    private func loadSavedAPIKey() {
        // In a real implementation, you'd load this from Keychain
        // For demo purposes, we'll leave it empty
        apiKey = ""
    }

    private func toggleEngine() {
        if suggestionEngine.isEnabled {
            suggestionEngine.stopEngine()
        } else {
            suggestionEngine.startEngine()
        }
    }

    private func testConnection() {
        isTestingConnection = true

        Task {
            // Test using the current aiService instance
            do {
                _ = try await aiService.improveGrammar(for: "This is a test.")

                DispatchQueue.main.async {
                    self.testResultMessage = "✅ Connection successful! API key is working."
                    self.isTestingConnection = false
                    self.showingTestResults = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.testResultMessage = "❌ Connection failed: \(error.localizedDescription)"
                    self.isTestingConnection = false
                    self.showingTestResults = true
                }
            }
        }
    }

    private func quickRewrite(style: AIRewriteStyle) {
        Task {
            if let rewritten = await suggestionEngine.rewriteCurrentText(style: style) {
                print("✅ Quick rewrite (\(style.rawValue)): \(rewritten)")
                // The rewritten text would be applied automatically through the text field integration
            }
        }
    }
}

#Preview {
    // Create mock objects for preview
    let mockService = OpenAIService(apiKey: "test")
    let mockIntegration = TextFieldIntegration(
        keyboardMonitor: KeyboardMonitor(),
        textFieldReader: TextFieldReader()
    )
    let mockEngine = AISuggestionEngine(
        aiService: mockService,
        textFieldIntegration: mockIntegration
    )

    return AISettingsView(suggestionEngine: mockEngine, aiService: mockService)
}

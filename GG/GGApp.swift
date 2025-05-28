//
//  GGApp.swift
//  GG
//
//  Created by gole on 28.5.25..
//

import SwiftUI

@main
struct GGApp: App {
    @StateObject private var keyboardMonitor = KeyboardMonitor()
    @StateObject private var textFieldReader = TextFieldReader()
    @StateObject private var textFieldIntegration: TextFieldIntegration
    @StateObject private var aiService: OpenAIService
    @StateObject private var aiSuggestionEngine: AISuggestionEngine
    @State private var isMonitoring = false

    init() {
        let keyboardMonitor = KeyboardMonitor()
        let textFieldReader = TextFieldReader()
        let textFieldIntegration = TextFieldIntegration(keyboardMonitor: keyboardMonitor, textFieldReader: textFieldReader)
        let aiService = OpenAIService(apiKey: "")
        let aiSuggestionEngine = AISuggestionEngine(aiService: aiService, textFieldIntegration: textFieldIntegration)

        self._keyboardMonitor = StateObject(wrappedValue: keyboardMonitor)
        self._textFieldReader = StateObject(wrappedValue: textFieldReader)
        self._textFieldIntegration = StateObject(wrappedValue: textFieldIntegration)
        self._aiService = StateObject(wrappedValue: aiService)
        self._aiSuggestionEngine = StateObject(wrappedValue: aiSuggestionEngine)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                keyboardMonitor: keyboardMonitor,
                textFieldReader: textFieldReader,
                aiSuggestionEngine: aiSuggestionEngine,
                aiService: aiService
            )
                .onAppear {
                    setupMonitoring()
                }
                .onDisappear {
                    stopMonitoring()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        // AI Settings window - can be opened directly
        WindowGroup("AI Settings") {
            AISettingsView(suggestionEngine: aiSuggestionEngine, aiService: aiService)
        }
        .windowToolbarStyle(.unified)

        // Demo window - can be opened directly
        WindowGroup("Text Field Demo") {
            TextFieldDemo()
        }
        .windowToolbarStyle(.unified)
    }

    private func setupMonitoring() {
        // Set up keyboard monitor
        keyboardMonitor.delegate = AppDelegate.shared
        keyboardMonitor.startMonitoring()

        // Set up text field reader
        textFieldReader.delegate = AppDelegate.shared
        textFieldReader.startMonitoring()

        // Set up AI suggestion engine
        aiSuggestionEngine.delegate = AppDelegate.shared

        // Initialize AppDelegate with references
        AppDelegate.shared.setupReferences(
            keyboardMonitor: keyboardMonitor,
            textFieldReader: textFieldReader,
            aiSuggestionEngine: aiSuggestionEngine
        )
    }

    private func stopMonitoring() {
        keyboardMonitor.stopMonitoring()
        textFieldReader.stopMonitoring()
        aiSuggestionEngine.stopEngine()
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, ObservableObject, KeyboardMonitorDelegate, TextFieldReaderDelegate, AISuggestionEngineDelegate {
    static let shared = AppDelegate()

    // References to main components
    private var keyboardMonitor: KeyboardMonitor?
    private var textFieldReader: TextFieldReader?
    private var aiSuggestionEngine: AISuggestionEngine?

    func setupReferences(keyboardMonitor: KeyboardMonitor, textFieldReader: TextFieldReader, aiSuggestionEngine: AISuggestionEngine) {
        self.keyboardMonitor = keyboardMonitor
        self.textFieldReader = textFieldReader
        self.aiSuggestionEngine = aiSuggestionEngine
    }

    // MARK: - KeyboardMonitorDelegate

    func keyboardMonitor(_ monitor: KeyboardMonitor, didTriggerSuggestion text: String) {
        print("📝 App received suggestion trigger: '\(text)'")

        // Post notification for other components
        NotificationCenter.default.post(
            name: .suggestionTriggered,
            object: nil,
            userInfo: ["text": text]
        )
    }

    // MARK: - TextFieldReaderDelegate

    func textFieldReader(_ reader: TextFieldReader, didDetectTextChange text: String, in element: AXUIElement) {
        print("📝 Text field content changed: '\(text)' in app: \(reader.focusedAppName)")

        // Post notification for text field changes
        NotificationCenter.default.post(
            name: .textFieldContentChanged,
            object: nil,
            userInfo: [
                "text": text,
                "appName": reader.focusedAppName,
                "element": element
            ]
        )
    }

    func textFieldReader(_ reader: TextFieldReader, didLoseFocus previousText: String) {
        print("📝 Text field lost focus. Previous text: '\(previousText)'")

        // Post notification for focus loss
        NotificationCenter.default.post(
            name: .textFieldLostFocus,
            object: nil,
            userInfo: ["previousText": previousText]
        )
    }

    // MARK: - AISuggestionEngineDelegate

    func suggestionEngine(_ engine: AISuggestionEngine, didGenerateSuggestions suggestions: [AISuggestion]) {
        print("🤖 AI generated \(suggestions.count) suggestions")

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .aiSuggestionsGenerated,
            object: nil,
            userInfo: ["suggestions": suggestions]
        )
    }

    func suggestionEngine(_ engine: AISuggestionEngine, didFailWithError error: AIServiceError) {
        print("❌ AI suggestion failed: \(error.localizedDescription)")

        // Post notification for error handling
        NotificationCenter.default.post(
            name: .aiSuggestionError,
            object: nil,
            userInfo: ["error": error]
        )
    }

    func suggestionEngine(_ engine: AISuggestionEngine, didApplySuggestion suggestion: AISuggestion, success: Bool) {
        print(success ? "✅ Applied AI suggestion" : "❌ Failed to apply AI suggestion")

        // Post notification for suggestion application
        NotificationCenter.default.post(
            name: .aiSuggestionApplied,
            object: nil,
            userInfo: [
                "suggestion": suggestion,
                "success": success
            ]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let suggestionTriggered = Notification.Name("suggestionTriggered")
    static let textFieldContentChanged = Notification.Name("textFieldContentChanged")
    static let textFieldLostFocus = Notification.Name("textFieldLostFocus")
    static let aiSuggestionsGenerated = Notification.Name("aiSuggestionsGenerated")
    static let aiSuggestionApplied = Notification.Name("aiSuggestionApplied")
    static let aiSuggestionError = Notification.Name("aiSuggestionError")
}

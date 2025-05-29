//
//  GGApp.swift
//  GG
//
//  Created by gole on 28.5.25..
//

import SwiftUI

// MARK: - Settings Manager

class SettingsManager: ObservableObject {
    @Published var apiKey: String {
        didSet {
            if !apiKey.isEmpty {
                _ = KeychainHelper.save(apiKey: apiKey)
            }
        }
    }

    @Published var autoTriggerEnabled: Bool {
        didSet { UserDefaults.standard.set(autoTriggerEnabled, forKey: "autoTriggerEnabled") }
    }

    @Published var minimumTextLength: Int {
        didSet { UserDefaults.standard.set(minimumTextLength, forKey: "minimumTextLength") }
    }

    @Published var suggestionDelay: Double {
        didSet { UserDefaults.standard.set(suggestionDelay, forKey: "suggestionDelay") }
    }

    @Published var maxSuggestions: Int {
        didSet { UserDefaults.standard.set(maxSuggestions, forKey: "maxSuggestions") }
    }

    init() {
        self.apiKey = KeychainHelper.load() ?? ""
        self.autoTriggerEnabled = UserDefaults.standard.object(forKey: "autoTriggerEnabled") as? Bool ?? true
        self.minimumTextLength = UserDefaults.standard.object(forKey: "minimumTextLength") as? Int ?? 15
        self.suggestionDelay = UserDefaults.standard.object(forKey: "suggestionDelay") as? Double ?? 2.0
        self.maxSuggestions = UserDefaults.standard.object(forKey: "maxSuggestions") as? Int ?? 5
    }
}

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
    public var aiSuggestionEngine: AISuggestionEngine?

    // Module 4: Suggestion UI Overlay
    private var suggestionOverlay: SuggestionOverlayWindow?
    private var overlayAutoHideTimer: Timer?

    // Public accessors for status checking
    public var isKeyboardMonitoring: Bool {
        return keyboardMonitor?.isMonitoring ?? false
    }

    public var isTextFieldReading: Bool {
        return textFieldReader?.isActive ?? false
    }

    public var isAIEngineRunning: Bool {
        return aiSuggestionEngine?.isEnabled ?? false
    }

    override init() {
        super.init()
        setupSuggestionOverlay()
        setupOverlayNotifications()
    }

    func setupReferences(keyboardMonitor: KeyboardMonitor, textFieldReader: TextFieldReader, aiSuggestionEngine: AISuggestionEngine) {
        self.keyboardMonitor = keyboardMonitor
        self.textFieldReader = textFieldReader
        self.aiSuggestionEngine = aiSuggestionEngine
    }

    // MARK: - Module 4: Suggestion Overlay Management

    private func setupSuggestionOverlay() {
        suggestionOverlay = SuggestionOverlayWindow()
        print("✅ Module 4: Suggestion overlay window created")
    }

    private func setupOverlayNotifications() {
        // Listen for hide overlay notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hideSuggestionOverlay),
            name: .hideSuggestionOverlay,
            object: nil
        )

        // Listen for apply suggestion notifications from overlay
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applySuggestionFromOverlay(_:)),
            name: .applySuggestionFromOverlay,
            object: nil
        )
    }

    @objc private func hideSuggestionOverlay() {
        suggestionOverlay?.hideOverlay()
        cancelAutoHideTimer()
        print("🔽 Module 4: Suggestion overlay hidden")
    }

    @objc private func applySuggestionFromOverlay(_ notification: Notification) {
        guard let suggestion = notification.userInfo?["suggestion"] as? AISuggestion else { return }

        // Apply the suggestion through the AI engine
        aiSuggestionEngine?.applySuggestion(suggestion)
        print("✅ Module 4: Applied suggestion from overlay: \(suggestion.type.rawValue)")
    }

    private func showSuggestionOverlay(with suggestions: [AISuggestion]) {
        guard !suggestions.isEmpty else { return }

        // Get current cursor position
        let cursorPosition = getCursorPosition()

        // Show overlay near cursor
        suggestionOverlay?.showNear(cursor: cursorPosition, with: suggestions)

        // Set up auto-hide timer (hide after 10 seconds of inactivity)
        setupAutoHideTimer()

        print("🔼 Module 4: Suggestion overlay shown with \(suggestions.count) suggestions")
    }

    private func getCursorPosition() -> NSPoint {
        // Try to get the actual text field position for more accurate positioning
        if let textFieldReader = textFieldReader,
           let elementInfo = textFieldReader.getFocusedElementInfo(),
           let positionValue = elementInfo["position"] as? NSValue {

            let elementPosition = positionValue.pointValue

            // For text fields, position the overlay near the top-right of the field
            // This gives a better user experience than using mouse position
            return NSPoint(x: elementPosition.x + 100, y: elementPosition.y + 20)
        }

        // Fallback to mouse location if we can't get text field position
        let mouseLocation = NSEvent.mouseLocation

        // In a real implementation, you might want to get the actual text cursor position
        // For now, we'll use mouse location as a reasonable approximation
        return mouseLocation
    }

    private func setupAutoHideTimer() {
        cancelAutoHideTimer()
        overlayAutoHideTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            self?.hideSuggestionOverlay()
        }
    }

    private func cancelAutoHideTimer() {
        overlayAutoHideTimer?.invalidate()
        overlayAutoHideTimer = nil
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

        // Hide overlay when text field loses focus
        hideSuggestionOverlay()

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

        // Module 4: Show suggestion overlay with generated suggestions
        showSuggestionOverlay(with: suggestions)

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .aiSuggestionsGenerated,
            object: nil,
            userInfo: ["suggestions": suggestions]
        )
    }

    func suggestionEngine(_ engine: AISuggestionEngine, didFailWithError error: AIServiceError) {
        print("❌ AI suggestion failed: \(error.localizedDescription)")

        // Hide overlay on error
        hideSuggestionOverlay()

        // Post notification for error handling
        NotificationCenter.default.post(
            name: .aiSuggestionError,
            object: nil,
            userInfo: ["error": error]
        )
    }

    func suggestionEngine(_ engine: AISuggestionEngine, didApplySuggestion suggestion: AISuggestion, success: Bool) {
        print(success ? "✅ Applied AI suggestion" : "❌ Failed to apply AI suggestion")

        // Hide overlay after applying suggestion
        if success {
            hideSuggestionOverlay()
        }

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

    // MARK: - Cleanup

    deinit {
        NotificationCenter.default.removeObserver(self)
        cancelAutoHideTimer()
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

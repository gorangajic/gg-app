//
//  TextFieldIntegration.swift
//  GG
//
//  Created by TypeWise AI
//  Module 2 Integration: Connects keyboard monitoring with text field reading
//

import Foundation
import ApplicationServices

// MARK: - Text Field Integration Class

class TextFieldIntegration: ObservableObject {

    // MARK: - Published Properties
    @Published var combinedText: String = ""
    @Published var analysisContext: TextAnalysisContext?

    // MARK: - Dependencies
    private let keyboardMonitor: KeyboardMonitor
    private let textFieldReader: TextFieldReader

    // MARK: - Private Properties
    private var lastKeyboardText: String = ""
    private var lastTextFieldText: String = ""

    // MARK: - Initialization

    init(keyboardMonitor: KeyboardMonitor, textFieldReader: TextFieldReader) {
        self.keyboardMonitor = keyboardMonitor
        self.textFieldReader = textFieldReader

        setupObservers()
    }

    // MARK: - Public Methods

    /// Get the most comprehensive text for AI analysis
    func getTextForAIAnalysis() -> String {
        // Prefer text field content as it's more complete and accurate
        if !textFieldReader.currentText.isEmpty {
            return textFieldReader.currentText
        }

        // Fall back to keyboard buffer
        return keyboardMonitor.currentText
    }

    /// Get context information for better AI suggestions
    func getAnalysisContext() -> TextAnalysisContext {
        let context = TextAnalysisContext(
            source: !textFieldReader.currentText.isEmpty ? .textField : .keyboard,
            appName: textFieldReader.focusedAppName,
            textFieldInfo: textFieldReader.getFocusedElementInfo(),
            keyboardBuffer: keyboardMonitor.currentText,
            textFieldContent: textFieldReader.currentText,
            combinedLength: getTextForAIAnalysis().count
        )

        DispatchQueue.main.async {
            self.analysisContext = context
        }

        return context
    }

    /// Insert AI-generated text into the current text field
    func insertAISuggestion(_ suggestion: String, replaceExisting: Bool = false) -> Bool {
        if replaceExisting {
            return textFieldReader.replaceCurrentText(with: suggestion)
        } else {
            return textFieldReader.insertText(suggestion)
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Monitor keyboard text changes
        NotificationCenter.default.addObserver(
            forName: .suggestionTriggered,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let text = notification.userInfo?["text"] as? String {
                self?.lastKeyboardText = text
                self?.updateCombinedText()
            }
        }

        // Monitor text field changes
        NotificationCenter.default.addObserver(
            forName: .textFieldContentChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let text = notification.userInfo?["text"] as? String {
                self?.lastTextFieldText = text
                self?.updateCombinedText()
            }
        }
    }

    private func updateCombinedText() {
        let newCombinedText = getTextForAIAnalysis()

        if combinedText != newCombinedText {
            combinedText = newCombinedText

            // Update analysis context
            _ = getAnalysisContext()

            // Post notification for AI analysis
            NotificationCenter.default.post(
                name: .textAnalysisReady,
                object: nil,
                userInfo: [
                    "text": newCombinedText,
                    "context": analysisContext as Any
                ]
            )
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Text Analysis Context

struct TextAnalysisContext {
    enum TextSource {
        case keyboard
        case textField
        case combined
    }

    let source: TextSource
    let appName: String
    let textFieldInfo: [String: Any]?
    let keyboardBuffer: String
    let textFieldContent: String
    let combinedLength: Int
    let timestamp: Date = Date()

    /// Determine if this text is suitable for AI analysis
    var isReadyForAnalysis: Bool {
        let text = source == .textField ? textFieldContent : keyboardBuffer
        return text.count > 10 && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Get contextual information for AI prompt
    var contextualInfo: String {
        var info = ["App: \(appName)"]

        if let fieldInfo = textFieldInfo {
            if let role = fieldInfo["role"] as? String {
                info.append("Field Type: \(role)")
            }
            if let title = fieldInfo["title"] as? String, !title.isEmpty {
                info.append("Field Title: \(title)")
            }
        }

        info.append("Text Length: \(combinedLength) characters")

        return info.joined(separator: ", ")
    }
}

// MARK: - Additional Notification Names

extension Notification.Name {
    static let textAnalysisReady = Notification.Name("textAnalysisReady")
}

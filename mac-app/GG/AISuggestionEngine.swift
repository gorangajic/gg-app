//
//  AISuggestionEngine.swift
//  GG
//
//  Created by TypeWise AI
//  Module 3: AI Suggestion Engine - Main Coordinator
//

import Foundation
import Combine
import SwiftUI

// MARK: - AI Suggestion Engine Delegate

protocol AISuggestionEngineDelegate: AnyObject {
    func suggestionEngine(_ engine: AISuggestionEngine, didGenerateSuggestions suggestions: [AISuggestion])
    func suggestionEngine(_ engine: AISuggestionEngine, didFailWithError error: AIServiceError)
    func suggestionEngine(_ engine: AISuggestionEngine, didApplySuggestion suggestion: AISuggestion, success: Bool)
}

// MARK: - AI Suggestion Engine

class AISuggestionEngine: ObservableObject {

    // MARK: - Published Properties
    @Published var isEnabled = false
    @Published var currentSuggestions: [AISuggestion] = []
    @Published var isProcessing = false
    @Published var lastProcessedText = ""
    @Published var apiKeyConfigured = false

    // MARK: - Configuration
    @Published var autoTriggerEnabled = true
    @Published var minimumTextLength = 15
    @Published var suggestionDelay: TimeInterval = 2.0
    @Published var maxSuggestions = 5

    // MARK: - Statistics
    @Published var totalSuggestionsGenerated = 0
    @Published var totalSuggestionsApplied = 0
    @Published var averageProcessingTime: TimeInterval = 0

    // MARK: - Private Properties
    private let aiService: AIServiceProtocol
    private let textFieldIntegration: TextFieldIntegration
    private var cancellables = Set<AnyCancellable>()
    private var suggestionTimer: Timer?

    // Delegate
    weak var delegate: AISuggestionEngineDelegate?

    // MARK: - Initialization

    init(aiService: AIServiceProtocol, textFieldIntegration: TextFieldIntegration) {
        self.aiService = aiService
        self.textFieldIntegration = textFieldIntegration

        setupObservers()
        checkAPIKeyConfiguration()
        setupAuthenticationObserver()
    }

    private func setupAuthenticationObserver() {
        // Listen for authentication changes to update apiKeyConfigured status
        NotificationCenter.default.addObserver(
            forName: .authenticationStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAPIKeyConfiguration()
        }
    }

    // MARK: - Public Methods

    func startEngine() {
        guard apiKeyConfigured else {
            print("❌ AISuggestionEngine: Cannot start - API key not configured")
            return
        }

        isEnabled = true
        print("✅ AISuggestionEngine: Engine started")
    }

    func stopEngine() {
        isEnabled = false
        suggestionTimer?.invalidate()
        suggestionTimer = nil
        clearCurrentSuggestions()
        print("⏹️ AISuggestionEngine: Engine stopped")
    }

    func generateSuggestionsManually() {
        guard isEnabled else { return }

        let text = textFieldIntegration.getTextForAIAnalysis()
        guard !text.isEmpty && text.count >= minimumTextLength else {
            print("⚠️ Text too short for suggestions: \(text.count) characters")
            return
        }

        Task {
            await generateSuggestions(for: text)
        }
    }

    func generateSuggestionsManually(for text: String) async {
        guard isEnabled else { return }
        guard !text.isEmpty && text.count >= minimumTextLength else {
            print("⚠️ Text too short for suggestions: \(text.count) characters")
            return
        }

        await generateSuggestions(for: text)
    }

    func applySuggestion(_ suggestion: AISuggestion) {
        let success = textFieldIntegration.insertAISuggestion(suggestion.suggestedText, replaceExisting: true)

        if success {
            DispatchQueue.main.async {
                self.totalSuggestionsApplied += 1
                self.clearCurrentSuggestions()
            }
            print("✅ Applied suggestion: \(suggestion.type.rawValue)")
        } else {
            print("❌ Failed to apply suggestion")
        }

        delegate?.suggestionEngine(self, didApplySuggestion: suggestion, success: success)
    }

    func dismissSuggestion(_ suggestion: AISuggestion) {
        DispatchQueue.main.async {
            self.currentSuggestions.removeAll { $0.id == suggestion.id }
        }
    }

    func clearCurrentSuggestions() {
        DispatchQueue.main.async {
            self.currentSuggestions.removeAll()
        }
    }

    func updateAPIKey(_ apiKey: String) {
        // This would require recreating the AI service - for now just update the flag
        DispatchQueue.main.async {
            self.apiKeyConfigured = !apiKey.isEmpty
        }
    }

    func setAutoTriggerEnabled(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.autoTriggerEnabled = enabled
        }
        print("🔧 Auto-trigger \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Listen for text analysis ready notifications
        NotificationCenter.default.publisher(for: .textAnalysisReady)
            .compactMap { $0.userInfo?["text"] as? String }
            .debounce(for: .seconds(suggestionDelay), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.handleTextChange(text)
            }
            .store(in: &cancellables)

        // Listen for suggestion triggers from keyboard monitor
        NotificationCenter.default.publisher(for: .suggestionTriggered)
            .compactMap { $0.userInfo?["text"] as? String }
            .debounce(for: .seconds(suggestionDelay), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.handleTextChange(text)
            }
            .store(in: &cancellables)

        // Listen for text field changes
        NotificationCenter.default.publisher(for: .textFieldContentChanged)
            .compactMap { $0.userInfo?["text"] as? String }
            .debounce(for: .seconds(suggestionDelay), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.handleTextChange(text)
            }
            .store(in: &cancellables)
    }

    private func handleTextChange(_ text: String) {
        guard isEnabled && autoTriggerEnabled else { return }
        guard text.count >= minimumTextLength else { return }
        guard text != lastProcessedText else { return }

        // Smart triggering conditions
        let shouldTrigger = evaluateTextForSuggestion(text)
        guard shouldTrigger else { return }

        // Cancel any existing timer
        suggestionTimer?.invalidate()

        // Start new timer for delayed processing
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: suggestionDelay, repeats: false) { [weak self] _ in
            Task {
                await self?.generateSuggestions(for: text)
            }
        }
    }

    private func evaluateTextForSuggestion(_ text: String) -> Bool {
        // Don't process very short text
        if text.count < minimumTextLength { return false }

        // Don't process very long text (limit AI costs)
        if text.count > 1000 { return false }

        // Check if text ends with sentence-ending punctuation
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let sentenceEnders: Set<Character> = [".", "!", "?"]
        let endsWithPunctuation = sentenceEnders.contains(trimmed.last ?? " ")

        // Check if text contains complete words (not just typing)
        let wordCount = text.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.count
        let hasEnoughWords = wordCount >= 3

        // Check for natural pause patterns
        let hasNaturalBreak = text.contains(". ") || text.contains("? ") || text.contains("! ") ||
                             text.contains("\n") || endsWithPunctuation

        // Trigger if we have enough content and a natural break point
        return hasEnoughWords && hasNaturalBreak
    }

    private func generateSuggestions(for text: String) async {
        guard !text.isEmpty else { return }

        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastProcessedText = text
        }

        do {
            let context = buildAIContext(for: text)
            let response = try await aiService.generateSuggestions(for: text, context: context)

            DispatchQueue.main.async {
                self.isProcessing = false
                self.currentSuggestions = Array(response.suggestions.prefix(self.maxSuggestions))
                self.totalSuggestionsGenerated += response.suggestions.count
                self.updateAverageProcessingTime(response.processingTime)
            }

            delegate?.suggestionEngine(self, didGenerateSuggestions: response.suggestions)

            // Post notification for UI updates
            NotificationCenter.default.post(
                name: .aiSuggestionsGenerated,
                object: nil,
                userInfo: [
                    "suggestions": response.suggestions,
                    "originalText": text,
                    "confidence": response.confidence
                ]
            )

            print("✅ Generated \(response.suggestions.count) suggestions with \(String(format: "%.1f", response.confidence * 100))% confidence")

        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
            }

            let serviceError = error as? AIServiceError ?? AIServiceError.networkError(error)
            delegate?.suggestionEngine(self, didFailWithError: serviceError)

            print("❌ Failed to generate suggestions: \(serviceError.localizedDescription)")
        }
    }

    private func buildAIContext(for text: String) -> LocalAIContext {
        let analysisContext = textFieldIntegration.getAnalysisContext()

        return LocalAIContext(
            appName: analysisContext.appName,
            fieldType: analysisContext.textFieldInfo?["role"] as? String,
            textLength: text.count
        )
    }

    private func checkAPIKeyConfiguration() {
        // Check if the AI service is authenticated (for ServerAIService)
        // or if API key is configured (for OpenAIService)
        if let serverService = aiService as? ServerAIService {
            apiKeyConfigured = serverService.isAuthenticated
        } else if let openAIService = aiService as? OpenAIService {
            apiKeyConfigured = openAIService.isAPIKeyConfigured
        } else {
            apiKeyConfigured = false
        }
    }

    private func updateAverageProcessingTime(_ newTime: TimeInterval) {
        let alpha = 0.3 // Exponential moving average factor
        averageProcessingTime = alpha * newTime + (1 - alpha) * averageProcessingTime
    }

    deinit {
        suggestionTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - AI Suggestion Engine Extensions

extension AISuggestionEngine {

    /// Get quick grammar improvement for current text
    func improveGrammarQuickly() async -> String? {
        let text = textFieldIntegration.getTextForAIAnalysis()
        guard !text.isEmpty else { return nil }

        do {
            let response = try await aiService.improveGrammar(for: text)
            return response.improvedText
        } catch {
            print("❌ Failed to improve grammar: \(error.localizedDescription)")
            return nil
        }
    }

    /// Rewrite current text in specified style
    func rewriteCurrentText(style: AIRewriteStyle) async -> String? {
        let text = textFieldIntegration.getTextForAIAnalysis()
        guard !text.isEmpty else { return nil }

        do {
            let response = try await aiService.rewriteText(text, style: style)
            return response.rewrittenText
        } catch {
            print("❌ Failed to rewrite text: \(error.localizedDescription)")
            return nil
        }
    }

    /// Get statistics summary
    var statisticsSummary: String {
        return """
        Suggestions Generated: \(totalSuggestionsGenerated)
        Suggestions Applied: \(totalSuggestionsApplied)
        Average Processing Time: \(String(format: "%.2f", averageProcessingTime))s
        Success Rate: \(totalSuggestionsGenerated > 0 ? String(format: "%.1f", Double(totalSuggestionsApplied) / Double(totalSuggestionsGenerated) * 100) : "0")%
        """
    }
}

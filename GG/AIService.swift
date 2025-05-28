//
//  AIService.swift
//  GG
//
//  Created by TypeWise AI
//  Module 3: AI Suggestion Engine - Core Service
//

import Foundation
import Combine

// MARK: - AI Service Protocol

protocol AIServiceProtocol {
    func generateSuggestions(for text: String, context: AIContext) async throws -> AISuggestionResponse
    func improveGrammar(for text: String) async throws -> AIImprovementResponse
    func rewriteText(_ text: String, style: AIRewriteStyle) async throws -> AIRewriteResponse
}

// MARK: - AI Context

struct AIContext {
    let appName: String
    let fieldType: String?
    let textLength: Int
    let language: String = "en"

    var contextPrompt: String {
        var prompt = "Context: Writing in \(appName)"
        if let fieldType = fieldType {
            prompt += " (\(fieldType))"
        }
        prompt += ". Text length: \(textLength) characters."
        return prompt
    }
}

// MARK: - AI Response Models

struct AISuggestionResponse {
    let original: String
    let suggestions: [AISuggestion]
    let confidence: Double
    let processingTime: TimeInterval
}

struct AISuggestion {
    let id: UUID = UUID()
    let type: SuggestionType
    let originalText: String
    let suggestedText: String
    let reason: String
    let confidence: Double
    let range: NSRange?
}

enum SuggestionType: String, CaseIterable {
    case grammar = "Grammar"
    case style = "Style"
    case clarity = "Clarity"
    case tone = "Tone"
    case spelling = "Spelling"
    case conciseness = "Conciseness"
}

struct AIImprovementResponse {
    let improvedText: String
    let changes: [TextChange]
    let overallImprovement: String
}

struct AIRewriteResponse {
    let rewrittenText: String
    let style: AIRewriteStyle
    let changesSummary: String
}

struct TextChange {
    let range: NSRange
    let original: String
    let replacement: String
    let type: SuggestionType
}

enum AIRewriteStyle: String, CaseIterable {
    case professional = "Professional"
    case casual = "Casual"
    case concise = "Concise"
    case friendly = "Friendly"
    case formal = "Formal"
    case creative = "Creative"
}

// MARK: - OpenAI Service Implementation

class OpenAIService: AIServiceProtocol, ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastError: AIServiceError?
    @Published var requestCount = 0
    @Published var totalTokensUsed = 0
    @Published var isAPIKeyConfigured = false

    // MARK: - Private Properties
    private var apiKey: String {
        didSet {
            isAPIKeyConfigured = !apiKey.isEmpty
        }
    }
    private let baseURL = "https://api.openai.com/v1"
    private let session = URLSession.shared
    private let model = "gpt-3.5-turbo"
    private let maxTokens = 500

    // MARK: - Initialization

    init(apiKey: String) {
        self.apiKey = apiKey
        self.isAPIKeyConfigured = !apiKey.isEmpty
    }

    // MARK: - Public Methods

    func updateAPIKey(_ newAPIKey: String) {
        DispatchQueue.main.async {
            self.apiKey = newAPIKey
        }
        print("🔑 OpenAIService: API key updated")
    }

    func generateSuggestions(for text: String, context: AIContext) async throws -> AISuggestionResponse {
        let startTime = Date()

        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastError = nil
        }

        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }

        let prompt = buildSuggestionPrompt(text: text, context: context)
        let response = try await makeOpenAIRequest(prompt: prompt)

        let suggestions = try parseSuggestionsResponse(response, originalText: text)
        let processingTime = Date().timeIntervalSince(startTime)

        DispatchQueue.main.async {
            self.requestCount += 1
        }

        return AISuggestionResponse(
            original: text,
            suggestions: suggestions,
            confidence: calculateOverallConfidence(suggestions),
            processingTime: processingTime
        )
    }

    func improveGrammar(for text: String) async throws -> AIImprovementResponse {
        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastError = nil
        }

        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }

        let prompt = """
        Please improve the grammar and clarity of the following text.
        Return only the improved text without explanations:

        "\(text)"
        """

        let response = try await makeOpenAIRequest(prompt: prompt)
        let improvedText = response.trimmingCharacters(in: .whitespacesAndNewlines)

        return AIImprovementResponse(
            improvedText: improvedText,
            changes: [], // We could implement change detection here
            overallImprovement: "Grammar and clarity improved"
        )
    }

    func rewriteText(_ text: String, style: AIRewriteStyle) async throws -> AIRewriteResponse {
        DispatchQueue.main.async {
            self.isProcessing = true
            self.lastError = nil
        }

        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }

        let prompt = """
        Please rewrite the following text in a \(style.rawValue.lowercased()) style.
        Return only the rewritten text without explanations:

        "\(text)"
        """

        let response = try await makeOpenAIRequest(prompt: prompt)
        let rewrittenText = response.trimmingCharacters(in: .whitespacesAndNewlines)

        return AIRewriteResponse(
            rewrittenText: rewrittenText,
            style: style,
            changesSummary: "Text rewritten in \(style.rawValue.lowercased()) style"
        )
    }

    // MARK: - Private Methods

    private func buildSuggestionPrompt(text: String, context: AIContext) -> String {
        return """
        You are a writing assistant. Analyze the following text and provide specific suggestions for improvement.
        \(context.contextPrompt)

        Text to analyze: "\(text)"

        Please provide suggestions in the following JSON format:
        {
            "suggestions": [
                {
                    "type": "grammar|style|clarity|tone|spelling|conciseness",
                    "original": "original text",
                    "suggested": "suggested improvement",
                    "reason": "explanation for the suggestion",
                    "confidence": 0.85
                }
            ]
        }

        Focus on the most important 3-5 improvements. Be specific and actionable.
        """
    }

    private func makeOpenAIRequest(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "max_tokens": maxTokens,
            "temperature": 0.3
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIServiceError.apiError(httpResponse.statusCode, errorMessage)
            }

            let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let choices = jsonResponse?["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw AIServiceError.invalidResponse
            }

            // Update token usage if available
            if let usage = jsonResponse?["usage"] as? [String: Any],
               let totalTokens = usage["total_tokens"] as? Int {
                DispatchQueue.main.async {
                    self.totalTokensUsed += totalTokens
                }
            }

            return content

        } catch {
            let serviceError = error as? AIServiceError ?? AIServiceError.networkError(error)
            DispatchQueue.main.async {
                self.lastError = serviceError
            }
            throw serviceError
        }
    }

    private func parseSuggestionsResponse(_ response: String, originalText: String) throws -> [AISuggestion] {
        // Try to extract JSON from the response
        guard let jsonData = response.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let suggestionsArray = jsonObject["suggestions"] as? [[String: Any]] else {
            // Fallback: create a simple improvement suggestion
            return [AISuggestion(
                type: .style,
                originalText: originalText,
                suggestedText: response,
                reason: "AI-generated improvement",
                confidence: 0.8,
                range: nil
            )]
        }

        return suggestionsArray.compactMap { dict in
            guard let typeString = dict["type"] as? String,
                  let type = SuggestionType(rawValue: typeString.capitalized),
                  let original = dict["original"] as? String,
                  let suggested = dict["suggested"] as? String,
                  let reason = dict["reason"] as? String,
                  let confidence = dict["confidence"] as? Double else {
                return nil
            }

            return AISuggestion(
                type: type,
                originalText: original,
                suggestedText: suggested,
                reason: reason,
                confidence: confidence,
                range: nil
            )
        }
    }

    private func calculateOverallConfidence(_ suggestions: [AISuggestion]) -> Double {
        guard !suggestions.isEmpty else { return 0.0 }
        return suggestions.map { $0.confidence }.reduce(0, +) / Double(suggestions.count)
    }
}

// MARK: - AI Service Error

enum AIServiceError: LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case apiError(Int, String)
    case invalidResponse
    case rateLimitExceeded
    case quotaExceeded

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenAI API key."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .invalidResponse:
            return "Invalid response from AI service."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait before making more requests."
        case .quotaExceeded:
            return "API quota exceeded. Please check your OpenAI usage."
        }
    }
}

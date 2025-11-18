//
//  AIService.swift
//  GG
//
//  Created by TypeWise AI
//  Module 3: AI Suggestion Engine - Core Service
//

import Foundation
import Combine
import Security

// MARK: - Keychain Helper for Secure Storage

class KeychainHelper {
    private static let service = "com.typewise.ai"

    // Generic save method
    static func save(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // Generic load method
    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }

        return nil
    }

    // Generic delete method
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    // Legacy methods for backward compatibility
    static func save(apiKey: String) -> Bool {
        return save(key: "openai-api-key", value: apiKey)
    }

    static func load() -> String? {
        return load(key: "openai-api-key")
    }

    static func delete() -> Bool {
        return delete(key: "openai-api-key")
    }
}

// MARK: - AI Service Protocol

protocol AIServiceProtocol {
    func generateSuggestions(for text: String, context: LocalAIContext) async throws -> AISuggestionResponse
    func improveGrammar(for text: String) async throws -> AIImprovementResponse
    func rewriteText(_ text: String, style: AIRewriteStyle) async throws -> AIRewriteResponse
}

// MARK: - AI Context

struct LocalAIContext {
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
    @Published var cacheHitRate: Double = 0.0

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

    // MARK: - Caching
    private var suggestionCache = [String: AISuggestionResponse]()
    private var cacheHits = 0
    private var totalRequests = 0
    private let maxCacheSize = 100
    private let cacheExpiryTime: TimeInterval = 300 // 5 minutes

    // MARK: - Initialization

    init(apiKey: String) {
        // Load API key from Keychain if empty
        if apiKey.isEmpty {
            self.apiKey = KeychainHelper.load() ?? ""
        } else {
            self.apiKey = apiKey
            // Save to Keychain
            _ = KeychainHelper.save(apiKey: apiKey)
        }
        self.isAPIKeyConfigured = !self.apiKey.isEmpty
    }

    // MARK: - Public Methods

    func updateAPIKey(_ newAPIKey: String) {
        DispatchQueue.main.async {
            self.apiKey = newAPIKey
        }
        print("🔑 OpenAIService: API key updated")
    }

    func generateSuggestions(for text: String, context: LocalAIContext) async throws -> AISuggestionResponse {
        totalRequests += 1

        // Check cache first
        let cacheKey = "\(text.hashValue)-\(context.appName)"
        if let cachedResponse = suggestionCache[cacheKey] {
            cacheHits += 1
            DispatchQueue.main.async {
                self.cacheHitRate = Double(self.cacheHits) / Double(self.totalRequests)
            }
            print("📋 Cache hit for text: \(text.prefix(50))...")
            return cachedResponse
        }

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

        // Retry logic
        var lastError: Error?
        for attempt in 1...3 {
            do {
                let response = try await makeOpenAIRequestWithRetry(prompt: prompt, attempt: attempt)
                let suggestions = try parseSuggestionsResponse(response, originalText: text)
                let processingTime = Date().timeIntervalSince(startTime)

                let result = AISuggestionResponse(
                    original: text,
                    suggestions: suggestions,
                    confidence: calculateOverallConfidence(suggestions),
                    processingTime: processingTime
                )

                // Cache the result
                cacheResult(key: cacheKey, response: result)

                DispatchQueue.main.async {
                    self.requestCount += 1
                    self.cacheHitRate = Double(self.cacheHits) / Double(self.totalRequests)
                }

                return result

            } catch {
                lastError = error
                if attempt < 3 {
                    let delay = pow(2.0, Double(attempt)) // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    print("⚠️ Retry attempt \(attempt + 1) after \(delay)s delay")
                }
            }
        }

        throw lastError ?? AIServiceError.networkError(NSError(domain: "Unknown", code: -1))
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

    private func buildSuggestionPrompt(text: String, context: LocalAIContext) -> String {
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

    private func cacheResult(key: String, response: AISuggestionResponse) {
        suggestionCache[key] = response

        // Prevent cache from growing too large
        if suggestionCache.count > maxCacheSize {
            let oldestKey = suggestionCache.keys.randomElement()!
            suggestionCache.removeValue(forKey: oldestKey)
        }
    }

    private func makeOpenAIRequestWithRetry(prompt: String, attempt: Int) async throws -> String {
        do {
            return try await makeOpenAIRequest(prompt: prompt)
        } catch {
            // Log specific error types for better debugging
            if let aiError = error as? AIServiceError {
                switch aiError {
                case .rateLimitExceeded:
                    print("🚫 Rate limit exceeded on attempt \(attempt)")
                    if attempt < 3 {
                        // Wait longer for rate limits
                        try await Task.sleep(nanoseconds: UInt64(5 * 1_000_000_000))
                    }
                case .apiError(let statusCode, let message):
                    print("❌ API error \(statusCode): \(message)")
                case .networkError(let underlyingError):
                    print("🌐 Network error: \(underlyingError.localizedDescription)")
                case .invalidAPIKey:
                    print("🔑 Invalid API key")
                case .invalidResponse:
                    print("📄 Invalid response format")
                case .quotaExceeded:
                    print("💰 API quota exceeded")
                }
            }
            throw error
        }
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

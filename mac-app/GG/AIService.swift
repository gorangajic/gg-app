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

// Note: OpenAIService removed - app now uses ServerAIService exclusively
// If direct OpenAI integration is needed in the future, implement it as a toggle option

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

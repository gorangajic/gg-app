//
//  ServerAIService.swift
//  GG
//
//  AI Service implementation that uses the TypeWise AI Server
//  instead of calling OpenAI directly
//

import Foundation
import Combine

// MARK: - Server AI Service Implementation

class ServerAIService: AIServiceProtocol, ObservableObject {

    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastError: AIServiceError?
    @Published var requestCount = 0
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    // MARK: - Private Properties
    private let apiClient = ServerAPIClient.shared

    // MARK: - Initialization

    init() {
        self.isAuthenticated = apiClient.isAuthenticated()
        loadCurrentUser()
        setupAuthenticationObserver()
    }

    // MARK: - Authentication State Sync

    private func setupAuthenticationObserver() {
        // Listen for authentication changes from the coordinator
        NotificationCenter.default.addObserver(
            forName: .authenticationStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.refreshAuthenticationState()
        }
    }

    func refreshAuthenticationState() {
        DispatchQueue.main.async {
            self.isAuthenticated = self.apiClient.isAuthenticated()
            if self.isAuthenticated {
                self.loadCurrentUser()
            } else {
                self.currentUser = nil
            }
        }
    }

    // MARK: - Authentication Methods

    func register(email: String, password: String, name: String? = nil) async throws {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await apiClient.register(email: email, password: password, name: name)
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentUser = response.user
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = .apiError(error.localizedDescription)
            }
            throw error
        }
    }

    func login(email: String, password: String) async throws {
        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await apiClient.login(email: email, password: password)
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.currentUser = response.user
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = .apiError(error.localizedDescription)
            }
            throw error
        }
    }

    func logout() async throws {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await apiClient.logout()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.lastError = .apiError(error.localizedDescription)
            }
            throw error
        }
    }

    // MARK: - AIServiceProtocol Implementation

    func generateSuggestions(for text: String, context: LocalAIContext) async throws -> AISuggestionResponse {
        guard isAuthenticated else {
            throw AIServiceError.notAuthenticated
        }

        isProcessing = true
        let startTime = Date()

        do {
            // Convert LocalAIContext to server's AIContext format
            let serverContext = ServerAPIClient.AIContext(
                appName: context.appName,
                fieldType: context.fieldType,
                textLength: context.textLength,
                language: context.language
            )

            let response = try await apiClient.generateSuggestions(
                text: text,
                context: serverContext,
                maxSuggestions: 5
            )

            DispatchQueue.main.async {
                self.requestCount += 1
                self.isProcessing = false
            }

            // Convert server suggestions to app suggestions
            let suggestions = response.suggestions.map { serverSuggestion -> AISuggestion in
                let suggestionType = SuggestionType(rawValue: serverSuggestion.type.capitalized) ?? .grammar
                return AISuggestion(
                    type: suggestionType,
                    originalText: serverSuggestion.original,
                    suggestedText: serverSuggestion.suggestion,
                    reason: serverSuggestion.reason,
                    confidence: serverSuggestion.confidence,
                    range: nil
                )
            }

            let processingTime = Date().timeIntervalSince(startTime)
            let averageConfidence = suggestions.isEmpty ? 0 : suggestions.map { $0.confidence }.reduce(0, +) / Double(suggestions.count)

            return AISuggestionResponse(
                original: text,
                suggestions: suggestions,
                confidence: averageConfidence,
                processingTime: processingTime
            )

        } catch {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.lastError = .apiError(error.localizedDescription)
            }
            throw error
        }
    }

    func improveGrammar(for text: String) async throws -> AIImprovementResponse {
        guard isAuthenticated else {
            throw AIServiceError.notAuthenticated
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await apiClient.improveGrammar(text: text)

            DispatchQueue.main.async {
                self.requestCount += 1
            }

            // Convert server changes to app changes
            let changes = response.changes.map { serverChange -> TextChange in
                let suggestionType = SuggestionType(rawValue: serverChange.type.capitalized) ?? .grammar
                return TextChange(
                    range: NSRange(location: 0, length: 0), // Server doesn't provide ranges
                    original: serverChange.original,
                    replacement: serverChange.corrected,
                    type: suggestionType
                )
            }

            return AIImprovementResponse(
                improvedText: response.improved,
                changes: changes,
                overallImprovement: response.changes.isEmpty ? "No changes needed" : "\(changes.count) improvements made"
            )

        } catch {
            DispatchQueue.main.async {
                self.lastError = .apiError(error.localizedDescription)
            }
            throw error
        }
    }

    func rewriteText(_ text: String, style: AIRewriteStyle) async throws -> AIRewriteResponse {
        guard isAuthenticated else {
            throw AIServiceError.notAuthenticated
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let response = try await apiClient.rewriteText(
                text: text,
                style: style.rawValue.lowercased()
            )

            DispatchQueue.main.async {
                self.requestCount += 1
            }

            return AIRewriteResponse(
                rewrittenText: response.rewritten,
                style: style,
                changesSummary: "Rewritten in \(style.rawValue) style"
            )

        } catch {
            DispatchQueue.main.async {
                self.lastError = .apiError(error.localizedDescription)
            }
            throw error
        }
    }

    // MARK: - Helper Methods

    private func loadCurrentUser() {
        // Could fetch current user info from server if needed
        // For now, we just check if authenticated
    }

    func setServerURL(_ url: String) {
        apiClient.setBaseURL(url)
    }

    func getServerURL() -> String {
        return apiClient.getBaseURL()
    }
}

// MARK: - AI Service Error Extension

extension AIServiceError {
    static var notAuthenticated: AIServiceError {
        return .apiError("Not authenticated. Please log in to use AI features.")
    }
}

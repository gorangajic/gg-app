//
//  ServerAPIClient.swift
//  GG
//
//  Client for TypeWise AI Server API
//  Handles authentication and AI feature requests
//

import Foundation

// MARK: - API Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String?
}

struct AuthResponse: Codable {
    let message: String
    let user: User
    let token: String
}

struct User: Codable {
    let id: String
    let email: String
    let name: String?
    let createdAt: String
}

struct GenerateSuggestionsRequest: Codable {
    let text: String
    let context: AIContext?
    let maxSuggestions: Int
}

struct AIContext: Codable {
    let appName: String?
    let fieldType: String?
    let textLength: Int
    let language: String
}

struct SuggestionResponse: Codable {
    let suggestions: [Suggestion]
    let processingTime: Int
}

struct Suggestion: Codable {
    let type: String
    let original: String
    let suggestion: String
    let reason: String
    let confidence: Double
}

struct ImproveGrammarRequest: Codable {
    let text: String
}

struct ImprovementResponse: Codable {
    let original: String
    let improved: String
    let changes: [Change]
    let processingTime: Int

    struct Change: Codable {
        let type: String
        let original: String
        let corrected: String
        let explanation: String
    }
}

struct RewriteRequest: Codable {
    let text: String
    let style: String
}

struct RewriteResponse: Codable {
    let original: String
    let rewritten: String
    let style: String
    let processingTime: Int
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
    let details: [ValidationError]?

    struct ValidationError: Codable {
        let message: String?
        let path: [String]?
    }
}

struct MessageResponse: Codable {
    let message: String
}

// MARK: - Server API Client

class ServerAPIClient {
    static let shared = ServerAPIClient()

    private let baseURL: String
    private var authToken: String?

    private init() {
        // Default to localhost, can be configured
        self.baseURL = UserDefaults.standard.string(forKey: "ServerBaseURL") ?? "http://localhost:3001"
        self.authToken = KeychainHelper.load(key: "ServerAuthToken")
    }

    // MARK: - Configuration

    func setBaseURL(_ url: String) {
        UserDefaults.standard.set(url, forKey: "ServerBaseURL")
    }

    func getBaseURL() -> String {
        return baseURL
    }

    func setAuthToken(_ token: String) {
        self.authToken = token
        KeychainHelper.save(key: "ServerAuthToken", value: token)
    }

    func clearAuthToken() {
        self.authToken = nil
        KeychainHelper.delete(key: "ServerAuthToken")
    }

    func isAuthenticated() -> Bool {
        return authToken != nil
    }

    // MARK: - Authentication

    func register(email: String, password: String, name: String? = nil) async throws -> AuthResponse {
        let request = RegisterRequest(email: email, password: password, name: name)
        let response: AuthResponse = try await post(endpoint: "/api/auth/register", body: request, authenticated: false)
        setAuthToken(response.token)
        return response
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let request = LoginRequest(email: email, password: password)
        let response: AuthResponse = try await post(endpoint: "/api/auth/login", body: request, authenticated: false)
        setAuthToken(response.token)
        return response
    }

    func logout() async throws {
        let _: MessageResponse = try await post(endpoint: "/api/auth/logout", body: EmptyBody(), authenticated: true)
        clearAuthToken()
    }

    // MARK: - AI Features

    func generateSuggestions(
        text: String,
        context: AIContext? = nil,
        maxSuggestions: Int = 5
    ) async throws -> SuggestionResponse {
        let request = GenerateSuggestionsRequest(
            text: text,
            context: context,
            maxSuggestions: maxSuggestions
        )
        return try await post(endpoint: "/api/suggestions/generate", body: request, authenticated: true)
    }

    func improveGrammar(text: String) async throws -> ImprovementResponse {
        let request = ImproveGrammarRequest(text: text)
        return try await post(endpoint: "/api/suggestions/improve-grammar", body: request, authenticated: true)
    }

    func rewriteText(text: String, style: String) async throws -> RewriteResponse {
        let request = RewriteRequest(text: text, style: style)
        return try await post(endpoint: "/api/suggestions/rewrite", body: request, authenticated: true)
    }

    // MARK: - HTTP Methods

    private func post<T: Codable, R: Codable>(
        endpoint: String,
        body: T,
        authenticated: Bool
    ) async throws -> R {
        guard let url = URL(string: baseURL + endpoint) else {
            throw ServerAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated {
            guard let token = authToken else {
                throw ServerAPIError.notAuthenticated
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            // Network-specific errors
            if error.code == .cannotConnectToHost || error.code == .networkConnectionLost {
                throw ServerAPIError.serverUnavailable
            }
            throw ServerAPIError.networkError(error)
        } catch {
            throw ServerAPIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServerAPIError.invalidResponse
        }

        // Handle error responses
        if httpResponse.statusCode >= 400 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ServerAPIError.apiError(statusCode: httpResponse.statusCode, message: errorResponse.error)
            }
            throw ServerAPIError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(R.self, from: data)
    }
}

// MARK: - Empty Body Helper

private struct EmptyBody: Codable {}

// MARK: - Errors

enum ServerAPIError: LocalizedError {
    case invalidURL
    case notAuthenticated
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(statusCode: Int, message: String)
    case networkError(Error)
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Server URL is not configured correctly. Please check your settings."
        case .notAuthenticated:
            return "You need to sign in to use AI features. Please authenticate in the app."
        case .invalidResponse:
            return "Received an unexpected response from the server. Please try again."
        case .httpError(let statusCode):
            return httpErrorMessage(for: statusCode)
        case .apiError(let statusCode, let message):
            return "Server returned an error (\(statusCode)): \(message)"
        case .networkError(let error):
            return "Network connection failed: \(error.localizedDescription)"
        case .serverUnavailable:
            return "Unable to connect to the server. Please check if the server is running."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL:
            return "Go to Settings and verify the server URL is correct (e.g., http://localhost:3001)"
        case .notAuthenticated:
            return "Click the 'Sign In' button to authenticate with your account."
        case .invalidResponse:
            return "This might be a temporary issue. Try again in a moment."
        case .httpError(let statusCode):
            return httpRecoverySuggestion(for: statusCode)
        case .apiError(let statusCode, _):
            return httpRecoverySuggestion(for: statusCode)
        case .networkError:
            return "Check your internet connection and ensure the server is running."
        case .serverUnavailable:
            return "Make sure the server is started with 'npm run dev' in the server directory."
        }
    }

    private func httpErrorMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "The request was invalid. Please check your input."
        case 401:
            return "Authentication failed. Please sign in again."
        case 403:
            return "Access denied. You don't have permission for this action."
        case 404:
            return "The requested resource was not found."
        case 429:
            return "Too many requests. Please wait a moment before trying again."
        case 500...599:
            return "The server encountered an error. Please try again later."
        default:
            return "Server error (HTTP \(statusCode)). Please try again."
        }
    }

    private func httpRecoverySuggestion(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Make sure you have entered text before requesting suggestions."
        case 401:
            return "Sign out and sign in again to refresh your authentication."
        case 403:
            return "Contact support if you believe this is an error."
        case 404:
            return "The server API might have changed. Try updating the app."
        case 429:
            return "Wait a few seconds and try again."
        case 500...599:
            return "This is a server issue. Please try again in a few minutes."
        default:
            return "Try again or contact support if the problem persists."
        }
    }
}

//
//  AuthenticationCoordinator.swift
//  GG
//
//  Coordinates browser-based authentication flow
//

import Foundation
import AppKit
import Combine

class AuthenticationCoordinator: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var authToken: String?
    @Published var serverURL: String {
        didSet {
            UserDefaults.standard.set(serverURL, forKey: "ServerURL")
            ServerAPIClient.shared.setBaseURL(serverURL)
        }
    }

    private let apiClient = ServerAPIClient.shared

    init() {
        // Load server URL from defaults
        self.serverURL = UserDefaults.standard.string(forKey: "ServerURL") ?? "http://localhost:3001"
        ServerAPIClient.shared.setBaseURL(serverURL)

        // Check if already authenticated
        self.isAuthenticated = apiClient.isAuthenticated()
        if let token = KeychainHelper.load(key: "ServerAuthToken") {
            self.authToken = token
        }
    }

    // MARK: - Browser-Based Authentication

    func openBrowserForLogin() {
        let loginURL = URL(string: "\(serverURL)/login")!
        NSWorkspace.shared.open(loginURL)
    }

    func openBrowserForRegistration() {
        let registerURL = URL(string: "\(serverURL)/register")!
        NSWorkspace.shared.open(registerURL)
    }

    // MARK: - Handle URL Callback

    func handleAuthCallback(url: URL) {
        guard url.scheme == "ggapp",
              url.host == "auth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let tokenItem = components.queryItems?.first(where: { $0.name == "token" }),
              let token = tokenItem.value else {
            print("Invalid auth callback URL: \(url)")
            return
        }

        // Save the token
        apiClient.setAuthToken(token)

        // Update state
        DispatchQueue.main.async {
            self.authToken = token
            self.isAuthenticated = true

            // Show notification
            self.showAuthSuccessNotification()

            // Optionally fetch user info
            Task {
                await self.fetchUserInfo()
            }
        }
    }

    // MARK: - Logout

    func logout() async {
        do {
            try await apiClient.logout()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
                self.authToken = nil
            }
        } catch {
            print("Logout error: \(error)")
            // Clear local state anyway
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.currentUser = nil
                self.authToken = nil
            }
        }
    }

    // MARK: - User Info

    private func fetchUserInfo() async {
        // For now, we don't have a user info endpoint
        // The user info is returned during login, so we'd need to store it
        // or create a /api/auth/me endpoint on the server
    }

    // MARK: - Notifications

    private func showAuthSuccessNotification() {
        let notification = NSUserNotification()
        notification.title = "TypeWise AI"
        notification.informativeText = "Successfully signed in!"
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }
}

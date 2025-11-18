//
//  AuthenticationView.swift
//  GG
//
//  Simple authentication UI for browser-based login
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authCoordinator: AuthenticationCoordinator
    @State private var showServerURLConfig = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("TypeWise AI")
                .font(.title)
                .fontWeight(.bold)

            if authCoordinator.isAuthenticated {
                // Authenticated State
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)

                    Text("Signed In")
                        .font(.headline)

                    if let user = authCoordinator.currentUser {
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Button("Sign Out") {
                        Task {
                            await authCoordinator.logout()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                // Not Authenticated State
                VStack(spacing: 15) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)

                    Text("Sign in to use AI features")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 15) {
                        Button("Sign In") {
                            authCoordinator.openBrowserForLogin()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Create Account") {
                            authCoordinator.openBrowserForRegistration()
                        }
                        .buttonStyle(.bordered)
                    }

                    Divider()
                        .padding(.vertical, 5)

                    // Server URL Configuration
                    Button(action: {
                        showServerURLConfig.toggle()
                    }) {
                        HStack {
                            Image(systemName: "server.rack")
                            Text("Server: \(formatServerURL(authCoordinator.serverURL))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Configure server URL")
                }
                .padding()
            }

            // Server URL Configuration Sheet
            if showServerURLConfig {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Server Configuration")
                        .font(.headline)

                    TextField("Server URL", text: $authCoordinator.serverURL)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Text("Default: http://localhost:3001")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button("Done") {
                            showServerURLConfig = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(minWidth: 300, minHeight: 250)
        .padding()
    }

    private func formatServerURL(_ url: String) -> String {
        if url.starts(with: "http://localhost") {
            return "localhost"
        } else if url.starts(with: "https://") {
            return url.replacingOccurrences(of: "https://", with: "")
        } else if url.starts(with: "http://") {
            return url.replacingOccurrences(of: "http://", with: "")
        }
        return url
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Not authenticated
            AuthenticationView()
                .environmentObject(AuthenticationCoordinator())
                .previewDisplayName("Not Signed In")

            // Authenticated
            AuthenticationView()
                .environmentObject({
                    let coordinator = AuthenticationCoordinator()
                    coordinator.isAuthenticated = true
                    coordinator.currentUser = User(
                        id: "1",
                        email: "user@example.com",
                        name: "Test User",
                        createdAt: "2024-01-01T00:00:00Z"
                    )
                    return coordinator
                }())
                .previewDisplayName("Signed In")
        }
    }
}

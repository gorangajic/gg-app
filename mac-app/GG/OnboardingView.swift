//
//  OnboardingView.swift
//  GG
//
//  First-time user onboarding flow
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authCoordinator: AuthenticationCoordinator
    @ObservedObject var aiService: ServerAIService
    @State private var currentStep = 0
    @State private var serverURL: String
    @State private var permissionsGranted = false

    init(aiService: ServerAIService, serverURL: String = "http://localhost:3001") {
        self.aiService = aiService
        self._serverURL = State(initialValue: serverURL)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            // Content
            TabView(selection: $currentStep) {
                WelcomeStep()
                    .tag(0)

                PermissionsStep(permissionsGranted: $permissionsGranted)
                    .tag(1)

                ServerSetupStep(serverURL: $serverURL)
                    .tag(2)

                AuthenticationStep(
                    aiService: aiService,
                    serverURL: $serverURL,
                    onComplete: completeOnboarding
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation buttons
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                if currentStep < 3 {
                    Button("Next") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                } else {
                    Button("Get Started") {
                        completeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!authCoordinator.isAuthenticated)
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
    }

    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return permissionsGranted
        case 2: return !serverURL.isEmpty
        case 3: return authCoordinator.isAuthenticated
        default: return false
        }
    }

    private func completeOnboarding() {
        // Save that onboarding is complete
        UserDefaults.standard.set(true, forKey: "OnboardingCompleted")
        UserDefaults.standard.set(serverURL, forKey: "ServerURL")
        authCoordinator.serverURL = serverURL
        dismiss()
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            Text("Welcome to TypeWise AI")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your intelligent writing assistant for macOS")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "keyboard", title: "System-Wide Monitoring", description: "Works in any app you type in")
                FeatureRow(icon: "sparkles", title: "AI-Powered Suggestions", description: "Get grammar, style, and clarity improvements")
                FeatureRow(icon: "hand.tap", title: "Manual Trigger", description: "Click the suggestion button when you need help")
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)

            Spacer()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Permissions Step

struct PermissionsStep: View {
    @Binding var permissionsGranted: Bool
    @State private var checkingPermissions = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Grant Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("TypeWise AI needs accessibility permissions to work")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                PermissionRow(
                    icon: "keyboard",
                    title: "Accessibility Access",
                    description: "Required to monitor keystrokes and read text fields",
                    granted: permissionsGranted
                )
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("To grant permissions:")
                    .font(.headline)

                Text("1. Click 'Open System Preferences' below")
                Text("2. Find 'TypeWise AI' or 'GG' in the list")
                Text("3. Check the box next to the app name")
                Text("4. Return here and click 'Check Permissions'")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                Button("Open System Preferences") {
                    openAccessibilityPreferences()
                }
                .buttonStyle(.bordered)

                Button("Check Permissions") {
                    checkPermissions()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            checkPermissions()
        }
    }

    private func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkPermissions() {
        checkingPermissions = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            permissionsGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)
            checkingPermissions = false
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let granted: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(granted ? .green : .red)
        }
    }
}

// MARK: - Server Setup Step

struct ServerSetupStep: View {
    @Binding var serverURL: String
    @State private var isServerReachable = false
    @State private var checking = false

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "server.rack")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Connect to Server")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Configure your TypeWise AI Server")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Server URL")
                    .font(.headline)

                TextField("http://localhost:3001", text: $serverURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                HStack(spacing: 8) {
                    Image(systemName: isServerReachable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isServerReachable ? .green : .orange)

                    if checking {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Checking...")
                            .font(.caption)
                    } else if isServerReachable {
                        Text("Server is reachable")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Cannot connect to server")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("How to start the server:")
                    .font(.headline)

                Text("1. Open Terminal")
                Text("2. Navigate to the server directory")
                Text("3. Run: npm run dev")
                Text("4. Wait for 'Server running on port 3001'")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Test Connection") {
                testServerConnection()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
        .onAppear {
            testServerConnection()
        }
    }

    private func testServerConnection() {
        checking = true
        isServerReachable = false

        guard let url = URL(string: "\(serverURL)/api/health") else {
            checking = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                checking = false
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 || httpResponse.statusCode == 404 {
                    // 404 is ok too - means server is running but endpoint doesn't exist
                    isServerReachable = true
                }
            }
        }.resume()
    }
}

// MARK: - Authentication Step

struct AuthenticationStep: View {
    @EnvironmentObject var authCoordinator: AuthenticationCoordinator
    @ObservedObject var aiService: ServerAIService
    @Binding var serverURL: String
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: authCoordinator.isAuthenticated ? "checkmark.circle.fill" : "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(authCoordinator.isAuthenticated ? .green : .purple)

            Text(authCoordinator.isAuthenticated ? "You're All Set!" : "Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)

            if authCoordinator.isAuthenticated {
                Text("Your account is connected and ready to use")
                    .font(.title3)
                    .foregroundColor(.secondary)

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Permissions granted")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Server connected")
                    }
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Account authenticated")
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else {
                Text("Create an account or sign in to start using AI features")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Text("This will open your web browser where you can:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("• Create a new account")
                    Text("• Sign in with existing credentials")
                    Text("• Authenticate with the server")
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)

                Button("Open Browser to Sign In") {
                    authCoordinator.openBrowserForLogin()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    let aiService = ServerAIService()
    let authCoordinator = AuthenticationCoordinator()

    return OnboardingView(aiService: aiService)
        .environmentObject(authCoordinator)
}

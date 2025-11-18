//
//  StatusBarController.swift
//  GG
//
//  Created by TypeWise AI
//

import SwiftUI
import Cocoa

class StatusBarController: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    @Published var isMenuShowing = false
    @Published var suggestionOverlayVisible = false
    @Published var lastSuggestionCount = 0

    init() {
        setupStatusBar()
        setupNotificationObservers()
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "wand.and.rays", accessibilityDescription: "TypeWise AI")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }

        setupPopover()
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 450, height: 650)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: StatusBarMenuView())
    }

    private func setupNotificationObservers() {
        // Listen for AI suggestions generated
        NotificationCenter.default.addObserver(
            forName: .aiSuggestionsGenerated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let suggestions = notification.userInfo?["suggestions"] as? [AISuggestion] {
                self?.lastSuggestionCount = suggestions.count
                self?.updateStatusIcon(showActivity: true)
            }
        }

        // Listen for overlay visibility changes
        NotificationCenter.default.addObserver(
            forName: .hideSuggestionOverlay,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.suggestionOverlayVisible = false
            self?.updateStatusIcon(showActivity: false)
        }
    }

    @objc func statusBarButtonClicked() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                isMenuShowing = false
            } else {
                // Update the popover content with current state
                popover.contentViewController = NSHostingController(
                    rootView: StatusBarMenuView(
                        overlayVisible: suggestionOverlayVisible,
                        lastSuggestionCount: lastSuggestionCount
                    )
                )
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isMenuShowing = true
            }
        }
    }

    func showQuickSettings() {
        statusBarButtonClicked()
    }

    func updateStatusIcon(isActive: Bool? = nil, showActivity: Bool = false) {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button {
                let iconName: String
                if showActivity {
                    iconName = "wand.and.stars"
                } else if isActive == false {
                    iconName = "wand.and.rays.inverse"
                } else {
                    iconName = "wand.and.rays"
                }

                button.image = NSImage(systemSymbolName: iconName,
                                     accessibilityDescription: "TypeWise AI")
            }
        }
    }

    func showSuggestionNotification(count: Int) {
        suggestionOverlayVisible = true
        lastSuggestionCount = count
        updateStatusIcon(showActivity: true)

        // Reset activity icon after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.updateStatusIcon(showActivity: false)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

struct StatusBarMenuView: View {
    @StateObject private var settings = SettingsManager()
    @State private var showMainWindow = false

    let overlayVisible: Bool
    let lastSuggestionCount: Int

    init(overlayVisible: Bool = false, lastSuggestionCount: Int = 0) {
        self.overlayVisible = overlayVisible
        self.lastSuggestionCount = lastSuggestionCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "wand.and.rays")
                    .foregroundColor(.blue)
                Text("TypeWise AI")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()

                // Status indicator
                Circle()
                    .fill(overlayVisible ? .green : .gray)
                    .frame(width: 8, height: 8)
            }

            // Module 4: Overlay Status
            VStack(alignment: .leading, spacing: 8) {
                Text("Suggestion Overlay")
                    .font(.headline)
                    .foregroundColor(.blue)

                HStack {
                    Image(systemName: overlayVisible ? "eye" : "eye.slash")
                        .foregroundColor(overlayVisible ? .green : .secondary)
                    Text(overlayVisible ? "Currently Visible" : "Hidden")
                        .foregroundColor(overlayVisible ? .green : .secondary)
                    Spacer()
                }

                if lastSuggestionCount > 0 {
                    Text("Last shown: \(lastSuggestionCount) suggestion\(lastSuggestionCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Quick overlay test
                Button("Test Overlay (Demo)") {
                    triggerTestOverlay()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Divider()

            // Quick toggles
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Settings")
                    .font(.headline)

                Toggle("Auto Suggestions", isOn: $settings.autoTriggerEnabled)

                HStack {
                    Text("Min Text Length:")
                    Spacer()
                    TextField("15", value: $settings.minimumTextLength, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }

                HStack {
                    Text("Suggestion Delay:")
                    Spacer()
                    TextField("2.0", value: $settings.suggestionDelay, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("sec")
                }

                HStack {
                    Text("Max Suggestions:")
                    Spacer()
                    TextField("5", value: $settings.maxSuggestions, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                }
            }

            Divider()

            // Module status
            VStack(alignment: .leading, spacing: 8) {
                Text("System Status")
                    .font(.headline)

                StatusRow(title: "Keyboard Monitor", status: AppDelegate.shared.isKeyboardMonitoring)
                StatusRow(title: "Text Field Reader", status: AppDelegate.shared.isTextFieldReading)
                StatusRow(title: "AI Engine", status: AppDelegate.shared.isAIEngineRunning)
                StatusRow(title: "Suggestion Overlay", status: true) // Always available once Module 4 is loaded
            }

            Divider()

            // Action buttons
            VStack(spacing: 8) {
                Button("Open Main Window") {
                    openMainWindow()
                }
                .buttonStyle(.bordered)

                Button("Open AI Settings") {
                    openSettingsWindow()
                }
                .buttonStyle(.bordered)

                Button("Hide Overlay") {
                    hideCurrentOverlay()
                }
                .buttonStyle(.bordered)
                .disabled(!overlayVisible)

                Button("Quit TypeWise AI") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func triggerTestOverlay() {
        // Create mock suggestions for testing
        let testSuggestions = [
            AISuggestion(
                type: .style,
                originalText: "This is a test",
                suggestedText: "This serves as a demonstration",
                reason: "More professional language improves clarity.",
                confidence: 0.95,
                range: nil
            ),
            AISuggestion(
                type: .grammar,
                originalText: "Your doing great",
                suggestedText: "You're doing great",
                reason: "Corrected contraction usage.",
                confidence: 0.98,
                range: nil
            )
        ]

        // Post notification to show test overlay
        NotificationCenter.default.post(
            name: .aiSuggestionsGenerated,
            object: nil,
            userInfo: ["suggestions": testSuggestions]
        )
    }

    private func hideCurrentOverlay() {
        NotificationCenter.default.post(name: .hideSuggestionOverlay, object: nil)
    }

    private func openMainWindow() {
        // Activate the main window
        if let window = NSApplication.shared.windows.first(where: { $0.title.isEmpty || $0.title == "GG" }) {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    private func openSettingsWindow() {
        // Open AI Settings window
        if let settingsWindow = NSApplication.shared.windows.first(where: { $0.title == "AI Settings" }) {
            settingsWindow.makeKeyAndOrderFront(nil)
        } else {
            // Create new settings window if it doesn't exist
            let settingsView = AISettingsView(
                suggestionEngine: AppDelegate.shared.aiSuggestionEngine ?? AISuggestionEngine(
                    aiService: ServerAIService(),
                    textFieldIntegration: TextFieldIntegration(
                        keyboardMonitor: KeyboardMonitor(),
                        textFieldReader: TextFieldReader()
                    )
                ),
                aiService: ServerAIService()
            )

            let hostingController = NSHostingController(rootView: settingsView)
            let window = NSWindow(contentViewController: hostingController)
            window.title = "AI Settings"
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct StatusRow: View {
    let title: String
    let status: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(status ? .green : .red)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption)
            Spacer()
            Text(status ? "Active" : "Inactive")
                .font(.caption)
                .foregroundColor(status ? .green : .secondary)
        }
    }
}

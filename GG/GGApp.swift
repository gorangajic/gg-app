//
//  GGApp.swift
//  GG
//
//  Created by gole on 28.5.25..
//

import SwiftUI

@main
struct GGApp: App {
    @StateObject private var keyboardMonitor = KeyboardMonitor()
    @StateObject private var textFieldReader = TextFieldReader()
    @State private var isMonitoring = false

    var body: some Scene {
        WindowGroup {
            ContentView(keyboardMonitor: keyboardMonitor, textFieldReader: textFieldReader)
                .onAppear {
                    setupMonitoring()
                }
                .onDisappear {
                    stopMonitoring()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Text Field Demo") {
                    openTextFieldDemo()
                }
                .keyboardShortcut("d", modifiers: .command)
            }
        }

        // Demo window
        WindowGroup("Text Field Demo") {
            TextFieldDemo()
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "textfield-demo"))
    }

    private func setupMonitoring() {
        // Set up keyboard monitor
        keyboardMonitor.delegate = AppDelegate.shared
        keyboardMonitor.startMonitoring()

        // Set up text field reader
        textFieldReader.delegate = AppDelegate.shared
        textFieldReader.startMonitoring()
    }

    private func stopMonitoring() {
        keyboardMonitor.stopMonitoring()
        textFieldReader.stopMonitoring()
    }

    private func openTextFieldDemo() {
        if let url = URL(string: "gg://textfield-demo") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, ObservableObject, KeyboardMonitorDelegate, TextFieldReaderDelegate {
    static let shared = AppDelegate()

    // MARK: - KeyboardMonitorDelegate

    func keyboardMonitor(_ monitor: KeyboardMonitor, didTriggerSuggestion text: String) {
        // This will be connected to Module 3 (AI Suggestion Engine) later
        print("📝 App received suggestion trigger: '\(text)'")

        // For now, just log the captured text
        NotificationCenter.default.post(
            name: .suggestionTriggered,
            object: nil,
            userInfo: ["text": text]
        )
    }

    // MARK: - TextFieldReaderDelegate

    func textFieldReader(_ reader: TextFieldReader, didDetectTextChange text: String, in element: AXUIElement) {
        print("📝 Text field content changed: '\(text)' in app: \(reader.focusedAppName)")

        // Post notification for text field changes
        NotificationCenter.default.post(
            name: .textFieldContentChanged,
            object: nil,
            userInfo: [
                "text": text,
                "appName": reader.focusedAppName,
                "element": element
            ]
        )
    }

    func textFieldReader(_ reader: TextFieldReader, didLoseFocus previousText: String) {
        print("📝 Text field lost focus. Previous text: '\(previousText)'")

        // Post notification for focus loss
        NotificationCenter.default.post(
            name: .textFieldLostFocus,
            object: nil,
            userInfo: ["previousText": previousText]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let suggestionTriggered = Notification.Name("suggestionTriggered")
    static let textFieldContentChanged = Notification.Name("textFieldContentChanged")
    static let textFieldLostFocus = Notification.Name("textFieldLostFocus")
}

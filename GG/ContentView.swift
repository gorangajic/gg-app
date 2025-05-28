//
//  ContentView.swift
//  GG
//
//  Created by gole on 28.5.25..
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var keyboardMonitor: KeyboardMonitor
    @ObservedObject var textFieldReader: TextFieldReader
    @State private var lastSuggestionText: String = "No suggestions yet"
    @State private var lastTextFieldChange: String = "No text field activity"

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack {
                Image(systemName: "keyboard")
                    .imageScale(.large)
                    .foregroundStyle(.blue)
                    .font(.system(size: 40))

                Text("TypeWise AI")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Modules 1 & 2: Keyboard + Text Field Monitoring")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Monitoring Status
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Circle()
                        .fill(keyboardMonitor.isMonitoring ? .green : .red)
                        .frame(width: 10, height: 10)

                    Text("Keyboard: \(keyboardMonitor.isMonitoring ? "Monitoring" : "Stopped")")
                        .font(.headline)
                }

                HStack {
                    Circle()
                        .fill(textFieldReader.isActive ? .green : .red)
                        .frame(width: 10, height: 10)

                    Text("Text Fields: \(textFieldReader.isActive ? "Monitoring" : "Stopped")")
                        .font(.headline)
                }

                Text("Buffer: \(keyboardMonitor.bufferCharacterCount) chars, \(keyboardMonitor.bufferWordCount) words")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !textFieldReader.focusedAppName.isEmpty {
                    Text("Focused App: \(textFieldReader.focusedAppName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Real-time Text Buffer
            VStack(alignment: .leading, spacing: 8) {
                Text("Live Keyboard Buffer:")
                    .font(.headline)

                ScrollView {
                    Text(keyboardMonitor.currentText.isEmpty ? "Start typing anywhere..." : keyboardMonitor.currentText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(keyboardMonitor.currentText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 120)
            }

            // Text Field Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Focused Text Field Content:")
                    .font(.headline)

                ScrollView {
                    Text(textFieldReader.currentText.isEmpty ? "No text field focused..." : textFieldReader.currentText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(textFieldReader.currentText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                .frame(height: 120)
            }

            // Last Activities
            VStack(alignment: .leading, spacing: 8) {
                Text("Last Suggestion Trigger:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(lastSuggestionText)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding(6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Last Text Field Change:")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(lastTextFieldChange)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Control Buttons
            HStack(spacing: 15) {
                Button(action: {
                    if keyboardMonitor.isMonitoring {
                        keyboardMonitor.stopMonitoring()
                    } else {
                        keyboardMonitor.startMonitoring()
                    }
                }) {
                    Text(keyboardMonitor.isMonitoring ? "Stop Keyboard" : "Start Keyboard")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)

                Button(action: {
                    if textFieldReader.isActive {
                        textFieldReader.stopMonitoring()
                    } else {
                        textFieldReader.startMonitoring()
                    }
                }) {
                    Text(textFieldReader.isActive ? "Stop Fields" : "Start Fields")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)

                Button("Clear Buffer") {
                    keyboardMonitor.clearBuffer()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 450, minHeight: 600)
        .onReceive(NotificationCenter.default.publisher(for: .suggestionTriggered)) { notification in
            if let text = notification.userInfo?["text"] as? String {
                lastSuggestionText = text
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .textFieldContentChanged)) { notification in
            if let text = notification.userInfo?["text"] as? String,
               let appName = notification.userInfo?["appName"] as? String {
                lastTextFieldChange = "[\(appName)] \(text)"
            }
        }
    }
}

#Preview {
    ContentView(keyboardMonitor: KeyboardMonitor(), textFieldReader: TextFieldReader())
}

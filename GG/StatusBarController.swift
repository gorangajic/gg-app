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

    init() {
        setupStatusBar()
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
        popover?.contentSize = NSSize(width: 400, height: 600)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: StatusBarMenuView())
    }

    @objc func statusBarButtonClicked() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                isMenuShowing = false
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                isMenuShowing = true
            }
        }
    }

    func showQuickSettings() {
        statusBarButtonClicked()
    }

    func updateStatusIcon(isActive: Bool) {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button {
                button.image = NSImage(systemSymbolName: isActive ? "wand.and.rays" : "wand.and.rays.inverse",
                                     accessibilityDescription: "TypeWise AI")
            }
        }
    }
}

struct StatusBarMenuView: View {
    @StateObject private var settings = SettingsManager()
    @State private var showMainWindow = false

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
            }

            Divider()

            // Quick toggles
            VStack(alignment: .leading, spacing: 12) {
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
            }

            Divider()

            // Action buttons
            VStack(spacing: 8) {
                Button("Open Main Window") {
                    showMainWindow = true
                }
                .buttonStyle(.bordered)

                Button("Open Settings") {
                    openSettingsWindow()
                }
                .buttonStyle(.bordered)

                Button("Quit TypeWise AI") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openSettingsWindow() {
        // This would open the settings window
        NSApp.sendAction(#selector(NSApp.orderFrontStandardAboutPanel(_:)), to: nil, from: nil)
    }
}

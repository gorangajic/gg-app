//
//  SuggestionOverlayWindow.swift
//  GG
//
//  Created by TypeWise AI
//  Module 4: Suggestion UI Overlay System
//

import SwiftUI
import Cocoa

class SuggestionOverlayWindow: NSPanel {
    private var hostingView: NSHostingView<SuggestionOverlayView>?
    private var currentSuggestions: [AISuggestion] = []

    // Override the read-only properties to control window behavior
    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return false
    }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupWindow()
    }

    private func setupWindow() {
        // Configure window properties for a floating overlay
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .alertPanel

        // Don't activate the window when shown
        hidesOnDeactivate = false

        // Accept mouse events but don't steal focus
        ignoresMouseEvents = false

        // Create hosting view
        let overlayView = SuggestionOverlayView()
        hostingView = NSHostingView(rootView: overlayView)
        contentView = hostingView

        // Initially hidden
        orderOut(nil)

        // Set up keyboard monitoring for overlay
        setupKeyboardHandling()
    }

    private func setupKeyboardHandling() {
        // Handle Escape key to close overlay
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 && self?.isVisible == true { // Escape key
                self?.hideOverlay()
                return nil // Consume the event
            }
            return event
        }
    }

    func showNear(cursor: NSPoint, with suggestions: [AISuggestion]) {
        guard !suggestions.isEmpty else { return }

        // Ensure all UI operations happen on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.currentSuggestions = suggestions

            // Calculate dynamic window size based on content
            let baseHeight: CGFloat = 80 // Header + padding
            let suggestionHeight: CGFloat = 100 // Approximate height per suggestion
            let maxHeight: CGFloat = 450 // Maximum height before scrolling
            let calculatedHeight = min(baseHeight + CGFloat(suggestions.count) * suggestionHeight, maxHeight)

            let windowSize = NSSize(width: 340, height: calculatedHeight)

            // Smart positioning near cursor with screen boundary awareness
            let optimalPosition = self.calculateOptimalPosition(near: cursor, windowSize: windowSize)

            self.setFrame(NSRect(origin: optimalPosition, size: windowSize), display: true)

            // Update content with new suggestions
            self.updateSuggestions(suggestions)

            // Show with smooth animation
            self.alphaValue = 0
            self.orderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().alphaValue = 1.0
            }

            // Bring to front
            self.orderFrontRegardless()
        }
    }

    private func calculateOptimalPosition(near cursor: NSPoint, windowSize: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else { return cursor }

        let screenFrame = screen.visibleFrame
        let margin: CGFloat = 10

        // Preferred position: slightly to the right and below cursor
        var x = cursor.x + 15
        var y = cursor.y - windowSize.height - 20

        // Adjust for right screen boundary
        if x + windowSize.width + margin > screenFrame.maxX {
            x = cursor.x - windowSize.width - 15
        }

        // Adjust for left screen boundary
        if x < screenFrame.minX + margin {
            x = screenFrame.minX + margin
        }

        // Adjust for bottom screen boundary
        if y < screenFrame.minY + margin {
            y = cursor.y + 25
        }

        // Adjust for top screen boundary
        if y + windowSize.height > screenFrame.maxY - margin {
            y = screenFrame.maxY - windowSize.height - margin
        }

        return NSPoint(x: x, y: y)
    }

    func hideOverlay() {
        // Ensure all UI operations happen on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().alphaValue = 0.0
            }) {
                self.orderOut(nil)
                self.currentSuggestions = []
            }
        }
    }

    private func updateSuggestions(_ suggestions: [AISuggestion]) {
        // Update the SwiftUI view with new suggestions
        if let hostingView = hostingView {
            hostingView.rootView = SuggestionOverlayView(suggestions: suggestions)
        }
    }

    // Handle clicks outside the window
    override func resignKey() {
        super.resignKey()
        // Don't auto-hide on resign key - let the timer handle it
    }
}

struct SuggestionOverlayView: View {
    let suggestions: [AISuggestion]
    @State private var selectedSuggestion: AISuggestion?
    @State private var hoveredSuggestion: AISuggestion?

    init(suggestions: [AISuggestion] = []) {
        self.suggestions = suggestions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with improved styling
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .imageScale(.medium)
                Text("AI Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()

                // Quick stats
                if !suggestions.isEmpty {
                    Text("\(suggestions.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }

                Button(action: closeOverlay) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .imageScale(.small)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.95))

            if !suggestions.isEmpty {
                Divider()

                // Suggestions list with improved scrolling
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                            OverlaySuggestionCard(
                                suggestion: suggestion,
                                index: index + 1,
                                isSelected: selectedSuggestion?.id == suggestion.id,
                                isHovered: hoveredSuggestion?.id == suggestion.id
                            ) {
                                applySuggestion(suggestion)
                            }
                            .onTapGesture {
                                selectedSuggestion = suggestion
                            }
                            .onHover { isHovering in
                                hoveredSuggestion = isHovering ? suggestion : nil
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 320)
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("No suggestions available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Keep typing to get AI-powered suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor).opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
        .frame(width: 340)
        .onAppear {
            // Auto-select first suggestion
            selectedSuggestion = suggestions.first
        }
    }

    private func applySuggestion(_ suggestion: AISuggestion) {
        // Post notification to apply suggestion
        NotificationCenter.default.post(
            name: .applySuggestionFromOverlay,
            object: nil,
            userInfo: ["suggestion": suggestion]
        )
        closeOverlay()
    }

    private func closeOverlay() {
        NotificationCenter.default.post(name: .hideSuggestionOverlay, object: nil)
    }
}

struct OverlaySuggestionCard: View {
    let suggestion: AISuggestion
    let index: Int
    let isSelected: Bool
    let isHovered: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Index number
                Text("\(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(colorForSuggestionType(suggestion.type))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    // Type and confidence header
                    HStack {
                        Text(suggestion.type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorForSuggestionType(suggestion.type))

                        Spacer()

                        // Confidence indicator
                        HStack(spacing: 4) {
                            Circle()
                                .fill(confidenceColor(suggestion.confidence))
                                .frame(width: 6, height: 6)
                            Text("\(Int(suggestion.confidence * 100))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Suggestion text with better formatting
                    Text(suggestion.suggestedText)
                        .font(.system(.callout, design: .rounded))
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Reason with subtle styling
                    if !suggestion.reason.isEmpty {
                        Text(suggestion.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                            .lineLimit(2)
                    }
                }
            }

            // Action button with keyboard shortcut hint
            HStack {
                Spacer()
                Button(action: onApply) {
                    HStack(spacing: 4) {
                        Text("Apply")
                        if index <= 9 {
                            Text("⌘\(index)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var backgroundColor: Color {
        if isSelected {
            return .blue.opacity(0.1)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor).opacity(0.5)
        } else {
            return Color(NSColor.textBackgroundColor).opacity(0.8)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return .blue.opacity(0.6)
        } else if isHovered {
            return .gray.opacity(0.4)
        } else {
            return .gray.opacity(0.2)
        }
    }

    private var borderWidth: CGFloat {
        isSelected ? 1.5 : 1.0
    }

    private func colorForSuggestionType(_ type: SuggestionType) -> Color {
        switch type {
        case .grammar: return .red
        case .style: return .blue
        case .clarity: return .green
        case .tone: return .purple
        case .spelling: return .orange
        case .conciseness: return .mint
        }
    }

    private func confidenceColor(_ confidence: Double) -> Color {
        if confidence >= 0.8 { return .green }
        else if confidence >= 0.6 { return .orange }
        else { return .red }
    }
}

extension Notification.Name {
    static let hideSuggestionOverlay = Notification.Name("hideSuggestionOverlay")
    static let applySuggestionFromOverlay = Notification.Name("applySuggestionFromOverlay")
}

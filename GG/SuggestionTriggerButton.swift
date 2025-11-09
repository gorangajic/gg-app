//
//  SuggestionTriggerButton.swift
//  GG
//
//  Created by TypeWise AI
//  Manual Suggestion Trigger Button
//

import SwiftUI
import Cocoa

class SuggestionTriggerButton: NSPanel {
    private var hostingView: NSHostingView<SuggestionButtonView>?
    private weak var suggestionDelegate: SuggestionTriggerDelegate?

    // Track text field position for smart positioning
    private var lastTextFieldPosition: NSPoint = NSPoint.zero
    private var lastTextFieldSize: NSSize = NSSize.zero

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 120, height: 40),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        setupButton()
    }

    private func setupButton() {
        // Configure window properties for a floating button
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        animationBehavior = .alertPanel

        // Don't steal focus but can receive clicks
        hidesOnDeactivate = false
        ignoresMouseEvents = false

        // Create the button view
        let buttonView = SuggestionButtonView { [weak self] in
            self?.triggerSuggestion()
        }
        hostingView = NSHostingView(rootView: buttonView)
        contentView = hostingView

        // Initially hidden
        orderOut(nil)
    }

    override var canBecomeKey: Bool {
        return false // Don't steal keyboard focus
    }

    override var canBecomeMain: Bool {
        return false
    }

    func setDelegate(_ delegate: SuggestionTriggerDelegate) {
        self.suggestionDelegate = delegate
    }

    func showNear(textField position: NSPoint, size: NSSize) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.lastTextFieldPosition = position
            self.lastTextFieldSize = size

            // Calculate optimal button position
            let buttonPosition = self.calculateButtonPosition(textFieldPosition: position, textFieldSize: size)

            // Position and show the button
            self.setFrame(NSRect(origin: buttonPosition, size: NSSize(width: 120, height: 40)), display: true)

            // Show with fade animation
            self.alphaValue = 0
            self.orderFront(nil)

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                self.animator().alphaValue = 1.0
            }
        }
    }

    func hideButton() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                self.animator().alphaValue = 0.0
            }) {
                self.orderOut(nil)
            }
        }
    }

    private func calculateButtonPosition(textFieldPosition: NSPoint, textFieldSize: NSSize) -> NSPoint {
        guard let screen = NSScreen.main else { return textFieldPosition }

        let screenFrame = screen.visibleFrame
        let buttonSize = NSSize(width: 120, height: 40)
        let margin: CGFloat = 10

        // Preferred position: to the right of the text field, vertically centered
        var x = textFieldPosition.x + textFieldSize.width + margin
        var y = textFieldPosition.y + (textFieldSize.height - buttonSize.height) / 2

        // Adjust for right screen boundary - move to left side if needed
        if x + buttonSize.width + margin > screenFrame.maxX {
            x = textFieldPosition.x - buttonSize.width - margin
        }

        // Adjust for left screen boundary
        if x < screenFrame.minX + margin {
            x = screenFrame.minX + margin
        }

        // Adjust for vertical boundaries
        if y < screenFrame.minY + margin {
            y = screenFrame.minY + margin
        } else if y + buttonSize.height > screenFrame.maxY - margin {
            y = screenFrame.maxY - buttonSize.height - margin
        }

        return NSPoint(x: x, y: y)
    }

    private func triggerSuggestion() {
        suggestionDelegate?.suggestionTriggerButtonPressed()
        hideButton() // Hide after triggering
    }
}

struct SuggestionButtonView: View {
    let onTrigger: () -> Void
    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTrigger) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .medium))

                Text("AI Suggest")
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isPressed ? .white : (isHovered ? .blue : .primary))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor)
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .pressAction {
            isPressed = true
        } onRelease: {
            isPressed = false
        }
    }

    private var backgroundColor: Color {
        if isPressed {
            return .blue
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor).opacity(0.9)
        } else {
            return Color(NSColor.windowBackgroundColor).opacity(0.95)
        }
    }
}

// Custom button style for press detection
struct PressableButtonStyle: ButtonStyle {
    let onPress: () -> Void
    let onRelease: () -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    onPress()
                } else {
                    onRelease()
                }
            }
    }
}

extension View {
    func pressAction(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.buttonStyle(PressableButtonStyle(onPress: onPress, onRelease: onRelease))
    }
}

protocol SuggestionTriggerDelegate: AnyObject {
    func suggestionTriggerButtonPressed()
}

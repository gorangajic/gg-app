//
//  KeyboardMonitor.swift
//  GG
//
//  Created by TypeWise AI
//

import Foundation
import Carbon
import Cocoa

class KeyboardMonitor: ObservableObject {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // Text buffering with size limits
    @Published var currentText: String = ""
    @Published var isMonitoring: Bool = false
    private var textBuffer: String = "" {
        didSet {
            // Limit buffer size to prevent memory issues
            if textBuffer.count > maxBufferSize {
                let startIndex = textBuffer.index(textBuffer.endIndex, offsetBy: -maxBufferSize + 100)
                textBuffer = String(textBuffer[startIndex...])
            }
        }
    }
    private var lastKeystrokeTime: Date = Date()
    private let suggestionDelay: TimeInterval = 1.5 // Delay before triggering suggestions
    private var suggestionTimer: Timer?

    // Memory management
    private let maxBufferSize = 1000 // Maximum characters in buffer
    private let maxTextLength = 500 // Maximum text length for AI processing

    // Trigger conditions
    private let sentenceEndMarkers: Set<Character> = [".", "!", "?"]
    private let wordSeparators: Set<Character> = [" ", "\n", "\t"]

    // Delegates for callbacks
    weak var delegate: KeyboardMonitorDelegate?

    init() {
        checkAccessibilityPermissions()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard checkAccessibilityPermissions() else {
            print("❌ Accessibility permissions not granted")
            DispatchQueue.main.async {
                self.isMonitoring = false
            }
            return
        }

        guard eventTap == nil else {
            print("⚠️ Keyboard monitoring already active")
            return
        }

        // Create event tap for key down events
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
                return monitor.handleKeyEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )

        guard let eventTap = eventTap else {
            print("❌ Failed to create event tap")
            DispatchQueue.main.async {
                self.isMonitoring = false
            }
            return
        }

        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)

        DispatchQueue.main.async {
            self.isMonitoring = true
        }

        print("✅ Keyboard monitoring started")
    }

    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.eventTap = nil
            self.runLoopSource = nil
        }

        suggestionTimer?.invalidate()
        suggestionTimer = nil

        DispatchQueue.main.async {
            self.isMonitoring = false
        }

        print("⏹️ Keyboard monitoring stopped")
    }

    func clearBuffer() {
        textBuffer = ""
        DispatchQueue.main.async {
            self.currentText = ""
        }
    }

    // MARK: - Private Methods

    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Handle special keys
        switch keyCode {
        case 51: // Delete key
            handleDeleteKey()
        case 36, 76: // Return/Enter keys
            handleReturnKey()
        case 49: // Space key
            handleSpaceKey()
        default:
            if let character = getCharacterFromKeyCode(keyCode, event: event) {
                handleCharacterInput(character)
            }
        }

        // Update timing
        lastKeystrokeTime = Date()

        // Schedule suggestion check
        scheduleIntelligentSuggestion()

        return Unmanaged.passUnretained(event)
    }

    private func getCharacterFromKeyCode(_ keyCode: Int64, event: CGEvent) -> Character? {
        // First try the standard UCKeyTranslate method
        if let character = getCharacterFromUCKeyTranslate(keyCode, event: event) {
            return character
        }

        // Fallback to hardcoded mapping with modifier support
        return getCharacterWithModifiers(keyCode, event: event)
    }

    private func getCharacterFromUCKeyTranslate(_ keyCode: Int64, event: CGEvent) -> Character? {
        let maxStringLength = 4
        var actualStringLength = 0
        var unicodeString = [UniChar](repeating: 0, count: maxStringLength)

        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        guard let keyLayoutPtr = layoutData else {
            return nil
        }

        let keyLayout = unsafeBitCast(keyLayoutPtr, to: UnsafePointer<UCKeyboardLayout>.self)

        // Better modifier key handling
        var modifierKeyState: UInt32 = 0
        let flags = event.flags

        if flags.contains(.maskShift) {
            modifierKeyState |= UInt32(shiftKey >> 8)
        }
        if flags.contains(.maskControl) {
            modifierKeyState |= UInt32(controlKey >> 8)
        }
        if flags.contains(.maskAlternate) {
            modifierKeyState |= UInt32(optionKey >> 8)
        }
        if flags.contains(.maskCommand) {
            modifierKeyState |= UInt32(cmdKey >> 8)
        }

        var deadKeyState: UInt32 = 0

        let status = UCKeyTranslate(
            keyLayout,
            UInt16(keyCode),
            UInt16(kUCKeyActionDisplay),
            modifierKeyState,
            UInt32(LMGetKbdType()),
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maxStringLength,
            &actualStringLength,
            &unicodeString
        )

        guard status == noErr, actualStringLength > 0 else {
            return nil
        }

        let string = String(utf16CodeUnits: unicodeString, count: actualStringLength)
        return string.first
    }

    private func getCharacterFromFallbackMapping(_ keyCode: Int64) -> Character? {
        // Common QWERTY keyboard mapping for US layout
        let keyMapping: [Int64: Character] = [
            0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
            11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2",
            20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
            29: "0", 30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
            39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "n", 46: "m", 47: ".",
            50: "`"
        ]

        return keyMapping[keyCode]
    }

    private func getCharacterWithModifiers(_ keyCode: Int64, event: CGEvent) -> Character? {
        let flags = event.flags
        let isShiftPressed = flags.contains(.maskShift)

        // Handle shifted characters
        if isShiftPressed {
            let shiftedMapping: [Int64: Character] = [
                18: "!", 19: "@", 20: "#", 21: "$", 23: "%", 22: "^", 26: "&", 28: "*", 25: "(", 29: ")",
                27: "_", 24: "+", 33: "{", 30: "}", 42: "|", 41: ":", 39: "\"", 43: "<", 47: ">", 44: "?", 50: "~"
            ]

            if let character = shiftedMapping[keyCode] {
                return character
            }

            // For letters, convert to uppercase
            if let baseChar = getCharacterFromFallbackMapping(keyCode), baseChar.isLetter {
                return Character(baseChar.uppercased())
            }
        }

        // Fall back to normal mapping
        return getCharacterFromFallbackMapping(keyCode)
    }

    private func handleCharacterInput(_ character: Character) {
        textBuffer.append(character)
        updateCurrentText()

        // Check for immediate triggers (sentence endings)
        if sentenceEndMarkers.contains(character) {
            triggerSuggestionAfterDelay(immediate: false)
        }
    }

    private func handleDeleteKey() {
        if !textBuffer.isEmpty {
            textBuffer.removeLast()
            updateCurrentText()
        }
    }

    private func handleReturnKey() {
        textBuffer.append("\n")
        updateCurrentText()
        triggerSuggestionAfterDelay(immediate: false)
    }

    private func handleSpaceKey() {
        textBuffer.append(" ")
        updateCurrentText()
    }

    private func updateCurrentText() {
        DispatchQueue.main.async {
            self.currentText = self.textBuffer
        }
    }

    private func scheduleIntelligentSuggestion() {
        // Cancel existing timer
        suggestionTimer?.invalidate()

        // Schedule new timer for pause detection
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: suggestionDelay, repeats: false) { [weak self] _ in
            self?.checkForSuggestionTrigger()
        }
    }

    private func triggerSuggestionAfterDelay(immediate: Bool) {
        let delay = immediate ? 0.1 : 0.5

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.triggerSuggestion()
        }
    }

    private func checkForSuggestionTrigger() {
        let timeSinceLastKeystroke = Date().timeIntervalSince(lastKeystrokeTime)

        // Only trigger if there's been a sufficient pause and we have meaningful text
        if timeSinceLastKeystroke >= suggestionDelay && shouldTriggerSuggestion() {
            triggerSuggestion()
        }
    }

    private func shouldTriggerSuggestion() -> Bool {
        let trimmedText = textBuffer.trimmingCharacters(in: .whitespacesAndNewlines)

        // Don't trigger for very short text
        guard trimmedText.count >= 3 else { return false }

        // Check if we have at least one complete word
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        return words.count >= 1
    }

    private func triggerSuggestion() {
        guard shouldTriggerSuggestion() else { return }

        let contextText = getRecentContext()

        // Notify delegate
        DispatchQueue.main.async {
            self.delegate?.keyboardMonitor(self, didTriggerSuggestion: contextText)
        }
    }

    private func getRecentContext() -> String {
        // Get the last few sentences or words for context
        let words = textBuffer.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }

        // Return last 20 words or all if less
        let contextWords = Array(words.suffix(20))
        return contextWords.joined(separator: " ")
    }

    private func checkAccessibilityPermissions() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !accessEnabled {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "TypeWise AI needs accessibility permission to monitor keystrokes. Please grant permission in System Preferences > Security & Privacy > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Preferences")
                alert.addButton(withTitle: "Cancel")

                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
            }
        }

        return accessEnabled
    }
}

// MARK: - Delegate Protocol

protocol KeyboardMonitorDelegate: AnyObject {
    func keyboardMonitor(_ monitor: KeyboardMonitor, didTriggerSuggestion text: String)
}

// MARK: - Extensions

extension KeyboardMonitor {
    var bufferWordCount: Int {
        return textBuffer.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    var bufferCharacterCount: Int {
        return textBuffer.count
    }
}

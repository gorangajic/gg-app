//
//  TextFieldReader.swift
//  GG
//
//  Created by TypeWise AI
//  Module 2: Focused Text Field Reader
//

import Foundation
import ApplicationServices
import Cocoa

// MARK: - Text Field Reader Delegate Protocol

protocol TextFieldReaderDelegate: AnyObject {
    func textFieldReader(_ reader: TextFieldReader, didDetectTextChange text: String, in element: AXUIElement)
    func textFieldReader(_ reader: TextFieldReader, didLoseFocus previousText: String)
}

// MARK: - Text Field Reader Class

class TextFieldReader: ObservableObject {

    // MARK: - Published Properties
    @Published var isActive: Bool = false
    @Published var currentText: String = ""
    @Published var focusedAppName: String = ""

    // MARK: - Private Properties
    private var focusedElement: AXUIElement?
    private var currentApp: NSRunningApplication?
    private var observer: AXObserver?
    private var monitoringTimer: Timer?

    // Delegate for callbacks
    weak var delegate: TextFieldReaderDelegate?

    // MARK: - Initialization

    init() {
        checkAccessibilityPermissions()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard checkAccessibilityPermissions() else {
            print("❌ TextFieldReader: Accessibility permissions not granted")
            return
        }

        print("🔍 TextFieldReader: Starting text field monitoring...")

        // Start periodic focus checking
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkFocusedTextField()
        }

        DispatchQueue.main.async {
            self.isActive = true
        }

        print("✅ TextFieldReader: Monitoring started")
    }

    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil

        if let observer = observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
            self.observer = nil
        }

        focusedElement = nil
        currentApp = nil

        DispatchQueue.main.async {
            self.isActive = false
            self.currentText = ""
            self.focusedAppName = ""
        }

        print("⏹️ TextFieldReader: Monitoring stopped")
    }

    func getCurrentText() -> String? {
        guard let element = focusedElement else {
            return nil
        }

        return extractTextFromElement(element)
    }

    func insertText(_ text: String, at position: Int? = nil) -> Bool {
        guard let element = focusedElement else {
            print("❌ No focused element to insert text into")
            return false
        }

        return injectTextIntoElement(element, text: text, at: position)
    }

    func replaceCurrentText(with newText: String) -> Bool {
        guard let element = focusedElement else {
            print("❌ No focused element to replace text in")
            return false
        }

        return replaceTextInElement(element, with: newText)
    }

    // MARK: - Private Methods

    private func checkAccessibilityPermissions() -> Bool {
        // Check if we have accessibility permissions
        let checkOptionPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [checkOptionPrompt: true] as CFDictionary
        let isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options)

        if !isAccessibilityEnabled {
            DispatchQueue.main.async {
                self.showAccessibilityAlert()
            }
        }

        return isAccessibilityEnabled
    }

    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        TypeWise AI needs accessibility permissions to read text from other applications.

        Steps to enable:
        1. System Preferences → Security & Privacy → Privacy
        2. Select "Accessibility" from the left panel
        3. Click the lock to make changes
        4. Add or check "TypeWise AI" in the list

        The app will work properly after you grant these permissions.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Preferences to Privacy & Security
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    private func checkFocusedTextField() {
        // Get the currently focused application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            resetFocus()
            return
        }

        // Update app name if changed
        if currentApp?.processIdentifier != frontmostApp.processIdentifier {
            currentApp = frontmostApp
            DispatchQueue.main.async {
                self.focusedAppName = frontmostApp.localizedName ?? "Unknown App"
            }
            print("🎯 TextFieldReader: Switched to app: \(focusedAppName)")
        }

        // Get the accessibility element for the app
        let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)

        // Try to get the focused element
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard result == .success, let element = focusedElement else {
            resetFocus()
            return
        }

        let axElement = element as! AXUIElement

        // Check if this is a text field
        if isTextInputElement(axElement) {
            handleNewFocusedElement(axElement)
        } else {
            resetFocus()
        }
    }

    private func isTextInputElement(_ element: AXUIElement) -> Bool {
        // Check role
        var roleValue: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)

        if roleResult == .success, let role = roleValue as? String {
            // Use string literals for better compatibility across macOS versions
            let textInputRoles = [
                "AXTextField",
                "AXTextArea",
                "AXComboBox",
                "AXSearchField",
                "AXSecureTextField"
            ]

            if textInputRoles.contains(role) {
                return true
            }
        }

        // Check subrole for rich text editors and web content
        var subRoleValue: CFTypeRef?
        let subRoleResult = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subRoleValue)

        if subRoleResult == .success, let subRole = subRoleValue as? String {
            let textSubRoles = [
                "AXStandardText",
                "AXSearchText",
                "AXSecureText"
            ]

            if textSubRoles.contains(subRole) || subRole.contains("Text") {
                return true
            }
        }

        // Check if element has editable text value
        var editableValue: CFTypeRef?
        let editableResult = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &editableValue)

        if editableResult == .success {
            // Additional check: see if the element is actually editable
            var focusableValue: CFTypeRef?
            let focusableResult = AXUIElementCopyAttributeValue(element, kAXFocusedAttribute as CFString, &focusableValue)
            return focusableResult == .success
        }

        return false
    }

    private func handleNewFocusedElement(_ element: AXUIElement) {
        // If this is the same element, just update text
        if let currentElement = focusedElement, CFEqual(currentElement, element) {
            updateCurrentText(from: element)
            return
        }

        // This is a new element
        focusedElement = element
        updateCurrentText(from: element)

        // Set up observer for text changes
        setupElementObserver(element)

        print("🎯 TextFieldReader: New text field focused")
    }

    private func updateCurrentText(from element: AXUIElement) {
        let text = extractTextFromElement(element) ?? ""

        DispatchQueue.main.async {
            if self.currentText != text {
                self.currentText = text
                self.delegate?.textFieldReader(self, didDetectTextChange: text, in: element)
            }
        }
    }

    private func resetFocus() {
        if focusedElement != nil {
            let previousText = currentText

            focusedElement = nil

            DispatchQueue.main.async {
                self.currentText = ""
                if !previousText.isEmpty {
                    self.delegate?.textFieldReader(self, didLoseFocus: previousText)
                }
            }
        }
    }

    private func setupElementObserver(_ element: AXUIElement) {
        // Remove existing observer
        if let observer = observer {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
        }

        // Create new observer
        guard let app = currentApp else { return }

        var newObserver: AXObserver?
        let result = AXObserverCreate(app.processIdentifier, { observer, element, notification, userData in
            let reader = Unmanaged<TextFieldReader>.fromOpaque(userData!).takeUnretainedValue()
            reader.handleElementNotification(element: element, notification: notification)
        }, &newObserver)

        guard result == .success, let observer = newObserver else {
            print("❌ Failed to create AX observer")
            return
        }

        self.observer = observer

        // Add notification for value changes
        AXObserverAddNotification(observer, element, kAXValueChangedNotification as CFString,
                                  UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))

        // Add to run loop
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    private func handleElementNotification(element: AXUIElement, notification: CFString) {
        let notificationName = notification as String

        switch notificationName {
        case kAXValueChangedNotification:
            updateCurrentText(from: element)
        default:
            break
        }
    }

    private func extractTextFromElement(_ element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value)

        guard result == .success else {
            return nil
        }

        if let stringValue = value as? String {
            return stringValue
        } else if let attributedString = value as? NSAttributedString {
            return attributedString.string
        }

        return nil
    }

    private func injectTextIntoElement(_ element: AXUIElement, text: String, at position: Int?) -> Bool {
        // First, get current text to determine insertion point
        guard let currentText = extractTextFromElement(element) else {
            return false
        }

        let insertPosition = position ?? currentText.count
        let beforeText = String(currentText.prefix(insertPosition))
        let afterText = String(currentText.dropFirst(insertPosition))
        let newText = beforeText + text + afterText

        return replaceTextInElement(element, with: newText)
    }

    private func replaceTextInElement(_ element: AXUIElement, with newText: String) -> Bool {
        // Try setting the value directly
        let result = AXUIElementSetAttributeValue(element, kAXValueAttribute as CFString, newText as CFString)

        if result == .success {
            print("✅ Successfully replaced text in element")
            return true
        } else {
            print("❌ Failed to replace text in element: \(result)")
            return false
        }
    }
}

// MARK: - Extensions

extension TextFieldReader {

    /// Get detailed information about the currently focused element
    func getFocusedElementInfo() -> [String: Any]? {
        guard let element = focusedElement else {
            return nil
        }

        var info: [String: Any] = [:]

        // Role
        var roleValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success,
           let role = roleValue as? String {
            info["role"] = role
        }

        // Title
        var titleValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue) == .success,
           let title = titleValue as? String {
            info["title"] = title
        }

        // Help text
        var helpValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXHelpAttribute as CFString, &helpValue) == .success,
           let help = helpValue as? String {
            info["help"] = help
        }

        // Position
        var positionValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue) == .success,
           let position = positionValue {
            info["position"] = position
        }

        // Size
        var sizeValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue) == .success,
           let size = sizeValue {
            info["size"] = size
        }

        return info
    }
}

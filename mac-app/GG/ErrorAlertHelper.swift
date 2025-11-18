//
//  ErrorAlertHelper.swift
//  GG
//
//  User-friendly error alert handler
//

import AppKit
import Foundation

class ErrorAlertHelper {

    /// Show a user-friendly error alert with recovery suggestions
    static func showError(_ error: Error, title: String = "Something Went Wrong") {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = title

            // Get user-friendly error description
            if let localizedError = error as? LocalizedError {
                alert.informativeText = localizedError.errorDescription ?? error.localizedDescription

                // Add recovery suggestion if available
                if let suggestion = localizedError.recoverySuggestion {
                    alert.informativeText += "\n\n💡 \(suggestion)"
                }
            } else {
                alert.informativeText = error.localizedDescription
            }

            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    /// Show an error with a retry option
    static func showErrorWithRetry(_ error: Error, title: String = "Request Failed", retryAction: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = title

            if let localizedError = error as? LocalizedError {
                alert.informativeText = localizedError.errorDescription ?? error.localizedDescription

                if let suggestion = localizedError.recoverySuggestion {
                    alert.informativeText += "\n\n💡 \(suggestion)"
                }
            } else {
                alert.informativeText = error.localizedDescription
            }

            alert.addButton(withTitle: "Retry")
            alert.addButton(withTitle: "Cancel")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                retryAction()
            }
        }
    }

    /// Show authentication required error
    static func showAuthenticationRequired(openAuthAction: @escaping () -> Void) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Sign In Required"
            alert.informativeText = "You need to sign in to use AI features.\n\n💡 Click 'Sign In' to authenticate with your account."
            alert.addButton(withTitle: "Sign In")
            alert.addButton(withTitle: "Later")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                openAuthAction()
            }
        }
    }

    /// Show server connection error with setup instructions
    static func showServerConnectionError() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "Cannot Connect to Server"
            alert.informativeText = """
            Unable to connect to the TypeWise AI Server.

            💡 To fix this:

            1. Make sure the server is running:
               • Open Terminal
               • Navigate to the server directory
               • Run: npm run dev

            2. Check the server URL in Settings
               • Default: http://localhost:3001

            3. Verify your internet connection
            """

            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "OK")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                // Could open settings window here
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

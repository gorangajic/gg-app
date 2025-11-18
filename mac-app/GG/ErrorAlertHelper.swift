//
//  ErrorAlertHelper.swift
//  GG
//
//  User-friendly error alert handler
//

import AppKit
import Foundation

class ErrorAlertHelper {

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
}

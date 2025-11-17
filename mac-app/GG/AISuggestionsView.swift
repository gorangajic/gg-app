//
//  AISuggestionsView.swift
//  GG
//
//  Created by TypeWise AI
//  Module 3: AI Suggestions Display
//

import SwiftUI

struct AISuggestionsView: View {
    @ObservedObject var suggestionEngine: AISuggestionEngine
    @State private var expandedSuggestions: Set<UUID> = []

    var body: some View {
        VStack(spacing: 15) {
            // Header
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)

                Text("AI Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if suggestionEngine.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if !suggestionEngine.currentSuggestions.isEmpty {
                    Button("Clear All") {
                        suggestionEngine.clearCurrentSuggestions()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }

            if suggestionEngine.currentSuggestions.isEmpty {
                // Empty state
                VStack(spacing: 10) {
                    Image(systemName: "text.quote")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text(suggestionEngine.isProcessing ? "Analyzing text..." : "No suggestions available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !suggestionEngine.isProcessing && suggestionEngine.isEnabled {
                        Text("Start typing to get AI-powered suggestions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 100)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
            } else {
                // Suggestions list
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(suggestionEngine.currentSuggestions, id: \.id) { suggestion in
                            SuggestionCard(
                                suggestion: suggestion,
                                isExpanded: expandedSuggestions.contains(suggestion.id),
                                onApply: {
                                    suggestionEngine.applySuggestion(suggestion)
                                },
                                onDismiss: {
                                    suggestionEngine.dismissSuggestion(suggestion)
                                },
                                onToggleExpanded: {
                                    toggleExpanded(suggestion.id)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func toggleExpanded(_ id: UUID) {
        if expandedSuggestions.contains(id) {
            expandedSuggestions.remove(id)
        } else {
            expandedSuggestions.insert(id)
        }
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: AISuggestion
    let isExpanded: Bool
    let onApply: () -> Void
    let onDismiss: () -> Void
    let onToggleExpanded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with type and confidence
            HStack {
                Label(suggestion.type.rawValue, systemImage: suggestionTypeIcon(suggestion.type))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(suggestionTypeColor(suggestion.type))

                Spacer()

                ConfidenceBadge(confidence: suggestion.confidence)

                Button(action: onToggleExpanded) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Suggestion preview
            VStack(alignment: .leading, spacing: 8) {
                if !suggestion.originalText.isEmpty && suggestion.originalText != suggestion.suggestedText {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Original:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(suggestion.originalText)
                            .font(.footnote)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(suggestion.suggestedText)
                        .font(.footnote)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                }
            }

            // Expanded content
            if isExpanded && !suggestion.reason.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(6)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button("Apply") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                if !isExpanded && !suggestion.reason.isEmpty {
                    Button("More Info") {
                        onToggleExpanded()
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private func suggestionTypeIcon(_ type: SuggestionType) -> String {
        switch type {
        case .grammar: return "checkmark.circle"
        case .style: return "paintbrush"
        case .clarity: return "eye"
        case .tone: return "speaker.wave.2"
        case .spelling: return "textformat.abc"
        case .conciseness: return "arrow.down.right.and.arrow.up.left"
        }
    }

    private func suggestionTypeColor(_ type: SuggestionType) -> Color {
        switch type {
        case .grammar: return .green
        case .style: return .purple
        case .clarity: return .blue
        case .tone: return .orange
        case .spelling: return .red
        case .conciseness: return .mint
        }
    }
}

// MARK: - Confidence Badge

struct ConfidenceBadge: View {
    let confidence: Double

    var body: some View {
        Text("\(Int(confidence * 100))%")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(confidenceColor.opacity(0.2))
            .foregroundColor(confidenceColor)
            .cornerRadius(12)
    }

    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    let mockSuggestions = [
        AISuggestion(
            type: .grammar,
            originalText: "Your doing great work",
            suggestedText: "You're doing great work",
            reason: "Corrected 'Your' to 'You're' - this is a contraction meaning 'You are'.",
            confidence: 0.95,
            range: nil
        ),
        AISuggestion(
            type: .style,
            originalText: "The meeting was very good",
            suggestedText: "The meeting was highly productive",
            reason: "More specific and professional language improves clarity and impact.",
            confidence: 0.82,
            range: nil
        ),
        AISuggestion(
            type: .conciseness,
            originalText: "In order to complete the task",
            suggestedText: "To complete the task",
            reason: "'In order to' is redundant. 'To' conveys the same meaning more concisely.",
            confidence: 0.88,
            range: nil
        )
    ]

    let mockService = OpenAIService(apiKey: "test")
    let mockIntegration = TextFieldIntegration(
        keyboardMonitor: KeyboardMonitor(),
        textFieldReader: TextFieldReader()
    )
    let mockEngine = AISuggestionEngine(
        aiService: mockService,
        textFieldIntegration: mockIntegration
    )

    // Set mock suggestions
    mockEngine.currentSuggestions = mockSuggestions

    return AISuggestionsView(suggestionEngine: mockEngine)
        .frame(width: 400, height: 500)
}

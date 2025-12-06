import SwiftUI
import Combine

/// Protocol that all text-based tool ViewModels must conform to
protocol TextToolViewModel: ObservableObject {
    var input: String { get set }
    var output: String { get }
    var errorMessage: String? { get }
    var isValid: Bool { get }
    var outputLanguage: CodeLanguage { get }
    var tool: Tool { get }

    func process()
    func clear()
    func copyOutput()
    func loadLastInput()
    func saveLastInput()
}

// Default implementation for copyOutput to avoid boilerplate
extension TextToolViewModel {
    func copyOutput() {
        guard !output.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }

    var inputCharCount: Int { input.count }
    var outputCharCount: Int { output.count }

    var outputLanguage: CodeLanguage { .plaintext }

    @MainActor
    func loadLastInput() {
        if let lastInput = HistoryManager.shared.getLastInput(for: tool), input.isEmpty {
            input = lastInput
        }
    }

    @MainActor
    func saveLastInput() {
        HistoryManager.shared.saveLastInput(input, for: tool)
    }
}

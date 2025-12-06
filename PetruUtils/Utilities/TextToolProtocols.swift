import SwiftUI
import Combine

/// Protocol that all text-based tool ViewModels must conform to
protocol TextToolViewModel: ObservableObject {
    var input: String { get set }
    var output: String { get }
    var errorMessage: String? { get }
    var isValid: Bool { get }
    
    func process()
    func clear()
    func copyOutput()
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
}

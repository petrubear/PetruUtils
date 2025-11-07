import SwiftUI
import AppKit

/// A TextEditor wrapper that properly handles keyboard shortcuts including paste (⌘V)
/// 
/// SwiftUI's native TextEditor doesn't always properly handle paste shortcuts on macOS.
/// This component wraps NSTextView to ensure all standard macOS text editing shortcuts work.
///
/// Supports:
/// - ⌘V (Paste)
/// - ⌘C (Copy)
/// - ⌘X (Cut)
/// - ⌘Z (Undo)
/// - ⌘⇧Z (Redo)
/// - All standard text selection and editing shortcuts
struct FocusableTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.font = font
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        if textView.string != text {
            textView.string = text
        }
        textView.font = font
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FocusableTextEditor
        
        init(_ parent: FocusableTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

/// A TextField wrapper that properly handles keyboard shortcuts including paste (⌘V)
struct FocusableTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: NSFont = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    
    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.font = font
        textField.placeholderString = placeholder
        textField.isBordered = false
        textField.backgroundColor = .clear
        textField.focusRingType = .none
        
        return textField
    }
    
    func updateNSView(_ textField: NSTextField, context: Context) {
        if textField.stringValue != text {
            textField.stringValue = text
        }
        textField.font = font
        textField.placeholderString = placeholder
    }
    
    func makeCoordinator() -> TextFieldCoordinator {
        TextFieldCoordinator(self)
    }
    
    class TextFieldCoordinator: NSObject, NSTextFieldDelegate {
        var parent: FocusableTextField
        
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }
        
        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = "Test text\nPaste works with ⌘V"
        @State private var fieldText = "test"
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("FocusableTextEditor")
                        .font(.headline)
                    
                    FocusableTextEditor(text: $text)
                        .frame(height: 200)
                        .border(Color.gray)
                    
                    Text("Current text: \(text)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack(alignment: .leading) {
                    Text("FocusableTextField")
                        .font(.headline)
                    
                    FocusableTextField(text: $fieldText, placeholder: "Enter text...")
                        .textFieldStyle(.roundedBorder)
                    
                    Text("Current: \(fieldText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}

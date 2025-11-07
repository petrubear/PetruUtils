import SwiftUI
import AppKit

/// A simple code block view for displaying plain text
struct CodeBlock: View {
    let text: String
    
    var body: some View {
        CodeTextView(text: text)
            .frame(minHeight: 100)
            .background(.background)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            .cornerRadius(8)
    }
}

/// NSTextView-based code display that guarantees top-left alignment
struct CodeTextView: NSViewRepresentable {
    let text: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .code
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.autoresizingMask = [.width]
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        textView.string = text.isEmpty ? "—" : text
        textView.font = .code
    }
}

/// A code block view with syntax highlighting support
struct SyntaxHighlightedCodeBlock: View {
    let text: String
    let language: SyntaxLanguage
    
    var body: some View {
        if text.isEmpty {
            CodeTextView(text: "—")
                .frame(minHeight: 100)
                .background(.background)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .cornerRadius(8)
        } else {
            CodeTextView(text: text)
                .frame(minHeight: 100)
                .background(.background)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .cornerRadius(8)
        }
    }
}

#Preview("Plain Code Block") {
    VStack {
        Text("Plain Text").font(.headline)
        CodeBlock(text: """
            eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
            """)
    }
    .padding()
}

#Preview("JSON Highlighted") {
    VStack {
        Text("JSON Syntax Highlighting").font(.headline)
        SyntaxHighlightedCodeBlock(
            text: """
            {
              "alg": "HS256",
              "typ": "JWT",
              "number": 123,
              "boolean": true,
              "null": null
            }
            """,
            language: .json
        )
    }
    .padding()
}

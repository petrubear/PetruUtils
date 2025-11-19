import SwiftUI
import AppKit

/// A simple code block view for displaying plain text
struct CodeBlock: View {
    let text: String
    let language: CodeLanguage?
    
    init(text: String, language: CodeLanguage? = nil) {
        self.text = text
        self.language = language
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CodeTextView(text: text, language: language)
        }
        .frame(minHeight: 100)
        .background(.background)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        .cornerRadius(8)
    }
}

/// Supported code languages for syntax highlighting
enum CodeLanguage: String {
    case json
    case javascript
    case swift
    case python
    case plaintext
}

/// NSTextView-based code display with syntax highlighting
struct CodeTextView: NSViewRepresentable {
    let text: String
    let language: CodeLanguage?
    
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
        let displayText = text.isEmpty ? "—" : text
        
        // Apply syntax highlighting if language is specified
        if let language = language, !text.isEmpty {
            textView.textStorage?.setAttributedString(highlightCode(displayText, language: language))
        } else {
            textView.string = displayText
        }
        
        textView.font = .code
    }
    
    private func highlightCode(_ code: String, language: CodeLanguage) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: code)
        attributed.addAttribute(.font, value: NSFont.code, range: NSRange(location: 0, length: attributed.length))
        
        // Dracula theme colors
        let backgroundColor = NSColor.clear
        let foregroundColor = NSColor(red: 0.95, green: 0.96, blue: 0.97, alpha: 1.0) // #f8f8f2
        let keywordColor = NSColor(red: 1.0, green: 0.47, blue: 0.78, alpha: 1.0)      // #ff79c6 (pink)
        let stringColor = NSColor(red: 0.95, green: 0.98, blue: 0.55, alpha: 1.0)     // #f1fa8c (yellow)
        let numberColor = NSColor(red: 0.74, green: 0.58, blue: 1.0, alpha: 1.0)      // #bd93f9 (purple)
        let commentColor = NSColor(red: 0.38, green: 0.47, blue: 0.64, alpha: 1.0)    // #6272a4 (comment)
        
        attributed.addAttribute(.foregroundColor, value: foregroundColor, range: NSRange(location: 0, length: attributed.length))
        
        if language == .json {
            highlightJSON(attributed, keyColor: keywordColor, stringColor: stringColor, numberColor: numberColor)
        }
        
        return attributed
    }
    
    private func highlightJSON(_ text: NSMutableAttributedString, keyColor: NSColor, stringColor: NSColor, numberColor: NSColor) {
        let string = text.string
        
        // Highlight keys (strings before colons)
        if let regex = try? NSRegularExpression(pattern: #""[^"]*"\s*:"#) {
            let matches = regex.matches(in: string, range: NSRange(location: 0, length: string.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: keyColor, range: match.range)
            }
        }
        
        // Highlight string values
        if let regex = try? NSRegularExpression(pattern: #":\s*"[^"]*""#) {
            let matches = regex.matches(in: string, range: NSRange(location: 0, length: string.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: stringColor, range: match.range)
            }
        }
        
        // Highlight numbers
        if let regex = try? NSRegularExpression(pattern: #"-?\d+\.?\d*([eE][+-]?\d+)?"#) {
            let matches = regex.matches(in: string, range: NSRange(location: 0, length: string.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: numberColor, range: match.range)
            }
        }
        
        // Highlight booleans
        if let regex = try? NSRegularExpression(pattern: #"\b(true|false|null)\b"#) {
            let matches = regex.matches(in: string, range: NSRange(location: 0, length: string.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: numberColor, range: match.range)
            }
        }
    }
}

/// A code block view with syntax highlighting support
struct SyntaxHighlightedCodeBlock: View {
    let text: String
    let language: SyntaxLanguage
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            CodeBlock(text: text, language: mapLanguage(language))
        }
    }
    
    private func mapLanguage(_ lang: SyntaxLanguage) -> CodeLanguage? {
        switch lang {
        case .json: return .json
        case .plain: return .plaintext
        case .xml, .html, .css, .sql, .javascript: return .plaintext
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

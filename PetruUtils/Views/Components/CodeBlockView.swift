import SwiftUI

/// A simple code block view for displaying plain text
struct CodeBlock: View {
    let text: String
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                Text(text.isEmpty ? "—" : text)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(minWidth: geometry.size.width, alignment: .topLeading)
                    .padding(8)
            }
        }
        .frame(minHeight: 100)
        .background(.background)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        .cornerRadius(8)
    }
}

/// A code block view with syntax highlighting support
struct SyntaxHighlightedCodeBlock: View {
    let text: String
    let language: SyntaxLanguage
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                if text.isEmpty {
                    Text("—")
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(minWidth: geometry.size.width, alignment: .topLeading)
                        .padding(8)
                } else {
                    SyntaxHighlightedText(text: text, language: language)
                        .frame(minWidth: geometry.size.width, alignment: .topLeading)
                        .padding(8)
                }
            }
        }
        .frame(minHeight: 100)
        .background(.background)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        .cornerRadius(8)
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

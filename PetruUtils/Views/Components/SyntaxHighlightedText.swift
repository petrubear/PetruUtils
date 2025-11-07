import SwiftUI

/// A view that displays text with syntax highlighting
struct SyntaxHighlightedText: View {
    let text: String
    let language: SyntaxLanguage
    
    var body: some View {
        Text(highlightedText())
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func highlightedText() -> AttributedString {
        switch language {
        case .json:
            return highlightJSON(text)
        case .plain:
            return AttributedString(text)
        }
    }
    
    private func highlightJSON(_ json: String) -> AttributedString {
        var attributed = AttributedString(json)
        
        // Define colors for different JSON elements (VS Code-like theme)
        let keyColor = Color(red: 0.6, green: 0.8, blue: 1.0) // Light blue for keys
        let stringColor = Color(red: 0.8, green: 0.9, blue: 0.7) // Light green for strings
        let numberColor = Color(red: 0.7, green: 0.9, blue: 0.7) // Mint green for numbers
        let booleanColor = Color(red: 0.8, green: 0.6, blue: 1.0) // Purple for booleans
        let nullColor = Color(red: 1.0, green: 0.6, blue: 0.6) // Pink for null
        let punctuationColor = Color.secondary
        
        // Pattern matching for JSON elements
        let patterns: [(regex: String, color: Color)] = [
            // Keys (strings before colons)
            (#"\"[^\"]*\"\s*:"#, keyColor),
            // String values (strings not followed by colons)
            (#":\s*\"[^\"]*\""#, stringColor),
            // Numbers
            (#"-?\d+\.?\d*([eE][+-]?\d+)?"#, numberColor),
            // Booleans
            (#"\b(true|false)\b"#, booleanColor),
            // Null
            (#"\bnull\b"#, nullColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = json as NSString
                let matches = regex.matches(in: json, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: json) {
                        let attributedRange = AttributedString.Index(range.lowerBound, within: attributed)!
                            ..< AttributedString.Index(range.upperBound, within: attributed)!
                        attributed[attributedRange].foregroundColor = color
                    }
                }
            }
        }
        
        return attributed
    }
}

enum SyntaxLanguage {
    case json
    case plain
}

// Alternative: Simple text view with better JSON display
struct JSONTextView: View {
    let jsonString: String
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            Text(jsonString)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .padding(8)
        }
        .frame(minHeight: 100)
    }
}

#Preview {
    VStack {
        SyntaxHighlightedText(
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
        .padding()
    }
}

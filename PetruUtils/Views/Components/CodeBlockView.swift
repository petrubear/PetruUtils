import SwiftUI
import AppKit

/// A simple code block view for displaying plain text with syntax highlighting
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
        .frame(minHeight: 100, maxHeight: .infinity)
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
    case xml
    case html
    case css
    case sql
    case yaml
}

/// NSTextView-based code display with syntax highlighting
struct CodeTextView: NSViewRepresentable {
    let text: String
    let language: CodeLanguage?
    
    @Environment(\.colorScheme) var colorScheme
    
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
            let attributed = NSMutableAttributedString(string: displayText)
            attributed.addAttribute(.font, value: NSFont.code, range: NSRange(location: 0, length: attributed.length))
            attributed.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributed.length))
            textView.textStorage?.setAttributedString(attributed)
        }
        
        textView.font = .code
    }
    
    private var textColor: NSColor {
        colorScheme == .dark ? NSColor(white: 0.9, alpha: 1.0) : NSColor(white: 0.1, alpha: 1.0)
    }
    
    private func highlightCode(_ code: String, language: CodeLanguage) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: code)
        attributed.addAttribute(.font, value: NSFont.code, range: NSRange(location: 0, length: attributed.length))
        attributed.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributed.length))
        
        // Common colors (adapted for Light/Dark mode)
        let isDark = colorScheme == .dark
        
        let keywordColor = isDark ? NSColor(red: 1.0, green: 0.47, blue: 0.78, alpha: 1.0) : NSColor(red: 0.8, green: 0.0, blue: 0.4, alpha: 1.0)
        let stringColor = isDark ? NSColor(red: 0.95, green: 0.98, blue: 0.55, alpha: 1.0) : NSColor(red: 0.8, green: 0.1, blue: 0.1, alpha: 1.0)
        let numberColor = isDark ? NSColor(red: 0.74, green: 0.58, blue: 1.0, alpha: 1.0) : NSColor(red: 0.4, green: 0.0, blue: 0.8, alpha: 1.0)
        let commentColor = isDark ? NSColor(red: 0.38, green: 0.47, blue: 0.64, alpha: 1.0) : NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        let tagColor = isDark ? NSColor(red: 0.33, green: 0.67, blue: 0.95, alpha: 1.0) : NSColor(red: 0.0, green: 0.4, blue: 0.7, alpha: 1.0)
        let attributeNameColor = isDark ? NSColor(red: 0.6, green: 0.8, blue: 1.0, alpha: 1.0) : NSColor(red: 0.2, green: 0.5, blue: 0.6, alpha: 1.0)
        
        switch language {
        case .json:
            highlightJSON(attributed, code: code, keyColor: keywordColor, stringColor: stringColor, numberColor: numberColor, boolColor: numberColor)
        case .xml, .html:
            highlightXMLHTML(attributed, code: code, tagColor: tagColor, attributeNameColor: attributeNameColor, attributeValueColor: stringColor, commentColor: commentColor)
        case .css:
            highlightCSS(attributed, code: code, propertyColor: keywordColor, valueColor: stringColor, commentColor: commentColor)
        case .sql:
            highlightSQL(attributed, code: code, keywordColor: keywordColor, stringColor: stringColor, numberColor: numberColor, commentColor: commentColor)
        case .javascript:
            highlightJavaScript(attributed, code: code, keywordColor: keywordColor, stringColor: stringColor, numberColor: numberColor, commentColor: commentColor)
        default:
            break
        }
        
        return attributed
    }
    
    private func highlightJSON(_ text: NSMutableAttributedString, code: String, keyColor: NSColor, stringColor: NSColor, numberColor: NSColor, boolColor: NSColor) {
        // Keys: "key":
        if let regex = try? NSRegularExpression(pattern: "\"[^\\\"]*\"\\s*:\\s*") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: keyColor, range: match.range)
            }
        }

        // String values: : "value"
        if let regex = try? NSRegularExpression(pattern: ":\\s*\"[^\\\"]*\"") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                // Color only the string portion within the match (after the colon and optional spaces)
                let range = match.range
                if let r = Range(range, in: code) {
                    let substring = String(code[r])
                    if let quoteIndex = substring.firstIndex(of: "\"") {
                        let offset = substring.distance(from: substring.startIndex, to: quoteIndex)
                        let stringRange = NSRange(location: range.location + offset, length: range.length - offset)
                        text.addAttribute(.foregroundColor, value: stringColor, range: stringRange)
                    }
                }
            }
        }

        // Numbers
        if let regex = try? NSRegularExpression(pattern: "-?\\d+\\.?\\d*([eE][+-]?\\d+)?") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: numberColor, range: match.range)
            }
        }

        // Booleans/Null
        if let regex = try? NSRegularExpression(pattern: "\\b(true|false|null)\\b") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: boolColor, range: match.range)
            }
        }
    }
    
    private func highlightXMLHTML(_ text: NSMutableAttributedString, code: String, tagColor: NSColor, attributeNameColor: NSColor, attributeValueColor: NSColor, commentColor: NSColor) {
        // Comments
        if let regex = try? NSRegularExpression(pattern: "<!--[\\s\\S]*?-->") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: commentColor, range: match.range)
            }
        }
        
        // Tags
        if let regex = try? NSRegularExpression(pattern: "</?[a-zA-Z][a-zA-Z0-9-]*") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: tagColor, range: match.range)
            }
        }
        
        // Attribute Names
        if let regex = try? NSRegularExpression(pattern: "\\s[a-zA-Z][a-zA-Z0-9-]*=") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: attributeNameColor, range: match.range)
            }
        }
        
        // Attribute Values
        if let regex = try? NSRegularExpression(pattern: "\"[^\\\"]*\"") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: attributeValueColor, range: match.range)
            }
        }
    }
    
    private func highlightCSS(_ text: NSMutableAttributedString, code: String, propertyColor: NSColor, valueColor: NSColor, commentColor: NSColor) {
        // Comments
        if let regex = try? NSRegularExpression(pattern: "/\\*[\\s\\S]*?\\*/") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: commentColor, range: match.range)
            }
        }
        
        // Properties
        if let regex = try? NSRegularExpression(pattern: "[a-zA-Z-]+\\s*:\\s*") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: propertyColor, range: match.range)
            }
        }
        
        // Values
        if let regex = try? NSRegularExpression(pattern: ":\\s*[^;{}]+") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                let range = match.range
                if let r = Range(range, in: code) {
                    let sub = String(code[r])
                    if let colonIndex = sub.firstIndex(of: ":") {
                        let offset = sub.distance(from: sub.startIndex, to: colonIndex) + 1
                        let valueRange = NSRange(location: range.location + offset, length: range.length - offset)
                        text.addAttribute(.foregroundColor, value: valueColor, range: valueRange)
                    }
                }
            }
        }
    }
    
    private func highlightSQL(_ text: NSMutableAttributedString, code: String, keywordColor: NSColor, stringColor: NSColor, numberColor: NSColor, commentColor: NSColor) {
        // Comments
        if let regex = try? NSRegularExpression(pattern: "--[^\\n]*") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: commentColor, range: match.range)
            }
        }
        
        // Strings
        if let regex = try? NSRegularExpression(pattern: "'[^']*'") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: stringColor, range: match.range)
            }
        }
        
        // Numbers
        if let regex = try? NSRegularExpression(pattern: "\\b\\d+\\.?\\d*\\b") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: numberColor, range: match.range)
            }
        }
        
        // Keywords
        if let regex = try? NSRegularExpression(pattern: "\\b(SELECT|FROM|WHERE|AND|OR|NOT|IN|LIKE|BETWEEN|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|ALTER|DROP|JOIN|LEFT|RIGHT|INNER|OUTER|ON|GROUP|BY|HAVING|ORDER|ASC|DESC|LIMIT|OFFSET|AS|NULL|IS|DISTINCT|UNION|ALL|CASE|WHEN|THEN|ELSE|END)\\b", options: .caseInsensitive) {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: keywordColor, range: match.range)
            }
        }
    }
    
    private func highlightJavaScript(_ text: NSMutableAttributedString, code: String, keywordColor: NSColor, stringColor: NSColor, numberColor: NSColor, commentColor: NSColor) {
        // Comments
        if let regex = try? NSRegularExpression(pattern: "//[^\\n]*|/\\*[\\s\\S]*?\\*/") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: commentColor, range: match.range)
            }
        }
        
        // Strings
        if let regex = try? NSRegularExpression(pattern: "'([^'\\\\]|\\\\.)*'|\"([^\"\\\\]|\\\\.)*\"|`([^`\\\\]|\\\\.)*`") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: stringColor, range: match.range)
            }
        }
        
        // Numbers
        if let regex = try? NSRegularExpression(pattern: "\\b\\d+\\.?\\d*([eE][+\\-]?\\d+)?\\b") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: numberColor, range: match.range)
            }
        }
        
        // Keywords
        if let regex = try? NSRegularExpression(pattern: "\\b(abstract|await|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|finally|for|function|if|import|in|instanceof|let|new|return|super|switch|this|throw|try|typeof|var|void|while|with|yield|async)\\b") {
            let matches = regex.matches(in: code, range: NSRange(location: 0, length: code.utf16.count))
            for match in matches {
                text.addAttribute(.foregroundColor, value: keywordColor, range: match.range)
            }
        }
    }
}


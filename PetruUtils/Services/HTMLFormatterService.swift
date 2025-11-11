import Foundation

struct HTMLFormatterService {
    enum HTMLError: LocalizedError {
        case emptyInput
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input is empty"
            }
        }
    }
    
    enum IndentStyle: String, CaseIterable {
        case twoSpaces = "2 Spaces"
        case fourSpaces = "4 Spaces"
        case tabs = "Tabs"
        
        var string: String {
            switch self {
            case .twoSpaces: return "  "
            case .fourSpaces: return "    "
            case .tabs: return "\t"
            }
        }
    }
    
    // MARK: - Format HTML
    
    func format(_ html: String, indentStyle: IndentStyle = .twoSpaces) throws -> String {
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HTMLError.emptyInput
        }
        
        let indent = indentStyle.string
        var formatted = ""
        var indentLevel = 0
        var inTag = false
        var currentTag = ""
        var tagContent = ""
        
        // Inline tags that shouldn't cause line breaks
        let inlineTags = Set(["a", "span", "strong", "em", "b", "i", "u", "code", "small", "abbr", "mark"])
        
        // Self-closing tags
        let selfClosingTags = Set(["br", "hr", "img", "input", "meta", "link", "area", "base", "col", "embed", "param", "source", "track", "wbr"])
        
        var i = html.startIndex
        var lastWasTag = false
        
        while i < html.endIndex {
            let char = html[i]
            
            if char == "<" {
                // Save any content before this tag
                if !tagContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    formatted += tagContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    tagContent = ""
                }
                
                inTag = true
                currentTag = ""
                
                // Check if it's a closing tag
                let nextIndex = html.index(after: i)
                if nextIndex < html.endIndex && html[nextIndex] == "/" {
                    indentLevel = max(0, indentLevel - 1)
                    if lastWasTag {
                        formatted += "\n" + String(repeating: indent, count: indentLevel)
                    }
                } else if !formatted.isEmpty && lastWasTag {
                    // Opening tag after another tag
                    formatted += "\n" + String(repeating: indent, count: indentLevel)
                }
                
                formatted.append(char)
                lastWasTag = false
            } else if char == ">" {
                formatted.append(char)
                inTag = false
                lastWasTag = true
                
                // Extract tag name
                let tagName = extractTagName(from: currentTag).lowercased()
                
                // Check if it's a self-closing tag or ends with /
                if currentTag.hasSuffix("/") || selfClosingTags.contains(tagName) {
                    // Self-closing, don't change indent
                } else if currentTag.hasPrefix("/") {
                    // Closing tag, already decreased indent
                } else if !inlineTags.contains(tagName) {
                    // Opening block-level tag
                    indentLevel += 1
                }
                
                currentTag = ""
            } else if inTag {
                currentTag.append(char)
                formatted.append(char)
            } else {
                // Content between tags
                if !char.isWhitespace || !tagContent.isEmpty {
                    tagContent.append(char)
                }
                if !char.isWhitespace {
                    lastWasTag = false
                }
            }
            
            i = html.index(after: i)
        }
        
        // Add any remaining content
        if !tagContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formatted += tagContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Minify HTML
    
    func minify(_ html: String) throws -> String {
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw HTMLError.emptyInput
        }
        
        var result = html
        
        // Remove comments
        result = result.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: .regularExpression)
        
        // Remove whitespace between tags
        result = result.replacingOccurrences(of: ">\\s+<", with: "><", options: .regularExpression)
        
        // Remove leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Collapse multiple spaces into one
        result = result.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        
        return result
    }
    
    // MARK: - Private Helpers
    
    private func extractTagName(from tag: String) -> String {
        let cleaned = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove leading / for closing tags
        let withoutSlash = cleaned.hasPrefix("/") ? String(cleaned.dropFirst()) : cleaned
        
        // Extract just the tag name (before space or >)
        if let spaceIndex = withoutSlash.firstIndex(where: { $0.isWhitespace }) {
            return String(withoutSlash[..<spaceIndex])
        } else if let slashIndex = withoutSlash.firstIndex(of: "/") {
            return String(withoutSlash[..<slashIndex])
        } else {
            return withoutSlash
        }
    }
}

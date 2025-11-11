import Foundation

struct CSSFormatterService {
    enum CSSError: LocalizedError {
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
    
    // MARK: - Format CSS
    
    func format(_ css: String, indentStyle: IndentStyle = .twoSpaces, sortProperties: Bool = false) throws -> String {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }
        
        let indent = indentStyle.string
        var formatted = ""
        var depth = 0
        var inSelector = true
        var currentLine = ""
        var properties: [String] = []
        
        var i = css.startIndex
        
        while i < css.endIndex {
            let char = css[i]
            
            switch char {
            case "{":
                // Opening brace - start of rule block
                formatted += currentLine.trimmingCharacters(in: .whitespacesAndNewlines) + " {\n"
                currentLine = ""
                depth += 1
                inSelector = false
                properties = []
                
            case "}":
                // Closing brace - end of rule block
                if !currentLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    properties.append(currentLine.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentLine = ""
                }
                
                // Sort properties if requested
                if sortProperties {
                    properties.sort()
                }
                
                // Add properties
                for property in properties {
                    if !property.isEmpty {
                        formatted += String(repeating: indent, count: depth) + property
                        if !property.hasSuffix(";") {
                            formatted += ";"
                        }
                        formatted += "\n"
                    }
                }
                
                depth = max(0, depth - 1)
                formatted += String(repeating: indent, count: depth) + "}\n"
                inSelector = true
                properties = []
                
            case ";":
                // End of property
                if !inSelector {
                    properties.append(currentLine.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentLine = ""
                } else {
                    currentLine.append(char)
                }
                
            case "\n", "\r":
                // Ignore newlines, we'll add our own
                break
                
            default:
                if !char.isWhitespace || !currentLine.isEmpty {
                    currentLine.append(char)
                }
            }
            
            i = css.index(after: i)
        }
        
        // Handle any remaining content
        if !currentLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formatted += currentLine.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Minify CSS
    
    func minify(_ css: String) throws -> String {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }
        
        var result = css
        
        // Remove comments
        result = result.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)
        
        // Remove all whitespace around special characters
        result = result.replacingOccurrences(of: "\\s*([{};:,])\\s*", with: "$1", options: .regularExpression)
        
        // Remove leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Collapse multiple spaces into one
        result = result.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        
        // Add space after colon for readability
        result = result.replacingOccurrences(of: ":", with: ": ", options: .literal)
        
        // Add space after comma in selectors
        result = result.replacingOccurrences(of: ",", with: ", ", options: .literal)
        
        // Remove unnecessary spaces
        result = result.replacingOccurrences(of: ": \\s+", with: ": ", options: .regularExpression)
        result = result.replacingOccurrences(of: ", \\s+", with: ", ", options: .regularExpression)
        
        return result
    }
    
    // MARK: - Validate CSS (Basic)
    
    func validate(_ css: String) -> (isValid: Bool, message: String) {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "Input is empty")
        }
        
        var braceCount = 0
        var issues: [String] = []
        
        for char in css {
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount < 0 {
                    issues.append("Mismatched closing brace")
                    break
                }
            }
        }
        
        if braceCount > 0 {
            issues.append("Missing \(braceCount) closing brace(s)")
        } else if braceCount < 0 {
            issues.append("Extra closing brace(s)")
        }
        
        if issues.isEmpty {
            return (true, "✓ Valid CSS syntax")
        } else {
            return (false, "✗ " + issues.joined(separator: ", "))
        }
    }
}

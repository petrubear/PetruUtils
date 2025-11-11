import Foundation

struct XMLFormatterService {
    enum XMLError: LocalizedError {
        case invalidXML(String)
        case emptyInput
        
        var errorDescription: String? {
            switch self {
            case .invalidXML(let message):
                return "Invalid XML: \(message)"
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
    
    struct ValidationResult {
        let isValid: Bool
        let message: String
    }
    
    // MARK: - Format XML
    
    func format(_ xml: String, indentStyle: IndentStyle = .twoSpaces) throws -> String {
        guard !xml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw XMLError.emptyInput
        }
        
        // Try to parse XML to validate it
        guard let data = xml.data(using: .utf8) else {
            throw XMLError.invalidXML("Could not encode XML string")
        }
        
        let parser = XMLParser(data: data)
        let delegate = XMLValidationDelegate()
        parser.delegate = delegate
        
        if !parser.parse() {
            if let error = parser.parserError {
                throw XMLError.invalidXML(error.localizedDescription)
            } else {
                throw XMLError.invalidXML("Failed to parse XML")
            }
        }
        
        // Format the XML
        return formatXMLString(xml, indentStyle: indentStyle)
    }
    
    // MARK: - Minify XML
    
    func minify(_ xml: String) throws -> String {
        guard !xml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw XMLError.emptyInput
        }
        
        // Validate first
        _ = try format(xml)
        
        // Remove all whitespace between tags
        var result = xml
        result = result.replacingOccurrences(of: "\\s*\\n\\s*", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: ">\\s+<", with: "><", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Validate XML
    
    func validate(_ xml: String) -> ValidationResult {
        guard !xml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ValidationResult(isValid: false, message: "Input is empty")
        }
        
        guard let data = xml.data(using: .utf8) else {
            return ValidationResult(isValid: false, message: "Could not encode XML string")
        }
        
        let parser = XMLParser(data: data)
        let delegate = XMLValidationDelegate()
        parser.delegate = delegate
        
        if parser.parse() {
            return ValidationResult(isValid: true, message: "✓ Valid XML")
        } else {
            let errorMessage = parser.parserError?.localizedDescription ?? "Unknown parsing error"
            let line = parser.lineNumber
            let column = parser.columnNumber
            return ValidationResult(
                isValid: false,
                message: "✗ Invalid XML at line \(line), column \(column): \(errorMessage)"
            )
        }
    }
    
    // MARK: - Private Helpers
    
    private func formatXMLString(_ xml: String, indentStyle: IndentStyle) -> String {
        let indent = indentStyle.string
        var formatted = ""
        var indentLevel = 0
        var inTag = false
        var tagContent = ""
        
        var i = xml.startIndex
        while i < xml.endIndex {
            let char = xml[i]
            
            if char == "<" {
                // Handle closing tags
                if !tagContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    formatted += tagContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    tagContent = ""
                }
                
                inTag = true
                
                // Check if it's a closing tag
                let nextIndex = xml.index(after: i)
                if nextIndex < xml.endIndex && xml[nextIndex] == "/" {
                    indentLevel = max(0, indentLevel - 1)
                    formatted += "\n" + String(repeating: indent, count: indentLevel)
                } else {
                    // Opening tag
                    if !formatted.isEmpty && formatted.last != "\n" {
                        formatted += "\n" + String(repeating: indent, count: indentLevel)
                    } else if formatted.isEmpty {
                        // First tag
                    } else {
                        formatted += String(repeating: indent, count: indentLevel)
                    }
                }
                
                formatted.append(char)
            } else if char == ">" {
                formatted.append(char)
                inTag = false
                
                // Check for self-closing tag or XML declaration
                let prevIndex = xml.index(before: i)
                if prevIndex >= xml.startIndex {
                    let prevChar = xml[prevIndex]
                    if prevChar == "/" || prevChar == "?" {
                        // Self-closing or declaration, don't increase indent
                    } else {
                        // Check if next char is not a closing tag
                        let nextIndex = xml.index(after: i)
                        if nextIndex < xml.endIndex {
                            let ahead = xml[nextIndex]
                            if ahead != "<" {
                                // There's content between tags
                            } else {
                                // Check if it's a closing tag
                                let afterNext = xml.index(after: nextIndex)
                                if afterNext < xml.endIndex && xml[afterNext] != "/" {
                                    indentLevel += 1
                                }
                            }
                        }
                    }
                    
                    // Increase indent for opening tags
                    if prevChar != "/" && prevChar != "?" {
                        let nextIndex = xml.index(after: i)
                        if nextIndex < xml.endIndex && xml[nextIndex] == "<" {
                            let afterNext = xml.index(after: nextIndex)
                            if afterNext < xml.endIndex && xml[afterNext] != "/" {
                                indentLevel += 1
                            }
                        } else if nextIndex < xml.endIndex && xml[nextIndex] != "<" {
                            // Content after tag
                            indentLevel += 1
                        }
                    }
                }
            } else if inTag {
                formatted.append(char)
            } else {
                // Content between tags
                if !char.isWhitespace || !tagContent.isEmpty {
                    tagContent.append(char)
                }
            }
            
            i = xml.index(after: i)
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - XML Parser Delegate

private class XMLValidationDelegate: NSObject, XMLParserDelegate {
    // Simple validation delegate that doesn't do anything special
    // Just used to validate XML structure
}

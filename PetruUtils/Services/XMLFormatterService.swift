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
        
        // Validate XML first
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
        
        // Format the XML using proper algorithm
        return formatXMLProperly(xml, indentStyle: indentStyle)
    }
    
    // MARK: - Minify XML
    
    func minify(_ xml: String) throws -> String {
        guard !xml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw XMLError.emptyInput
        }
        
        // Validate first
        _ = try format(xml)
        
        // Remove whitespace between tags while preserving text content
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
    
    private func formatXMLProperly(_ xml: String, indentStyle: IndentStyle) -> String {
        let indent = indentStyle.string
        var result: [String] = []
        var level = 0
        
        // Tokenize by tags while preserving text
        let regex = try? NSRegularExpression(pattern: "(<[^>]+>)", options: [])
        let ns = xml as NSString
        let parts = regex?.splitByMatches(in: xml) ?? [xml]
        
        for part in parts {
            let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.hasPrefix("</") {
                // Closing tag
                level = max(0, level - 1)
                result.append(String(repeating: indent, count: level) + trimmed)
            } else if trimmed.hasPrefix("<?") || trimmed.hasPrefix("<!") || trimmed.hasSuffix("/>") {
                // Declaration, comment, or self-closing
                result.append(String(repeating: indent, count: level) + trimmed)
            } else if trimmed.hasPrefix("<") {
                // Opening tag
                result.append(String(repeating: indent, count: level) + trimmed)
                level += 1
            } else {
                // Text node
                result.append(String(repeating: indent, count: level) + trimmed)
            }
        }
        
        return result.joined(separator: "\n")
    }
}

private extension NSRegularExpression {
    func splitByMatches(in string: String) -> [String] {
        let ns = string as NSString
        var lastIndex = 0
        var parts: [String] = []
        let matches = self.matches(in: string, range: NSRange(location: 0, length: ns.length))
        for match in matches {
            let range = match.range
            if range.location > lastIndex {
                parts.append(ns.substring(with: NSRange(location: lastIndex, length: range.location - lastIndex)))
            }
            parts.append(ns.substring(with: range))
            lastIndex = range.location + range.length
        }
        if lastIndex < ns.length {
            parts.append(ns.substring(with: NSRange(location: lastIndex, length: ns.length - lastIndex)))
        }
        return parts
    }
}

// MARK: - XML Parser Delegate

private class XMLValidationDelegate: NSObject, XMLParserDelegate {}

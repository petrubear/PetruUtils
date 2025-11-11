import Foundation

/// Service for formatting, minifying, and validating JSON
struct JSONFormatterService {
    
    enum JSONError: LocalizedError {
        case invalidJSON(String)
        case emptyInput
        case serializationFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON(let details): return "Invalid JSON: \(details)"
            case .emptyInput: return "Input cannot be empty."
            case .serializationFailed: return "Failed to serialize JSON."
            }
        }
    }
    
    enum IndentStyle: Int {
        case twoSpaces = 2
        case fourSpaces = 4
        case tabs = 0
        
        var description: String {
            switch self {
            case .twoSpaces: return "2 Spaces"
            case .fourSpaces: return "4 Spaces"
            case .tabs: return "Tabs"
            }
        }
    }
    
    struct ValidationResult {
        let isValid: Bool
        let error: String?
        let lineNumber: Int?
        let columnNumber: Int?
    }
    
    // MARK: - Format JSON
    
    func format(_ json: String, indent: IndentStyle = .twoSpaces, sortKeys: Bool = false) throws -> String {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw JSONError.emptyInput }
        
        guard let data = cleaned.data(using: .utf8) else {
            throw JSONError.invalidJSON("Unable to convert to data")
        }
        
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            
            var options: JSONSerialization.WritingOptions = [.prettyPrinted]
            if sortKeys {
                options.insert(.sortedKeys)
            }
            if #available(macOS 10.15, *) {
                options.insert(.withoutEscapingSlashes)
            }
            
            let formatted = try JSONSerialization.data(withJSONObject: object, options: options)
            guard var result = String(data: formatted, encoding: .utf8) else {
                throw JSONError.serializationFailed
            }
            
            // Adjust indentation if needed
            if indent != .fourSpaces {
                result = adjustIndentation(result, to: indent)
            }
            
            return result
        } catch let error as NSError {
            throw JSONError.invalidJSON(extractErrorDetails(from: error))
        }
    }
    
    // MARK: - Minify JSON
    
    func minify(_ json: String) throws -> String {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw JSONError.emptyInput }
        
        guard let data = cleaned.data(using: .utf8) else {
            throw JSONError.invalidJSON("Unable to convert to data")
        }
        
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            let minified = try JSONSerialization.data(withJSONObject: object, options: [])
            
            guard let result = String(data: minified, encoding: .utf8) else {
                throw JSONError.serializationFailed
            }
            return result
        } catch let error as NSError {
            throw JSONError.invalidJSON(extractErrorDetails(from: error))
        }
    }
    
    // MARK: - Validate JSON
    
    func validate(_ json: String) -> ValidationResult {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleaned.isEmpty {
            return ValidationResult(isValid: false, error: "Input is empty", lineNumber: nil, columnNumber: nil)
        }
        
        guard let data = cleaned.data(using: .utf8) else {
            return ValidationResult(isValid: false, error: "Unable to convert to data", lineNumber: nil, columnNumber: nil)
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return ValidationResult(isValid: true, error: nil, lineNumber: nil, columnNumber: nil)
        } catch let error as NSError {
            let details = extractErrorDetails(from: error)
            let (line, column) = extractLineColumn(from: error, in: cleaned)
            return ValidationResult(isValid: false, error: details, lineNumber: line, columnNumber: column)
        }
    }
    
    // MARK: - Helper Methods
    
    private func adjustIndentation(_ json: String, to style: IndentStyle) -> String {
        switch style {
        case .twoSpaces:
            // Default from JSONSerialization is 2 spaces, no change needed
            return json
        case .fourSpaces:
            // This is the default from JSONSerialization
            return json
        case .tabs:
            // Replace leading spaces with tabs
            let lines = json.split(separator: "\n", omittingEmptySubsequences: false)
            return lines.map { line in
                let str = String(line)
                let leadingSpaces = str.prefix(while: { $0 == " " })
                let tabCount = leadingSpaces.count / 2
                let content = str.drop(while: { $0 == " " })
                return String(repeating: "\t", count: tabCount) + content
            }.joined(separator: "\n")
        }
    }
    
    private func extractErrorDetails(from error: NSError) -> String {
        if let description = error.userInfo["NSDebugDescription"] as? String {
            return description
        }
        return error.localizedDescription
    }
    
    private func extractLineColumn(from error: NSError, in json: String) -> (Int?, Int?) {
        // Try to extract character index from error
        if let debugDesc = error.userInfo["NSDebugDescription"] as? String {
            // Look for patterns like "around character 123"
            if let range = debugDesc.range(of: #"character (\d+)"#, options: .regularExpression) {
                let numStr = debugDesc[range].replacingOccurrences(of: "character ", with: "")
                if let charIndex = Int(numStr) {
                    return calculateLineColumn(at: charIndex, in: json)
                }
            }
        }
        return (nil, nil)
    }
    
    private func calculateLineColumn(at index: Int, in text: String) -> (Int, Int) {
        let prefix = text.prefix(index)
        let lines = prefix.split(separator: "\n", omittingEmptySubsequences: false)
        let lineNumber = lines.count
        let columnNumber = (lines.last?.count ?? 0) + 1
        return (lineNumber, columnNumber)
    }
    
    // MARK: - Sort Keys
    
    func sortKeys(_ json: String, indent: IndentStyle = .twoSpaces) throws -> String {
        try format(json, indent: indent, sortKeys: true)
    }
    
    // MARK: - Compact JSON (single line, but readable)
    
    func compact(_ json: String) throws -> String {
        let formatted = try format(json)
        return formatted.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
    }
}

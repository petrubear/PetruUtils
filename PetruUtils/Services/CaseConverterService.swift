import Foundation

/// Service for converting text between different cases
struct CaseConverterService {
    
    // MARK: - Error Types
    
    enum CaseConversionError: LocalizedError {
        case emptyInput
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input cannot be empty."
            }
        }
    }
    
    // MARK: - Conversion Results
    
    struct ConversionResult {
        let original: String
        let camelCase: String
        let pascalCase: String
        let snakeCase: String
        let kebabCase: String
        let upperCase: String
        let lowerCase: String
        let titleCase: String
        let sentenceCase: String
        let constantCase: String  // SCREAMING_SNAKE_CASE
    }
    
    // MARK: - Word Extraction
    
    /// Extract words from input text using various delimiters and patterns
    private func extractWords(_ text: String) -> [String] {
        var words: [String] = []
        var currentWord = ""
        var previousCharWasLower = false
        
        for char in text {
            if char.isUppercase {
                if previousCharWasLower && !currentWord.isEmpty {
                    // Transition from lowercase to uppercase (e.g., "camelCase" -> ["camel", "Case"])
                    words.append(currentWord)
                    currentWord = String(char)
                } else {
                    currentWord.append(char)
                }
                previousCharWasLower = false
            } else if char.isLowercase {
                currentWord.append(char)
                previousCharWasLower = true
            } else if char.isNumber {
                currentWord.append(char)
            } else {
                // Delimiter found (space, underscore, hyphen, etc.)
                if !currentWord.isEmpty {
                    words.append(currentWord)
                    currentWord = ""
                }
                previousCharWasLower = false
            }
        }
        
        // Add final word
        if !currentWord.isEmpty {
            words.append(currentWord)
        }
        
        return words.filter { !$0.isEmpty }
    }
    
    // MARK: - Case Conversions
    
    /// Convert to camelCase
    func toCamelCase(_ text: String) -> String {
        let words = extractWords(text)
        guard !words.isEmpty else { return text }
        
        let first = words[0].lowercased()
        let rest = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        
        return ([first] + rest).joined()
    }
    
    /// Convert to PascalCase
    func toPascalCase(_ text: String) -> String {
        let words = extractWords(text)
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined()
    }
    
    /// Convert to snake_case
    func toSnakeCase(_ text: String) -> String {
        let words = extractWords(text)
        return words.map { $0.lowercased() }.joined(separator: "_")
    }
    
    /// Convert to kebab-case
    func toKebabCase(_ text: String) -> String {
        let words = extractWords(text)
        return words.map { $0.lowercased() }.joined(separator: "-")
    }
    
    /// Convert to UPPER CASE
    func toUpperCase(_ text: String) -> String {
        text.uppercased()
    }
    
    /// Convert to lower case
    func toLowerCase(_ text: String) -> String {
        text.lowercased()
    }
    
    /// Convert to Title Case
    func toTitleCase(_ text: String) -> String {
        let words = extractWords(text)
        return words.map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }.joined(separator: " ")
    }
    
    /// Convert to Sentence case
    func toSentenceCase(_ text: String) -> String {
        let words = extractWords(text)
        guard !words.isEmpty else { return text }
        
        let first = words[0].prefix(1).uppercased() + words[0].dropFirst().lowercased()
        let rest = words.dropFirst().map { $0.lowercased() }
        
        return ([first] + rest).joined(separator: " ")
    }
    
    /// Convert to CONSTANT_CASE (SCREAMING_SNAKE_CASE)
    func toConstantCase(_ text: String) -> String {
        let words = extractWords(text)
        return words.map { $0.uppercased() }.joined(separator: "_")
    }
    
    // MARK: - Full Conversion
    
    /// Convert text to all case formats
    func convertAll(_ text: String) throws -> ConversionResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw CaseConversionError.emptyInput
        }
        
        return ConversionResult(
            original: trimmed,
            camelCase: toCamelCase(trimmed),
            pascalCase: toPascalCase(trimmed),
            snakeCase: toSnakeCase(trimmed),
            kebabCase: toKebabCase(trimmed),
            upperCase: toUpperCase(trimmed),
            lowerCase: toLowerCase(trimmed),
            titleCase: toTitleCase(trimmed),
            sentenceCase: toSentenceCase(trimmed),
            constantCase: toConstantCase(trimmed)
        )
    }
    
    // MARK: - Bulk Conversion
    
    /// Convert multiple lines of text
    func convertBulk(_ text: String, separator: String = "\n") throws -> [ConversionResult] {
        let lines = text.components(separatedBy: separator)
        return try lines
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { try convertAll($0) }
    }
}

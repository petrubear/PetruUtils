import Foundation

/// Service responsible for formatting, minifying, and validating JavaScript code
struct JavaScriptFormatterService {
    // MARK: - Types
    
    enum FormatterError: LocalizedError {
        case emptyInput
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input cannot be empty"
            }
        }
    }
    
    enum IndentStyle: String, CaseIterable, Identifiable {
        case twoSpaces = "2 Spaces"
        case fourSpaces = "4 Spaces"
        case tabs = "Tabs"
        
        var id: String { rawValue }
        
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
        let message: String?
        let line: Int?
        let column: Int?
    }
    
    // MARK: - Public API
    
    func format(_ code: String, indentStyle: IndentStyle = .fourSpaces) throws -> String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FormatterError.emptyInput }
        
        let minified = try minify(trimmed)
        let indentUnit = indentStyle.string
        let characters = Array(minified)
        var result = ""
        var indentLevel = 0
        var inString: Character?
        var isEscaping = false
        var parenDepth = 0
        
        func appendIndent() {
            result.append(String(repeating: indentUnit, count: max(indentLevel, 0)))
        }
        
        func trimTrailingWhitespace() {
            while let last = result.last, last == " " || last == "\t" || last == "\n" {
                result.removeLast()
                if last == "\n" { break }
            }
        }
        
        var index = 0
        while index < characters.count {
            let char = characters[index]
            
            if let stringDelimiter = inString {
                result.append(char)
                if char == "\\" && !isEscaping {
                    isEscaping = true
                } else {
                    if char == stringDelimiter && !isEscaping {
                        inString = nil
                    }
                    isEscaping = false
                }
                index += 1
                continue
            }
            
            switch char {
            case "'", "\"", "`":
                inString = char
                result.append(char)
            case "{" , "[":
                result.append(char)
                result.append("\n")
                indentLevel += 1
                appendIndent()
            case "}", "]":
                trimTrailingWhitespace()
                result.append("\n")
                indentLevel = max(indentLevel - 1, 0)
                appendIndent()
                result.append(char)
                if index + 1 < characters.count {
                    let next = characters[index + 1]
                    if next != "," && next != ";" {
                        result.append("\n")
                        appendIndent()
                    }
                }
            case ";":
                result.append(";\n")
                appendIndent()
            case ",":
                if parenDepth > 0 {
                    result.append(",")
                } else {
                    result.append(",\n")
                    appendIndent()
                }
            case "(":
                parenDepth += 1
                result.append(char)
            case ")":
                parenDepth = max(parenDepth - 1, 0)
                result.append(char)
            case " " where result.last == " ":
                break
            default:
                result.append(char)
            }
            index += 1
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func minify(_ code: String) throws -> String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw FormatterError.emptyInput }
        
        let characters = Array(trimmed)
        var result = ""
        var index = 0
        var inString: Character?
        var isEscaping = false
        var inLineComment = false
        var inBlockComment = false
        
        func needsSpace(between previous: Character?, and next: Character?) -> Bool {
            guard let prev = previous, let next = next else { return false }
            return (isIdentifierChar(prev) || prev.isNumber) && (isIdentifierChar(next) || next.isNumber)
        }
        
        while index < characters.count {
            let char = characters[index]
            
            if inLineComment {
                if char == "\n" {
                    inLineComment = false
                }
                index += 1
                continue
            }
            
            if inBlockComment {
                if char == "*" && index + 1 < characters.count && characters[index + 1] == "/" {
                    inBlockComment = false
                    index += 2
                } else {
                    index += 1
                }
                continue
            }
            
            if let stringDelimiter = inString {
                result.append(char)
                if char == "\\" && !isEscaping {
                    isEscaping = true
                } else {
                    if char == stringDelimiter && !isEscaping {
                        inString = nil
                    }
                    isEscaping = false
                }
                index += 1
                continue
            }
            
            if char == "'" || char == "\"" || char == "`" {
                inString = char
                result.append(char)
                index += 1
                continue
            }
            
            // Preserve readability around assignment/arrow operators
            if char == "=" {
                var op = "="
                var lookahead = index + 1
                while lookahead < characters.count && (characters[lookahead] == "=" || characters[lookahead] == ">") {
                    op.append(characters[lookahead])
                    lookahead += 1
                }
                
                if let last = result.last, !last.isWhitespace {
                    result.append(" ")
                }
                
                result.append(op)
                
                if let next = nextNonWhitespace(from: characters, start: lookahead),
                   !";,)}]".contains(next) {
                    result.append(" ")
                }
                
                index = lookahead
                continue
            }
            
            if char == "/" && index + 1 < characters.count {
                let next = characters[index + 1]
                if next == "/" {
                    inLineComment = true
                    index += 2
                    continue
                } else if next == "*" {
                    inBlockComment = true
                    index += 2
                    continue
                }
            }
            
            if char.isWhitespace {
                let next = nextNonWhitespace(from: characters, start: index + 1)
                if needsSpace(between: result.last, and: next) {
                    result.append(" ")
                }
                index += 1
                continue
            }
            
            result.append(char)
            index += 1
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func validate(_ code: String) -> ValidationResult {
        let characters = Array(code)
        var stack: [(char: Character, line: Int, column: Int)] = []
        var line = 1
        var column = 1
        var inString: Character?
        var isEscaping = false
        var inLineComment = false
        var inBlockComment = false
        
        func message(_ text: String, _ line: Int, _ column: Int) -> ValidationResult {
            ValidationResult(isValid: false, message: text, line: line, column: column)
        }
        
        var index = 0
        while index < characters.count {
            let char = characters[index]
            
            if char == "\n" {
                line += 1
                column = 1
            } else {
                column += 1
            }
            
            if inLineComment {
                if char == "\n" {
                    inLineComment = false
                }
                index += 1
                continue
            }
            
            if inBlockComment {
                if char == "*" && index + 1 < characters.count && characters[index + 1] == "/" {
                    inBlockComment = false
                    index += 2
                    column += 1
                } else {
                    index += 1
                }
                continue
            }
            
            if let stringDelimiter = inString {
                if char == "\\" && !isEscaping {
                    isEscaping = true
                } else {
                    if char == stringDelimiter && !isEscaping {
                        inString = nil
                    }
                    isEscaping = false
                }
                index += 1
                continue
            }
            
            if char == "'" || char == "\"" || char == "`" {
                inString = char
                index += 1
                continue
            }
            
            if char == "/" && index + 1 < characters.count {
                let next = characters[index + 1]
                if next == "/" {
                    inLineComment = true
                    index += 2
                    column += 1
                    continue
                } else if next == "*" {
                    inBlockComment = true
                    index += 2
                    column += 1
                    continue
                }
            }
            
            if "({[".contains(char) {
                stack.append((char, line, column))
            } else if ")}]".contains(char) {
                guard let last = stack.popLast() else {
                    return message("Unexpected closing \(char)", line, column)
                }
                if !matches(open: last.char, close: char) {
                    return message("Mismatched \(last.char) and \(char)", line, column)
                }
            }
            
            index += 1
        }
        
        if let stringDelimiter = inString {
            return ValidationResult(isValid: false, message: "Unclosed string literal (\(stringDelimiter))", line: line, column: column)
        }
        
        if let last = stack.last {
            return ValidationResult(isValid: false, message: "Unclosed \(last.char)", line: last.line, column: last.column)
        }
        
        return ValidationResult(isValid: true, message: nil, line: nil, column: nil)
    }
    
    // MARK: - Helpers
    
    private func matches(open: Character, close: Character) -> Bool {
        switch (open, close) {
        case ("(", ")"), ("[", "]"), ("{", "}"): return true
        default: return false
        }
    }
    
    private func isIdentifierChar(_ char: Character) -> Bool {
        char.isLetter || char == "_" || char == "$"
    }
    
    private func nextNonWhitespace(from characters: [Character], start: Int) -> Character? {
        var index = start
        while index < characters.count {
            let char = characters[index]
            if !char.isWhitespace {
                return char
            }
            index += 1
        }
        return nil
    }
}

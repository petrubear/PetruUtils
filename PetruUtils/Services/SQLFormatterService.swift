import Foundation

struct SQLFormatterService {
    enum SQLError: LocalizedError {
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
    
    // MARK: - Format SQL
    
    func format(_ sql: String, indentStyle: IndentStyle = .twoSpaces, uppercaseKeywords: Bool = true) throws -> String {
        guard !sql.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SQLError.emptyInput
        }
        
        let indent = indentStyle.string
        var formatted = ""
        var currentIndent = 0
        
        // SQL keywords that should be on their own line
        let majorKeywords = [
            "SELECT", "FROM", "WHERE", "GROUP BY", "HAVING", "ORDER BY",
            "INSERT INTO", "VALUES", "UPDATE", "SET", "DELETE FROM",
            "CREATE TABLE", "ALTER TABLE", "DROP TABLE",
            "JOIN", "LEFT JOIN", "RIGHT JOIN", "INNER JOIN", "OUTER JOIN",
            "UNION", "UNION ALL", "INTERSECT", "EXCEPT",
            "CASE", "WHEN", "THEN", "ELSE", "END"
        ]
        
        // Split by semicolons (statement separators)
        let statements = sql.components(separatedBy: ";")
        
        for (index, statement) in statements.enumerated() {
            let trimmed = statement.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            var formattedStatement = formatStatement(trimmed, indent: indent, uppercaseKeywords: uppercaseKeywords)
            
            formatted += formattedStatement
            
            // Add semicolon back (except for last empty statement)
            if index < statements.count - 1 {
                formatted += ";\n\n"
            }
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Minify SQL
    
    func minify(_ sql: String) throws -> String {
        guard !sql.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SQLError.emptyInput
        }
        
        var result = sql
        
        // Remove comments
        result = result.replacingOccurrences(of: "--[^\n]*", with: "", options: .regularExpression)
        result = result.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)
        
        // Collapse whitespace
        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove spaces around operators and punctuation
        result = result.replacingOccurrences(of: "\\s*([,;()])\\s*", with: "$1", options: .regularExpression)
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Validate SQL (Basic)
    
    func validate(_ sql: String) -> (isValid: Bool, message: String) {
        guard !sql.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "Input is empty")
        }
        
        var issues: [String] = []
        
        // Check for balanced parentheses
        var parenCount = 0
        for char in sql {
            if char == "(" {
                parenCount += 1
            } else if char == ")" {
                parenCount -= 1
                if parenCount < 0 {
                    issues.append("Mismatched closing parenthesis")
                    break
                }
            }
        }
        
        if parenCount > 0 {
            issues.append("Missing \(parenCount) closing parenthesis")
        }
        
        // Check for basic SQL structure
        let upper = sql.uppercased()
        let hasKeyword = upper.contains("SELECT") || upper.contains("INSERT") ||
                        upper.contains("UPDATE") || upper.contains("DELETE") ||
                        upper.contains("CREATE") || upper.contains("ALTER") ||
                        upper.contains("DROP")
        
        if !hasKeyword {
            issues.append("No SQL keywords found")
        }
        
        if issues.isEmpty {
            return (true, "✓ Valid SQL syntax")
        } else {
            return (false, "✗ " + issues.joined(separator: ", "))
        }
    }
    
    // MARK: - Private Helpers
    
    private func formatStatement(_ statement: String, indent: String, uppercaseKeywords: Bool) -> String {
        var result = statement
        
        // Keywords that should be on new lines
        let lineBreakKeywords = [
            "SELECT", "FROM", "WHERE", "GROUP BY", "HAVING", "ORDER BY",
            "JOIN", "LEFT JOIN", "RIGHT JOIN", "INNER JOIN", "OUTER JOIN",
            "UNION", "UNION ALL"
        ]
        
        // Add line breaks before major keywords
        for keyword in lineBreakKeywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = result as NSString
                let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
                
                // Process matches in reverse to maintain string indices
                for match in matches.reversed() {
                    if let range = Range(match.range, in: result) {
                        let replacement = uppercaseKeywords ? keyword : keyword.lowercased()
                        
                        // Add newline before keyword if not at start
                        if range.lowerBound != result.startIndex {
                            result.replaceSubrange(range, with: "\n" + replacement)
                        } else {
                            result.replaceSubrange(range, with: replacement)
                        }
                    }
                }
            }
        }
        
        // Uppercase all SQL keywords if requested
        if uppercaseKeywords {
            let allKeywords = [
                "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN", "LIKE", "BETWEEN",
                "INSERT", "INTO", "VALUES", "UPDATE", "SET", "DELETE",
                "CREATE", "TABLE", "ALTER", "DROP", "INDEX",
                "JOIN", "LEFT", "RIGHT", "INNER", "OUTER", "ON",
                "GROUP", "BY", "HAVING", "ORDER", "ASC", "DESC",
                "LIMIT", "OFFSET", "AS", "NULL", "IS", "DISTINCT",
                "UNION", "ALL", "CASE", "WHEN", "THEN", "ELSE", "END"
            ]
            
            for keyword in allKeywords {
                let pattern = "\\b\(keyword)\\b"
                result = result.replacingOccurrences(
                    of: pattern,
                    with: keyword,
                    options: [.regularExpression, .caseInsensitive]
                )
            }
        }
        
        // Format with indentation
        let lines = result.components(separatedBy: "\n")
        var formattedLines: [String] = []
        var currentIndent = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // Adjust indent for closing keywords
            if trimmed.uppercased().hasPrefix("WHERE") ||
               trimmed.uppercased().hasPrefix("GROUP BY") ||
               trimmed.uppercased().hasPrefix("HAVING") ||
               trimmed.uppercased().hasPrefix("ORDER BY") {
                currentIndent = 0
            }
            
            formattedLines.append(String(repeating: indent, count: currentIndent) + trimmed)
            
            // Adjust indent for opening keywords
            if trimmed.uppercased().hasPrefix("SELECT") ||
               trimmed.uppercased().hasPrefix("FROM") {
                currentIndent = 1
            }
        }
        
        return formattedLines.joined(separator: "\n")
    }
}

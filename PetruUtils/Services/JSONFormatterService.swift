import Foundation
import Combine

/// Service for formatting, minifying, and validating JSON
struct JSONFormatterService {

    // MARK: - JSON Tree Node

    /// Represents a node in a JSON tree structure
    final class JSONTreeNode: Identifiable, ObservableObject {
        let id = UUID()
        let key: String?
        let value: JSONValue
        let path: String
        @Published var isExpanded: Bool = true
        var children: [JSONTreeNode]

        init(key: String?, value: JSONValue, path: String, children: [JSONTreeNode] = []) {
            self.key = key
            self.value = value
            self.path = path
            self.children = children
        }

        var displayKey: String {
            key ?? ""
        }

        var isExpandable: Bool {
            switch value {
            case .object, .array:
                return !children.isEmpty
            default:
                return false
            }
        }

        var typeLabel: String {
            switch value {
            case .object(let dict): return "{\(dict.count)}"
            case .array(let arr): return "[\(arr.count)]"
            case .string: return "string"
            case .number: return "number"
            case .bool: return "bool"
            case .null: return "null"
            }
        }
    }

    /// Represents a JSON value type
    enum JSONValue {
        case object([String: Any])
        case array([Any])
        case string(String)
        case number(NSNumber)
        case bool(Bool)
        case null

        var displayValue: String {
            switch self {
            case .object: return "{...}"
            case .array: return "[...]"
            case .string(let s): return "\"\(s)\""
            case .number(let n): return n.stringValue
            case .bool(let b): return b ? "true" : "false"
            case .null: return "null"
            }
        }

        var isContainer: Bool {
            switch self {
            case .object, .array: return true
            default: return false
            }
        }
    }
    
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

    // MARK: - Parse JSON to Tree

    func parseToTree(_ json: String) throws -> JSONTreeNode {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw JSONError.emptyInput }

        guard let data = cleaned.data(using: .utf8) else {
            throw JSONError.invalidJSON("Unable to convert to data")
        }

        do {
            let object = try JSONSerialization.jsonObject(with: data)
            return buildNode(key: nil, value: object, path: "$")
        } catch let error as NSError {
            throw JSONError.invalidJSON(extractErrorDetails(from: error))
        }
    }

    private func buildNode(key: String?, value: Any, path: String) -> JSONTreeNode {
        if let dict = value as? [String: Any] {
            let children = dict.sorted { $0.key < $1.key }.map { k, v in
                let childPath = path + "." + escapePathKey(k)
                return buildNode(key: k, value: v, path: childPath)
            }
            return JSONTreeNode(key: key, value: .object(dict), path: path, children: children)
        } else if let array = value as? [Any] {
            let children = array.enumerated().map { index, v in
                let childPath = path + "[\(index)]"
                return buildNode(key: "[\(index)]", value: v, path: childPath)
            }
            return JSONTreeNode(key: key, value: .array(array), path: path, children: children)
        } else if let str = value as? String {
            return JSONTreeNode(key: key, value: .string(str), path: path)
        } else if let num = value as? NSNumber {
            // Check if it's a boolean
            if CFGetTypeID(num) == CFBooleanGetTypeID() {
                return JSONTreeNode(key: key, value: .bool(num.boolValue), path: path)
            }
            return JSONTreeNode(key: key, value: .number(num), path: path)
        } else if value is NSNull {
            return JSONTreeNode(key: key, value: .null, path: path)
        } else {
            return JSONTreeNode(key: key, value: .string(String(describing: value)), path: path)
        }
    }

    private func escapePathKey(_ key: String) -> String {
        // If key contains special characters, wrap in brackets
        if key.contains(".") || key.contains("[") || key.contains("]") || key.contains(" ") {
            return "['\(key)']"
        }
        return key
    }

    // MARK: - Get Value at JSONPath

    func getValueAtPath(_ json: String, path: String) throws -> String {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw JSONError.emptyInput }

        guard let data = cleaned.data(using: .utf8) else {
            throw JSONError.invalidJSON("Unable to convert to data")
        }

        let object = try JSONSerialization.jsonObject(with: data)
        guard let value = navigateToPath(object, path: path) else {
            return "Path not found"
        }

        if let dict = value as? [String: Any] {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "{}"
        } else if let arr = value as? [Any] {
            let data = try JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? "[]"
        } else if let str = value as? String {
            return "\"\(str)\""
        } else if let num = value as? NSNumber {
            return num.stringValue
        } else if value is NSNull {
            return "null"
        }
        return String(describing: value)
    }

    private func navigateToPath(_ root: Any, path: String) -> Any? {
        guard path.hasPrefix("$") else { return nil }

        var current: Any = root
        var remaining = path.dropFirst() // Remove $

        while !remaining.isEmpty {
            if remaining.hasPrefix(".") {
                remaining = remaining.dropFirst()
                // Get key until next . or [
                var key = ""
                while let char = remaining.first, char != "." && char != "[" {
                    key.append(char)
                    remaining = remaining.dropFirst()
                }
                guard !key.isEmpty, let dict = current as? [String: Any], let value = dict[key] else {
                    return nil
                }
                current = value
            } else if remaining.hasPrefix("[") {
                remaining = remaining.dropFirst()
                if remaining.hasPrefix("'") {
                    // Bracket notation with string key: ['key']
                    remaining = remaining.dropFirst()
                    var key = ""
                    while let char = remaining.first, char != "'" {
                        key.append(char)
                        remaining = remaining.dropFirst()
                    }
                    remaining = remaining.dropFirst() // Remove closing '
                    remaining = remaining.dropFirst() // Remove ]
                    guard let dict = current as? [String: Any], let value = dict[key] else {
                        return nil
                    }
                    current = value
                } else {
                    // Array index: [0]
                    var indexStr = ""
                    while let char = remaining.first, char != "]" {
                        indexStr.append(char)
                        remaining = remaining.dropFirst()
                    }
                    remaining = remaining.dropFirst() // Remove ]
                    guard let index = Int(indexStr), let array = current as? [Any], index >= 0, index < array.count else {
                        return nil
                    }
                    current = array[index]
                }
            } else {
                break
            }
        }
        return current
    }
}

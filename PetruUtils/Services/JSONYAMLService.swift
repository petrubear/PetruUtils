import Foundation

/// Service for converting between JSON and YAML (simplified YAML support)
struct JSONYAMLService {
    
    enum ConversionError: LocalizedError {
        case invalidJSON
        case invalidYAML
        case emptyInput
        case conversionFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "Invalid JSON format."
            case .invalidYAML: return "Invalid YAML format."
            case .emptyInput: return "Input cannot be empty."
            case .conversionFailed: return "Conversion failed."
            }
        }
    }
    
    // MARK: - JSON to YAML
    
    func jsonToYAML(_ json: String) throws -> String {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ConversionError.emptyInput }
        
        guard let data = cleaned.data(using: .utf8) else { throw ConversionError.invalidJSON }
        let object = try JSONSerialization.jsonObject(with: data)
        
        return try convertToYAML(object, indent: 0)
    }
    
    private func convertToYAML(_ object: Any, indent: Int) throws -> String {
        let indentStr = String(repeating: "  ", count: indent)
        
        if let dict = object as? [String: Any] {
            var result = ""
            for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                if let nestedDict = value as? [String: Any] {
                    result += "\(indentStr)\(key):\n"
                    result += try convertToYAML(nestedDict, indent: indent + 1)
                } else if let array = value as? [Any] {
                    result += "\(indentStr)\(key):\n"
                    result += try convertToYAML(array, indent: indent + 1)
                } else {
                    result += "\(indentStr)\(key): \(formatValue(value))\n"
                }
            }
            return result
        } else if let array = object as? [Any] {
            var result = ""
            for item in array {
                if let dict = item as? [String: Any] {
                    result += "\(indentStr)- "
                    let dictYAML = try convertToYAML(dict, indent: indent + 1)
                    let lines = dictYAML.split(separator: "\n")
                    if let first = lines.first {
                        result += first.trimmingCharacters(in: .whitespaces) + "\n"
                        for line in lines.dropFirst() {
                            result += "  \(line)\n"
                        }
                    }
                } else {
                    result += "\(indentStr)- \(formatValue(item))\n"
                }
            }
            return result
        }
        
        return "\(indentStr)\(formatValue(object))\n"
    }
    
    private func formatValue(_ value: Any) -> String {
        if value is NSNull {
            return "null"
        } else if let str = value as? String {
            // Quote strings if they contain special characters
            if str.contains(":") || str.contains("#") || str.contains("[") || str.contains("]") {
                return "\"\(str)\""
            }
            return str
        } else if let num = value as? NSNumber {
            return "\(num)"
        }
        return "\(value)"
    }
    
    // MARK: - YAML to JSON (basic implementation)
    
    func yamlToJSON(_ yaml: String) throws -> String {
        let cleaned = yaml.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ConversionError.emptyInput }
        
        // This is a simplified YAML parser - only handles basic cases
        let object = try parseYAML(cleaned)
        
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        guard let json = String(data: data, encoding: .utf8) else {
            throw ConversionError.conversionFailed
        }
        return json
    }
    
    private func parseYAML(_ yaml: String) throws -> Any {
        let lines = yaml.split(separator: "\n").map { String($0) }
        var result: [String: Any] = [:]
        var currentKey: String?
        var arrayItems: [Any] = []
        var inArray = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            if trimmed.hasPrefix("- ") {
                // Array item
                let value = String(trimmed.dropFirst(2))
                arrayItems.append(parseValue(value))
                inArray = true
            } else if let colonIndex = trimmed.firstIndex(of: ":") {
                // Save previous array if any
                if inArray, let key = currentKey {
                    result[key] = arrayItems
                    arrayItems = []
                    inArray = false
                }
                
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let valueStr = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                
                currentKey = key
                if !valueStr.isEmpty {
                    result[key] = parseValue(valueStr)
                }
            }
        }
        
        // Save final array if any
        if inArray, let key = currentKey {
            result[key] = arrayItems
        }
        
        return result.isEmpty ? [:] : result
    }
    
    private func parseValue(_ value: String) -> Any {
        let trimmed = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        
        if trimmed == "null" { return NSNull() }
        if trimmed == "true" { return true }
        if trimmed == "false" { return false }
        if let int = Int(trimmed) { return int }
        if let double = Double(trimmed) { return double }
        
        return trimmed
    }
}

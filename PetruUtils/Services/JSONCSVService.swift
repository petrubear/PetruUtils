import Foundation

struct JSONCSVService {
    enum ConversionError: LocalizedError {
        case invalidJSON, invalidCSV, emptyInput, notAnArray
        var errorDescription: String? {
            switch self {
            case .invalidJSON: return "Invalid JSON format."
            case .invalidCSV: return "Invalid CSV format."
            case .emptyInput: return "Input cannot be empty."
            case .notAnArray: return "JSON must be an array of objects."
            }
        }
    }
    
    func jsonToCSV(_ json: String, delimiter: String = ",") throws -> String {
        let cleaned = json.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ConversionError.emptyInput }
        
        guard let data = cleaned.data(using: .utf8) else { throw ConversionError.invalidJSON }
        let object = try JSONSerialization.jsonObject(with: data)
        
        guard let array = object as? [[String: Any]], !array.isEmpty else {
            throw ConversionError.notAnArray
        }
        
        // Get all keys from all objects
        var allKeys = Set<String>()
        for dict in array {
            allKeys.formUnion(dict.keys)
        }
        let sortedKeys = Array(allKeys).sorted()
        
        // Header
        var csv = sortedKeys.joined(separator: delimiter) + "\n"
        
        // Rows
        for dict in array {
            let row = sortedKeys.map { key -> String in
                if let value = dict[key] {
                    return formatCSVValue(value)
                }
                return ""
            }
            csv += row.joined(separator: delimiter) + "\n"
        }
        
        return csv
    }
    
    func csvToJSON(_ csv: String, delimiter: String = ",") throws -> String {
        let cleaned = csv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ConversionError.emptyInput }
        
        let lines = cleaned.split(separator: "\n").map { String($0) }
        guard lines.count > 1 else { throw ConversionError.invalidCSV }
        
        let headers = lines[0].split(separator: Character(delimiter)).map { String($0).trimmingCharacters(in: .whitespaces) }
        var result: [[String: Any]] = []
        
        for line in lines.dropFirst() {
            let values = line.split(separator: Character(delimiter)).map { String($0).trimmingCharacters(in: .whitespaces) }
            var dict: [String: Any] = [:]
            for (index, header) in headers.enumerated() {
                dict[header] = index < values.count ? parseValue(values[index]) : ""
            }
            result.append(dict)
        }
        
        let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func formatCSVValue(_ value: Any) -> String {
        if value is NSNull { return "null" }
        if let str = value as? String {
            if str.contains(",") || str.contains("\"") || str.contains("\n") {
                return "\"\(str.replacingOccurrences(of: "\"", with: "\"\""))\""
            }
            return str
        }
        return "\(value)"
    }
    
    private func parseValue(_ value: String) -> Any {
        if value == "null" { return NSNull() }
        if value == "true" { return true }
        if value == "false" { return false }
        if let int = Int(value) { return int }
        if let double = Double(value) { return double }
        return value
    }
}

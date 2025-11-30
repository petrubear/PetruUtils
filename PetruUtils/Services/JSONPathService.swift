import Foundation

struct JSONPathService {
    enum JSONPathError: LocalizedError {
        case invalidJSON
        case invalidPath
        case noMatches
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "Invalid JSON input. Please check your JSON syntax."
            case .invalidPath:
                return "Invalid JSONPath expression."
            case .noMatches:
                return "No matches found for the given path."
            }
        }
    }
    
    struct PathResult {
        let value: Any
        let path: String
        let matches: Int
    }
    
    func evaluate(json: String, path: String) throws -> PathResult {
        // Parse JSON
        guard let data = json.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data) else {
            throw JSONPathError.invalidJSON
        }
        
        // Evaluate path
        let results = try evaluatePath(path, in: jsonObject)
        
        guard !results.isEmpty else {
            throw JSONPathError.noMatches
        }
        
        // Format results
        let resultValue: Any
        if results.count == 1 {
            resultValue = results[0]
        } else {
            resultValue = results
        }
        
        return PathResult(value: resultValue, path: path, matches: results.count)
    }
    
    func formatResult(_ result: PathResult) throws -> String {
        // Allow primitive fragments (e.g., a single string/number/bool) returned by JSONPath
        let data: Data
        if JSONSerialization.isValidJSONObject(result.value) {
            data = try JSONSerialization.data(withJSONObject: result.value, options: [.prettyPrinted, .sortedKeys])
        } else {
            // fragmentsAllowed lets us serialize primitives; fall back to a description if that somehow fails
            do {
                data = try JSONSerialization.data(withJSONObject: result.value,
                                                  options: [.prettyPrinted, .sortedKeys, .fragmentsAllowed])
            } catch {
                return "\(result.value)"
            }
        }
        return String(data: data, encoding: .utf8) ?? "{}"
    }
    
    private func evaluatePath(_ path: String, in object: Any) throws -> [Any] {
        let trimmedPath = path.trimmingCharacters(in: .whitespaces)
        
        // Root selector
        if trimmedPath == "$" || trimmedPath.isEmpty {
            return [object]
        }
        
        // Remove leading $
        let workingPath = trimmedPath.hasPrefix("$") ? String(trimmedPath.dropFirst()) : trimmedPath
        
        // Split path into components
        var results = [object]
        let components = parsePathComponents(workingPath)
        
        for component in components {
            var newResults: [Any] = []
            
            for currentObject in results {
                switch component {
                case .property(let key):
                    if let dict = currentObject as? [String: Any], let value = dict[key] {
                        newResults.append(value)
                    }
                    
                case .arrayIndex(let index):
                    if let array = currentObject as? [Any], index >= 0 && index < array.count {
                        newResults.append(array[index])
                    }
                    
                case .arrayAll:
                    if let array = currentObject as? [Any] {
                        newResults.append(contentsOf: array)
                    }
                    
                case .recursiveDescent(let key):
                    newResults.append(contentsOf: recursiveSearch(key: key, in: currentObject))
                }
            }
            
            results = newResults
        }
        
        return results
    }
    
    private enum PathComponent {
        case property(String)
        case arrayIndex(Int)
        case arrayAll
        case recursiveDescent(String)
    }
    
    private func parsePathComponents(_ path: String) -> [PathComponent] {
        var components: [PathComponent] = []
        var current = path
        
        while !current.isEmpty {
            // Handle recursive descent (..)
            if current.hasPrefix("..") {
                current = String(current.dropFirst(2))
                if let dotIndex = current.firstIndex(of: "."),
                   dotIndex != current.startIndex {
                    let key = String(current[..<dotIndex])
                    components.append(.recursiveDescent(key))
                    current = String(current[dotIndex...])
                } else if let bracketIndex = current.firstIndex(of: "["),
                          bracketIndex != current.startIndex {
                    let key = String(current[..<bracketIndex])
                    components.append(.recursiveDescent(key))
                    current = String(current[bracketIndex...])
                } else if !current.isEmpty && !current.hasPrefix(".") && !current.hasPrefix("[") {
                    components.append(.recursiveDescent(current))
                    current = ""
                }
                continue
            }
            
            // Skip leading dot
            if current.hasPrefix(".") {
                current = String(current.dropFirst())
            }
            
            // Handle array notation [index] or [*]
            if current.hasPrefix("[") {
                if let endIndex = current.firstIndex(of: "]") {
                    let indexStr = current[current.index(after: current.startIndex)..<endIndex]
                    if indexStr == "*" {
                        components.append(.arrayAll)
                    } else if let index = Int(indexStr) {
                        components.append(.arrayIndex(index))
                    }
                    current = String(current[current.index(after: endIndex)...])
                }
                continue
            }
            
            // Handle property access (respect nearest delimiter whether dot or bracket)
            let dotIndex = current.firstIndex(of: ".")
            let bracketIndex = current.firstIndex(of: "[")
            
            let nextDelimiter: String.Index?
            switch (dotIndex, bracketIndex) {
            case let (dot?, bracket?):
                nextDelimiter = dot < bracket ? dot : bracket
            case let (dot?, nil):
                nextDelimiter = dot
            case let (nil, bracket?):
                nextDelimiter = bracket
            default:
                nextDelimiter = nil
            }
            
            if let delimiter = nextDelimiter {
                let key = String(current[..<delimiter])
                if !key.isEmpty {
                    components.append(.property(key))
                }
                current = String(current[delimiter...])
            } else {
                if !current.isEmpty {
                    components.append(.property(current))
                }
                current = ""
            }
        }
        
        return components
    }
    
    private func recursiveSearch(key: String, in object: Any) -> [Any] {
        var results: [Any] = []
        
        if let dict = object as? [String: Any] {
            if let value = dict[key] {
                results.append(value)
            }
            for (_, value) in dict {
                results.append(contentsOf: recursiveSearch(key: key, in: value))
            }
        } else if let array = object as? [Any] {
            for item in array {
                results.append(contentsOf: recursiveSearch(key: key, in: item))
            }
        }
        
        return results
    }
}

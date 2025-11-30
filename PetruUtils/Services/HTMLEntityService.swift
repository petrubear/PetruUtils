import Foundation

struct HTMLEntityService {
    enum HTMLEntityError: LocalizedError {
        case encodingFailed
        case decodingFailed
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode text to HTML entities"
            case .decodingFailed:
                return "Failed to decode HTML entities"
            }
        }
    }
    
    // Common HTML named entities
    private let namedEntities: [String: String] = [
        "&": "&amp;",
        "<": "&lt;",
        ">": "&gt;",
        "\"": "&quot;",
        "'": "&apos;",
        " ": "&nbsp;",
        "©": "&copy;",
        "®": "&reg;",
        "™": "&trade;",
        "€": "&euro;",
        "£": "&pound;",
        "¥": "&yen;",
        "¢": "&cent;",
        "§": "&sect;",
        "¶": "&para;",
        "•": "&bull;",
        "…": "&hellip;",
        "–": "&ndash;",
        "—": "&mdash;",
        "°": "&deg;",
        "±": "&plusmn;",
        "×": "&times;",
        "÷": "&divide;",
        "¼": "&frac14;",
        "½": "&frac12;",
        "¾": "&frac34;"
    ]
    
    /// Encode text to HTML entities (named and numeric)
    func encode(_ text: String, useNamedEntities: Bool = true, useNumericEntities: Bool = true) -> String {
        var encoded = ""
        
        for scalar in text.unicodeScalars {
            let char = String(scalar)
            
            if useNamedEntities, let entity = namedEntities[char] {
                encoded += entity
                continue
            }
            
            if useNumericEntities, scalar.value > 127 || (!useNamedEntities && shouldEncode(scalar)) {
                encoded += "&#\(scalar.value);"
                continue
            }
            
            encoded += char
        }
        
        return encoded
    }
    
    /// Encode text to hex HTML entities
    func encodeToHex(_ text: String) -> String {
        var result = ""
        for scalar in text.unicodeScalars {
            if scalar.value > 127 || shouldEncode(scalar) {
                result += String(format: "&#x%X;", scalar.value)
            } else {
                result += String(scalar)
            }
        }
        return result
    }
    
    /// Decode HTML entities to text
    func decode(_ text: String) -> String {
        var result = text
        
        // Decode named entities
        let reverseEntities = Dictionary(uniqueKeysWithValues: namedEntities.map { ($1, $0) })
        for (entity, char) in reverseEntities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        
        // Decode numeric entities (&#123; or &#xABC;)
        let numericPattern = "&#(x?)([0-9A-Fa-f]+);"
        if let regex = try? NSRegularExpression(pattern: numericPattern) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            
            // Process matches in reverse to maintain indices
            for match in matches.reversed() {
                if match.numberOfRanges >= 3 {
                    let isHex = nsString.substring(with: match.range(at: 1)) == "x"
                    let valueString = nsString.substring(with: match.range(at: 2))
                    
                    if let value = isHex ? UInt32(valueString, radix: 16) : UInt32(valueString),
                       let scalar = UnicodeScalar(value) {
                        let char = String(scalar)
                        let range = match.range
                        result = (result as NSString).replacingCharacters(in: range, with: char)
                    }
                }
            }
        }
        
        return result
    }
    
    /// Encode only special HTML characters (&, <, >, ", ')
    func encodeSpecialChars(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }
    
    // MARK: - Private Helpers
    
    private func shouldEncode(_ scalar: UnicodeScalar) -> Bool {
        let value = scalar.value
        // Encode control characters, special HTML chars, and non-ASCII
        return value < 32 || value == 38 || value == 60 || value == 62 || value == 34 || value == 39
    }
}

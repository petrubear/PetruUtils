import Foundation

struct BackslashEscapeService {
    enum EscapeMode {
        case standard      // \n, \t, \r, \", \\, \'
        case unicode       // \u0000 format
        case json          // JSON-specific escaping
        case python        // Python string escaping
        case c             // C/C++ string escaping
    }
    
    /// Escape special characters in a string
    func escape(_ text: String, mode: EscapeMode = .standard) -> String {
        var result = ""
        
        for char in text {
            switch char {
            case "\n":
                result += "\\n"
            case "\t":
                result += "\\t"
            case "\r":
                result += "\\r"
            case "\"":
                result += "\\\""
            case "\\":
                result += "\\\\"
            case "\'":
                if mode == .python || mode == .c {
                    result += "\\'"
                } else {
                    result.append(char)
                }
            default:
                // Handle unicode escaping for non-ASCII characters
                if mode == .unicode || mode == .json {
                    if !char.isASCII {
                        for scalar in String(char).unicodeScalars {
                            result += String(format: "\\u%04x", scalar.value)
                        }
                    } else {
                        result.append(char)
                    }
                } else {
                    result.append(char)
                }
            }
        }
        
        return result
    }
    
    /// Unescape a string containing escape sequences
    func unescape(_ text: String) -> String {
        var result = ""
        var iterator = text.makeIterator()
        
        while let char = iterator.next() {
            if char == "\\" {
                if let next = iterator.next() {
                    switch next {
                    case "n":
                        result.append("\n")
                    case "t":
                        result.append("\t")
                    case "r":
                        result.append("\r")
                    case "\"":
                        result.append("\"")
                    case "\\":
                        result.append("\\")
                    case "\'":
                        result.append("\'")
                    case "u":
                        // Handle \uXXXX unicode escape
                        var unicodeHex = ""
                        for _ in 0..<4 {
                            if let hexChar = iterator.next() {
                                unicodeHex.append(hexChar)
                            }
                        }
                        if let value = UInt32(unicodeHex, radix: 16),
                           let scalar = UnicodeScalar(value) {
                            result.append(Character(scalar))
                        } else {
                            // Invalid unicode, keep original
                            result.append("\\u")
                            result.append(contentsOf: unicodeHex)
                        }
                    case "x":
                        // Handle \xHH hex escape
                        var hexValue = ""
                        for _ in 0..<2 {
                            if let hexChar = iterator.next() {
                                hexValue.append(hexChar)
                            }
                        }
                        if let value = UInt32(hexValue, radix: 16),
                           let scalar = UnicodeScalar(value) {
                            result.append(Character(scalar))
                        } else {
                            result.append("\\x")
                            result.append(contentsOf: hexValue)
                        }
                    default:
                        // Unknown escape, keep both characters
                        result.append("\\")
                        result.append(next)
                    }
                } else {
                    result.append("\\")
                }
            } else {
                result.append(char)
            }
        }
        
        return result
    }
}

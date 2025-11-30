import Foundation

/// Service responsible for Base64 encoding and decoding operations
struct Base64Service {
    
    // MARK: - Types
    
    enum Base64Error: LocalizedError {
        case invalidBase64String
        case emptyInput
        case encodingFailed
        case decodingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidBase64String:
                return "Invalid Base64 string"
            case .emptyInput:
                return "Input cannot be empty"
            case .encodingFailed:
                return "Failed to encode data"
            case .decodingFailed:
                return "Failed to decode Base64"
            }
        }
    }
    
    enum Base64Variant {
        case standard
        case urlSafe
    }
    
    // MARK: - Text Encoding
    
    /// Encodes text to Base64
    /// - Parameters:
    ///   - text: The text to encode
    ///   - variant: Base64 variant (standard or URL-safe)
    /// - Returns: Base64 encoded string
    /// - Throws: Base64Error if encoding fails
    func encodeText(_ text: String, variant: Base64Variant = .standard) throws -> String {
        guard !text.isEmpty else {
            throw Base64Error.emptyInput
        }
        
        guard let data = text.data(using: .utf8) else {
            throw Base64Error.encodingFailed
        }
        
        return encodeData(data, variant: variant)
    }
    
    /// Decodes Base64 string to text
    /// - Parameters:
    ///   - base64: The Base64 string to decode
    ///   - variant: Base64 variant (standard or URL-safe)
    /// - Returns: Decoded text
    /// - Throws: Base64Error if decoding fails
    func decodeText(_ base64: String, variant: Base64Variant = .standard) throws -> String {
        guard !base64.isEmpty else {
            throw Base64Error.emptyInput
        }
        
        let data = try decodeData(base64, variant: variant)
        
        guard let text = String(data: data, encoding: .utf8) else {
            throw Base64Error.decodingFailed
        }
        
        return text
    }
    
    // MARK: - Data Encoding
    
    /// Encodes raw data to Base64
    /// - Parameters:
    ///   - data: The data to encode
    ///   - variant: Base64 variant (standard or URL-safe)
    /// - Returns: Base64 encoded string
    func encodeData(_ data: Data, variant: Base64Variant = .standard) -> String {
        let base64 = data.base64EncodedString()
        
        switch variant {
        case .standard:
            return base64
        case .urlSafe:
            return base64
                .replacingOccurrences(of: "+", with: "-")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "=", with: "")
        }
    }
    
    /// Decodes Base64 string to raw data
    /// - Parameters:
    ///   - base64: The Base64 string to decode
    ///   - variant: Base64 variant (standard or URL-safe)
    /// - Returns: Decoded data
    /// - Throws: Base64Error if decoding fails
    func decodeData(_ base64: String, variant: Base64Variant = .standard) throws -> Data {
        // Remove all whitespace/newlines so we can decode formatted strings too
        var processedString = removeFormatting(base64)
        
        // Handle URL-safe variant
        if variant == .urlSafe {
            processedString = processedString
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            
            // Add padding if needed
            let remainder = processedString.count % 4
            if remainder > 0 {
                processedString += String(repeating: "=", count: 4 - remainder)
            }
        }
        
        guard let data = Data(base64Encoded: processedString) else {
            throw Base64Error.invalidBase64String
        }
        
        return data
    }
    
    // MARK: - File Operations
    
    /// Encodes file data to Base64
    /// - Parameters:
    ///   - url: URL of the file to encode
    ///   - variant: Base64 variant (standard or URL-safe)
    /// - Returns: Base64 encoded string
    /// - Throws: Base64Error or file errors
    func encodeFile(at url: URL, variant: Base64Variant = .standard) throws -> String {
        let data = try Data(contentsOf: url)
        return encodeData(data, variant: variant)
    }
    
    /// Decodes Base64 string and saves to file
    /// - Parameters:
    ///   - base64: The Base64 string to decode
    ///   - url: Destination URL for the decoded file
    ///   - variant: Base64 variant (standard or URL-safe)
    /// - Throws: Base64Error or file errors
    func decodeToFile(_ base64: String, to url: URL, variant: Base64Variant = .standard) throws {
        let data = try decodeData(base64, variant: variant)
        try data.write(to: url)
    }
    
    // MARK: - Utilities
    
    /// Validates if a string is valid Base64
    /// - Parameter string: The string to validate
    /// - Returns: true if valid Base64
    func isValidBase64(_ string: String) -> Bool {
        let cleanString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Empty string is not valid
        guard !cleanString.isEmpty else { return false }
        
        // Try to decode
        return Data(base64Encoded: cleanString) != nil
    }
    
    /// Formats Base64 string with line breaks (for readability)
    /// - Parameters:
    ///   - base64: The Base64 string to format
    ///   - lineLength: Characters per line (default 76, per RFC 2045)
    /// - Returns: Formatted Base64 string with line breaks
    func formatWithLineBreaks(_ base64: String, lineLength: Int = 76) -> String {
        var result = ""
        var index = base64.startIndex
        
        while index < base64.endIndex {
            let endIndex = base64.index(index, offsetBy: lineLength, limitedBy: base64.endIndex) ?? base64.endIndex
            result += base64[index..<endIndex]
            
            if endIndex < base64.endIndex {
                result += "\n"
            }
            
            index = endIndex
        }
        
        return result
    }
    
    /// Removes line breaks and whitespace from Base64 string
    /// - Parameter base64: The Base64 string to clean
    /// - Returns: Cleaned Base64 string
    func removeFormatting(_ base64: String) -> String {
        return base64.components(separatedBy: .whitespacesAndNewlines).joined()
    }
    
    /// Gets information about the decoded size
    /// - Parameter base64: The Base64 string
    /// - Returns: Approximate decoded size in bytes
    func getDecodedSize(_ base64: String) -> Int {
        let cleanString = removeFormatting(base64)
        let padding = cleanString.filter { $0 == "=" }.count
        return (cleanString.count * 3) / 4 - padding
    }
}

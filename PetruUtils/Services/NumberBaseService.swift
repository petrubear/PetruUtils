import Foundation

/// Service for converting numbers between different bases (Binary, Octal, Decimal, Hexadecimal)
struct NumberBaseService {
    
    // MARK: - Error Types
    
    enum NumberBaseError: LocalizedError {
        case invalidBinaryInput
        case invalidOctalInput
        case invalidDecimalInput
        case invalidHexInput
        case valueOutOfRange
        case emptyInput
        case invalidFormat
        
        var errorDescription: String? {
            switch self {
            case .invalidBinaryInput:
                return "Invalid binary input. Only 0 and 1 are allowed."
            case .invalidOctalInput:
                return "Invalid octal input. Only digits 0-7 are allowed."
            case .invalidDecimalInput:
                return "Invalid decimal input. Only digits 0-9 and optional minus sign are allowed."
            case .invalidHexInput:
                return "Invalid hexadecimal input. Only digits 0-9 and letters A-F are allowed."
            case .valueOutOfRange:
                return "Value is out of range for 64-bit integer."
            case .emptyInput:
                return "Input cannot be empty."
            case .invalidFormat:
                return "Invalid number format."
            }
        }
    }
    
    // MARK: - Base Conversion Methods
    
    /// Convert from decimal to binary
    func decimalToBinary(_ decimal: Int64) -> String {
        if decimal == 0 {
            return "0"
        }
        
        if decimal < 0 {
            // For negative numbers, show two's complement representation
            let unsigned = UInt64(bitPattern: decimal)
            return String(unsigned, radix: 2)
        }
        
        return String(decimal, radix: 2)
    }
    
    /// Convert from decimal to octal
    func decimalToOctal(_ decimal: Int64) -> String {
        if decimal == 0 {
            return "0"
        }
        
        if decimal < 0 {
            let unsigned = UInt64(bitPattern: decimal)
            return String(unsigned, radix: 8)
        }
        
        return String(decimal, radix: 8)
    }
    
    /// Convert from decimal to hexadecimal
    func decimalToHex(_ decimal: Int64) -> String {
        if decimal == 0 {
            return "0"
        }
        
        if decimal < 0 {
            let unsigned = UInt64(bitPattern: decimal)
            return String(unsigned, radix: 16).uppercased()
        }
        
        return String(decimal, radix: 16).uppercased()
    }
    
    /// Convert from binary string to decimal
    func binaryToDecimal(_ binary: String) throws -> Int64 {
        let cleaned = cleanInput(binary)
        
        guard !cleaned.isEmpty else {
            throw NumberBaseError.emptyInput
        }
        
        // Check for valid binary characters
        let validChars = CharacterSet(charactersIn: "01")
        guard cleaned.unicodeScalars.allSatisfy({ validChars.contains($0) }) else {
            throw NumberBaseError.invalidBinaryInput
        }
        
        // Handle values that fit in Int64
        if cleaned.count <= 63 {
            guard let value = Int64(cleaned, radix: 2) else {
                throw NumberBaseError.invalidFormat
            }
            return value
        }
        
        // Handle 64-bit values (might be negative in two's complement)
        if cleaned.count == 64 {
            guard let unsignedValue = UInt64(cleaned, radix: 2) else {
                throw NumberBaseError.invalidFormat
            }
            return Int64(bitPattern: unsignedValue)
        }
        
        // Too long
        throw NumberBaseError.valueOutOfRange
    }
    
    /// Convert from octal string to decimal
    func octalToDecimal(_ octal: String) throws -> Int64 {
        let cleaned = cleanInput(octal)
        
        guard !cleaned.isEmpty else {
            throw NumberBaseError.emptyInput
        }
        
        // Check for valid octal characters
        let validChars = CharacterSet(charactersIn: "01234567")
        guard cleaned.unicodeScalars.allSatisfy({ validChars.contains($0) }) else {
            throw NumberBaseError.invalidOctalInput
        }
        
        // Handle values that fit in signed Int64 (21 octal digits max)
        if cleaned.count <= 21 {
            guard let value = Int64(cleaned, radix: 8) else {
                throw NumberBaseError.invalidFormat
            }
            return value
        }
        
        // Handle 22-digit octal (64-bit unsigned)
        if cleaned.count == 22 {
            guard let unsignedValue = UInt64(cleaned, radix: 8) else {
                throw NumberBaseError.invalidFormat
            }
            // Check if it fits in Int64
            if unsignedValue <= UInt64(Int64.max) {
                return Int64(unsignedValue)
            }
            return Int64(bitPattern: unsignedValue)
        }
        
        throw NumberBaseError.valueOutOfRange
    }
    
    /// Convert from hexadecimal string to decimal
    func hexToDecimal(_ hex: String) throws -> Int64 {
        let cleaned = cleanInput(hex)
        
        guard !cleaned.isEmpty else {
            throw NumberBaseError.emptyInput
        }
        
        // Check for valid hex characters
        let validChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        guard cleaned.unicodeScalars.allSatisfy({ validChars.contains($0) }) else {
            throw NumberBaseError.invalidHexInput
        }
        
        // Handle values that fit in signed Int64 (15 hex digits max)
        if cleaned.count <= 15 {
            guard let value = Int64(cleaned, radix: 16) else {
                throw NumberBaseError.invalidFormat
            }
            return value
        }
        
        // Handle 16-digit hex (64-bit unsigned)
        if cleaned.count == 16 {
            guard let unsignedValue = UInt64(cleaned, radix: 16) else {
                throw NumberBaseError.invalidFormat
            }
            return Int64(bitPattern: unsignedValue)
        }
        
        throw NumberBaseError.valueOutOfRange
    }
    
    /// Convert from decimal string to Int64
    func decimalStringToInt64(_ decimal: String) throws -> Int64 {
        let cleaned = decimal.trimmingCharacters(in: .whitespaces)
        
        guard !cleaned.isEmpty else {
            throw NumberBaseError.emptyInput
        }
        
        guard let value = Int64(cleaned) else {
            throw NumberBaseError.invalidDecimalInput
        }
        
        return value
    }
    
    // MARK: - Bit Representation
    
    /// Get bit representation as groups of 8 bits
    func getBitRepresentation(_ decimal: Int64) -> String {
        let binary = String(UInt64(bitPattern: decimal), radix: 2)
        let padded = String(repeating: "0", count: 64 - binary.count) + binary
        
        // Group into 8-bit chunks
        var result: [String] = []
        for i in stride(from: 0, to: 64, by: 8) {
            let start = padded.index(padded.startIndex, offsetBy: i)
            let end = padded.index(start, offsetBy: 8)
            result.append(String(padded[start..<end]))
        }
        
        return result.joined(separator: " ")
    }
    
    /// Get byte representation (8 bytes for 64-bit integer)
    func getByteRepresentation(_ decimal: Int64) -> String {
        let unsigned = UInt64(bitPattern: decimal)
        var bytes: [String] = []
        
        for i in (0..<8).reversed() {
            let byte = (unsigned >> (i * 8)) & 0xFF
            bytes.append(String(format: "%02X", byte))
        }
        
        return bytes.joined(separator: " ")
    }
    
    // MARK: - Conversion Results
    
    struct ConversionResult {
        let decimal: Int64
        let binary: String
        let octal: String
        let hex: String
        let bitRepresentation: String
        let byteRepresentation: String
        let isSigned: Bool
        
        var decimalString: String {
            String(decimal)
        }
    }
    
    /// Convert from any base to all bases
    func convertFromBinary(_ binary: String) throws -> ConversionResult {
        let decimal = try binaryToDecimal(binary)
        return createResult(from: decimal)
    }
    
    func convertFromOctal(_ octal: String) throws -> ConversionResult {
        let decimal = try octalToDecimal(octal)
        return createResult(from: decimal)
    }
    
    func convertFromDecimal(_ decimalStr: String) throws -> ConversionResult {
        let decimal = try decimalStringToInt64(decimalStr)
        return createResult(from: decimal)
    }
    
    func convertFromHex(_ hex: String) throws -> ConversionResult {
        let decimal = try hexToDecimal(hex)
        return createResult(from: decimal)
    }
    
    // MARK: - Helper Methods
    
    private func createResult(from decimal: Int64) -> ConversionResult {
        ConversionResult(
            decimal: decimal,
            binary: decimalToBinary(decimal),
            octal: decimalToOctal(decimal),
            hex: decimalToHex(decimal),
            bitRepresentation: getBitRepresentation(decimal),
            byteRepresentation: getByteRepresentation(decimal),
            isSigned: decimal < 0
        )
    }
    
    private func cleanInput(_ input: String) -> String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
    }
}

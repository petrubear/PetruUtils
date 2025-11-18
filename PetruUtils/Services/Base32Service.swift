import Foundation

struct Base32Service {
    enum Base32Error: LocalizedError {
        case invalidBase32Input
        case invalidEncoding
        
        var errorDescription: String? {
            switch self {
            case .invalidBase32Input:
                return "Invalid Base32 input. Base32 should only contain A-Z and 2-7."
            case .invalidEncoding:
                return "Failed to encode data to Base32."
            }
        }
    }
    
    enum Variant {
        case standard       // RFC 4648 standard alphabet (A-Z, 2-7)
        case hex            // RFC 4648 extended hex alphabet (0-9, A-V)
        
        var alphabet: String {
            switch self {
            case .standard: return "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
            case .hex: return "0123456789ABCDEFGHIJKLMNOPQRSTUV"
            }
        }
        
        var padding: Character { "=" }
    }
    
    // MARK: - Encoding
    
    func encode(_ text: String, variant: Variant = .standard) throws -> String {
        guard let data = text.data(using: .utf8) else {
            throw Base32Error.invalidEncoding
        }
        return encodeData(data, variant: variant)
    }
    
    private func encodeData(_ data: Data, variant: Variant) -> String {
        let alphabet = variant.alphabet
        var result = ""
        var buffer: UInt64 = 0
        var bitsInBuffer = 0
        
        for byte in data {
            buffer = (buffer << 8) | UInt64(byte)
            bitsInBuffer += 8
            
            while bitsInBuffer >= 5 {
                bitsInBuffer -= 5
                let index = Int((buffer >> bitsInBuffer) & 0x1F)
                let char = alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)]
                result.append(char)
            }
        }
        
        // Handle remaining bits
        if bitsInBuffer > 0 {
            buffer = buffer << (5 - bitsInBuffer)
            let index = Int(buffer & 0x1F)
            let char = alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)]
            result.append(char)
        }
        
        // Add padding
        while result.count % 8 != 0 {
            result.append(variant.padding)
        }
        
        return result
    }
    
    // MARK: - Decoding
    
    func decode(_ base32: String, variant: Variant = .standard) throws -> String {
        let data = try decodeToData(base32, variant: variant)
        guard let text = String(data: data, encoding: .utf8) else {
            throw Base32Error.invalidEncoding
        }
        return text
    }
    
    private func decodeToData(_ base32: String, variant: Variant) throws -> Data {
        let alphabet = variant.alphabet
        var decoded = Data()
        var buffer: UInt64 = 0
        var bitsInBuffer = 0
        
        // Create lookup table
        var lookup = [Character: Int]()
        for (index, char) in alphabet.enumerated() {
            lookup[char] = index
        }
        
        // Remove padding and whitespace
        let cleaned = base32.uppercased().replacingOccurrences(of: String(variant.padding), with: "")
            .filter { !$0.isWhitespace }
        
        for char in cleaned {
            guard let value = lookup[char] else {
                throw Base32Error.invalidBase32Input
            }
            
            buffer = (buffer << 5) | UInt64(value)
            bitsInBuffer += 5
            
            if bitsInBuffer >= 8 {
                bitsInBuffer -= 8
                let byte = UInt8((buffer >> bitsInBuffer) & 0xFF)
                decoded.append(byte)
            }
        }
        
        return decoded
    }
    
    // MARK: - Validation
    
    func isValidBase32(_ text: String, variant: Variant = .standard) -> Bool {
        let alphabet = variant.alphabet
        let validChars = Set(alphabet + String(variant.padding))
        return text.uppercased().allSatisfy { validChars.contains($0) || $0.isWhitespace }
    }
}

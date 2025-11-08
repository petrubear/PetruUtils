import Foundation

/// Service for generating UUIDs and ULIDs
struct UUIDService {
    
    // MARK: - Types
    
    enum UUIDVersion: String, CaseIterable, Identifiable {
        case v1 = "UUID v1"
        case v4 = "UUID v4"
        case v5 = "UUID v5"
        case ulid = "ULID"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .v1: return "Time-based (MAC address + timestamp)"
            case .v4: return "Random (cryptographically secure)"
            case .v5: return "Name-based (SHA-1 hash)"
            case .ulid: return "Universally Unique Lexicographically Sortable ID"
            }
        }
    }
    
    enum UUIDFormat: String, CaseIterable, Identifiable {
        case lowercase = "lowercase"
        case uppercase = "UPPERCASE"
        case withHyphens = "with-hyphens"
        case withoutHyphens = "withouthyphens"
        
        var id: String { rawValue }
    }
    
    enum UUIDError: LocalizedError {
        case v5RequiresNamespace
        case v5RequiresName
        case invalidNamespace
        case ulidGenerationFailed
        
        var errorDescription: String? {
            switch self {
            case .v5RequiresNamespace:
                return "UUID v5 requires a namespace UUID"
            case .v5RequiresName:
                return "UUID v5 requires a name string"
            case .invalidNamespace:
                return "Invalid namespace UUID format"
            case .ulidGenerationFailed:
                return "Failed to generate ULID"
            }
        }
    }
    
    // MARK: - UUID Generation
    
    /// Generates a single UUID
    /// - Parameters:
    ///   - version: UUID version to generate
    ///   - namespace: Namespace UUID (required for v5)
    ///   - name: Name string (required for v5)
    /// - Returns: Generated UUID string
    func generateUUID(
        version: UUIDVersion,
        namespace: String? = nil,
        name: String? = nil
    ) throws -> String {
        switch version {
        case .v1:
            return generateUUIDv1()
        case .v4:
            return UUID().uuidString
        case .v5:
            return try generateUUIDv5(namespace: namespace, name: name)
        case .ulid:
            return try generateULID()
        }
    }
    
    /// Generates multiple UUIDs
    /// - Parameters:
    ///   - count: Number of UUIDs to generate (1-1000)
    ///   - version: UUID version to generate
    ///   - namespace: Namespace UUID (for v5)
    ///   - namePrefix: Name prefix (for v5, will append numbers)
    /// - Returns: Array of generated UUID strings
    func generateBulk(
        count: Int,
        version: UUIDVersion,
        namespace: String? = nil,
        namePrefix: String? = nil
    ) throws -> [String] {
        let safeCount = min(max(count, 1), 1000)
        var results: [String] = []
        
        for i in 0..<safeCount {
            if version == .v5, let prefix = namePrefix {
                let name = "\(prefix)\(i)"
                results.append(try generateUUID(version: version, namespace: namespace, name: name))
            } else {
                results.append(try generateUUID(version: version, namespace: namespace, name: nil))
            }
        }
        
        return results
    }
    
    // MARK: - Formatting
    
    /// Formats UUID string according to specified format
    /// - Parameters:
    ///   - uuid: UUID string to format
    ///   - format: Desired format
    /// - Returns: Formatted UUID string
    func format(_ uuid: String, as format: UUIDFormat) -> String {
        let cleaned = uuid.replacingOccurrences(of: "-", with: "")
        
        switch format {
        case .lowercase:
            return insertHyphens(cleaned.lowercased())
        case .uppercase:
            return insertHyphens(cleaned.uppercased())
        case .withHyphens:
            return insertHyphens(cleaned)
        case .withoutHyphens:
            return cleaned
        }
    }
    
    /// Formats an array of UUIDs
    func formatBulk(_ uuids: [String], as format: UUIDFormat) -> [String] {
        uuids.map { self.format($0, as: format) }
    }
    
    // MARK: - Validation
    
    /// Validates if a string is a valid UUID format
    /// - Parameter string: String to validate
    /// - Returns: true if valid UUID format
    func isValidUUID(_ string: String) -> Bool {
        let uuidPattern = "^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$"
        let regex = try? NSRegularExpression(pattern: uuidPattern)
        let range = NSRange(string.startIndex..., in: string)
        return regex?.firstMatch(in: string, range: range) != nil
    }
    
    /// Validates if a string is a valid ULID format
    /// - Parameter string: String to validate
    /// - Returns: true if valid ULID format
    func isValidULID(_ string: String) -> Bool {
        // ULID is 26 characters: 10 timestamp + 16 random (Crockford's Base32)
        guard string.count == 26 else { return false }
        
        let validChars = CharacterSet(charactersIn: "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        let stringChars = CharacterSet(charactersIn: string.uppercased())
        
        return validChars.isSuperset(of: stringChars)
    }
    
    // MARK: - Private UUID Generation
    
    /// Generates UUID v1 (time-based)
    private func generateUUIDv1() -> String {
        // Swift doesn't have native v1 support, so we'll simulate it
        // by creating a v4 and manipulating the version bits
        var uuid = UUID().uuid
        
        // Set version to 1 (bits 12-15 of time_hi_and_version)
        uuid.6 = (uuid.6 & 0x0F) | 0x10
        
        // Set variant to RFC 4122 (bits 6-7 of clock_seq_hi_and_reserved)
        uuid.8 = (uuid.8 & 0x3F) | 0x80
        
        return uuidFromBytes(uuid)
    }
    
    /// Generates UUID v5 (name-based SHA-1)
    private func generateUUIDv5(namespace: String?, name: String?) throws -> String {
        guard let namespace = namespace, !namespace.isEmpty else {
            throw UUIDError.v5RequiresNamespace
        }
        
        guard let name = name, !name.isEmpty else {
            throw UUIDError.v5RequiresName
        }
        
        guard let namespaceUUID = UUID(uuidString: namespace) else {
            throw UUIDError.invalidNamespace
        }
        
        // Combine namespace UUID bytes and name bytes
        var data = Data()
        withUnsafeBytes(of: namespaceUUID.uuid) { data.append(contentsOf: $0) }
        if let nameData = name.data(using: .utf8) {
            data.append(nameData)
        }
        
        // SHA-1 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        // Set version (4 bits) and variant (2 bits)
        hash[6] = (hash[6] & 0x0F) | 0x50  // Version 5
        hash[8] = (hash[8] & 0x3F) | 0x80  // Variant RFC 4122
        
        // Convert first 16 bytes to UUID string
        return String(format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                     hash[0], hash[1], hash[2], hash[3],
                     hash[4], hash[5], hash[6], hash[7],
                     hash[8], hash[9], hash[10], hash[11],
                     hash[12], hash[13], hash[14], hash[15])
    }
    
    // MARK: - ULID Generation
    
    /// Generates a ULID (Universally Unique Lexicographically Sortable Identifier)
    private func generateULID() throws -> String {
        // ULID structure: 48 bits timestamp + 80 bits randomness = 128 bits total
        // Encoded as 26 Crockford Base32 characters
        
        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000) // milliseconds
        
        // Generate 10 bytes of randomness
        var randomBytes = [UInt8](repeating: 0, count: 10)
        let result = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        guard result == errSecSuccess else {
            throw UUIDError.ulidGenerationFailed
        }
        
        // Encode timestamp (48 bits = 10 chars in Base32)
        var encoded = encodeBase32(value: timestamp, length: 10)
        
        // Encode randomness (80 bits = 16 chars in Base32)
        let randomValue = randomBytes.reduce(UInt64(0)) { result, byte in
            (result << 8) | UInt64(byte)
        }
        encoded += encodeBase32(value: randomValue, length: 16)
        
        return encoded
    }
    
    /// Encodes a value as Crockford Base32
    private func encodeBase32(value: UInt64, length: Int) -> String {
        let alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
        var result = ""
        var val = value
        
        for _ in 0..<length {
            let index = Int(val % 32)
            let char = alphabet[alphabet.index(alphabet.startIndex, offsetBy: index)]
            result = String(char) + result
            val /= 32
        }
        
        return result
    }
    
    // MARK: - Helpers
    
    private func insertHyphens(_ uuid: String) -> String {
        guard uuid.count == 32 else { return uuid }
        
        let index8 = uuid.index(uuid.startIndex, offsetBy: 8)
        let index12 = uuid.index(uuid.startIndex, offsetBy: 12)
        let index16 = uuid.index(uuid.startIndex, offsetBy: 16)
        let index20 = uuid.index(uuid.startIndex, offsetBy: 20)
        
        return "\(uuid[..<index8])-\(uuid[index8..<index12])-\(uuid[index12..<index16])-\(uuid[index16..<index20])-\(uuid[index20...])"
    }
    
    private func uuidFromBytes(_ uuid: uuid_t) -> String {
        return String(format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                     uuid.0, uuid.1, uuid.2, uuid.3,
                     uuid.4, uuid.5, uuid.6, uuid.7,
                     uuid.8, uuid.9, uuid.10, uuid.11,
                     uuid.12, uuid.13, uuid.14, uuid.15)
    }
    
    // MARK: - Common Namespaces
    
    static let namespaceURL = "6ba7b811-9dad-11d1-80b4-00c04fd430c8"
    static let namespaceDNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"
    static let namespaceOID = "6ba7b812-9dad-11d1-80b4-00c04fd430c8"
    static let namespaceX500 = "6ba7b814-9dad-11d1-80b4-00c04fd430c8"
}

// Import CommonCrypto for SHA-1
import CommonCrypto

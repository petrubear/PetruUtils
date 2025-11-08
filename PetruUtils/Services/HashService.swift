import Foundation
import CryptoKit

/// Service for generating cryptographic hashes
struct HashService {
    
    // MARK: - Types
    
    enum HashAlgorithm: String, CaseIterable, Identifiable {
        case md5 = "MD5"
        case sha1 = "SHA-1"
        case sha256 = "SHA-256"
        case sha384 = "SHA-384"
        case sha512 = "SHA-512"
        
        var id: String { rawValue }
        
        var displayName: String { rawValue }
        
        var outputLength: Int {
            switch self {
            case .md5: return 32
            case .sha1: return 40
            case .sha256: return 64
            case .sha384: return 96
            case .sha512: return 128
            }
        }
    }
    
    enum HashError: LocalizedError {
        case emptyInput
        case invalidFile
        case fileReadError
        case hmacRequiresKey
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input cannot be empty"
            case .invalidFile:
                return "Invalid file path or file not found"
            case .fileReadError:
                return "Failed to read file contents"
            case .hmacRequiresKey:
                return "HMAC mode requires a secret key"
            }
        }
    }
    
    // MARK: - Hash Text
    
    /// Generates hash from text
    /// - Parameters:
    ///   - text: The text to hash
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hex-encoded hash string
    /// - Throws: HashError if input is invalid
    func hashText(_ text: String, algorithm: HashAlgorithm) throws -> String {
        guard !text.isEmpty else {
            throw HashError.emptyInput
        }
        
        guard let data = text.data(using: .utf8) else {
            throw HashError.emptyInput
        }
        
        return hashData(data, algorithm: algorithm)
    }
    
    // MARK: - Hash File
    
    /// Generates hash from file
    /// - Parameters:
    ///   - url: URL of the file to hash
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hex-encoded hash string
    /// - Throws: HashError if file cannot be read
    func hashFile(at url: URL, algorithm: HashAlgorithm) throws -> String {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw HashError.invalidFile
        }
        
        guard let data = try? Data(contentsOf: url) else {
            throw HashError.fileReadError
        }
        
        return hashData(data, algorithm: algorithm)
    }
    
    // MARK: - HMAC
    
    /// Generates HMAC from text
    /// - Parameters:
    ///   - text: The text to hash
    ///   - key: Secret key for HMAC
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hex-encoded HMAC string
    /// - Throws: HashError if input is invalid
    func hmacText(_ text: String, key: String, algorithm: HashAlgorithm) throws -> String {
        guard !text.isEmpty else {
            throw HashError.emptyInput
        }
        
        guard !key.isEmpty else {
            throw HashError.hmacRequiresKey
        }
        
        guard let data = text.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            throw HashError.emptyInput
        }
        
        return hmacData(data, key: keyData, algorithm: algorithm)
    }
    
    /// Generates HMAC from file
    /// - Parameters:
    ///   - url: URL of the file to hash
    ///   - key: Secret key for HMAC
    ///   - algorithm: Hash algorithm to use
    /// - Returns: Hex-encoded HMAC string
    /// - Throws: HashError if file cannot be read
    func hmacFile(at url: URL, key: String, algorithm: HashAlgorithm) throws -> String {
        guard !key.isEmpty else {
            throw HashError.hmacRequiresKey
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw HashError.invalidFile
        }
        
        guard let data = try? Data(contentsOf: url),
              let keyData = key.data(using: .utf8) else {
            throw HashError.fileReadError
        }
        
        return hmacData(data, key: keyData, algorithm: algorithm)
    }
    
    // MARK: - Verification
    
    /// Verifies if text produces the expected hash
    /// - Parameters:
    ///   - text: Text to verify
    ///   - expectedHash: Expected hash value
    ///   - algorithm: Hash algorithm to use
    /// - Returns: true if hash matches
    func verifyHash(text: String, expectedHash: String, algorithm: HashAlgorithm) -> Bool {
        guard let computedHash = try? hashText(text, algorithm: algorithm) else {
            return false
        }
        return timingSafeEqual(computedHash.lowercased(), expectedHash.lowercased())
    }
    
    /// Verifies if file produces the expected hash
    /// - Parameters:
    ///   - url: URL of file to verify
    ///   - expectedHash: Expected hash value
    ///   - algorithm: Hash algorithm to use
    /// - Returns: true if hash matches
    func verifyFileHash(at url: URL, expectedHash: String, algorithm: HashAlgorithm) -> Bool {
        guard let computedHash = try? hashFile(at: url, algorithm: algorithm) else {
            return false
        }
        return timingSafeEqual(computedHash.lowercased(), expectedHash.lowercased())
    }
    
    // MARK: - Private Methods
    
    /// Hashes data using the specified algorithm
    private func hashData(_ data: Data, algorithm: HashAlgorithm) -> String {
        switch algorithm {
        case .md5:
            return Insecure.MD5.hash(data: data).hexString
        case .sha1:
            return Insecure.SHA1.hash(data: data).hexString
        case .sha256:
            return SHA256.hash(data: data).hexString
        case .sha384:
            return SHA384.hash(data: data).hexString
        case .sha512:
            return SHA512.hash(data: data).hexString
        }
    }
    
    /// Generates HMAC for data using the specified algorithm
    private func hmacData(_ data: Data, key: Data, algorithm: HashAlgorithm) -> String {
        switch algorithm {
        case .md5:
            let symmetricKey = SymmetricKey(data: key)
            return HMAC<Insecure.MD5>.authenticationCode(for: data, using: symmetricKey).hexString
        case .sha1:
            let symmetricKey = SymmetricKey(data: key)
            return HMAC<Insecure.SHA1>.authenticationCode(for: data, using: symmetricKey).hexString
        case .sha256:
            let symmetricKey = SymmetricKey(data: key)
            return HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey).hexString
        case .sha384:
            let symmetricKey = SymmetricKey(data: key)
            return HMAC<SHA384>.authenticationCode(for: data, using: symmetricKey).hexString
        case .sha512:
            let symmetricKey = SymmetricKey(data: key)
            return HMAC<SHA512>.authenticationCode(for: data, using: symmetricKey).hexString
        }
    }
    
    /// Timing-safe string comparison to prevent timing attacks
    private func timingSafeEqual(_ lhs: String, _ rhs: String) -> Bool {
        guard lhs.count == rhs.count else { return false }
        
        var result = 0
        for (c1, c2) in zip(lhs, rhs) {
            result |= Int(c1.asciiValue ?? 0) ^ Int(c2.asciiValue ?? 0)
        }
        return result == 0
    }
}

// MARK: - Hash Digest Extension

extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension HashedAuthenticationCode {
    var hexString: String {
        self.withUnsafeBytes { bytes in
            bytes.map { String(format: "%02x", $0) }.joined()
        }
    }
}

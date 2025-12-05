import Foundation
import CryptoKit

/// Service for bcrypt-style password hashing and verification
/// Note: This implementation uses PBKDF2 with SHA256 as a native macOS alternative to bcrypt
/// For production bcrypt, consider using a dedicated library
struct BcryptService {

    // MARK: - Error Types

    enum BcryptError: LocalizedError {
        case emptyPassword
        case emptyHash
        case invalidHashFormat
        case invalidCostFactor
        case hashGenerationFailed
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .emptyPassword:
                return "Password cannot be empty."
            case .emptyHash:
                return "Hash cannot be empty."
            case .invalidHashFormat:
                return "Invalid hash format. Expected format: $pbkdf2-sha256$cost$salt$hash"
            case .invalidCostFactor:
                return "Cost factor must be between 4 and 31."
            case .hashGenerationFailed:
                return "Failed to generate hash."
            case .verificationFailed:
                return "Password verification failed."
            }
        }
    }

    // MARK: - Hash Result

    struct HashResult: Equatable {
        let hash: String
        let algorithm: String
        let cost: Int
        let salt: String
        let derivedKey: String

        var fullHash: String {
            return "$pbkdf2-sha256$\(cost)$\(salt)$\(derivedKey)"
        }
    }

    // MARK: - Constants

    /// Minimum cost factor (2^4 = 16 iterations base)
    static let minCost = 4

    /// Maximum cost factor (2^31 iterations - extremely slow)
    static let maxCost = 31

    /// Default cost factor (2^12 = 4096 iterations base, multiplied by iteration count)
    static let defaultCost = 12

    /// Salt length in bytes
    private let saltLength = 16

    /// Derived key length in bytes
    private let keyLength = 32

    // MARK: - Public Methods

    /// Generate a hash for the given password
    func generateHash(password: String, cost: Int = defaultCost) throws -> HashResult {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw BcryptError.emptyPassword
        }

        guard cost >= BcryptService.minCost && cost <= BcryptService.maxCost else {
            throw BcryptError.invalidCostFactor
        }

        // Generate random salt
        var saltBytes = [UInt8](repeating: 0, count: saltLength)
        let status = SecRandomCopyBytes(kSecRandomDefault, saltLength, &saltBytes)

        guard status == errSecSuccess else {
            throw BcryptError.hashGenerationFailed
        }

        let salt = Data(saltBytes)
        let saltBase64 = salt.base64EncodedString()

        // Calculate iterations based on cost (2^cost)
        let iterations = 1 << cost

        // Derive key using PBKDF2
        guard let passwordData = trimmed.data(using: .utf8) else {
            throw BcryptError.hashGenerationFailed
        }

        let derivedKey = try deriveKey(password: passwordData, salt: salt, iterations: iterations)
        let derivedKeyBase64 = derivedKey.base64EncodedString()

        return HashResult(
            hash: "$pbkdf2-sha256$\(cost)$\(saltBase64)$\(derivedKeyBase64)",
            algorithm: "PBKDF2-SHA256",
            cost: cost,
            salt: saltBase64,
            derivedKey: derivedKeyBase64
        )
    }

    /// Verify a password against a hash
    func verifyPassword(password: String, hash: String) throws -> Bool {
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHash = hash.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPassword.isEmpty else {
            throw BcryptError.emptyPassword
        }

        guard !trimmedHash.isEmpty else {
            throw BcryptError.emptyHash
        }

        // Parse the hash
        let components = trimmedHash.split(separator: "$").map { String($0) }

        // Expected: ["pbkdf2-sha256", "cost", "salt", "derivedKey"]
        guard components.count == 4,
              components[0] == "pbkdf2-sha256",
              let cost = Int(components[1]),
              cost >= BcryptService.minCost && cost <= BcryptService.maxCost else {
            throw BcryptError.invalidHashFormat
        }

        let saltBase64 = components[2]
        let expectedKeyBase64 = components[3]

        guard let salt = Data(base64Encoded: saltBase64),
              let expectedKey = Data(base64Encoded: expectedKeyBase64),
              let passwordData = trimmedPassword.data(using: .utf8) else {
            throw BcryptError.invalidHashFormat
        }

        let iterations = 1 << cost

        // Derive key with same parameters
        let derivedKey = try deriveKey(password: passwordData, salt: salt, iterations: iterations)

        // Timing-safe comparison
        return timingSafeCompare(derivedKey, expectedKey)
    }

    /// Parse a hash to extract its components
    func parseHash(_ hash: String) throws -> (algorithm: String, cost: Int, salt: String, derivedKey: String) {
        let trimmed = hash.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw BcryptError.emptyHash
        }

        let components = trimmed.split(separator: "$").map { String($0) }

        guard components.count == 4,
              components[0] == "pbkdf2-sha256",
              let cost = Int(components[1]),
              cost >= BcryptService.minCost && cost <= BcryptService.maxCost else {
            throw BcryptError.invalidHashFormat
        }

        return (
            algorithm: "PBKDF2-SHA256",
            cost: cost,
            salt: components[2],
            derivedKey: components[3]
        )
    }

    /// Get estimated time for hash generation at a given cost
    func estimatedTime(for cost: Int) -> String {
        // Rough estimates based on typical hardware
        let baseTime: Double = 0.001 // 1ms for cost=4

        // Time doubles with each cost increase
        let multiplier = Double(1 << (cost - 4))
        let estimatedMs = baseTime * multiplier * 1000

        if estimatedMs < 1000 {
            return String(format: "~%.0fms", estimatedMs)
        } else if estimatedMs < 60000 {
            return String(format: "~%.1fs", estimatedMs / 1000)
        } else if estimatedMs < 3600000 {
            return String(format: "~%.1f min", estimatedMs / 60000)
        } else {
            return String(format: "~%.1f hours", estimatedMs / 3600000)
        }
    }

    // MARK: - Private Methods

    private func deriveKey(password: Data, salt: Data, iterations: Int) throws -> Data {
        var derivedKey = Data(count: keyLength)

        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBytes in
            password.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedKeyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        keyLength
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            throw BcryptError.hashGenerationFailed
        }

        return derivedKey
    }

    private func timingSafeCompare(_ a: Data, _ b: Data) -> Bool {
        guard a.count == b.count else {
            return false
        }

        var result: UInt8 = 0
        for (byteA, byteB) in zip(a, b) {
            result |= byteA ^ byteB
        }

        return result == 0
    }
}

// MARK: - CommonCrypto Import

import CommonCrypto

import Foundation
import CryptoKit

/// Service for generating Time-based One-Time Passwords (TOTP) per RFC 6238
struct TOTPService {

    // MARK: - Error Types

    enum TOTPError: LocalizedError {
        case emptySecret
        case invalidBase32Secret
        case invalidDigits
        case invalidPeriod
        case invalidAlgorithm

        var errorDescription: String? {
            switch self {
            case .emptySecret:
                return "Secret key cannot be empty."
            case .invalidBase32Secret:
                return "Invalid Base32 encoded secret. Secret must contain only A-Z and 2-7."
            case .invalidDigits:
                return "Digits must be between 6 and 8."
            case .invalidPeriod:
                return "Period must be between 15 and 120 seconds."
            case .invalidAlgorithm:
                return "Unsupported algorithm."
            }
        }
    }

    // MARK: - Supported Algorithms

    enum Algorithm: String, CaseIterable, Identifiable {
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case sha512 = "SHA512"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sha1: return "SHA-1 (Default)"
            case .sha256: return "SHA-256"
            case .sha512: return "SHA-512"
            }
        }
    }

    // MARK: - TOTP Configuration

    struct TOTPConfig: Equatable {
        var secret: String
        var digits: Int = 6
        var period: Int = 30
        var algorithm: Algorithm = .sha1
        var issuer: String?
        var accountName: String?
    }

    // MARK: - TOTP Result

    struct TOTPResult: Equatable {
        let code: String
        let remainingSeconds: Int
        let period: Int
        let timestamp: Date

        var progress: Double {
            Double(remainingSeconds) / Double(period)
        }
    }

    // MARK: - Constants

    static let minDigits = 6
    static let maxDigits = 8
    static let defaultDigits = 6
    static let minPeriod = 15
    static let maxPeriod = 120
    static let defaultPeriod = 30

    // MARK: - Public Methods

    /// Generate current TOTP code
    func generateTOTP(config: TOTPConfig, at date: Date = Date()) throws -> TOTPResult {
        try validateConfig(config)

        let secretData = try decodeBase32(config.secret)
        let counter = getCounter(for: date, period: config.period)
        let code = try generateCode(secret: secretData, counter: counter, digits: config.digits, algorithm: config.algorithm)

        let remainingSeconds = config.period - Int(date.timeIntervalSince1970) % config.period

        return TOTPResult(
            code: code,
            remainingSeconds: remainingSeconds,
            period: config.period,
            timestamp: date
        )
    }

    /// Generate TOTP code for a specific counter value (useful for testing)
    func generateTOTP(config: TOTPConfig, counter: UInt64) throws -> String {
        try validateConfig(config)

        let secretData = try decodeBase32(config.secret)
        return try generateCode(secret: secretData, counter: counter, digits: config.digits, algorithm: config.algorithm)
    }

    /// Get next N TOTP codes
    func getNextCodes(config: TOTPConfig, count: Int = 5, from date: Date = Date()) throws -> [(code: String, validFrom: Date, validUntil: Date)] {
        try validateConfig(config)

        var results: [(code: String, validFrom: Date, validUntil: Date)] = []
        let secretData = try decodeBase32(config.secret)

        let baseCounter = getCounter(for: date, period: config.period)

        for i in 0..<count {
            let counter = baseCounter + UInt64(i)
            let code = try generateCode(secret: secretData, counter: counter, digits: config.digits, algorithm: config.algorithm)

            let validFrom = Date(timeIntervalSince1970: Double(counter) * Double(config.period))
            let validUntil = validFrom.addingTimeInterval(Double(config.period))

            results.append((code: code, validFrom: validFrom, validUntil: validUntil))
        }

        return results
    }

    /// Verify a TOTP code (with optional window for clock skew)
    func verifyTOTP(code: String, config: TOTPConfig, window: Int = 1, at date: Date = Date()) throws -> Bool {
        try validateConfig(config)

        let secretData = try decodeBase32(config.secret)
        let baseCounter = getCounter(for: date, period: config.period)

        // Check codes within the window
        for offset in -window...window {
            let counter = UInt64(Int64(baseCounter) + Int64(offset))
            let expectedCode = try generateCode(secret: secretData, counter: counter, digits: config.digits, algorithm: config.algorithm)

            if timingSafeCompare(code, expectedCode) {
                return true
            }
        }

        return false
    }

    /// Generate otpauth:// URI for QR code
    func generateOTPAuthURI(config: TOTPConfig) throws -> String {
        try validateConfig(config)

        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = "totp"

        // Build label
        var label = ""
        if let issuer = config.issuer, !issuer.isEmpty {
            label += issuer + ":"
        }
        if let account = config.accountName, !account.isEmpty {
            label += account
        } else {
            label += "Unknown"
        }
        components.path = "/" + label

        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "secret", value: config.secret.uppercased().replacingOccurrences(of: " ", with: "")))
        queryItems.append(URLQueryItem(name: "digits", value: String(config.digits)))
        queryItems.append(URLQueryItem(name: "period", value: String(config.period)))
        queryItems.append(URLQueryItem(name: "algorithm", value: config.algorithm.rawValue))

        if let issuer = config.issuer, !issuer.isEmpty {
            queryItems.append(URLQueryItem(name: "issuer", value: issuer))
        }

        components.queryItems = queryItems

        return components.string ?? ""
    }

    /// Parse an otpauth:// URI
    func parseOTPAuthURI(_ uri: String) throws -> TOTPConfig {
        guard let components = URLComponents(string: uri),
              components.scheme == "otpauth",
              components.host == "totp" else {
            throw TOTPError.invalidBase32Secret
        }

        var config = TOTPConfig(secret: "")

        // Parse query parameters
        if let queryItems = components.queryItems {
            for item in queryItems {
                switch item.name.lowercased() {
                case "secret":
                    config.secret = item.value ?? ""
                case "digits":
                    config.digits = Int(item.value ?? "") ?? Self.defaultDigits
                case "period":
                    config.period = Int(item.value ?? "") ?? Self.defaultPeriod
                case "algorithm":
                    if let algo = Algorithm(rawValue: item.value?.uppercased() ?? "") {
                        config.algorithm = algo
                    }
                case "issuer":
                    config.issuer = item.value
                default:
                    break
                }
            }
        }

        // Parse account from path
        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.contains(":") {
            let parts = path.split(separator: ":", maxSplits: 1)
            if parts.count == 2 {
                config.accountName = String(parts[1])
            }
        } else if !path.isEmpty {
            config.accountName = path
        }

        try validateConfig(config)

        return config
    }

    /// Validate secret is valid Base32
    func isValidBase32Secret(_ secret: String) -> Bool {
        let normalized = secret.uppercased().replacingOccurrences(of: " ", with: "")

        guard !normalized.isEmpty else { return false }

        // Base32 alphabet: A-Z and 2-7
        let base32Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")

        return normalized.unicodeScalars.allSatisfy { base32Chars.contains($0) }
    }

    // MARK: - Private Methods

    private func validateConfig(_ config: TOTPConfig) throws {
        let normalizedSecret = config.secret.uppercased().replacingOccurrences(of: " ", with: "")

        guard !normalizedSecret.isEmpty else {
            throw TOTPError.emptySecret
        }

        guard isValidBase32Secret(normalizedSecret) else {
            throw TOTPError.invalidBase32Secret
        }

        guard config.digits >= Self.minDigits && config.digits <= Self.maxDigits else {
            throw TOTPError.invalidDigits
        }

        guard config.period >= Self.minPeriod && config.period <= Self.maxPeriod else {
            throw TOTPError.invalidPeriod
        }
    }

    private func getCounter(for date: Date, period: Int) -> UInt64 {
        UInt64(date.timeIntervalSince1970) / UInt64(period)
    }

    private func generateCode(secret: Data, counter: UInt64, digits: Int, algorithm: Algorithm) throws -> String {
        // Convert counter to big-endian bytes
        var counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: &counterBigEndian, count: 8)

        // Generate HMAC
        let hmacData: Data

        switch algorithm {
        case .sha1:
            let key = SymmetricKey(data: secret)
            let hmac = HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key)
            hmacData = Data(hmac)
        case .sha256:
            let key = SymmetricKey(data: secret)
            let hmac = HMAC<SHA256>.authenticationCode(for: counterData, using: key)
            hmacData = Data(hmac)
        case .sha512:
            let key = SymmetricKey(data: secret)
            let hmac = HMAC<SHA512>.authenticationCode(for: counterData, using: key)
            hmacData = Data(hmac)
        }

        // Dynamic truncation
        let offset = Int(hmacData[hmacData.count - 1] & 0x0F)
        let truncatedHash = hmacData.subdata(in: offset..<(offset + 4))

        var number = truncatedHash.withUnsafeBytes { ptr in
            ptr.load(as: UInt32.self).bigEndian
        }
        number &= 0x7FFFFFFF

        // Generate code with specified digits
        let modulo = UInt32(pow(10.0, Double(digits)))
        let code = number % modulo

        return String(format: "%0\(digits)d", code)
    }

    private func decodeBase32(_ input: String) throws -> Data {
        let normalized = input.uppercased().replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "=", with: "")

        guard !normalized.isEmpty else {
            throw TOTPError.emptySecret
        }

        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var bits = ""

        for char in normalized {
            guard let index = alphabet.firstIndex(of: char) else {
                throw TOTPError.invalidBase32Secret
            }
            let value = alphabet.distance(from: alphabet.startIndex, to: index)
            bits += String(value, radix: 2).padLeft(toLength: 5, withPad: "0")
        }

        var bytes: [UInt8] = []
        var index = bits.startIndex

        while bits.distance(from: index, to: bits.endIndex) >= 8 {
            let endIndex = bits.index(index, offsetBy: 8)
            let byteString = String(bits[index..<endIndex])
            if let byte = UInt8(byteString, radix: 2) {
                bytes.append(byte)
            }
            index = endIndex
        }

        return Data(bytes)
    }

    private func timingSafeCompare(_ a: String, _ b: String) -> Bool {
        guard a.count == b.count else { return false }

        var result: UInt8 = 0
        for (charA, charB) in zip(a.utf8, b.utf8) {
            result |= charA ^ charB
        }

        return result == 0
    }
}

// MARK: - String Extension

private extension String {
    func padLeft(toLength length: Int, withPad pad: String) -> String {
        let needed = length - count
        if needed <= 0 {
            return self
        }
        return String(repeating: pad, count: needed) + self
    }
}

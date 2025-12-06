import Foundation
import CryptoKit
import Security

/// Service responsible for JWT encoding, decoding, and verification
struct JWTService {

    // MARK: - Types

    enum Algorithm: String, CaseIterable {
        case hs256 = "HS256"
        case hs384 = "HS384"
        case hs512 = "HS512"
        case rs256 = "RS256"
        case rs384 = "RS384"
        case rs512 = "RS512"
        case es256 = "ES256"
        case es384 = "ES384"
        case es512 = "ES512"
        case ps256 = "PS256"
        case ps384 = "PS384"
        case ps512 = "PS512"

        var isSymmetric: Bool {
            switch self {
            case .hs256, .hs384, .hs512: return true
            default: return false
            }
        }

        var isRSA: Bool {
            switch self {
            case .rs256, .rs384, .rs512, .ps256, .ps384, .ps512: return true
            default: return false
            }
        }

        var isECDSA: Bool {
            switch self {
            case .es256, .es384, .es512: return true
            default: return false
            }
        }

        var isPSS: Bool {
            switch self {
            case .ps256, .ps384, .ps512: return true
            default: return false
            }
        }
    }

    struct DecodedJWT {
        let header: [String: Any]
        let payload: [String: Any]
        let signature: String
        let headerJSON: String
        let payloadJSON: String
    }

    struct ClaimValidation {
        let claim: String
        let value: String
        let isValid: Bool
        let message: String
    }

    enum JWTError: LocalizedError, Equatable {
        case invalidSegmentCount
        case invalidBase64Encoding
        case invalidJSON
        case invalidAlgorithm
        case missingSecret
        case missingPublicKey
        case invalidPublicKey
        case signatureMismatch
        case unsupportedAlgorithm(String)

        var errorDescription: String? {
            switch self {
            case .invalidSegmentCount:
                return "JWT must have 3 segments (header.payload.signature)"
            case .invalidBase64Encoding:
                return "Invalid base64url encoding"
            case .invalidJSON:
                return "Invalid JSON structure"
            case .invalidAlgorithm:
                return "Unsupported algorithm"
            case .missingSecret:
                return "Secret is required for HMAC verification"
            case .missingPublicKey:
                return "Public key is required for RSA/ECDSA verification"
            case .invalidPublicKey:
                return "Invalid public key format"
            case .signatureMismatch:
                return "Signature verification failed"
            case .unsupportedAlgorithm(let alg):
                return "Unsupported algorithm: \(alg)"
            }
        }
    }
    
    // MARK: - Decoding
    
    /// Decodes a JWT token into its component parts
    /// - Parameter token: The JWT token string
    /// - Returns: Decoded JWT structure
    /// - Throws: JWTError if decoding fails
    func decode(_ token: String) throws -> DecodedJWT {
        let parts = token.split(separator: ".").map(String.init)
        
        guard parts.count == 3 else {
            throw JWTError.invalidSegmentCount
        }
        
        let headerData = try base64urlDecode(parts[0])
        let payloadData = try base64urlDecode(parts[1])
        
        guard let headerJSON = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any] else {
            throw JWTError.invalidJSON
        }
        
        guard let payloadJSON = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else {
            throw JWTError.invalidJSON
        }
        
        let headerPretty = try prettyJSON(from: headerData)
        let payloadPretty = try prettyJSON(from: payloadData)
        
        return DecodedJWT(
            header: headerJSON,
            payload: payloadJSON,
            signature: parts[2],
            headerJSON: headerPretty,
            payloadJSON: payloadPretty
        )
    }
    
    // MARK: - Verification
    
    /// Verifies the signature of a JWT token using HS256 algorithm
    /// - Parameters:
    ///   - token: The JWT token string
    ///   - secret: The shared secret for HMAC
    /// - Returns: true if signature is valid
    /// - Throws: JWTError if verification cannot be performed
    func verifyHS256(token: String, secret: String) throws -> Bool {
        guard !secret.isEmpty else {
            throw JWTError.missingSecret
        }
        
        let parts = token.split(separator: ".").map(String.init)
        
        guard parts.count == 3 else {
            throw JWTError.invalidSegmentCount
        }
        
        // Verify the algorithm in header
        let headerData = try base64urlDecode(parts[0])
        guard let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let alg = header["alg"] as? String,
              alg == "HS256" else {
            throw JWTError.invalidAlgorithm
        }
        
        let signingInput = Data((parts[0] + "." + parts[1]).utf8)
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: signingInput, using: key)
        let expectedSig = base64urlEncode(Data(mac))
        
        return timingSafeEquals(expectedSig, parts[2])
    }
    
    // MARK: - Unified Verification

    /// Verifies a JWT token with the specified algorithm
    /// - Parameters:
    ///   - token: The JWT token string
    ///   - algorithm: The algorithm to use for verification
    ///   - secret: The shared secret (for HMAC algorithms)
    ///   - publicKey: The public key in PEM format (for RSA/ECDSA algorithms)
    /// - Returns: true if signature is valid
    func verify(token: String, algorithm: Algorithm, secret: String? = nil, publicKey: String? = nil) throws -> Bool {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count == 3 else {
            throw JWTError.invalidSegmentCount
        }

        // Verify the algorithm in header matches
        let headerData = try base64urlDecode(parts[0])
        guard let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let alg = header["alg"] as? String,
              alg.uppercased() == algorithm.rawValue else {
            throw JWTError.invalidAlgorithm
        }

        let signingInput = Data((parts[0] + "." + parts[1]).utf8)
        let signatureData = try base64urlDecode(parts[2])

        switch algorithm {
        case .hs256:
            return try verifyHMAC(signingInput: signingInput, signature: signatureData, secret: secret, hash: .sha256)
        case .hs384:
            return try verifyHMAC(signingInput: signingInput, signature: signatureData, secret: secret, hash: .sha384)
        case .hs512:
            return try verifyHMAC(signingInput: signingInput, signature: signatureData, secret: secret, hash: .sha512)
        case .rs256:
            return try verifyRSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, algorithm: .rsaSignatureMessagePKCS1v15SHA256)
        case .rs384:
            return try verifyRSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, algorithm: .rsaSignatureMessagePKCS1v15SHA384)
        case .rs512:
            return try verifyRSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, algorithm: .rsaSignatureMessagePKCS1v15SHA512)
        case .ps256:
            return try verifyRSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, algorithm: .rsaSignatureMessagePSSSHA256)
        case .ps384:
            return try verifyRSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, algorithm: .rsaSignatureMessagePSSSHA384)
        case .ps512:
            return try verifyRSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, algorithm: .rsaSignatureMessagePSSSHA512)
        case .es256:
            return try verifyECDSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, curve: .p256)
        case .es384:
            return try verifyECDSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, curve: .p384)
        case .es512:
            return try verifyECDSA(signingInput: signingInput, signature: signatureData, publicKey: publicKey, curve: .p521)
        }
    }

    // MARK: - HMAC Verification

    private enum HashAlgorithm {
        case sha256, sha384, sha512
    }

    private func verifyHMAC(signingInput: Data, signature: Data, secret: String?, hash: HashAlgorithm) throws -> Bool {
        guard let secret = secret, !secret.isEmpty else {
            throw JWTError.missingSecret
        }

        let key = SymmetricKey(data: Data(secret.utf8))
        let expectedSignature: Data

        switch hash {
        case .sha256:
            let mac = HMAC<SHA256>.authenticationCode(for: signingInput, using: key)
            expectedSignature = Data(mac)
        case .sha384:
            let mac = HMAC<SHA384>.authenticationCode(for: signingInput, using: key)
            expectedSignature = Data(mac)
        case .sha512:
            let mac = HMAC<SHA512>.authenticationCode(for: signingInput, using: key)
            expectedSignature = Data(mac)
        }

        return timingSafeEquals(base64urlEncode(expectedSignature), base64urlEncode(signature))
    }

    // MARK: - RSA Verification

    private func verifyRSA(signingInput: Data, signature: Data, publicKey: String?, algorithm: SecKeyAlgorithm) throws -> Bool {
        guard let publicKeyPEM = publicKey, !publicKeyPEM.isEmpty else {
            throw JWTError.missingPublicKey
        }

        let secKey = try parsePublicKey(pem: publicKeyPEM)

        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(secKey, algorithm, signingInput as CFData, signature as CFData, &error)

        if let error = error {
            let nsError = error.takeRetainedValue() as Error
            throw JWTError.unsupportedAlgorithm(nsError.localizedDescription)
        }

        return result
    }

    // MARK: - ECDSA Verification

    private enum ECCurve {
        case p256, p384, p521
    }

    private func verifyECDSA(signingInput: Data, signature: Data, publicKey: String?, curve: ECCurve) throws -> Bool {
        guard let publicKeyPEM = publicKey, !publicKeyPEM.isEmpty else {
            throw JWTError.missingPublicKey
        }

        // ECDSA signatures in JWT are in raw R||S format, need to convert for some verification methods
        let secKey = try parsePublicKey(pem: publicKeyPEM)

        let algorithm: SecKeyAlgorithm
        switch curve {
        case .p256:
            algorithm = .ecdsaSignatureMessageX962SHA256
        case .p384:
            algorithm = .ecdsaSignatureMessageX962SHA384
        case .p521:
            algorithm = .ecdsaSignatureMessageX962SHA512
        }

        // JWT uses raw R||S format, Security framework expects DER format
        let derSignature = try convertRawToDER(signature: signature, curve: curve)

        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(secKey, algorithm, signingInput as CFData, derSignature as CFData, &error)

        return result
    }

    private func convertRawToDER(signature: Data, curve: ECCurve) throws -> Data {
        let componentLength: Int
        switch curve {
        case .p256: componentLength = 32
        case .p384: componentLength = 48
        case .p521: componentLength = 66
        }

        guard signature.count == componentLength * 2 else {
            throw JWTError.signatureMismatch
        }

        let r = signature.prefix(componentLength)
        let s = signature.suffix(componentLength)

        // Build DER encoded signature
        func encodeInteger(_ data: Data) -> Data {
            var bytes = Array(data)
            // Remove leading zeros but keep at least one byte
            while bytes.count > 1 && bytes[0] == 0 && bytes[1] & 0x80 == 0 {
                bytes.removeFirst()
            }
            // Add leading zero if high bit is set (to indicate positive number)
            if bytes[0] & 0x80 != 0 {
                bytes.insert(0, at: 0)
            }
            var result = Data([0x02, UInt8(bytes.count)])
            result.append(contentsOf: bytes)
            return result
        }

        let rDer = encodeInteger(r)
        let sDer = encodeInteger(s)
        let sequenceLength = rDer.count + sDer.count

        var der = Data([0x30])
        if sequenceLength < 128 {
            der.append(UInt8(sequenceLength))
        } else {
            der.append(0x81)
            der.append(UInt8(sequenceLength))
        }
        der.append(rDer)
        der.append(sDer)

        return der
    }

    // MARK: - Public Key Parsing

    private func parsePublicKey(pem: String) throws -> SecKey {
        let cleanedPEM = pem
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard let keyData = Data(base64Encoded: cleanedPEM) else {
            throw JWTError.invalidPublicKey
        }

        let options: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]

        var error: Unmanaged<CFError>?
        if let secKey = SecKeyCreateWithData(keyData as CFData, options as CFDictionary, &error) {
            return secKey
        }

        // Try EC key
        let ecOptions: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
        ]

        if let secKey = SecKeyCreateWithData(keyData as CFData, ecOptions as CFDictionary, &error) {
            return secKey
        }

        throw JWTError.invalidPublicKey
    }

    // MARK: - Token Generation

    /// Generates a JWT token with HS256 algorithm
    /// - Parameters:
    ///   - payload: The payload claims
    ///   - secret: The shared secret for HMAC
    /// - Returns: JWT token string
    /// - Throws: JWTError if generation fails
    func generateHS256(payload: [String: Any], secret: String) throws -> String {
        guard !secret.isEmpty else {
            throw JWTError.missingSecret
        }

        let header: [String: Any] = [
            "alg": "HS256",
            "typ": "JWT"
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header, options: [.sortedKeys])
        let sortedPayload = try recursivelySortKeys(in: payload)
        let payloadData = try JSONSerialization.data(withJSONObject: sortedPayload, options: [.sortedKeys])

        let headerBase64 = base64urlEncode(headerData)
        let payloadBase64 = base64urlEncode(payloadData)

        let signingInput = Data((headerBase64 + "." + payloadBase64).utf8)
        let key = SymmetricKey(data: Data(secret.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: signingInput, using: key)
        let signature = base64urlEncode(Data(mac))

        return "\(headerBase64).\(payloadBase64).\(signature)"
    }
    
    // MARK: - Claims Extraction
    
    /// Extracts standard JWT claims from payload
    /// - Parameter payload: The JWT payload dictionary
    /// - Returns: Dictionary of standard claims
    func extractStandardClaims(from payload: [String: Any]) -> [String: Any] {
        var claims: [String: Any] = [:]
        
        let standardClaimKeys = ["iss", "sub", "aud", "exp", "nbf", "iat", "jti"]
        
        for key in standardClaimKeys {
            if let value = payload[key] {
                claims[key] = value
            }
        }
        
        return claims
    }
    
    /// Validates time-based claims (exp, nbf, iat)
    /// - Parameter payload: The JWT payload dictionary
    /// - Returns: Array of validation messages
    func validateTimeClaims(in payload: [String: Any]) -> [String] {
        var messages: [String] = []
        let now = Date().timeIntervalSince1970

        // Check expiration
        if let exp = payload["exp"] as? TimeInterval {
            if exp < now {
                messages.append("Token expired at \(formatTimestamp(exp))")
            } else {
                messages.append("Token expires at \(formatTimestamp(exp))")
            }
        }

        // Check not before
        if let nbf = payload["nbf"] as? TimeInterval {
            if nbf > now {
                messages.append("Token not valid until \(formatTimestamp(nbf))")
            }
        }

        // Check issued at
        if let iat = payload["iat"] as? TimeInterval {
            messages.append("Token issued at \(formatTimestamp(iat))")
        }

        return messages
    }

    /// Validates all standard claims and returns detailed validation results
    /// - Parameter payload: The JWT payload dictionary
    /// - Returns: Array of ClaimValidation results
    func validateClaims(in payload: [String: Any]) -> [ClaimValidation] {
        var validations: [ClaimValidation] = []
        let now = Date().timeIntervalSince1970

        // exp - Expiration Time
        if let exp = payload["exp"] {
            let expValue = (exp as? TimeInterval) ?? (exp as? Int).map { TimeInterval($0) } ?? 0
            let isValid = expValue > now
            validations.append(ClaimValidation(
                claim: "exp",
                value: formatTimestamp(expValue),
                isValid: isValid,
                message: isValid ? "Token is not expired" : "Token has expired"
            ))
        }

        // nbf - Not Before
        if let nbf = payload["nbf"] {
            let nbfValue = (nbf as? TimeInterval) ?? (nbf as? Int).map { TimeInterval($0) } ?? 0
            let isValid = nbfValue <= now
            validations.append(ClaimValidation(
                claim: "nbf",
                value: formatTimestamp(nbfValue),
                isValid: isValid,
                message: isValid ? "Token is active" : "Token not yet valid"
            ))
        }

        // iat - Issued At
        if let iat = payload["iat"] {
            let iatValue = (iat as? TimeInterval) ?? (iat as? Int).map { TimeInterval($0) } ?? 0
            let isValid = iatValue <= now
            validations.append(ClaimValidation(
                claim: "iat",
                value: formatTimestamp(iatValue),
                isValid: isValid,
                message: isValid ? "Issued in the past" : "Issued in the future (suspicious)"
            ))
        }

        // iss - Issuer (always valid if present, just informational)
        if let iss = payload["iss"] as? String {
            validations.append(ClaimValidation(
                claim: "iss",
                value: iss,
                isValid: true,
                message: "Issuer identifier"
            ))
        }

        // sub - Subject (always valid if present)
        if let sub = payload["sub"] as? String {
            validations.append(ClaimValidation(
                claim: "sub",
                value: sub,
                isValid: true,
                message: "Subject identifier"
            ))
        }

        // aud - Audience
        if let aud = payload["aud"] {
            let audValue: String
            if let audString = aud as? String {
                audValue = audString
            } else if let audArray = aud as? [String] {
                audValue = audArray.joined(separator: ", ")
            } else {
                audValue = String(describing: aud)
            }
            validations.append(ClaimValidation(
                claim: "aud",
                value: audValue,
                isValid: true,
                message: "Intended audience"
            ))
        }

        // jti - JWT ID
        if let jti = payload["jti"] as? String {
            validations.append(ClaimValidation(
                claim: "jti",
                value: jti,
                isValid: true,
                message: "Unique token identifier"
            ))
        }

        return validations
    }

    /// Detects the algorithm from a JWT token header
    /// - Parameter token: The JWT token string
    /// - Returns: The detected algorithm or nil
    func detectAlgorithm(from token: String) -> Algorithm? {
        let parts = token.split(separator: ".").map(String.init)
        guard parts.count >= 1,
              let headerData = try? base64urlDecode(parts[0]),
              let header = try? JSONSerialization.jsonObject(with: headerData) as? [String: Any],
              let alg = header["alg"] as? String else {
            return nil
        }
        return Algorithm(rawValue: alg.uppercased())
    }
    
    // MARK: - Helpers
    
    private func recursivelySortKeys(in dictionary: [String: Any]) throws -> [String: Any] {
        var sortedDict: [String: Any] = [:]
        for key in dictionary.keys.sorted() {
            if let nestedDict = dictionary[key] as? [String: Any] {
                sortedDict[key] = try recursivelySortKeys(in: nestedDict)
            } else {
                sortedDict[key] = dictionary[key]
            }
        }
        return sortedDict
    }
    
    private func base64urlDecode(_ input: String) throws -> Data {
        var s = input.replacingOccurrences(of: "-", with: "+")
                     .replacingOccurrences(of: "_", with: "/")
        let pad = (4 - (s.count % 4)) % 4
        if pad > 0 {
            s.append(String(repeating: "=", count: pad))
        }
        
        guard let data = Data(base64Encoded: s) else {
            throw JWTError.invalidBase64Encoding
        }
        
        return data
    }
    
    private func base64urlEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    private func prettyJSON(from data: Data) throws -> String {
        let obj = try JSONSerialization.jsonObject(with: data)
        let pretty = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys])
        return String(decoding: pretty, as: UTF8.self)
    }
    
    private func timingSafeEquals(_ a: String, _ b: String) -> Bool {
        let da = Data(a.utf8), db = Data(b.utf8)
        if da.count != db.count { return false }
        var res: UInt8 = 0
        for i in 0..<da.count { res |= da[i] ^ db[i] }
        return res == 0
    }
    
    private func formatTimestamp(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

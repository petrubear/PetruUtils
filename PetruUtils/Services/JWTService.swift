import Foundation
import CryptoKit

/// Service responsible for JWT encoding, decoding, and verification
struct JWTService {
    
    // MARK: - Types
    
    struct DecodedJWT {
        let header: [String: Any]
        let payload: [String: Any]
        let signature: String
        let headerJSON: String
        let payloadJSON: String
    }
    
    enum JWTError: LocalizedError {
        case invalidSegmentCount
        case invalidBase64Encoding
        case invalidJSON
        case invalidAlgorithm
        case missingSecret
        case signatureMismatch
        
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
            case .signatureMismatch:
                return "Signature verification failed"
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
        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        
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
    
    // MARK: - Helpers
    
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

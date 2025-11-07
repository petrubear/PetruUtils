import Testing
import Foundation
@testable import PetruUtils

struct JWTServiceTests {
    
    let service = JWTService()
    
    // MARK: - Token Generation Tests
    
    @Test("Generate HS256 token with simple payload")
    func testGenerateHS256SimpleToken() throws {
        let payload: [String: Any] = [
            "sub": "1234567890",
            "name": "John Doe",
            "iat": 1516239022
        ]
        let secret = "your-256-bit-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        
        // Verify token has 3 parts
        let parts = token.split(separator: ".").map(String.init)
        #expect(parts.count == 3)
        
        // Verify we can decode it back
        let decoded = try service.decode(token)
        #expect(decoded.payload["sub"] as? String == "1234567890")
        #expect(decoded.payload["name"] as? String == "John Doe")
        #expect(decoded.payload["iat"] as? Int == 1516239022)
    }
    
    @Test("Generate and verify HS256 token")
    func testGenerateAndVerifyHS256() throws {
        let payload: [String: Any] = [
            "user_id": 42,
            "email": "test@example.com"
        ]
        let secret = "test-secret-key"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let isValid = try service.verifyHS256(token: token, secret: secret)
        
        #expect(isValid == true)
    }
    
    @Test("Generate token fails with empty secret")
    func testGenerateTokenEmptySecret() {
        let payload: [String: Any] = ["sub": "test"]
        
        #expect(throws: JWTService.JWTError.missingSecret) {
            _ = try service.generateHS256(payload: payload, secret: "")
        }
    }
    
    // MARK: - Decoding Tests
    
    @Test("Decode valid HS256 token")
    func testDecodeValidToken() throws {
        // This is a real JWT token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        
        let decoded = try service.decode(token)
        
        #expect(decoded.header["alg"] as? String == "HS256")
        #expect(decoded.header["typ"] as? String == "JWT")
        #expect(decoded.payload["sub"] as? String == "1234567890")
        #expect(decoded.payload["name"] as? String == "John Doe")
        #expect(decoded.payload["iat"] as? Int == 1516239022)
        #expect(decoded.signature == "SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c")
    }
    
    @Test("Decode token with special characters in payload")
    func testDecodeTokenWithSpecialCharacters() throws {
        let payload: [String: Any] = [
            "message": "Hello, World! 🌍",
            "emoji": "🔒🔓",
            "special": "Special chars: @#$%^&*()"
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        #expect(decoded.payload["message"] as? String == "Hello, World! 🌍")
        #expect(decoded.payload["emoji"] as? String == "🔒🔓")
        #expect(decoded.payload["special"] as? String == "Special chars: @#$%^&*()")
    }
    
    @Test("Decode token with nested objects")
    func testDecodeTokenWithNestedObjects() throws {
        let payload: [String: Any] = [
            "user": [
                "id": 123,
                "name": "Alice",
                "roles": ["admin", "user"]
            ],
            "metadata": [
                "created": 1234567890,
                "updated": 1234567900
            ]
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        let user = decoded.payload["user"] as? [String: Any]
        #expect(user?["id"] as? Int == 123)
        #expect(user?["name"] as? String == "Alice")
        
        let metadata = decoded.payload["metadata"] as? [String: Any]
        #expect(metadata?["created"] as? Int == 1234567890)
    }
    
    @Test("Decode fails with invalid segment count")
    func testDecodeInvalidSegmentCount() {
        let invalidToken = "only.two.segments.here.four"
        
        #expect(throws: JWTService.JWTError.invalidSegmentCount) {
            _ = try service.decode(invalidToken)
        }
    }
    
    @Test("Decode fails with invalid base64")
    func testDecodeInvalidBase64() {
        let invalidToken = "not!valid!base64.not!valid!base64.not!valid!base64"
        
        #expect(throws: JWTService.JWTError.invalidBase64Encoding) {
            _ = try service.decode(invalidToken)
        }
    }
    
    @Test("Decode fails with invalid JSON")
    func testDecodeInvalidJSON() {
        // Valid base64 but not valid JSON
        let invalidHeader = "YWJjZGVm" // "abcdef" in base64
        let invalidPayload = "Z2hpamts" // "ghijkl" in base64
        let signature = "bW5vcHFyc3R1dnd4eXo"
        let invalidToken = "\(invalidHeader).\(invalidPayload).\(signature)"
        
        #expect(throws: JWTService.JWTError.invalidJSON) {
            _ = try service.decode(invalidToken)
        }
    }
    
    @Test("Decode token with whitespace")
    func testDecodeTokenWithWhitespace() throws {
        let token = "  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c  "
        
        let decoded = try service.decode(token.trimmingCharacters(in: .whitespacesAndNewlines))
        
        #expect(decoded.payload["sub"] as? String == "1234567890")
    }
    
    // MARK: - Verification Tests
    
    @Test("Verify valid HS256 token")
    func testVerifyValidHS256Token() throws {
        // Known valid token with secret "your-256-bit-secret"
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        let secret = "your-256-bit-secret"
        
        let isValid = try service.verifyHS256(token: token, secret: secret)
        
        #expect(isValid == true)
    }
    
    @Test("Verify fails with wrong secret")
    func testVerifyFailsWithWrongSecret() throws {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        let wrongSecret = "wrong-secret"
        
        let isValid = try service.verifyHS256(token: token, secret: wrongSecret)
        
        #expect(isValid == false)
    }
    
    @Test("Verify fails with tampered payload")
    func testVerifyFailsWithTamperedPayload() throws {
        let secret = "test-secret"
        let originalPayload: [String: Any] = ["amount": 100]
        
        let token = try service.generateHS256(payload: originalPayload, secret: secret)
        
        // Tamper with the payload (change amount to 1000)
        let parts = token.split(separator: ".").map(String.init)
        let tamperedPayload = "{\"amount\":1000}"
        let tamperedBase64 = Data(tamperedPayload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        let tamperedToken = "\(parts[0]).\(tamperedBase64).\(parts[2])"
        
        let isValid = try service.verifyHS256(token: tamperedToken, secret: secret)
        
        #expect(isValid == false)
    }
    
    @Test("Verify fails with empty secret")
    func testVerifyEmptySecret() {
        let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.xyz"
        
        #expect(throws: JWTService.JWTError.missingSecret) {
            _ = try service.verifyHS256(token: token, secret: "")
        }
    }
    
    @Test("Verify fails with wrong algorithm in header")
    func testVerifyFailsWithWrongAlgorithm() throws {
        // Create a token with RS256 in header
        let header = "{\"alg\":\"RS256\",\"typ\":\"JWT\"}"
        let payload = "{\"sub\":\"1234567890\"}"
        let headerBase64 = Data(header.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        let payloadBase64 = Data(payload.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        
        let token = "\(headerBase64).\(payloadBase64).fakesignature"
        
        #expect(throws: JWTService.JWTError.invalidAlgorithm) {
            _ = try service.verifyHS256(token: token, secret: "test")
        }
    }
    
    @Test("Verify fails with malformed token")
    func testVerifyMalformedToken() {
        let malformedToken = "not.a.valid.token.structure"
        
        #expect(throws: JWTService.JWTError.invalidSegmentCount) {
            _ = try service.verifyHS256(token: malformedToken, secret: "test")
        }
    }
    
    // MARK: - Claims Extraction Tests
    
    @Test("Extract standard claims from payload")
    func testExtractStandardClaims() {
        let payload: [String: Any] = [
            "iss": "https://example.com",
            "sub": "user123",
            "aud": "app123",
            "exp": 1234567890,
            "nbf": 1234567800,
            "iat": 1234567800,
            "jti": "token-id-123",
            "custom_claim": "custom_value",
            "another_claim": 42
        ]
        
        let claims = service.extractStandardClaims(from: payload)
        
        #expect(claims["iss"] as? String == "https://example.com")
        #expect(claims["sub"] as? String == "user123")
        #expect(claims["aud"] as? String == "app123")
        #expect(claims["exp"] as? Int == 1234567890)
        #expect(claims["nbf"] as? Int == 1234567800)
        #expect(claims["iat"] as? Int == 1234567800)
        #expect(claims["jti"] as? String == "token-id-123")
        #expect(claims["custom_claim"] == nil) // Custom claims should not be included
        #expect(claims["another_claim"] == nil)
    }
    
    @Test("Extract claims from payload with missing standard claims")
    func testExtractClaimsWithMissingClaims() {
        let payload: [String: Any] = [
            "sub": "user123",
            "custom": "value"
        ]
        
        let claims = service.extractStandardClaims(from: payload)
        
        #expect(claims["sub"] as? String == "user123")
        #expect(claims["iss"] == nil)
        #expect(claims["exp"] == nil)
        #expect(claims.count == 1)
    }
    
    @Test("Extract claims from empty payload")
    func testExtractClaimsFromEmptyPayload() {
        let payload: [String: Any] = [:]
        
        let claims = service.extractStandardClaims(from: payload)
        
        #expect(claims.isEmpty)
    }
    
    // MARK: - Time Claims Validation Tests
    
    @Test("Validate time claims with future expiration")
    func testValidateTimeClaimsWithFutureExp() {
        let futureTime = Date().timeIntervalSince1970 + 3600 // 1 hour from now
        let payload: [String: Any] = [
            "exp": futureTime
        ]
        
        let messages = service.validateTimeClaims(in: payload)
        
        #expect(messages.count == 1)
        #expect(messages[0].contains("expires at"))
    }
    
    @Test("Validate time claims with past expiration")
    func testValidateTimeClaimsWithPastExp() {
        let pastTime = Date().timeIntervalSince1970 - 3600 // 1 hour ago
        let payload: [String: Any] = [
            "exp": pastTime
        ]
        
        let messages = service.validateTimeClaims(in: payload)
        
        #expect(messages.count == 1)
        #expect(messages[0].contains("expired at"))
    }
    
    @Test("Validate time claims with all time fields")
    func testValidateTimeClaimsWithAllFields() {
        let now = Date().timeIntervalSince1970
        let payload: [String: Any] = [
            "exp": now + 3600,
            "nbf": now - 60,
            "iat": now - 100
        ]
        
        let messages = service.validateTimeClaims(in: payload)
        
        // Should have at least 2 messages (exp and iat), nbf only shows if invalid
        #expect(messages.count >= 2)
        #expect(messages.contains { $0.contains("expires at") })
        #expect(messages.contains { $0.contains("issued at") })
    }
    
    @Test("Validate time claims with no time fields")
    func testValidateTimeClaimsWithNoTimeFields() {
        let payload: [String: Any] = [
            "sub": "user123",
            "name": "Test User"
        ]
        
        let messages = service.validateTimeClaims(in: payload)
        
        #expect(messages.isEmpty)
    }
    
    // MARK: - Base64URL Encoding Tests
    
    @Test("Generate token with characters requiring base64url encoding")
    func testBase64URLEncodingWithSpecialCharacters() throws {
        // Create payload that will generate + and / in standard base64
        let payload: [String: Any] = [
            "data": ">>>???<<<"
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        
        // Token should not contain +, /, or =
        #expect(!token.contains("+"))
        #expect(!token.contains("/"))
        #expect(!token.contains("="))
        
        // Should be able to decode it back
        let decoded = try service.decode(token)
        #expect(decoded.payload["data"] as? String == ">>>???<<<")
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle very long payload")
    func testVeryLongPayload() throws {
        var payload: [String: Any] = [:]
        for i in 0..<100 {
            payload["field_\(i)"] = "value_\(i)_" + String(repeating: "x", count: 100)
        }
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        #expect(decoded.payload.count == 100)
        #expect(decoded.payload["field_0"] as? String == "value_0_" + String(repeating: "x", count: 100))
    }
    
    @Test("Handle unicode characters in payload")
    func testUnicodeCharactersInPayload() throws {
        let payload: [String: Any] = [
            "chinese": "你好世界",
            "arabic": "مرحبا بالعالم",
            "emoji": "🌍🔐💻",
            "mixed": "Hello 世界 🌍"
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        #expect(decoded.payload["chinese"] as? String == "你好世界")
        #expect(decoded.payload["arabic"] as? String == "مرحبا بالعالم")
        #expect(decoded.payload["emoji"] as? String == "🌍🔐💻")
        #expect(decoded.payload["mixed"] as? String == "Hello 世界 🌍")
    }
    
    @Test("Handle numeric values in payload")
    func testNumericValuesInPayload() throws {
        let payload: [String: Any] = [
            "integer": 42,
            "negative": -100,
            "double": 3.14159,
            "large": 9223372036854775807, // Int64 max
            "zero": 0
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        #expect(decoded.payload["integer"] as? Int == 42)
        #expect(decoded.payload["negative"] as? Int == -100)
        #expect(decoded.payload["double"] as? Double == 3.14159)
        #expect(decoded.payload["zero"] as? Int == 0)
    }
    
    @Test("Handle boolean values in payload")
    func testBooleanValuesInPayload() throws {
        let payload: [String: Any] = [
            "is_active": true,
            "is_deleted": false
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        #expect(decoded.payload["is_active"] as? Bool == true)
        #expect(decoded.payload["is_deleted"] as? Bool == false)
    }
    
    @Test("Handle null values in payload")
    func testNullValuesInPayload() throws {
        let payload: [String: Any] = [
            "nullable_field": NSNull(),
            "normal_field": "value"
        ]
        let secret = "test-secret"
        
        let token = try service.generateHS256(payload: payload, secret: secret)
        let decoded = try service.decode(token)
        
        #expect(decoded.payload["nullable_field"] is NSNull)
        #expect(decoded.payload["normal_field"] as? String == "value")
    }
    
    // MARK: - Security Tests
    
    @Test("Different secrets produce different signatures")
    func testDifferentSecretsProduceDifferentSignatures() throws {
        let payload: [String: Any] = ["sub": "test"]
        
        let token1 = try service.generateHS256(payload: payload, secret: "secret1")
        let token2 = try service.generateHS256(payload: payload, secret: "secret2")
        
        let sig1 = token1.split(separator: ".")[2]
        let sig2 = token2.split(separator: ".")[2]
        
        #expect(sig1 != sig2)
    }
    
    @Test("Same payload and secret produce same token")
    func testDeterministicTokenGeneration() throws {
        let payload: [String: Any] = [
            "sub": "user123",
            "name": "Test"
        ]
        let secret = "test-secret"
        
        let token1 = try service.generateHS256(payload: payload, secret: secret)
        let token2 = try service.generateHS256(payload: payload, secret: secret)
        
        #expect(token1 == token2)
    }
}

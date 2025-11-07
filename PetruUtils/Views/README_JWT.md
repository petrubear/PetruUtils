# JWT Debugger Tool

## Overview

The JWT Debugger is a fully functional tool for decoding, verifying, and generating JSON Web Tokens (JWT) using the HS256 algorithm. It provides a user-friendly interface for developers to inspect and validate JWT tokens offline.

## Features

### ✅ Implemented

- **Decode JWT Tokens**: Parse and display JWT header, payload, and signature
- **Verify Signatures**: Validate HS256 signatures using HMAC-SHA256
- **Generate Tokens**: Create new JWT tokens with custom payloads
- **Pretty JSON Display**: Formatted, syntax-highlighted JSON output
- **Claims Summary**: Quick view of standard JWT claims (iss, sub, aud, exp)
- **Error Handling**: Detailed error messages for invalid tokens
- **Keyboard Shortcuts**:
  - `⌘D` - Decode token
  - `⌘V` - Verify signature
  - `⌘K` - Clear all fields
- **Split View**: Resizable panes for input and output
- **Whitespace Trimming**: Handles tokens with leading/trailing whitespace

### Algorithm Support

**Current**: HS256 (HMAC with SHA-256)

**Planned**: RS256, RS384, RS512, ES256, ES384, ES512, PS256, PS384, PS512

## Usage

### Decoding a JWT

1. Paste your JWT token into the left pane
2. Click "Decode" or press `⌘D`
3. View the decoded header, payload, and signature in the right pane

### Verifying a Signature

1. Decode the token first
2. Select "HS256" from the algorithm dropdown
3. Enter the shared secret in the text field
4. Click "Verify" or press `⌘V`
5. The status indicator will show:
   - 🟢 Green: Valid signature
   - 🔴 Red: Invalid signature
   - ⚫ Gray: Not verified yet

### Understanding the Output

#### Header
Contains metadata about the token:
- `alg`: Algorithm used (e.g., "HS256")
- `typ`: Token type (usually "JWT")

#### Payload
Contains the claims (data) encoded in the token:
- **Standard Claims**:
  - `iss` (Issuer): Who created the token
  - `sub` (Subject): Who the token is about
  - `aud` (Audience): Who the token is intended for
  - `exp` (Expiration): When the token expires (Unix timestamp)
  - `nbf` (Not Before): When the token becomes valid (Unix timestamp)
  - `iat` (Issued At): When the token was created (Unix timestamp)
  - `jti` (JWT ID): Unique identifier for the token
- **Custom Claims**: Any additional data

#### Signature
The base64url-encoded signature used to verify the token's authenticity.

## Architecture

### Components

- **JWTView.swift**: SwiftUI view with split-pane layout
- **JWTViewModel**: View model managing UI state (`@MainActor`)
- **JWTService.swift**: Core business logic for JWT operations
- **JWTServiceTests.swift**: Comprehensive unit tests (40+ test cases)

### Design Patterns

- **MVVM**: Separation of view, view model, and service layer
- **Protocol-Oriented**: Extensible for future algorithm support
- **Testable**: Business logic isolated in service layer

## Security Features

- **Timing-Safe Comparison**: Prevents timing attacks when comparing signatures
- **Base64URL Encoding**: RFC 4648 compliant encoding/decoding
- **HMAC-SHA256**: Uses Apple's CryptoKit for cryptographic operations
- **Offline Operation**: No network requests; all processing is local

## API Reference

### JWTService

#### Methods

```swift
func decode(_ token: String) throws -> DecodedJWT
```
Decodes a JWT token into its components.

**Parameters**:
- `token`: The JWT token string

**Returns**: `DecodedJWT` struct containing header, payload, signature, and formatted JSON

**Throws**: `JWTError` if token is malformed or invalid

---

```swift
func verifyHS256(token: String, secret: String) throws -> Bool
```
Verifies the signature of an HS256 JWT token.

**Parameters**:
- `token`: The JWT token string
- `secret`: The shared secret for HMAC

**Returns**: `true` if signature is valid, `false` otherwise

**Throws**: `JWTError` if verification cannot be performed

---

```swift
func generateHS256(payload: [String: Any], secret: String) throws -> String
```
Generates a new JWT token with HS256 algorithm.

**Parameters**:
- `payload`: Dictionary of claims to include in the token
- `secret`: The shared secret for HMAC

**Returns**: Complete JWT token string

**Throws**: `JWTError` if generation fails

---

```swift
func extractStandardClaims(from payload: [String: Any]) -> [String: Any]
```
Extracts standard JWT claims from a payload.

**Parameters**:
- `payload`: The JWT payload dictionary

**Returns**: Dictionary containing only standard claims (iss, sub, aud, exp, nbf, iat, jti)

---

```swift
func validateTimeClaims(in payload: [String: Any]) -> [String]
```
Validates time-based claims (exp, nbf, iat) and returns human-readable messages.

**Parameters**:
- `payload`: The JWT payload dictionary

**Returns**: Array of validation messages

### Error Types

```swift
enum JWTError: LocalizedError {
    case invalidSegmentCount    // Token doesn't have exactly 3 parts
    case invalidBase64Encoding  // Base64URL decoding failed
    case invalidJSON           // JSON parsing failed
    case invalidAlgorithm      // Unsupported or mismatched algorithm
    case missingSecret         // Secret required but not provided
    case signatureMismatch     // Signature verification failed
}
```

## Testing

The JWT Debugger includes comprehensive unit tests covering:

- ✅ Token generation (simple, complex, nested payloads)
- ✅ Token decoding (valid, invalid, malformed)
- ✅ Signature verification (valid, tampered, wrong secret)
- ✅ Claims extraction and validation
- ✅ Base64URL encoding/decoding
- ✅ Edge cases (unicode, large payloads, special characters)
- ✅ Security (timing attacks, tampering)

**Test Coverage**: 40+ test cases, all passing

Run tests:
```bash
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'
```

## Known Limitations

1. **Algorithm Support**: Currently only HS256 is implemented
2. **Key Format**: HS256 accepts plain text secrets (not base64-encoded keys)
3. **Token Generation UI**: Not yet exposed in the UI (API available)
4. **Claims Validation**: Time-based validation (exp, nbf) not enforced in UI

## Future Enhancements

### Phase 1 (High Priority)
- [ ] Token generation UI
- [ ] Support for RS256/RS384/RS512 (RSA)
- [ ] Public key input for RSA verification
- [ ] Save/load keys securely

### Phase 2 (Medium Priority)
- [ ] Support for ES256/ES384/ES512 (ECDSA)
- [ ] Claims editor with validation
- [ ] Time-based claims validation with visual indicators
- [ ] Token expiration countdown
- [ ] Multiple secret storage (keychain)

### Phase 3 (Low Priority)
- [ ] Support for PS256/PS384/PS512 (RSA-PSS)
- [ ] JWK (JSON Web Key) support
- [ ] JWE (JSON Web Encryption) support
- [ ] Token history
- [ ] Export decoded tokens

## Example Tokens

### Valid HS256 Token
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```
**Secret**: `your-256-bit-secret`

**Header**:
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload**:
```json
{
  "sub": "1234567890",
  "name": "John Doe",
  "iat": 1516239022
}
```

## Resources

- [JWT.io](https://jwt.io) - Official JWT documentation and debugger
- [RFC 7519](https://tools.ietf.org/html/rfc7519) - JSON Web Token (JWT) specification
- [RFC 4648](https://tools.ietf.org/html/rfc4648) - Base64URL encoding
- [Apple CryptoKit](https://developer.apple.com/documentation/cryptokit) - Cryptographic operations

## License

Part of PetruUtils project. See main LICENSE file for details.

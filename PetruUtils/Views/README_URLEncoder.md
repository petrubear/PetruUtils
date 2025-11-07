# URL Encoder/Decoder

## Overview

The URL Encoder/Decoder tool provides fast, offline encoding and decoding of URL components using RFC 3986 standards. Essential for working with web APIs, query parameters, path segments, and form data.

## Features

### ✅ Implemented

- **Encode Text to URL format**: Convert text for safe URL use
- **Decode URL-encoded text**: Convert URL-encoded text back to readable format
- **Multiple Component Types**:
  - **Full URL**: Encode/decode complete URLs
  - **Query Parameter**: RFC 3986 query string encoding
  - **Path Segment**: URL path component encoding
  - **Form Data**: application/x-www-form-urlencoded format
- **Auto-Detect Mode**: Automatically detect if input is encoded or decoded
- **Character Count**: Real-time character counting
- **Error Handling**: Clear error messages for invalid input
- **Keyboard Shortcuts**:
  - `⌘↩` - Process (encode/decode)
  - `⌘K` - Clear all fields
  - `⌘D` - Auto-detect encoding mode
  - `⌘⇧C` - Copy output to clipboard
- **JetBrains Mono Font**: Consistent 15pt monospaced font
- **Split View**: Resizable input/output panes

## Usage

### Encoding Text

1. Select **"Encode"** mode
2. Choose component type (Query Parameter, Path Segment, Form Data, or Full URL)
3. Type or paste text in the left pane
4. Click **"Process"** or press `⌘↩`
5. Encoded output appears in the right pane

**Example (Query Parameter):**
```
Input:  Hello, World!
Output: Hello%2C%20World%21
```

### Decoding URL-Encoded Text

1. Select **"Decode"** mode
2. Choose component type matching how it was encoded
3. Paste URL-encoded text in the left pane
4. Click **"Process"** or press `⌘↩`
5. Decoded text appears in the right pane
6. Green checkmark indicates successful decoding

**Example:**
```
Input:  Hello%2C%20World%21
Output: Hello, World!
```

### Auto-Detect

Press `⌘D` or click **"Auto-Detect"** to automatically determine if the input is encoded or decoded. The tool will switch to the appropriate mode.

## URL Component Types

### Query Parameter (RFC 3986)
- **Use for**: URL query strings, API parameters
- **Encoding**: Percent-encodes reserved characters (`!*'();:@&=+$,/?#[]`)
- **Example**: `Hello World` → `Hello%20World`
- **Common in**: `?search=Hello%20World&page=1`

### Path Segment
- **Use for**: URL path components, file names in URLs
- **Encoding**: Encodes spaces and special chars, preserves slashes
- **Example**: `my file.txt` → `my%20file.txt`
- **Common in**: `/api/users/my%20file.txt`

### Form Data (application/x-www-form-urlencoded)
- **Use for**: HTML form submissions, POST data
- **Encoding**: Spaces become `+`, special chars percent-encoded
- **Example**: `Hello World` → `Hello+World`
- **Common in**: Form POST bodies, older APIs

### Full URL
- **Use for**: Complete URLs with scheme, host, path, query
- **Encoding**: Intelligently encodes only necessary parts
- **Example**: `https://example.com/path?q=hello world`
- **Note**: Validates URL structure before encoding

## Architecture

### Components

- **URLView.swift**: SwiftUI interface with mode/type selection
- **URLViewModel**: Manages UI state and user interactions  
- **URLService.swift**: Core encoding/decoding logic
- **URLServiceTests.swift**: Comprehensive unit tests (60+ tests)

### Design Pattern

```
View (URLView)
  ↓
ViewModel (URLViewModel) - UI State
  ↓
Service (URLService) - Business Logic
  ↓
Foundation - CharacterSet, URLComponents
```

## API Reference

### URLService

```swift
struct URLService {
    // Encoding
    func encode(_ text: String, type: URLComponentType) throws -> String
    
    // Decoding
    func decode(_ text: String, type: URLComponentType) throws -> String
    
    // Validation
    func isValidURL(_ urlString: String) -> Bool
    func isURLEncoded(_ text: String) -> Bool
    func isFormEncoded(_ text: String) -> Bool
    
    // Utilities
    func extractQueryParameters(_ urlString: String) throws -> [(String, String)]
    func buildURL(scheme: String?, host: String?, path: String?, 
                  queryParameters: [(String, String)]?) -> String?
    func getEncodedPercentage(_ text: String) -> Double
    func normalizeEncoding(_ text: String, type: URLComponentType) throws -> String
}
```

### Component Types

```swift
enum URLComponentType {
    case fullURL        // Complete URL with scheme
    case queryParameter // Query string values
    case pathSegment    // URL path components
    case formData       // Form-encoded data
}
```

### Error Types

```swift
enum URLServiceError: LocalizedError {
    case emptyInput        // Input is empty or whitespace
    case invalidURL        // Invalid URL format
    case encodingFailed    // Encoding operation failed
    case decodingFailed    // Decoding operation failed
}
```

## Testing

### Test Coverage (60+ tests)

- ✅ Query parameter encoding/decoding
- ✅ Form data encoding (+ for spaces)
- ✅ Path segment encoding
- ✅ Full URL encoding/decoding
- ✅ Round-trip encoding/decoding
- ✅ Unicode support (Chinese, Japanese, Arabic)
- ✅ Emoji support
- ✅ Special character handling
- ✅ Reserved character encoding
- ✅ Validation functions
- ✅ URL parsing and building
- ✅ Edge cases (single char, very long text)

Run tests:
```bash
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'
```

## Examples

### Query Parameter Encoding
```swift
let service = URLService()
let encoded = try service.encode("name=John Doe", type: .queryParameter)
// Result: "name%3DJohn%20Doe"
```

### Form Data Encoding
```swift
let encoded = try service.encode("Hello World", type: .formData)
// Result: "Hello+World"
```

### Path Segment Encoding
```swift
let encoded = try service.encode("my file.txt", type: .pathSegment)
// Result: "my%20file.txt"
```

### Full URL Decoding
```swift
let decoded = try service.decode(
    "https://api.example.com/search?q=Hello%20World", 
    type: .fullURL
)
// Result: "https://api.example.com/search?q=Hello World"
```

### Extract Query Parameters
```swift
let params = try service.extractQueryParameters(
    "https://example.com?name=John&age=30"
)
// Result: [("name", "John"), ("age", "30")]
```

## Common Use Cases

### 1. API Query Parameters
```
Input:  search query
Output: search%20query
Use:    /api/search?q=search%20query
```

### 2. Form Data Submission
```
Input:  username=John Doe
Output: username%3DJohn+Doe
Use:    POST body in form submissions
```

### 3. File Paths in URLs
```
Input:  user documents/report.pdf
Output: user%20documents/report.pdf
Use:    /files/user%20documents/report.pdf
```

### 4. Building URLs Programmatically
```swift
let url = service.buildURL(
    scheme: "https",
    host: "api.example.com",
    path: "/v1/users",
    queryParameters: [("filter", "active"), ("limit", "10")]
)
// Result: "https://api.example.com/v1/users?filter=active&limit=10"
```

### 5. Decoding API Responses
```
Input:  error%3A%20File%20not%20found
Output: error: File not found
Use:    Parse error messages from APIs
```

## RFC 3986 Compliance

The URL Encoder follows **RFC 3986** (Uniform Resource Identifier) standards:

- **Reserved Characters**: `! * ' ( ) ; : @ & = + $ , / ? # [ ]`
- **Unreserved Characters**: `A-Z a-z 0-9 - _ . ~`
- **Percent Encoding**: `%XX` where XX is the hexadecimal byte value

### Encoding Rules by Component Type

| Component       | Encodes Reserved | Spaces As | Example              |
|----------------|------------------|-----------|----------------------|
| Query Param    | Yes              | `%20`     | `a=b&c=d` → `a%3Db%26c%3Dd` |
| Path Segment   | Partial          | `%20`     | `my file` → `my%20file` |
| Form Data      | Yes              | `+`       | `Hello World` → `Hello+World` |
| Full URL       | Selective        | `%20`     | Preserves URL structure |

## Known Limitations

1. **Full URL Encoding**: May accept some malformed URLs due to Swift's permissive URL parsing
2. **Large Text**: Entire input loaded into memory
3. **Component Detection**: Auto-detect uses heuristics, may not be 100% accurate
4. **IDN (Internationalized Domain Names)**: Not explicitly handled

## Future Enhancements

### Planned Features
- [ ] IDN (punycode) encoding/decoding
- [ ] URL builder with visual components
- [ ] Batch encoding/decoding
- [ ] URL comparison tool
- [ ] Query parameter editor
- [ ] Copy as cURL command
- [ ] Template/snippet support
- [ ] History of encoded/decoded values

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘↩` | Process (encode/decode) |
| `⌘K` | Clear all fields |
| `⌘D` | Auto-detect mode |
| `⌘⇧C` | Copy output to clipboard |
| `⌘V` | Paste into input field |

## Resources

- [RFC 3986](https://tools.ietf.org/html/rfc3986) - Uniform Resource Identifier (URI)
- [RFC 1738](https://tools.ietf.org/html/rfc1738) - Uniform Resource Locators (URL)
- [HTML 5.2 Spec](https://www.w3.org/TR/html52/sec-forms.html#urlencoded-form-data) - Form data encoding
- [MDN: encodeURIComponent](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/encodeURIComponent)

## License

Part of PetruUtils project. See main LICENSE file for details.

---

*Last Updated: November 7, 2025*

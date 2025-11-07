# Base64 Encoder/Decoder

## Overview

The Base64 Encoder/Decoder tool provides fast, offline encoding and decoding of text using Base64 and Base64URL formats. Perfect for encoding binary data, API tokens, or any data that needs to be transmitted as text.

## Features

### ✅ Implemented

- **Encode Text to Base64**: Convert any text to Base64 format
- **Decode Base64 to Text**: Convert Base64 back to readable text
- **Standard Base64**: RFC 4648 compliant standard Base64
- **URL-Safe Base64**: Base64URL variant for use in URLs (- and _ instead of + and /)
- **Character Count**: Real-time character counting for input/output
- **Error Handling**: Clear error messages for invalid Base64
- **Keyboard Shortcuts**:
  - `⌘↩` - Process (encode/decode)
  - `⌘K` - Clear all fields
  - `⌘⇧C` - Copy output to clipboard
- **JetBrains Mono Font**: Consistent 15pt monospaced font
- **Split View**: Resizable input/output panes

## Usage

### Encoding Text to Base64

1. Select **"Encode"** mode
2. Choose **"Standard"** or **"URL-Safe"** variant
3. Type or paste text in the left pane
4. Click **"Process"** or press `⌘↩`
5. Base64 output appears in the right pane

**Example:**
```
Input:  Hello, World!
Output: SGVsbG8sIFdvcmxkIQ==
```

### Decoding Base64 to Text

1. Select **"Decode"** mode
2. Choose **"Standard"** or **"URL-Safe"** variant
3. Paste Base64 in the left pane
4. Click **"Process"** or press `⌘↩`
5. Decoded text appears in the right pane
6. Green checkmark indicates valid Base64

**Example:**
```
Input:  SGVsbG8sIFdvcmxkIQ==
Output: Hello, World!
```

## Base64 Variants

### Standard Base64
- Uses characters: `A-Z`, `a-z`, `0-9`, `+`, `/`
- Padding with `=` characters
- RFC 4648 compliant
- **Use for**: Email attachments, data URLs, general encoding

### URL-Safe Base64
- Uses characters: `A-Z`, `a-z`, `0-9`, `-`, `_`
- No padding (`=` removed)
- Safe for URLs and filenames
- **Use for**: URL parameters, JWT tokens, web applications

## Architecture

### Components

- **Base64View.swift**: SwiftUI interface with mode/variant selection
- **Base64ViewModel**: Manages UI state and user interactions
- **Base64Service.swift**: Core encoding/decoding logic
- **Base64ServiceTests.swift**: Comprehensive unit tests (30+ tests)

### Design Pattern

```
View (Base64View)
  ↓
ViewModel (Base64ViewModel) - UI State
  ↓
Service (Base64Service) - Business Logic
  ↓
Foundation.Data - Base64 encoding/decoding
```

## API Reference

### Base64Service

```swift
struct Base64Service {
    // Text operations
    func encodeText(_ text: String, variant: Base64Variant = .standard) throws -> String
    func decodeText(_ base64: String, variant: Base64Variant = .standard) throws -> String
    
    // Data operations
    func encodeData(_ data: Data, variant: Base64Variant = .standard) -> String
    func decodeData(_ base64: String, variant: Base64Variant = .standard) throws -> Data
    
    // File operations
    func encodeFile(at url: URL, variant: Base64Variant = .standard) throws -> String
    func decodeToFile(_ base64: String, to url: URL, variant: Base64Variant = .standard) throws
    
    // Utilities
    func isValidBase64(_ string: String) -> Bool
    func formatWithLineBreaks(_ base64: String, lineLength: Int = 76) -> String
    func removeFormatting(_ base64: String) -> String
    func getDecodedSize(_ base64: String) -> Int
}
```

### Error Types

```swift
enum Base64Error: LocalizedError {
    case invalidBase64String    // Invalid Base64 format
    case emptyInput            // Input cannot be empty
    case encodingFailed        // Text encoding failed
    case decodingFailed        // Base64 decoding failed
}
```

## Testing

### Test Coverage (30+ tests)

- ✅ Text encoding/decoding
- ✅ Standard vs URL-safe variants
- ✅ Round-trip encoding/decoding
- ✅ Invalid Base64 detection
- ✅ Whitespace handling
- ✅ Unicode support (emoji, Chinese, Arabic)
- ✅ Edge cases (single char, very long text)
- ✅ Binary data encoding/decoding
- ✅ RFC 4648 test vectors

Run tests:
```bash
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'
```

## Examples

### Basic Encoding
```swift
let service = Base64Service()
let encoded = try service.encodeText("Hello")
// Result: "SGVsbG8="
```

### URL-Safe Encoding
```swift
let encoded = try service.encodeText("Hello>>World", variant: .urlSafe)
// Result: "SGVsbG8-PldvcmxkIQ" (note: - instead of +, no padding)
```

### Validation
```swift
let isValid = service.isValidBase64("SGVsbG8=")
// Result: true
```

### With Formatting
```swift
let formatted = service.formatWithLineBreaks(longBase64, lineLength: 76)
// Result: Base64 with line breaks every 76 characters (RFC 2045)
```

## Common Use Cases

### 1. Encode API Credentials
```
Input:  username:password
Output: dXNlcm5hbWU6cGFzc3dvcmQ=
Use:    Basic Auth header
```

### 2. Data URLs for Images
```
Input:  [Binary image data]
Output: /9j/4AAQSkZJRgABAQEASABIAAD...
Use:    data:image/jpeg;base64,...
```

### 3. JWT Tokens (URL-Safe)
```
Input:  {"sub":"1234567890","name":"John Doe"}
Output: eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0
Use:    JWT payload
```

### 4. Encode Binary for JSON
```
Input:  [Binary data]
Output: [Base64 string]
Use:    Store binary in JSON
```

## Known Limitations

1. **Text Only**: UI currently supports text only (file encoding via API only)
2. **Memory**: Large inputs loaded entirely into memory
3. **No Syntax Highlighting**: Base64 output is plain text

## Future Enhancements

### Planned Features
- [ ] File drag-and-drop support
- [ ] Image preview for decoded images
- [ ] Base32 encoding support
- [ ] Hex encoding/decoding
- [ ] Multi-line formatting options
- [ ] Copy as data URL
- [ ] Batch file processing

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘↩` | Process (encode/decode) |
| `⌘K` | Clear all fields |
| `⌘⇧C` | Copy output to clipboard |
| `⌘V` | Paste into input field |

## Resources

- [RFC 4648](https://tools.ietf.org/html/rfc4648) - Base64 Data Encoding
- [RFC 2045](https://tools.ietf.org/html/rfc2045) - MIME Base64 with line breaks
- [Base64 on Wikipedia](https://en.wikipedia.org/wiki/Base64)

## License

Part of PetruUtils project. See main LICENSE file for details.

---

*Last Updated: November 7, 2025*

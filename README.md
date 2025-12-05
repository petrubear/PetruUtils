# PetruUtils

A native macOS application providing an all-in-one toolbox for software developers. Inspired by [DevUtils](https://devutils.com), PetruUtils offers 40+ carefully crafted developer tools with a focus on privacy, performance, and offline operation.

## Project Status

**Current Phase**: Phase 10 – Enhancements & Hardening (planned)

- **Tools Implemented**: 40 of 40 planned (100%) (see `Tool.swift`)
- **Tests**: 435+ service/unit tests across implemented tools
- **Preferences/History/Favorites**: Complete (Phase 5)
- **Release Automation**: Complete (GitHub Actions workflow ready)

## Features

### Core Principles

- **Privacy First**: All operations run locally; no data leaves your machine
- **Offline by Default**: Full functionality without internet connection
- **Native Performance**: Built with SwiftUI for Apple Silicon and Intel Macs
- **Smart Detection**: Intelligent clipboard content detection
- **Developer UX**: Keyboard shortcuts, quick actions, minimal friction

---

## Implemented Tools

### Phase 2 - Core Tools

- **JWT Debugger** - Full HS256 support with decode, verify, and generate capabilities
- **Base64 Encoder/Decoder** - Encode/decode text with Standard and URL-safe variants
- **URL Encoder/Decoder** - Full URL encoding/decoding with multiple component types
- **Hash Generator** - MD5, SHA-1, SHA-256, SHA-384, SHA-512 with HMAC support
- **UUID/ULID Generator** - UUID v1, v4, v5 and ULID generation with bulk support
- **QR Code Generator** - Generate and scan QR codes with custom colors and error correction
- **Smart Clipboard Detection** - Automatic content type detection with tool suggestions

### Phase 3 - Converters

- **Number Base Converter** - Convert between Binary, Octal, Decimal, and Hexadecimal with bit/byte representation
- **Unix Timestamp Converter** - Convert timestamps to/from human-readable dates with timezone support
- **Case Converter** - Convert between camelCase, snake_case, kebab-case, PascalCase, and more
- **Color Converter** - Convert between HEX, RGB, HSL, HSV, and CMYK with live preview
- **JSON <-> YAML Converter** - Bidirectional conversion between JSON and YAML formats
- **JSON <-> CSV Converter** - Convert JSON arrays to CSV and back with delimiter options
- **Markdown <-> HTML Converter** - Convert between Markdown and HTML formats

### Phase 4 - Advanced Tools

- **JSON Formatter** - Format, minify, and validate JSON (tree view, JSONPath breadcrumbs pending)
- **JavaScript Formatter** - Format, minify, and validate JavaScript
- **RegExp Tester** - Test regular expressions with match highlighting and capture groups
- **Text Diff** - Side-by-side text comparison with line-by-line diff highlighting
- **XML Formatter** - Format, minify, and validate XML with indentation options
- **HTML Formatter** - Format and minify HTML with intelligent tag handling
- **CSS Formatter** - Format, minify, and validate CSS with property sorting option
- **SQL Formatter** - Format, minify, and validate SQL with keyword uppercasing option

### Phase 6 - Text Utilities

- **Line Sorter** - Sort lines alphabetically with case-sensitive, natural sort, reverse, and shuffle options
- **Line Deduplicator** - Remove duplicate lines with options to keep first/last occurrence and sort
- **Text Replacer** - Find and replace with regex support, case-sensitive/insensitive, and whole word matching
- **String Inspector** - Comprehensive text analysis: character/word/line counts, byte sizes, entropy, Unicode analysis

### Phase 7 - Encoders & Generators

- **HTML Entity Encoder/Decoder** - Encode/decode HTML entities (named, decimal, hex formats)
- **Lorem Ipsum Generator** - Generate placeholder text (paragraphs, sentences, words)

### Phase 8 - Inspectors & Generators

- **URL Parser** - Parse URLs into components (scheme, host, port, path, query params, fragment)
- **Random String Generator** - Generate cryptographically secure random strings with customizable character sets
- **Backslash Escape/Unescape** - Escape and unescape special characters in strings (quotes, newlines, tabs, etc.)
- **Base32 Encoder/Decoder** - Encode/decode Base32 with Standard and Hex variants (RFC 4648)
- **Cron Expression Parser** - Parse cron expressions with human-readable descriptions and next 10 execution times
- **JSON Path Tester** - Test JSONPath expressions with syntax like $.users[0].name, $..email

### Phase 9 - Remaining Utilities (Complete)

- **cURL to Code Converter** - Convert cURL commands to code in Swift, Python, JavaScript, Go, PHP, and Ruby
- **SVG to CSS Converter** - Convert SVG to CSS data URIs with optimization and multiple format options
- **Certificate Inspector (X.509)** - Decode and inspect X.509 certificates with detailed information and JSON export
- **IP Utilities** - CIDR/subnet calculator with network info, host ranges, IP classification, and binary/hex representations
- **ASCII Art Generator** - Convert text to ASCII art with multiple fonts (Banner, Block, Small, Standard, Mini)
- **Bcrypt Generator/Verifier** - Generate PBKDF2-SHA256 password hashes and verify passwords with configurable cost factor
- **TOTP Generator** - Generate RFC 6238 Time-based One-Time Passwords with QR code, countdown timer, and multiple algorithms

---

## Technical Stack

- **Platform**: macOS 13.0+ (Ventura and later)
- **Architecture**: Universal binary (Apple Silicon + Intel)
- **Framework**: SwiftUI + Combine
- **Language**: Swift 5.9+
- **Xcode**: 15.0+
- **Testing**: Swift Testing framework

### Key Technologies

- **CryptoKit**: Cryptographic operations (HMAC, SHA-256)
- **Foundation**: Core data processing, encoding/decoding
- **AppKit**: Native macOS integrations
- **SwiftUI**: Modern UI framework

---

## Installation & Usage

### Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building from source)

### Building from Source

```bash
# Clone the repository
cd /path/to/PetruUtils

# Open in Xcode
open PetruUtils.xcodeproj

# Build and run
# Press Cmd+R
```

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'

# Or use Xcode: Cmd+U
```

---

## Architecture

### Design Pattern

```
+-----------------------------------------+
|            Views (SwiftUI)              |
+-----------------------------------------+
|          ViewModels (@MainActor)        |
+-----------------------------------------+
|        Services (Business Logic)        |
+-----------------------------------------+
|    Foundation / CryptoKit / AppKit      |
+-----------------------------------------+
```

### Project Structure

```
PetruUtils/
├── PetruUtilsApp.swift              # App entry point
├── Models/
│   └── Tool.swift                    # Tool definitions
├── ViewModels/                       # View models (MVVM)
├── Views/
│   ├── ContentView.swift             # Main navigation
│   └── [Tool]View.swift              # Individual tool UIs
├── Services/
│   ├── [Tool]Service.swift           # Business logic
│   ├── PreferencesManager.swift      # App preferences
│   └── HistoryManager.swift          # Tool history/favorites
└── Resources/
    └── Assets.xcassets

PetruUtilsTests/
└── [Tool]ServiceTests.swift          # Unit tests
```

### Key Design Decisions

- **MVVM Pattern**: Clear separation of concerns
- **Protocol-Oriented**: Extensible and testable
- **Service Layer**: Business logic isolated from UI
- **Testable**: Comprehensive unit test coverage

---

## Tool Documentation

### JWT Debugger

The JWT Debugger is a fully functional tool for decoding, verifying, and generating JSON Web Tokens (JWT) using the HS256 algorithm.

**Features**:
- Decode JWT tokens (header, payload, signature)
- Verify HS256 signatures using HMAC-SHA256
- Generate JWT tokens programmatically
- Pretty JSON display with syntax highlighting
- Claims summary showing standard JWT fields
- Keyboard shortcuts: `Cmd+D` (Decode), `Cmd+V` (Verify), `Cmd+K` (Clear)

**Algorithm Support**:
- Current: HS256 (HMAC with SHA-256)
- Planned: RS256, RS384, RS512, ES256, ES384, ES512, PS256, PS384, PS512

### Base64 Encoder/Decoder

Fast, offline encoding and decoding of text using Base64 and Base64URL formats.

**Features**:
- Encode text to Base64
- Decode Base64 to text
- Standard Base64 (RFC 4648)
- URL-Safe Base64 (uses `-` and `_` instead of `+` and `/`)
- Keyboard shortcuts: `Cmd+Return` (Process), `Cmd+K` (Clear), `Cmd+Shift+C` (Copy)

**Variants**:
- **Standard**: Characters `A-Z`, `a-z`, `0-9`, `+`, `/` with `=` padding
- **URL-Safe**: Characters `A-Z`, `a-z`, `0-9`, `-`, `_` without padding

### URL Encoder/Decoder

RFC 3986 compliant URL encoding and decoding with multiple component types.

**Features**:
- Multiple component types: Full URL, Query Parameter, Path Segment, Form Data
- Auto-detect mode
- Extract query parameters
- Keyboard shortcuts: `Cmd+Return` (Process), `Cmd+K` (Clear), `Cmd+D` (Auto-detect)

**Component Types**:
- **Query Parameter**: RFC 3986 query string encoding
- **Path Segment**: URL path component encoding
- **Form Data**: application/x-www-form-urlencoded format
- **Full URL**: Intelligently encodes complete URLs

---

## Testing

### Test Coverage

- Service suites for JWT, Base64, URL, Hash, UUID/ULID, QR Code, Clipboard Monitor, History Manager, Line utilities, etc.
- Token generation, decoding, verification (HS256)
- Edge cases (unicode, large payloads, special characters)
- Security tests (timing attacks, tampering attempts)
- Error handling and validation branches

### Test Results

```bash
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'
# BUILD SUCCEEDED – all current suites green
```

---

## Roadmap

### Phase 1: Foundation - Complete
- [x] Project setup and architecture
- [x] Main navigation and sidebar
- [x] JWT Debugger with HS256 support
- [x] Comprehensive unit tests

### Phase 2: Core Tools - Complete
- [x] Base64 Encoder/Decoder
- [x] URL Encoder/Decoder
- [x] Hash Generator
- [x] UUID/ULID Generator
- [x] QR Code Generator
- [x] Smart Clipboard Detection

### Phase 3: Converters - Complete
- [x] Number Base Converter
- [x] Unix Timestamp Converter
- [x] Case Converter
- [x] Color Converter
- [x] JSON <-> YAML
- [x] JSON <-> CSV
- [x] Markdown <-> HTML

### Phase 4: Advanced Tools - Complete
- [x] JSON Formatter
- [x] RegExp Tester
- [x] Text Diff/Compare
- [x] XML Formatter
- [x] HTML Formatter
- [x] CSS Formatter
- [x] SQL Formatter
- [x] JavaScript Formatter

### Phase 5: Polish & Release - Complete
- [x] Tool history and favorites
- [x] Preferences panel (6 categories)
- [x] Export/import utilities
- [x] Lazy loading for performance
- [x] App icon specification
- [x] Clipboard auto-switch preference wiring
- [x] GitHub Action workflow for releases

### Phase 6: Text Utilities - Complete
- [x] Line Sorter
- [x] Line Deduplicator
- [x] Text Replacer
- [x] String Inspector

### Phase 7: Encoders & Generators - Complete
- [x] HTML Entity Encoder/Decoder
- [x] Lorem Ipsum Generator

### Phase 8: Inspectors & Generators - Complete
- [x] URL Parser
- [x] Random String Generator
- [x] Backslash Escape/Unescape
- [x] Base32 Encoder/Decoder
- [x] Cron Expression Parser
- [x] JSON Path Tester

### Phase 9: Remaining Utilities - Complete
- [x] JavaScript Formatter
- [x] cURL to Code Converter
- [x] SVG to CSS Converter
- [x] Certificate Inspector (X.509)
- [x] IP Utilities
- [x] ASCII Art Generator
- [x] Bcrypt Generator/Verifier
- [x] TOTP Generator

### Phase 10: Enhancements & Hardening - Planned
- [ ] JSON Formatter tree view, JSONPath breadcrumbs, line numbers
- [ ] CSS Formatter SCSS/LESS conversion & vendor auto-prefixing
- [ ] JWT Debugger RSA/ECDSA/PS algorithms with public-key inputs

### Phase 11: Release Automation - Complete
- [x] GitHub Action workflow for builds and releases

---

## Upcoming Work

1. Enhance existing tools: JSON Formatter tree view/breadcrumbs, CSS Formatter SCSS/LESS + prefixing, JWT Debugger RSA/ECDSA/PS support.
2. Design and implement custom app icon.
3. Final polish and v1.0 release.

---

## Contributing

This is a personal project, but suggestions and feedback are welcome!

### Development Guidelines

1. Follow Swift style conventions
2. Write unit tests for all business logic
3. Document public APIs
4. Keep UI and business logic separated
5. Use SwiftUI best practices

See `AGENTS.md` for detailed development guidelines.

---

## License

TBD - To be determined

---

## Acknowledgments

- Inspired by [DevUtils](https://devutils.com)
- Built with Apple's SwiftUI and CryptoKit
- JWT implementation follows RFC 7519

---

## Contact

Edison Martinez - Project Creator

---

**Note**: This project is under active development. Features and APIs may change.

*Last Updated: December 2025*

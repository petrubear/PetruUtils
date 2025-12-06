# PetruUtils

A native macOS application providing an all-in-one toolbox for software developers. Inspired by [DevUtils](https://devutils.com), PetruUtils offers 40+ carefully crafted developer tools with a focus on privacy, performance, and offline operation.

## Project Status

**Current Phase**: v1.0 Release Ready

- **Tools Implemented**: 40 of 40 planned (100%)
- **Tests**: 435+ service/unit tests across implemented tools
- **All Phases Complete**: Foundation through Release Automation

## Features

### Core Principles

- **Privacy First**: All operations run locally; no data leaves your machine
- **Offline by Default**: Full functionality without internet connection
- **Native Performance**: Built with SwiftUI for Apple Silicon and Intel Macs
- **Smart Detection**: Intelligent clipboard content detection
- **Developer UX**: Keyboard shortcuts, quick actions, minimal friction

---

## Implemented Tools

### Core Tools

- **JWT Debugger** - Full support for HS256/384/512, RS256/384/512, PS256/384/512, ES256/384/512 with public key verification and claim validation
- **Base64 Encoder/Decoder** - Encode/decode text with Standard and URL-safe variants
- **URL Encoder/Decoder** - Full URL encoding/decoding with multiple component types
- **Hash Generator** - MD5, SHA-1, SHA-256, SHA-384, SHA-512 with HMAC support
- **UUID/ULID Generator** - UUID v1, v4, v5 and ULID generation with bulk support
- **QR Code Generator** - Generate and scan QR codes with custom colors and error correction
- **Smart Clipboard Detection** - Automatic content type detection with tool suggestions

### Converters

- **Number Base Converter** - Convert between Binary, Octal, Decimal, and Hexadecimal with bit/byte representation
- **Unix Timestamp Converter** - Convert timestamps to/from human-readable dates with timezone support
- **Case Converter** - Convert between camelCase, snake_case, kebab-case, PascalCase, and more
- **Color Converter** - Convert between HEX, RGB, HSL, HSV, and CMYK with live preview
- **JSON <-> YAML Converter** - Bidirectional conversion between JSON and YAML formats
- **JSON <-> CSV Converter** - Convert JSON arrays to CSV and back with delimiter options
- **Markdown <-> HTML Converter** - Convert between Markdown and HTML formats

### Formatters

- **JSON Formatter** - Format, minify, validate with tree view, JSONPath breadcrumbs, and line numbers
- **JavaScript Formatter** - Format, minify, and validate JavaScript
- **XML Formatter** - Format, minify, and validate XML with indentation options
- **HTML Formatter** - Format and minify HTML with intelligent tag handling
- **CSS Formatter** - Format, minify with SCSS/LESS conversion and vendor auto-prefixing
- **SQL Formatter** - Format, minify, and validate SQL with keyword uppercasing option

### Text Utilities

- **RegExp Tester** - Test regular expressions with match highlighting and capture groups
- **Text Diff** - Side-by-side text comparison with line-by-line diff highlighting
- **Line Sorter** - Sort lines alphabetically with case-sensitive, natural sort, reverse, and shuffle options
- **Line Deduplicator** - Remove duplicate lines with options to keep first/last occurrence and sort
- **Text Replacer** - Find and replace with regex support, case-sensitive/insensitive, and whole word matching
- **String Inspector** - Comprehensive text analysis: character/word/line counts, byte sizes, entropy, Unicode analysis

### Encoders & Generators

- **HTML Entity Encoder/Decoder** - Encode/decode HTML entities (named, decimal, hex formats)
- **Lorem Ipsum Generator** - Generate placeholder text (paragraphs, sentences, words)
- **Random String Generator** - Generate cryptographically secure random strings with customizable character sets
- **Backslash Escape/Unescape** - Escape and unescape special characters in strings
- **Base32 Encoder/Decoder** - Encode/decode Base32 with Standard and Hex variants (RFC 4648)

### Inspectors & Parsers

- **URL Parser** - Parse URLs into components (scheme, host, port, path, query params, fragment)
- **Cron Expression Parser** - Parse cron expressions with human-readable descriptions and next 10 execution times
- **JSON Path Tester** - Test JSONPath expressions with syntax like $.users[0].name, $..email
- **Certificate Inspector (X.509)** - Decode and inspect X.509 certificates with detailed information and JSON export

### Developer Utilities

- **cURL to Code Converter** - Convert cURL commands to code in Swift, Python, JavaScript, Go, PHP, and Ruby
- **SVG to CSS Converter** - Convert SVG to CSS data URIs with optimization and multiple format options
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

- **CryptoKit**: Cryptographic operations (HMAC, SHA, RSA, ECDSA)
- **Security**: RSA/ECDSA signature verification, X.509 certificate parsing
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

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Process/Execute | `Cmd+Return` |
| Decode | `Cmd+D` |
| Verify | `Cmd+V` |
| Format | `Cmd+F` |
| Minify | `Cmd+M` |
| Clear | `Cmd+K` |
| Copy Output | `Cmd+Shift+C` |
| Preferences | `Cmd+,` |

---

## Roadmap

### Phase 1-9: Complete
All 40 tools implemented with comprehensive test coverage.

### Phase 10: Enhancements & Hardening - Complete
- [x] JSON Formatter tree view, JSONPath breadcrumbs, line numbers
- [x] CSS Formatter SCSS/LESS conversion & vendor auto-prefixing
- [x] JWT Debugger RSA/ECDSA/PS algorithms with public-key inputs and claim validation

### Phase 11: Release Automation - Complete
- [x] GitHub Action workflow for builds and releases
- [x] Code signing and notarization documentation

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

*Last Updated: December 2025*

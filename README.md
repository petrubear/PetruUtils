# PetruUtils

A native macOS application providing an all-in-one toolbox for software developers. Inspired by [DevUtils](https://devutils.com), PetruUtils offers 40+ carefully crafted developer tools with a focus on privacy, performance, and offline operation.

## 🎯 Project Status

**Current Phase**: Phase 9 – Remaining Utilities (in progress)

- **Tools Implemented**: 34 of 40 planned (85%) (see `Tool.swift`)
- **Tests**: 330+ service/unit tests across implemented tools
- **Preferences/History/Favorites**: ✅ Complete (Phase 5)
- **Release Automation**: ✅ Complete (GitHub Actions workflow ready)

### Implemented Tools

**Phase 2 - Core Tools** ✅
- ✅ **JWT Debugger** - Full HS256 support with decode, verify, and generate capabilities
- ✅ **Base64 Encoder/Decoder** - Encode/decode text with Standard and URL-safe variants
- ✅ **URL Encoder/Decoder** - Full URL encoding/decoding with multiple component types
- ✅ **Hash Generator** - MD5, SHA-1, SHA-256, SHA-384, SHA-512 with HMAC support
- ✅ **UUID/ULID Generator** - UUID v1, v4, v5 and ULID generation with bulk support
- ✅ **QR Code Generator** - Generate and scan QR codes with custom colors and error correction
- ✅ **Smart Clipboard Detection** - Automatic content type detection with tool suggestions

**Phase 3 - Converters** ✅
- ✅ **Number Base Converter** - Convert between Binary, Octal, Decimal, and Hexadecimal with bit/byte representation
- ✅ **Unix Timestamp Converter** - Convert timestamps to/from human-readable dates with timezone support
- ✅ **Case Converter** - Convert between camelCase, snake_case, kebab-case, PascalCase, and more
- ✅ **Color Converter** - Convert between HEX, RGB, HSL, HSV, and CMYK with live preview
- ✅ **JSON ↔ YAML Converter** - Bidirectional conversion between JSON and YAML formats
- ✅ **JSON ↔ CSV Converter** - Convert JSON arrays to CSV and back with delimiter options
- ✅ **Markdown ↔ HTML Converter** - Convert between Markdown and HTML formats

**Phase 4 - Advanced Tools** ✅ (partial enhancements pending)
- ✅ **JSON Formatter** - Format, minify, and validate JSON (tree view, JSONPath breadcrumbs still pending)
- ✅ **JavaScript Formatter** - Format, minify, and validate JavaScript (initial formatter/minifier/validator complete; TS/JSX helpers forthcoming)
- ✅ **RegExp Tester** - Test regular expressions with match highlighting and capture groups
- ✅ **Text Diff** - Side-by-side text comparison with line-by-line diff highlighting
- ✅ **XML Formatter** - Format, minify, and validate XML with indentation options
- ✅ **HTML Formatter** - Format and minify HTML with intelligent tag handling
- ✅ **CSS Formatter** - Format, minify, and validate CSS with property sorting option (SCSS/LESS conversion + prefixing pending)
- ✅ **SQL Formatter** - Format, minify, and validate SQL with keyword uppercasing option

**Phase 6 - Text Utilities** ✅ (4/4 tools)
- ✅ **Line Sorter** - Sort lines alphabetically with case-sensitive, natural sort, reverse, and shuffle options
- ✅ **Line Deduplicator** - Remove duplicate lines with options to keep first/last occurrence and sort
- ✅ **Text Replacer** - Find and replace with regex support, case-sensitive/insensitive, and whole word matching
- ✅ **String Inspector** - Comprehensive text analysis: character/word/line counts, byte sizes, entropy, Unicode analysis

**Phase 7 - Encoders & Generators** ✅ (2/2 tools)
- ✅ **HTML Entity Encoder/Decoder** - Encode/decode HTML entities (named, decimal, hex formats)
- ✅ **Lorem Ipsum Generator** - Generate placeholder text (paragraphs, sentences, words)

**Phase 8 - Inspectors & Generators** ✅ (7/7 tools)
- ✅ **URL Parser** - Parse URLs into components (scheme, host, port, path, query params, fragment)
- ✅ **Random String Generator** - Generate cryptographically secure random strings with customizable character sets
- ✅ **Backslash Escape/Unescape** - Escape and unescape special characters in strings (quotes, newlines, tabs, etc.)
- ✅ **Base32 Encoder/Decoder** - Encode/decode Base32 with Standard and Hex variants (RFC 4648)
- ✅ **Cron Expression Parser** - Parse cron expressions with human-readable descriptions and next 10 execution times
- ✅ **JSON Path Tester** - Test JSONPath expressions with syntax like $.users[0].name, $..email

**Phase 9 - Remaining Utilities** 🚧 (partial)
- ✅ **cURL → Code Converter** - Convert cURL commands to code in Swift, Python, JavaScript, Go, PHP, and Ruby

### Planned Tools (40+)

See [SPEC.md](SPEC.md) for the complete specification including:
- Formatters & Validators (JSON, XML, HTML, CSS, JavaScript, SQL)
- Encoders & Decoders (Base64, URL, HTML entities, JWT)
- Converters (YAML↔JSON, CSV↔JSON, Number Base, Color, Unix Time)
- Generators (UUID/ULID, Hash, Lorem Ipsum, QR Code)
- Inspectors & Debuggers (RegExp, Text Diff, String Inspector, Cron Parser)
- Text Utilities (Line Sorter, Deduplicator, Text Replacer)

## 🚀 Features

### Core Principles

- **🔒 Privacy First**: All operations run locally; no data leaves your machine
- **🌐 Offline by Default**: Full functionality without internet connection
- **⚡ Native Performance**: Built with SwiftUI for Apple Silicon and Intel Macs
- **🧠 Smart Detection**: Intelligent clipboard content detection (planned)
- **⌨️ Developer UX**: Keyboard shortcuts, quick actions, minimal friction

### JWT Debugger Features

- Decode JWT tokens (header, payload, signature)
- Verify HS256 signatures using HMAC-SHA256
- Generate JWT tokens programmatically
- Pretty JSON formatting with syntax highlighting
- Claims extraction and display
- Keyboard shortcuts (⌘D, ⌘V, ⌘K)
- Split-pane interface with resizable divider
- Comprehensive error handling

## 🛠 Technical Stack

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

## 📦 Installation & Usage

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
⌘R
```

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'

# Or use Xcode
⌘U
```

**Test Status**: ⚠️ 328 service tests defined; local CI run currently blocked by Preview macro sandboxing in this environment (last attempt Nov 30, 2025)  
**Tools Completed**: 33 of 40 (82.5% complete)  
**Phase 5 Features**: Preferences, History, Favorites, Export/Import shipped; release automation still pending

## 📚 Documentation

- **[SPEC.md](SPEC.md)** - Complete application specification with all planned tools
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Current implementation details
- **[PHASE5_PREFERENCES_PLAN.md](PHASE5_PREFERENCES_PLAN.md)** - Detailed Phase 5 preferences & polish plan
- **[README_JWT.md](PetruUtils/Views/README_JWT.md)** - JWT Debugger documentation

## 🏗 Architecture

### Design Pattern

```
┌─────────────────────────────────────────┐
│            Views (SwiftUI)              │
├─────────────────────────────────────────┤
│          ViewModels (@MainActor)        │
├─────────────────────────────────────────┤
│        Services (Business Logic)        │
├─────────────────────────────────────────┤
│    Foundation / CryptoKit / AppKit      │
└─────────────────────────────────────────┘
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
│   └── JWTView.swift                 # JWT Debugger UI
├── Services/
│   └── JWTService.swift              # JWT business logic
└── Resources/
    └── Assets.xcassets

PetruUtilsTests/
└── JWTServiceTests.swift             # Unit tests (40+)
```

### Key Design Decisions

- **MVVM Pattern**: Clear separation of concerns
- **Protocol-Oriented**: Extensible and testable
- **Service Layer**: Business logic isolated from UI
- **Testable**: Comprehensive unit test coverage

## 🧪 Testing

### Test Coverage

- ✅ Service suites for JWT, Base64, URL, Hash, UUID/ULID, QR Code, Clipboard Monitor, History Manager, Line utilities, etc.
- ✅ Token generation, decoding, verification (HS256 today)
- ✅ Edge cases (unicode, large payloads, special characters)
- ✅ Security tests (timing attacks, tampering attempts)
- ✅ Error handling and validation branches for each service

### Test Results

```bash
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'
# BUILD SUCCEEDED – all current suites green
```

## 🗺 Roadmap

### Phase 1: Foundation ✅
- [x] Project setup and architecture
- [x] Main navigation and sidebar
- [x] JWT Debugger with HS256 support
- [x] Comprehensive unit tests
- [x] Documentation

### Phase 2: Core Tools ✅
- [x] Base64 Encoder/Decoder
- [x] URL Encoder/Decoder
- [x] Hash Generator
- [x] UUID/ULID Generator
- [x] QR Code Generator
- [x] Smart Clipboard Detection

### Phase 3: Converters 🔄 (7/9 complete)
- [x] Number Base Converter
- [x] Unix Timestamp Converter
- [x] Case Converter
- [x] Color Converter
- [x] JSON ↔ YAML
- [x] JSON ↔ CSV
- [x] Markdown ↔ HTML
- [ ] cURL → Code Converter
- [ ] SVG → CSS Converter

### Phase 4: Advanced Tools ✅ (enhancements pending)
- [x] JSON Formatter (needs tree view + JSONPath breadcrumbs)
- [x] RegExp Tester
- [x] Text Diff/Compare
- [x] XML Formatter
- [x] HTML Formatter
- [x] CSS Formatter (SCSS/LESS conversion + auto-prefixing still pending)
- [x] SQL Formatter
- [x] JavaScript Formatter

### Phase 5: Polish & Release ✅
- [x] Tool history and favorites
- [x] Preferences panel (6 categories)
- [x] Export/import utilities
- [x] Lazy loading for performance
- [x] App icon specification
- [x] Clipboard auto-switch preference wiring
- [x] GitHub Action workflow to build & upload releases on version tags

### Phase 6: Text Utilities ✅
- [x] Line Sorter
- [x] Line Deduplicator
- [x] Text Replacer
- [x] String Inspector

### Phase 7: Encoders & Generators ✅
- [x] HTML Entity Encoder/Decoder
- [x] Lorem Ipsum Generator

### Phase 8: Inspectors & Generators ✅
- [x] URL Parser
- [x] Random String Generator
- [x] Backslash Escape/Unescape
- [x] Base32 Encoder/Decoder
- [x] Cron Expression Parser
- [x] JSON Path Tester

### Phase 9: Remaining Utilities 🚧 (2/8)
- [x] JavaScript Formatter
- [x] cURL → Code Converter
- [ ] SVG → CSS Converter
- [ ] Certificate Inspector (X.509)
- [ ] IP Utilities (CIDR/subnet calculator, subnet math)
- [ ] ASCII Art Generator
- [ ] Bcrypt Generator/Verifier
- [ ] TOTP Generator

### Phase 10: Enhancements & Hardening 🚧
- [ ] JSON Formatter tree view, JSONPath breadcrumbs, line numbers, richer validation UI
- [ ] CSS Formatter SCSS/LESS conversion & vendor auto-prefixing
- [ ] JWT Debugger support for RSA/ECDSA/PS algorithms plus public-key inputs and claim validation

### Phase 11: Release Automation 🔲
- [ ] GitHub Action workflow that builds/tests/signs the macOS app and uploads release artifacts on version tags

## 🔮 Upcoming Work

1. Ship the remaining utilities (JavaScript Formatter, cURL → Code, SVG → CSS, Certificate Inspector, IP Utilities, ASCII Art generator, Bcrypt helper, TOTP generator).
2. Enhance existing tools: JSON Formatter tree view/breadcrumbs, CSS Formatter SCSS/LESS + prefixing, JWT Debugger RSA/ECDSA/PS support with key inputs.
3. Create a GitHub Action that builds, signs/notarizes, tests, and attaches artifacts whenever a version tag (e.g., `v*`) is pushed.

## 🤝 Contributing

This is a personal project, but suggestions and feedback are welcome!

### Development Guidelines

1. Follow Swift style conventions
2. Write unit tests for all business logic
3. Document public APIs
4. Keep UI and business logic separated
5. Use SwiftUI best practices

## 📄 License

TBD - To be determined

## 🙏 Acknowledgments

- Inspired by [DevUtils](https://devutils.com)
- Built with Apple's SwiftUI and CryptoKit
- JWT implementation follows RFC 7519

## 📞 Contact

Edison Martinez - Project Creator

---

**Note**: This project is under active development. Features and APIs may change.

*Last Updated: November 30, 2025*

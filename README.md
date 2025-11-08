# PetruUtils

A native macOS application providing an all-in-one toolbox for software developers. Inspired by [DevUtils](https://devutils.com), PetruUtils offers 40+ carefully crafted developer tools with a focus on privacy, performance, and offline operation.

## 🎯 Project Status

**Current Phase**: Phase 2 - Core Tools ✅ COMPLETE

### Implemented Tools

- ✅ **JWT Debugger** - Full HS256 support with decode, verify, and generate capabilities
- ✅ **Base64 Encoder/Decoder** - Encode/decode text with Standard and URL-safe variants
- ✅ **URL Encoder/Decoder** - Full URL encoding/decoding with multiple component types
- ✅ **Hash Generator** - MD5, SHA-1, SHA-256, SHA-384, SHA-512 with HMAC support
- ✅ **UUID/ULID Generator** - UUID v1, v4, v5 and ULID generation with bulk support
- ✅ **QR Code Generator** - Generate and scan QR codes with custom colors and error correction
- ✅ **Smart Clipboard Detection** - Automatic content type detection with tool suggestions

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

**Test Status**: ✅ 200+ tests passing (all service tests)

## 📚 Documentation

- **[SPEC.md](SPEC.md)** - Complete application specification with all planned tools
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Current implementation details
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

- ✅ **40+ Unit Tests** for JWT Service
- ✅ Token generation, decoding, verification
- ✅ Edge cases (unicode, large payloads, special characters)
- ✅ Security tests (timing attacks, tampering)
- ✅ Error handling and validation

### Test Results

```bash
Test Suite 'All tests' passed
Executed 40+ tests, with 0 failures
```

## 🗺 Roadmap

### Phase 1: Foundation ✅ (Complete)
- [x] Project setup and architecture
- [x] Main navigation and sidebar
- [x] JWT Debugger with HS256 support
- [x] Comprehensive unit tests
- [x] Documentation

### Phase 2: Core Tools ✅ COMPLETE
- [x] Base64 Encoder/Decoder
- [x] URL Encoder/Decoder
- [x] Hash Generator
- [x] UUID/ULID Generator
- [x] QR Code Generator
- [x] Smart Clipboard Detection

### Phase 3: Converters
- [ ] Number Base Converter
- [ ] Color Converter
- [ ] Unix Timestamp Converter
- [ ] Case Converter
- [ ] JSON ↔ YAML
- [ ] JSON ↔ CSV

### Phase 4: Advanced Tools
- [ ] RegExp Tester
- [ ] Text Diff/Compare
- [ ] XML Formatter
- [ ] HTML Formatter
- [ ] JSON Formatter (enhanced)

### Phase 5: Polish & Features
- [ ] Smart clipboard detection
- [ ] Tool history and favorites
- [ ] Preferences panel
- [ ] Performance optimization

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

*Last Updated: November 7, 2025*

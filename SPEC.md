# PetruUtils - Technical Specification

## Project Overview

PetruUtils is a native macOS application that provides an all-in-one toolbox for software developers, inspired by DevUtils. It offers 40+ carefully crafted developer tools in a single, offline-first application with a focus on privacy, performance, and developer experience.

### Core Philosophy
- **Privacy First**: All operations run locally; no data leaves the user's machine
- **Offline by Default**: Full functionality without internet connection
- **Native Performance**: Built with SwiftUI for Apple Silicon and Intel Macs
- **Smart Detection**: Intelligent clipboard content detection with automatic tool suggestion
- **Developer UX**: Keyboard shortcuts, quick actions, and minimal friction

---

## Technical Stack

### Platform Requirements
- **macOS**: 13.0+ (Ventura and later)
- **Architecture**: Universal binary (Apple Silicon + Intel)
- **Framework**: SwiftUI + Combine
- **Language**: Swift 5.9+
- **Xcode**: 15.0+

### Key Technologies
- **CryptoKit**: Hashing, HMAC, encryption operations
- **Foundation**: Core data processing, encoding/decoding
- **AppKit**: Native macOS integrations, pasteboard, file operations
- **RegexBuilder**: Modern regex parsing and validation
- **CoreImage**: QR code generation and processing
- **Syntax Highlighting**: Custom or third-party library (e.g., Splash, Highlightr)

---

## Architecture

### Design Pattern
- **MVVM** (Model-View-ViewModel) for each tool
- **Protocol-Oriented**: Common tool protocol for consistency
- **Modular**: Each tool is self-contained and independently testable

### Project Structure
```
PetruUtils/
├── PetruUtilsApp.swift              # App entry point
├── Models/
│   ├── Tool.swift                    # Tool enum and metadata
│   └── ToolCategory.swift            # Category grouping
├── ViewModels/
│   ├── MainViewModel.swift           # App-level state
│   └── Tools/                        # Individual tool ViewModels
│       ├── JSONFormatterViewModel.swift
│       ├── Base64ViewModel.swift
│       └── ...
├── Views/
│   ├── ContentView.swift             # Main navigation
│   ├── Sidebar/
│   │   ├── SidebarView.swift
│   │   └── ToolRow.swift
│   ├── ToolContainer.swift           # Common tool wrapper
│   └── Tools/                        # Individual tool views
│       ├── JSONFormatterView.swift
│       ├── Base64View.swift
│       └── ...
├── Services/
│   ├── ClipboardMonitor.swift        # Smart detection
│   ├── ToolDetector.swift            # Pattern matching
│   └── HistoryManager.swift          # Recent conversions
├── Utilities/
│   ├── Extensions/
│   ├── Formatters/
│   └── Validators/
└── Resources/
    └── Assets.xcassets
```

---

## Feature Specification

### 1. Navigation & Layout

#### Main Window
- **Split View Layout**: Two-pane design (sidebar + detail)
- **Sidebar**: Categorized tool list with search/filter
- **Detail Pane**: Active tool interface
- **Resizable**: User can adjust pane widths (persist preferences)
- **Window Controls**: Min size 900x600, default 1200x800

#### Sidebar Features
- Search bar for quick tool filtering
- Category sections (collapsible):
  - Formatters & Validators
  - Encoders & Decoders
  - Converters
  - Generators
  - Inspectors & Debuggers
- Tool icons (SF Symbols)
- Recent tools section
- Favorites/pinning capability

#### Toolbar
- Tool-specific actions (Format, Validate, Copy, Clear, etc.)
- Settings button (global preferences)
- Theme toggle (Light/Dark/System)
- Quick tool switcher (⌘T)

---

### 2. Smart Detection

#### Clipboard Monitoring
- **Background Service**: Monitors clipboard changes
- **Privacy Respecting**: User must grant pasteboard access
- **Intelligent Pattern Matching**:
  - JSON: Detect `{` or `[` with valid structure
  - Base64: Pattern match + entropy analysis
  - URLs: RFC-compliant URL detection
  - Unix timestamps: 10 or 13-digit numbers
  - JWT: Three base64url segments separated by dots
  - UUID: 8-4-4-4-12 hex pattern
  - XML/HTML: Tag detection
  - CSS/JS: Code pattern recognition
  - Hash values: Hex strings of specific lengths (32, 40, 64, 128 chars)
  
#### Smart Suggestions
- **Notification Badge**: Show suggested tool in sidebar
- **Auto-Paste Option**: Preference to auto-paste detected content
- **Multi-Tool Suggestions**: Some content may match multiple tools
- **Keyboard Shortcut**: ⌘⇧V to paste and detect

---

### 3. Tool Categories & Features

### Category: Formatters & Validators

#### 3.1 JSON Formatter/Validator
**Status**: ✅ Partially implemented (needs enhancement)

**Features**:
- Format/prettify JSON with customizable indentation (2, 4 spaces or tabs)
- Minify JSON (remove whitespace)
- Validate JSON syntax with detailed error messages (line/column)
- Sort keys alphabetically
- JSON tree view (collapsible/expandable)
- Path extraction (show JSON path on hover)
- Line numbers
- Syntax highlighting

**Input/Output**:
- Input: Raw JSON text
- Output: Formatted/validated JSON
- Error display with line/column indication

**Keyboard Shortcuts**:
- ⌘F: Format
- ⌘M: Minify
- ⌘K: Clear

---

#### 3.2 XML Formatter/Validator

**Features**:
- Format/prettify XML with indentation
- Minify XML
- Validate against XML schema (optional XSD upload)
- Convert to/from JSON
- XPath testing
- Syntax highlighting

---

#### 3.3 HTML Formatter

**Features**:
- Format/prettify HTML
- Minify HTML
- Live preview pane
- Convert to Markdown
- Convert to JSX (React)
- Validate HTML5
- Extract links, images, scripts

---

#### 3.4 CSS Formatter

**Features**:
- Format/prettify CSS
- Minify CSS
- Sort properties alphabetically
- Validate syntax
- Convert to SCSS/LESS/Sass
- Auto-prefix vendor prefixes

---

#### 3.5 JavaScript Formatter

**Features**:
- Format/prettify JavaScript
- Minify JavaScript
- Validate syntax
- Convert to TypeScript (basic)
- ES6+ compatibility check

---

#### 3.6 SQL Formatter

**Features**:
- Format SQL queries
- Support multiple dialects (MySQL, PostgreSQL, SQLite, SQL Server)
- Syntax highlighting
- Keyword capitalization options
- Validate syntax

---

### Category: Encoders & Decoders

#### 3.7 Base64 Encoder/Decoder
**Status**: 🔲 Planned

**Features**:
- Encode text/files to Base64
- Decode Base64 to text/files
- Support for Base64URL variant
- Image preview for decoded images
- File drag-and-drop support
- Multi-line support
- Detect and auto-decode

**Modes**:
- Text ↔ Base64
- File ↔ Base64
- Image preview

---

#### 3.8 URL Encoder/Decoder

**Features**:
- URL encode/decode
- Component encoding (encode only query params)
- Full URL parsing (protocol, host, path, query, fragment)
- Query parameter extraction and formatting
- Validation

---

#### 3.9 HTML Entity Encoder/Decoder

**Features**:
- Encode special characters to HTML entities
- Decode HTML entities to characters
- Named entities (e.g., `&nbsp;`)
- Numeric entities (e.g., `&#160;`)
- Hex entities (e.g., `&#xA0;`)

---

#### 3.10 JWT Debugger
**Status**: ✅ Implemented (HS256 only)

**Enhancements Needed**:
- Support additional algorithms:
  - RS256, RS384, RS512 (RSA)
  - ES256, ES384, ES512 (ECDSA)
  - PS256, PS384, PS512 (RSA-PSS)
- Public key input for RSA/ECDSA verification
- Decode without verification option
- Claims validation (exp, nbf, iat)
- Token generation feature
- Save/load keys

---

#### 3.11 Backslash Escape/Unescape

**Features**:
- Escape special characters (`\n`, `\t`, `\"`, etc.)
- Unescape escaped strings
- Language-specific escaping (JSON, JavaScript, C, Python, etc.)
- Unicode escape sequences

---

### Category: Converters

#### 3.12 JSON ↔ YAML Converter

**Features**:
- Bidirectional conversion
- Preserve comments (YAML → JSON lossy)
- Syntax highlighting for both
- Validation for both formats

---

#### 3.13 JSON ↔ CSV Converter

**Features**:
- JSON array to CSV table
- CSV to JSON array
- Custom delimiter support (comma, tab, semicolon)
- Header row handling
- Nested object flattening options

---

#### 3.14 Number Base Converter

**Features**:
- Convert between bases: Binary, Octal, Decimal, Hexadecimal
- Live conversion as you type
- Support for signed/unsigned integers
- Bit manipulation view
- Byte representation

---

#### 3.15 Color Converter

**Features**:
- Convert between formats:
  - HEX (#RRGGBB)
  - RGB (rgb(r, g, b))
  - HSL (hsl(h, s%, l%))
  - HSV/HSB
  - CMYK
- Color picker integration
- Preview swatch
- Copy to clipboard in any format

---

#### 3.16 Unix Timestamp Converter

**Features**:
- Unix timestamp (seconds) ↔ Human-readable date
- Millisecond timestamp support
- Current timestamp button
- Timezone selection
- Multiple date format outputs (ISO 8601, RFC 2822, custom)
- Relative time display ("2 hours ago")

---

#### 3.17 Case Converter

**Features**:
- Convert between cases:
  - camelCase
  - PascalCase
  - snake_case
  - kebab-case
  - UPPER_CASE
  - lower case
  - Title Case
  - Sentence case
- Bulk text support

---

#### 3.18 Markdown ↔ HTML Converter

**Features**:
- Markdown to HTML conversion
- HTML to Markdown conversion
- Live preview
- GitHub Flavored Markdown support
- Syntax highlighting in code blocks

---

#### 3.19 cURL to Code Converter

**Features**:
- Parse cURL command
- Generate equivalent code in:
  - Swift (URLSession, Alamofire)
  - Python (requests, urllib)
  - JavaScript (fetch, axios)
  - Go (net/http)
  - PHP (cURL)
  - Ruby (Net::HTTP)
- Copy to clipboard

---

#### 3.20 SVG to CSS Converter

**Features**:
- Convert SVG to data URI for CSS background
- Optimize SVG (remove metadata, minimize)
- Preview SVG
- Generate CSS code

---

### Category: Generators

#### 3.21 UUID/ULID Generator
**Status**: 🔲 Planned

**Features**:
- Generate UUIDs (v1, v4, v5)
- Generate ULIDs
- Bulk generation (1-1000)
- Uppercase/lowercase options
- With/without hyphens
- Copy all or individual IDs

---

#### 3.22 Hash Generator

**Features**:
- Generate hashes from text/files
- Supported algorithms:
  - MD5
  - SHA-1
  - SHA-224, SHA-256, SHA-384, SHA-512
  - SHA3-224, SHA3-256, SHA3-384, SHA3-512
  - Keccak-256 (Ethereum)
- File drag-and-drop support
- HMAC mode with key input
- Compare hashes (verify)

---

#### 3.23 Lorem Ipsum Generator

**Features**:
- Generate placeholder text
- Options: paragraphs, sentences, words, bytes
- Quantity selector (1-100)
- "Lorem ipsum" or random words
- Copy to clipboard

---

#### 3.24 QR Code Generator
**Status**: 🔲 Planned

**Features**:
- Generate QR codes from text/URLs
- Error correction levels (L, M, Q, H)
- Size customization
- Color customization (foreground/background)
- Export as PNG, SVG, PDF
- QR code scanner (camera/image file)

---

#### 3.25 Random String Generator

**Features**:
- Generate random strings
- Character sets: lowercase, uppercase, numbers, symbols
- Custom length (1-1000)
- Bulk generation
- Avoid ambiguous characters option (0/O, 1/l/I)
- Cryptographically secure randomness

---

### Category: Inspectors & Debuggers

#### 3.26 RegExp Tester

**Features**:
- Test regular expressions
- Multiple flavors: JavaScript, Swift, Python, Go, PHP
- Real-time match highlighting
- Match groups display
- Test string multiline support
- Common regex patterns library (email, URL, IP, etc.)
- Explanation/documentation of regex

---

#### 3.27 Text Diff/Compare

**Features**:
- Side-by-side diff view
- Inline diff view
- Line-by-line comparison
- Character-level diff
- Ignore whitespace option
- Syntax highlighting for code diffs
- Export diff as unified format

---

#### 3.28 String Inspector

**Features**:
- Analyze string properties:
  - Character count
  - Word count
  - Line count
  - Byte size (UTF-8, UTF-16)
  - Entropy
- Character frequency analysis
- Unicode code points
- Detect encoding
- Line ending detection (LF, CRLF, CR)

---

#### 3.29 Cron Expression Parser

**Features**:
- Parse cron expressions
- Human-readable description
- Next 10 execution times
- Timezone support
- Validate syntax
- Common cron patterns library

---

#### 3.30 Certificate Inspector (X.509)

**Features**:
- Decode X.509 certificates (PEM, DER)
- Display certificate details:
  - Subject, Issuer
  - Valid from/to dates
  - Serial number
  - Public key algorithm
  - Signature algorithm
  - Extensions (SAN, key usage, etc.)
- Certificate chain validation
- File or paste input
- Export as JSON

---

#### 3.31 JSON Path Tester

**Features**:
- Test JSON Path expressions
- Syntax highlighting
- Result preview
- Support JSONPath syntax
- Common path examples

---

### Category: Text Utilities

#### 3.32 Line Sorter

**Features**:
- Sort lines alphabetically
- Ascending/descending
- Case-sensitive/insensitive
- Natural sort (handle numbers correctly)
- Reverse order
- Shuffle lines

---

#### 3.33 Line Deduplicator

**Features**:
- Remove duplicate lines
- Keep first or last occurrence
- Case-sensitive/insensitive
- Sort after deduplication (optional)
- Show duplicate count

---

#### 3.34 Text Replacer

**Features**:
- Find and replace
- Regex support
- Case-sensitive/insensitive
- Whole word matching
- Replace all or one at a time
- Preview changes

---

#### 3.35 URL Parser

**Features**:
- Parse URL components:
  - Protocol/scheme
  - Host/domain
  - Port
  - Path
  - Query parameters (as table)
  - Fragment
- Validation
- Query parameter editing

---

### Additional Tools (Optional/Phase 2)

#### 3.36 IP Address Tools
- IP to binary/hex conversion
- CIDR calculator
- Subnet calculator
- IP validation (IPv4/IPv6)

#### 3.37 Base32 Encoder/Decoder
- Standard Base32
- Base32 Hex variant

#### 3.38 ASCII Art Generator
- Text to ASCII art
- Font selection

#### 3.39 Bcrypt Generator/Verifier
- Hash passwords with bcrypt
- Verify bcrypt hashes
- Cost factor adjustment

#### 3.40 TOTP Generator
- Time-based One-Time Password
- QR code import
- Multiple accounts management

---

## UI/UX Design Principles

### Visual Design
- **Native macOS Look**: Follow Apple Human Interface Guidelines
- **Consistent Layout**: All tools use similar input/output structure
- **Monospaced Fonts**: For code, JSON, Base64, etc.
- **Syntax Highlighting**: Color-coded for readability
- **Clear Typography**: SF Pro for UI, SF Mono for code

### Interaction Patterns
- **Copy on Click**: Click any output to copy to clipboard
- **Drag & Drop**: Accept file drops where applicable
- **Auto-Paste**: Paste clipboard on tool switch (optional preference)
- **Undo/Redo**: Standard text editing with ⌘Z/⌘⇧Z
- **Tool-Specific Actions**: Context-appropriate toolbar buttons

### Accessibility
- **Keyboard Navigation**: Full keyboard control
- **VoiceOver Support**: Proper labels and hints
- **Contrast Compliance**: WCAG AA minimum
- **Resizable Text**: Support Dynamic Type where possible

---

## Keyboard Shortcuts

### Global Shortcuts
- `⌘T` - Quick tool switcher (fuzzy search)
- `⌘1` through `⌘9` - Switch to tool by position
- `⌘F` - Focus search in sidebar
- `⌘,` - Open preferences
- `⌘W` - Close window
- `⌘Q` - Quit application
- `⌘⇧V` - Smart paste from clipboard

### Tool-Specific Shortcuts
- `⌘R` - Run/Execute/Format (context-dependent)
- `⌘K` - Clear all inputs
- `⌘C` - Copy output
- `⌘V` - Paste input
- `⌘⇧C` - Copy as... (format options)
- `⌘E` - Export to file
- `⌘I` - Import from file

---

## Data Persistence

### User Preferences
- Last used tool
- Favorite tools
- Window size and position
- Pane split ratios
- Theme preference
- Default encodings/formats
- Smart detection enabled/disabled
- History retention period

### Storage
- **UserDefaults**: For preferences and settings
- **Files**: For history/recent items (optional, privacy-conscious)
- **No Analytics**: No telemetry or usage tracking

---

## Performance Requirements

### Responsiveness
- Tool switch: < 100ms
- Format/convert operations: < 500ms for typical input
- Large file handling: Progress indicators for > 1MB
- Smart detection: < 50ms per clipboard check

### Memory
- Baseline: < 100MB
- With large files: Streaming where possible
- No memory leaks on tool switching

---

## Testing Strategy

### Unit Tests
- ViewModels: Test all conversion/formatting logic
- Utilities: Test encoding, validation, parsing functions
- Services: Mock clipboard, test pattern detection

### UI Tests
- Navigation flows
- Keyboard shortcuts
- Copy/paste operations
- Tool switching

### Manual Testing
- Performance with large files
- Edge cases (malformed input)
- Accessibility with VoiceOver
- Multi-monitor setups

---

## Development Phases

### Phase 1: Foundation (Weeks 1-2)
- ✅ Project setup and architecture
- ✅ Main navigation and sidebar
- ✅ Tool protocol and base classes
- ✅ Common UI components (CodeBlock, ToolContainer)
- ✅ JWT Debugger (already implemented)

### Phase 2: Core Tools (Weeks 3-6)
- ✅ Base64 Encoder/Decoder
- ✅ URL Encoder/Decoder
- Hash Generator
- UUID/ULID Generator
- QR Code Generator
- Smart Clipboard Detection Service
  - Background clipboard monitoring
  - Pattern detection (JSON, Base64, JWT, URLs, etc.)
  - Auto-suggestion in sidebar
  - Privacy-respecting implementation
- JSON Formatter (enhance existing)
- Text Diff

### Phase 3: Converters (Weeks 7-9)
- Number Base Converter
- Color Converter
- Unix Timestamp Converter
- Case Converter
- JSON ↔ YAML
- JSON ↔ CSV
- Markdown ↔ HTML

### Phase 4: Advanced Tools (Weeks 10-12)
- RegExp Tester
- XML Formatter
- HTML Formatter
- CSS Formatter
- SQL Formatter
- cURL to Code
- Certificate Inspector

### Phase 5: Polish & Smart Features (Weeks 13-14)
- Smart clipboard detection
- History and favorites
- Export/import functionality
- Preferences panel
- Performance optimization
- Bug fixes and refinement

### Phase 6: Additional Tools (Optional)
- Remaining text utilities
- Specialized converters
- Community-requested features

---

## Open Questions & Decisions

1. **Syntax Highlighting Library**: Custom implementation vs third-party (Splash, Highlightr)?
2. **File Size Limits**: Max file size for processing? Stream vs load into memory?
3. **History**: Should we persist conversion history? If yes, how long?
4. **Plugins**: Future extensibility for third-party tools?
5. **Cloud Sync**: UserDefaults sync via iCloud for preferences across devices?
6. **Menu Bar App**: Should there be a lightweight menu bar version?
7. **Spotlight Integration**: Quick Look plugin for formats?

---

## Success Metrics

- **Functionality**: All tools work correctly with typical and edge-case inputs
- **Performance**: Sub-second response for 95% of operations
- **Usability**: Users can complete tasks without documentation
- **Stability**: No crashes during normal operation
- **Privacy**: Zero network requests (except for updates)

---

## Future Enhancements

- **Themes**: Additional color schemes beyond Light/Dark
- **Customization**: User-defined tools or scripts
- **Batch Operations**: Process multiple files at once
- **CLI**: Command-line interface for power users
- **Alfred/Raycast Integration**: Launch specific tools directly
- **iOS Companion App**: Subset of tools for iPhone/iPad
- **Scripting Support**: AppleScript/JavaScript automation

---

## Resources & References

- **DevUtils**: https://devutils.com (inspiration)
- **Apple HIG**: https://developer.apple.com/design/human-interface-guidelines/macos
- **SwiftUI Documentation**: https://developer.apple.com/documentation/swiftui
- **CryptoKit**: https://developer.apple.com/documentation/cryptokit
- **Regular Expressions**: NSRegularExpression, RegexBuilder

---

## License & Distribution

- **License**: TBD (MIT, Apache 2.0, or proprietary)
- **Distribution**: Direct download, Mac App Store, Homebrew
- **Pricing Model**: Free, freemium, or paid (TBD)
- **Open Source**: Consider open-sourcing individual tools or utilities

---

*This specification is a living document and will be updated as development progresses and requirements evolve.*

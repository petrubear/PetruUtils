# PetruUtils - Technical Specification

## Project Overview

PetruUtils is a native macOS application that provides an all-in-one toolbox for software developers, inspired by DevUtils. It offers 40+ carefully crafted developer tools in a single, offline-first application with a focus on privacy, performance, and developer experience.

**Current Snapshot (Dec 3, 2025)**
- 35 of 40 tools implemented (87.5%) (see `Tool.swift`)
- Phase 9 in progress; cURL → Code and SVG → CSS converters shipped
- 360+ service tests authored
- Release automation workflow ✅ complete

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
**Status**: ✅ IMPLEMENTED (initial)

**Features**:
- Format/prettify JavaScript with customizable indentation (2/4 spaces, tabs)
- Minify JavaScript (removes comments/whitespace while preserving strings)
- Validate syntax basics (balanced braces/brackets/parentheses, string closure)
- Syntax highlighting for output pane
- Roadmap: TypeScript conversion helpers and ES6+ linting (future)

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
**Status**: ✅ IMPLEMENTED

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
**Status**: ✅ IMPLEMENTED

**Features**:
- URL encode/decode
- Component encoding (encode only query params)
- Full URL parsing (protocol, host, path, query, fragment)
- Query parameter extraction and formatting
- Validation

---

#### 3.9 HTML Entity Encoder/Decoder
**Status**: ✅ IMPLEMENTED

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
**Status**: ✅ IMPLEMENTED

**Features**:
- Escape special characters (`\n`, `\t`, `\"`, etc.)
- Unescape escaped strings
- Language-specific escaping (JSON, JavaScript, C, Python, etc.)
- Unicode escape sequences

---

### Category: Converters

#### 3.12 JSON ↔ YAML Converter
**Status**: ✅ Implemented

**Features**:
- Bidirectional conversion
- Syntax validation for both formats
- Pretty formatting
- Keyboard shortcuts (⌘Return convert, ⌘K clear)

---

#### 3.13 JSON ↔ CSV Converter
**Status**: ✅ Implemented

**Features**:
- JSON array to CSV table
- CSV to JSON array
- Custom delimiter support (comma, semicolon, tab)
- Automatic header generation from JSON keys
- Keyboard shortcuts (⌘Return convert, ⌘K clear)

---

#### 3.14 Number Base Converter
**Status**: ✅ Implemented

**Features**:
- Convert between bases: Binary, Octal, Decimal, Hexadecimal
- Live conversion as you type (press Return in any field)
- Support for signed/unsigned integers (64-bit)
- 64-bit representation view
- Byte representation (8 bytes)
- Two's complement for negative numbers
- Copy individual values or all results
- Keyboard shortcuts (⌘K clear, ⌘⇧C copy all)

---

#### 3.15 Color Converter
**Status**: ✅ Implemented

**Features**:
- Convert between formats:
  - HEX (#RRGGBB)
  - RGB (rgb(r, g, b))
  - HSL (hsl(h, s%, l%))
  - HSV/HSB
  - CMYK
- Color picker integration
- Live preview swatch
- Copy individual formats or all
- Keyboard shortcuts (⌘K clear)

---

#### 3.16 Unix Timestamp Converter
**Status**: ✅ Implemented

**Features**:
- Unix timestamp (seconds) ↔ Human-readable date
- Millisecond timestamp support (auto-detects)
- Current timestamp button
- Timezone selection (10 common timezones)
- Multiple date format outputs (ISO 8601, RFC 2822, Full, Long, Medium, Short, Custom)
- Relative time display ("2 hours ago", "in 3 days")
- Keyboard shortcuts (⌘K clear)

---

#### 3.17 Case Converter
**Status**: ✅ Implemented

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
  - CONSTANT_CASE (SCREAMING_SNAKE_CASE)
- Displays all variants simultaneously
- Copy individual cases or all at once
- Keyboard shortcuts (⌘K clear, ⌘⇧C copy all)

---

#### 3.18 Markdown ↔ HTML Converter
**Status**: ✅ Implemented

**Features**:
- Markdown to HTML conversion
- HTML to Markdown conversion
- Supports headers, bold, italic, code, links
- Mode toggle for bidirectional conversion
- Keyboard shortcuts (⌘Return convert, ⌘K clear)

---

#### 3.19 cURL to Code Converter
**Status**: ✅ IMPLEMENTED

**Features**:
- Parse cURL command (supports -X, -H, -d, -F, -u, -G flags)
- Generate equivalent code in:
  - Swift (URLSession)
  - Python (requests)
  - JavaScript (fetch)
  - Go (net/http)
  - PHP (cURL)
  - Ruby (Net::HTTP)
- Copy to clipboard
- Auto-convert when changing target language
- Comprehensive error handling

---

#### 3.20 SVG to CSS Converter
**Status**: ✅ IMPLEMENTED

**Features**:
- Convert SVG to data URI for CSS background ✅
- Optimize SVG (remove metadata, minimize) ✅
- Preview SVG ✅
- Generate CSS code for multiple formats (background-image, mask-image, etc.) ✅
- File size calculation ✅
- Dimension extraction ✅

---

### Category: Generators

#### 3.21 UUID/ULID Generator
**Status**: ✅ IMPLEMENTED

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
**Status**: ✅ IMPLEMENTED

**Features**:
- Generate placeholder text
- Options: paragraphs, sentences, words
- Quantity selector (1-100)
- "Lorem ipsum" or random words
- Copy to clipboard

---

#### 3.24 QR Code Generator
**Status**: ✅ IMPLEMENTED

**Features**:
- Generate QR codes from text/URLs
- Error correction levels (L, M, Q, H)
- Size customization
- Color customization (foreground/background)
- Export as PNG, SVG, PDF
- QR code scanner (camera/image file)

---

#### 3.25 Random String Generator
**Status**: ✅ IMPLEMENTED

**Features**:
- Generate random strings
- Character sets: lowercase, uppercase, numbers, symbols
- Custom length (1-1000)
- Bulk generation (1-100)
- Avoid ambiguous characters option (0/O, 1/l/I)
- Cryptographically secure randomness (SecRandomCopyBytes)
- Individual copy buttons for each string

---

### Category: Inspectors & Debuggers

#### 3.26 RegExp Tester
**Status**: ✅ IMPLEMENTED

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
**Status**: ✅ IMPLEMENTED

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
**Status**: ✅ IMPLEMENTED

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
**Status**: ✅ IMPLEMENTED

**Features**:
- Parse cron expressions
- Human-readable description
- Next 10 execution times
- Timezone support (10 common timezones)
- Validate syntax
- Field breakdown display

---

#### 3.30 Certificate Inspector (X.509)
**Status**: 🔲 Planned

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
**Status**: ✅ IMPLEMENTED

**Features**:
- Test JSONPath expressions
- Syntax highlighting for results
- Result preview with match count
- Support JSONPath syntax ($.property, [index], [*], ..recursive)
- Live evaluation

---

### Category: Text Utilities

#### 3.32 Line Sorter
**Status**: ✅ IMPLEMENTED

**Features**:
- Sort lines alphabetically
- Ascending/descending
- Case-sensitive/insensitive
- Natural sort (handle numbers correctly)
- Reverse order
- Shuffle lines

---

#### 3.33 Line Deduplicator
**Status**: ✅ IMPLEMENTED

**Features**:
- Remove duplicate lines
- Keep first or last occurrence
- Case-sensitive/insensitive
- Sort after deduplication (optional)
- Show duplicate count

---

#### 3.34 Text Replacer
**Status**: ✅ IMPLEMENTED

**Features**:
- Find and replace
- Regex support
- Case-sensitive/insensitive
- Whole word matching
- Replace all or one at a time
- Live match count preview

---

#### 3.35 URL Parser
**Status**: ✅ IMPLEMENTED

**Features**:
- Parse URL components:
  - Protocol/scheme
  - Host/domain
  - Port
  - Path
  - Query parameters (as table)
  - Fragment
  - User/password (if present)
- Validation
- Clean display of parsed components

---

### Additional Tools (Optional/Phase 2)

#### 3.36 IP Address Tools
**Status**: 🔲 Planned
- IP to binary/hex conversion
- CIDR calculator
- Subnet calculator
- IP validation (IPv4/IPv6)

#### 3.37 Base32 Encoder/Decoder
**Status**: ✅ IMPLEMENTED

**Features**:
- Standard Base32 (RFC 4648)
- Base32 Hex variant
- Encode/decode text
- Live conversion
- Error handling

#### 3.38 ASCII Art Generator
**Status**: 🔲 Planned
- Text to ASCII art
- Font selection

#### 3.39 Bcrypt Generator/Verifier
**Status**: 🔲 Planned
- Hash passwords with bcrypt
- Verify bcrypt hashes
- Cost factor adjustment

#### 3.40 TOTP Generator
**Status**: 🔲 Planned
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

#### Appearance
- Theme preference (Light, Dark, Auto)
- Code block font family
- Code block font size
- Syntax highlighting color scheme
- Sidebar icon size

#### Behavior
- Last used tool
- Default tool on launch
- Window size and position
- Pane split ratios
- Auto-clear input on tool switch
- Confirm before clearing large inputs

#### Clipboard
- Smart detection enabled/disabled
- Show banner notifications
- Auto-switch to suggested tool
- Clipboard check interval

#### Formats & Defaults
- Default Base64 variant
- Default hash algorithm
- Default UUID version
- Default QR error correction level
- Line break style preference

#### History
- Favorite/pinned tools
- Recent tools list
- History enabled/disabled
- History retention period
- Max history items per tool

#### Advanced
- Max file size for processing
- Debug logging enabled
- Performance settings

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

### Phase 2: Core Tools ✅ COMPLETE (Weeks 3-6)
- ✅ Base64 Encoder/Decoder
- ✅ URL Encoder/Decoder
- ✅ Hash Generator (MD5, SHA1, SHA256, SHA384, SHA512, HMAC)
- ✅ UUID/ULID Generator (v1, v4, v5, ULID with bulk generation)
- ✅ QR Code Generator (with scanning, custom colors, error correction)
- ✅ Smart Clipboard Detection Service
  - ✅ Background clipboard monitoring
  - ✅ Pattern detection (JSON, Base64, JWT, URLs, UUID, ULID, Hash, XML)
  - ✅ Auto-suggestion in sidebar
  - ✅ Privacy-respecting implementation
- ✅ JSON Formatter (enhance existing) - moved to Phase 4 and COMPLETED
- ✅ Text Diff - moved to Phase 4 and COMPLETED

### Phase 3: Converters (Weeks 7-9) ✅ COMPLETE
- ✅ Number Base Converter (Binary, Octal, Decimal, Hex with 64-bit support)
- ✅ Unix Timestamp Converter (seconds/milliseconds, multiple formats, timezones)
- ✅ Case Converter (9 case types with live preview)
- ✅ Color Converter (HEX, RGB, HSL, HSV, CMYK with color picker)
- ✅ JSON ↔ YAML (bidirectional conversion with validation)
- ✅ JSON ↔ CSV (array conversion with custom delimiters)
- ✅ Markdown ↔ HTML (bidirectional with formatting support)

### Phase 4: Advanced Tools (Weeks 10-12) ✅ COMPLETE
- ✅ JSON Formatter (format, minify, validate with indentation options)
- ✅ RegExp Tester (match highlighting, capture groups, common patterns)
- ✅ Text Diff (side-by-side comparison with line-by-line highlighting)
- ✅ XML Formatter (format, minify, validate with XML parser)
- ✅ HTML Formatter (format, minify with intelligent tag handling)
- ✅ CSS Formatter (format, minify, validate with property sorting)
- ✅ SQL Formatter (format, minify, validate with keyword uppercasing)

**Additional Phase 4 Tools (Future)**:
- ⬜ cURL to Code Converter
- ⬜ Certificate Inspector
- ⬜ JWT Debugger Enhancement

### Phase 5: Polish & Smart Features ✅ COMPLETE (Weeks 13-14)
- ✅ Smart clipboard detection (COMPLETE)
- ✅ History and favorites
  - ✅ Recent tools list (tracks last 10 tools)
  - ✅ Favorite/pin tools to top of sidebar (with star indicators)
  - ✅ Recent conversions per tool (with retention settings)
  - ✅ Clear history option
- ✅ Export/import functionality
  - ✅ Export tool outputs to files (FileExportImport utility)
  - ✅ Import from files (with file type filtering)
  - ✅ Text and binary data support
- ✅ **Preferences Panel** (⌘,)
  - ✅ **Appearance**
    - ✅ Theme selection (Light, Dark, Auto)
    - ✅ Code block font family selection
      - SF Mono (default)
      - Menlo
      - Monaco
      - Courier New
    - ✅ Code block font size (10-24pt with live preview)
    - ✅ Syntax highlighting color scheme
    - ✅ Sidebar icon size (Small, Medium, Large)
  - ✅ **Behavior**
    - ✅ Default tool on launch (last used or specific tool)
    - ✅ Auto-clear input on tool switch (toggle)
    - ✅ Confirm before clearing large inputs (toggle)
    - ✅ Remember window size and position (toggle)
    - ✅ Remember split pane ratios (toggle)
  - ✅ **Clipboard**
    - ✅ Enable/disable clipboard monitoring
    - ✅ Show banner notifications (toggle)
    - ✅ Auto-switch to suggested tool (toggle)
    - ✅ Clipboard check interval (0.5s - 5s slider)
  - ✅ **Formats & Defaults**
    - ✅ Default Base64 variant (Standard/URL-safe)
    - ✅ Default hash algorithm (MD5/SHA-1/SHA-256/SHA-384/SHA-512)
    - ✅ Default UUID version (v1/v4/v5/ULID)
    - ✅ Default error correction level for QR codes (L/M/Q/H)
    - ✅ Line break style (LF, CRLF, CR)
  - ✅ **History**
    - ✅ Enable/disable history (toggle)
    - ✅ History retention period (1 day to Forever)
    - ✅ Max history items per tool (10-100 slider)
    - ✅ Clear all history button (with confirmation)
  - ✅ **Advanced**
    - ✅ Max file size for processing (1MB-100MB slider)
    - ✅ Enable debug logging (toggle)
    - ✅ Reset all preferences button (with confirmation)
- ✅ **App Icon & Branding**
  - ✅ App icon specification document (APP_ICON_SPEC.md)
  - ✅ Design guidelines and requirements
  - ✅ Technical requirements for all sizes
  - ⬜ Custom icon design (future enhancement)
- ✅ Performance optimization
  - ✅ Lazy loading of tool views (LazyToolView wrapper)
  - ✅ Optimized view switching with .id() modifier
  - ✅ Efficient state management with @MainActor
- ✅ Bug fixes and refinement
  - ✅ Sidebar with favorites and recent sections
  - ✅ Context menu for favoriting tools
  - ✅ Comprehensive preference persistence

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

## CI/CD & Release Automation

- **Trigger**: GitHub Action workflow runs on pushes of semantic version tags (`v*`).
- **Build**: Use Xcode’s command-line tools to archive the macOS app (universal build).
- **Tests**: Execute `xcodebuild test -scheme PetruUtils` before packaging.
- **Artifacts**: Produce a signed/notarized `.app` plus `.dmg`/`.zip` and attach to the GitHub Release tied to the tag.
- **Versioning**: Update `Info.plist` version/build numbers from the tag inside the workflow.
- **Notifications**: Mark the release as “Latest” and include changelog notes derived from the tag.

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

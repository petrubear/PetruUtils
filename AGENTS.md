# PetruUtils - AI Agent Guide

## Project Overview

**PetruUtils** is a native macOS developer toolbox application built with SwiftUI. It provides 40+ utilities for developers (all 40 implemented) with a focus on privacy, offline operation, and native performance.

**Current Status**: v1.0 Release Ready (All phases complete, 40/40 tools implemented = 100%)

---

## Quick Start for AI Agents

### Understanding the Project

1. **Read these files first** (in order):
   - `README.md` - Project overview and current status
   - `AGENTS.md` - This file (development guidelines)

2. **Architecture Pattern**: MVVM with Service Layer

   ```
   View (SwiftUI) → ViewModel (@MainActor) → Service (Business Logic) → Foundation APIs
   ```

3. **Tech Stack**:
   - Language: Swift 5.9+
   - Framework: SwiftUI + Combine
   - Platform: macOS 13.0+
   - Testing: Swift Testing framework
   - No external dependencies (only Apple frameworks)

---

## Project Structure

```
PetruUtils/
├── PetruUtils/                    # Main app target
│   ├── PetruUtilsApp.swift       # App entry point
│   ├── Tool.swift                 # Tool enum (add new tools here)
│   ├── ContentView.swift          # Main navigation with sidebar
│   ├── Services/                  # Business logic (testable)
│   │   ├── ToolRegistry.swift     # Dynamic tool view registration
│   │   ├── JWTService.swift
│   │   ├── Base64Service.swift
│   │   ├── URLService.swift
│   │   ├── HashService.swift
│   │   ├── UUIDService.swift
│   │   ├── QRCodeService.swift
│   │   ├── PreferencesManager.swift
│   │   ├── HistoryManager.swift
│   │   └── ClipboardMonitor.swift
│   ├── Views/                     # SwiftUI views
│   │   ├── JWTView.swift
│   │   ├── Base64View.swift
│   │   ├── URLView.swift
│   │   ├── HashView.swift
│   │   ├── UUIDView.swift
│   │   ├── QRCodeView.swift
│   │   ├── PreferencesView.swift
│   │   └── Components/            # Reusable components
│   │       ├── GenericTextToolView.swift  # Reusable tool view layout
│   │       ├── CodeBlockView.swift
│   │       ├── FocusableTextEditor.swift
│   │       └── SyntaxHighlightedText.swift
│   └── Utilities/
│       ├── TextToolProtocols.swift  # Protocols for generic tool ViewModels
│       ├── FileExportImport.swift
│       └── Extensions/
│           └── Font+Extensions.swift
├── PetruUtilsTests/               # Unit tests
│   ├── JWTServiceTests.swift      (40+ tests)
│   ├── Base64ServiceTests.swift   (25+ tests)
│   ├── URLServiceTests.swift      (30+ tests)
│   ├── HashServiceTests.swift     (30+ tests)
│   ├── UUIDServiceTests.swift     (35+ tests)
│   ├── QRCodeServiceTests.swift   (25+ tests)
│   ├── HistoryManagerTests.swift  (8 tests)
│   └── ClipboardMonitorTests.swift (35+ tests)
└── PetruUtilsUITests/             # UI tests (currently disabled)
```

---

## How to Add a New Tool

### Step-by-Step Process

#### 1. **Add Tool to Enum** (`Tool.swift`)

```swift
enum Tool: String, CaseIterable, Identifiable {
    // ... existing tools
    case newTool

    var title: String {
        case .newTool: return "New Tool Name"
    }

    var iconName: String {
        case .newTool: return "sf.symbol.name"
    }
}
```

#### 2. **Create Service** (`Services/NewToolService.swift`)

```swift
import Foundation

struct NewToolService {
    enum NewToolError: LocalizedError {
        case someError
        var errorDescription: String? { /* ... */ }
    }

    func doSomething(_ input: String) throws -> String {
        // Business logic here
    }
}
```

**Service Guidelines**:

- Pure Swift struct (no SwiftUI dependencies)
- Throwing functions for errors
- Well-documented public methods
- Fully testable in isolation

#### 3. **Create Tests** (`Tests/NewToolServiceTests.swift`)

```swift
import Testing
import Foundation
@testable import PetruUtils

@Suite("New Tool Service Tests")
struct NewToolServiceTests {
    let service = NewToolService()

    @Test("Test basic functionality")
    func testBasic() throws {
        let result = try service.doSomething("input")
        #expect(result == "expected")
    }

    // Add strictly necessary unit tests to cover the core functionality of the service:
    // - Happy path
    // - Error cases
    // - Edge cases
    // - Unicode/special characters
}
```

**Testing Standards**:

- Use Swift Testing framework (`@Test`, `#expect`)
- Test only the core functionality of the service
- Test edge cases, errors, and Unicode
- All tests must pass before committing

#### 4. **Create View** (`Views/NewToolView.swift`)

**Use GenericTextToolView if applicable** (standard text input -> output flow):

```swift
import SwiftUI
import Combine

struct NewToolView: View {
    @StateObject private var vm = NewToolViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "New Tool",
            inputTitle: "Input",
            outputTitle: "Output",
            inputIcon: "icon.name",
            outputIcon: "icon.name",
            toolbarContent: {
                Button("Action") { vm.process() }
            },
            configContent: {
                // Optional configuration UI
            },
            helpContent: {
                // Optional help text
            }
        )
    }
}

@MainActor
final class NewToolViewModel: TextToolViewModel {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let service = NewToolService()
    
    func process() {
        // Logic
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
}
```

**Or standard custom view**:

```swift
import SwiftUI
import Combine

struct NewToolView: View {
    @StateObject private var vm = NewToolViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                inputPane
                outputPane
            }
        }
    }

    // Standard layout patterns...
}
```

**View Guidelines**:

- **Prefer `GenericTextToolView`** for standard text processing tools to reduce code duplication.
- Use `HSplitView` for custom layouts requiring resizeable panes.
- Include keyboard shortcuts (⌘Return, ⌘K, ⌘⇧C)
- Show character counts
- Display errors prominently
- Add tooltips and help text
- **CRITICAL**: ALL code output MUST use `SyntaxHighlightedText` with appropriate language
  - JSON → `.json`
  - XML → `.xml`
  - HTML → `.html`
  - CSS → `.css`
  - SQL → `.sql`
  - Plain text → `.plain`
  - NEVER use plain `Text()` or `CodeBlock()` for code output

#### 5. **Register Tool** (`Services/ToolRegistry.swift`)

```swift
// In ToolRegistry.swift registerAllTools()
register(.newTool) { AnyView(NewToolView()) }
```

The `ContentView.swift` uses `ToolRegistry` to dynamically load views, so you no longer need to edit `ContentView.swift`.

#### 6. **Update Documentation**

- Add tool to `README.md` "Implemented Tools" section
- Update test count
- Update percentage complete

---

## Coding Standards

### Swift Style

- Follow Apple's Swift API Design Guidelines
- Use SwiftUI best practices
- Prefer value types (struct) over reference types (class)
- Use `@MainActor` for ViewModels
- Explicit error handling with `throws`

### Naming Conventions

- Services: `[Tool]Service.swift`
- Views: `[Tool]View.swift`
- Tests: `[Tool]ServiceTests.swift`
- ViewModels: `[Tool]ViewModel` (inside view file)

### Architecture Rules

1. **Services** = Pure business logic, no UI dependencies
2. **ViewModels** = UI state management, calls services
3. **Views** = SwiftUI presentation only
4. **Never** mix business logic in views
5. **Always** create tests for services

### Common Patterns

#### Error Handling

```swift
enum MyError: LocalizedError {
    case invalidInput
    var errorDescription: String? {
        "User-friendly message"
    }
}
```

#### Color Conversion (for image generation)

```swift
// Only use system colors to avoid hanging
if color == .black { return .black }
if color == .white { return .white }
// ... etc
return .black // fallback
```

#### Keyboard Shortcuts

```swift
.keyboardShortcut(.return, modifiers: [.command])  // ⌘Return
.keyboardShortcut("k", modifiers: [.command])      // ⌘K
.keyboardShortcut("c", modifiers: [.command, .shift]) // ⌘⇧C
```

#### Syntax Highlighting (CRITICAL)

```swift
// ALWAYS use SyntaxHighlightedText for code output
ScrollView {
    SyntaxHighlightedText(text: vm.output, language: .json)  // or .xml, .html, .css, .sql, .plain
        .padding(8)
}
.overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

// NEVER use:
// Text(vm.output)  ❌ WRONG
// CodeBlock(text: vm.output)  ❌ DEPRECATED for formatters
```

---

## Development Workflow

### Before Starting Work

1. Read relevant documentation
2. Check `README.md` for tool specifications
3. Look at similar existing tools for patterns
4. Run tests to ensure baseline: `xcodebuild test -scheme PetruUtils`

### Development Process

1. Create service with business logic
2. Write only the most important test to validate functionality, dont test simple stuff and dont create unnecesary tests
3. Create view following existing patterns (or reuse GenericTextToolView)
4. Integrate into `Tool.swift` and `Services/ToolRegistry.swift`
5. Run all tests: ensure 100% pass rate
6. Build and manually test the UI
7. Update documentation

### Testing Commands

```bash
# Build only
xcodebuild build -scheme PetruUtils -destination 'platform=macOS'

# Run all tests
xcodebuild test -scheme PetruUtils -destination 'platform=macOS'

# Run specific test suite
xcodebuild test -scheme PetruUtils -destination 'platform=macOS' \
  -only-testing:PetruUtilsTests/NewToolServiceTests

# Check for build errors
xcodebuild build -scheme PetruUtils 2>&1 | grep error:
```

### Quality Checklist

- [ ] Service has no SwiftUI dependencies
- [ ] Unit tests written and passing
- [ ] View follows split-pane pattern
- [ ] Keyboard shortcuts implemented
- [ ] Error messages are user-friendly
- [ ] Character counts shown
- [ ] Copy functionality works
- [ ] **Code output uses SyntaxHighlightedText with correct language**
- [ ] **All monospace text elements should use 'Jetbrains Mono' font included in the App**
- [ ] Tool added to enum and ToolRegistry
- [ ] Documentation updated
- [ ] No compiler warnings

---

## Current Phase Status

### ✅ Phase 1: Foundation (Complete)

- Architecture and navigation
- Common components
- JWT Debugger

### ✅ Phase 2: Core Tools (Complete)

- Base64 Encoder/Decoder
- URL Encoder/Decoder
- Hash Generator (5 algorithms + HMAC)
- UUID/ULID Generator
- QR Code Generator
- Smart Clipboard Detection

### ✅ Phase 3: Converters (Complete - 7/7 tools)

- Number Base Converter
- Unix Timestamp Converter
- Case Converter
- Color Converter
- JSON ↔ YAML
- JSON ↔ CSV
- Markdown ↔ HTML

### ✅ Phase 4: Advanced Tools (Complete)

- RegExp Tester
- Text Diff/Compare
- XML Formatter
- HTML Formatter
- CSS Formatter (with SCSS/LESS conversion + vendor prefixing)
- SQL Formatter
- JSON Formatter (with tree view, JSONPath breadcrumbs, line numbers)
- JavaScript Formatter

### ✅ Phase 5: Polish & Preferences (Complete)

- Preferences panel with 6 categories
- App icon specification
- History & favorites
- Performance optimization
- Clipboard auto-switch wiring
- GitHub Action release workflow

### ✅ Phase 6: Text Utilities (Complete)

- Line Sorter
- Line Deduplicator
- Text Replacer
- String Inspector

### ✅ Phase 7: Encoders & Generators (Complete)

- HTML Entity Encoder/Decoder
- Lorem Ipsum Generator

### ✅ Phase 8: Inspectors & Generators (Complete)

- URL Parser
- Random String Generator
- Backslash Escape/Unescape
- Base32 Encoder/Decoder
- Cron Expression Parser
- JSON Path Tester

### ✅ Phase 9: Remaining Utilities (Complete)

- JavaScript Formatter ✅
- cURL → Code Converter ✅
- SVG → CSS Converter ✅
- Certificate Inspector (X.509) ✅
- IP Utilities (CIDR/subnet calculator, subnet math) ✅
- ASCII Art Generator ✅
- Bcrypt Generator/Verifier ✅
- TOTP Generator ✅

### ✅ Phase 10: Enhancements & Hardening (Complete)

- JSON Formatter tree view, JSONPath breadcrumbs, line numbers, validation improvements
- CSS Formatter SCSS/LESS conversion & vendor auto-prefixing
- JWT Debugger RSA/ECDSA/PS algorithm support with public-key inputs and claim validation indicators

### ✅ Phase 11: Release Automation (Complete)

- GitHub Action workflow to build/test the macOS app and attach artifacts when a version tag is pushed
- Code signing and notarization guide provided in `SIGNING_NOTARIZATION.md`

---

## Known Issues & Gotchas

### Color Conversion

**Problem**: SwiftUI `Color` to `NSColor` conversion can cause infinite recursion
**Solution**: Use simple system color mapping only (see `QRCodeView.swift` for example)

### Clipboard Monitoring

**Issue**: Some tests fail due to detection being too eager
**Status**: Service works, tests need tuning

### UI Tests

**Status**: Disabled - focus on service-level unit tests only
**Reason**: Faster development, better coverage for business logic

### Import Order

Always import in this order:

```swift
import SwiftUI        // If needed
import Combine        // If using @Published
import Foundation     // Always
// Then specific frameworks (CoreImage, AppKit, etc.)
@testable import PetruUtils  // Tests only
```

---

## Testing Philosophy

### What to Test

✅ All service business logic
✅ Error conditions
✅ Edge cases (empty, very long, Unicode)
✅ Roundtrip operations (encode → decode → verify)
✅ Known test vectors
✅ Boundary conditions

### What NOT to Test

❌ SwiftUI view rendering (too brittle)
❌ Trivial getters/setters
❌ Third-party framework behavior

### Test Quality Standards

- Use descriptive test names: `@Test("Decode Base64 with special characters")`
- Test one thing per test
- Use known test vectors where applicable
- Cover both happy and sad paths
- Include Unicode and special character tests

---

## App Icon Specification

### Design Concept

**Primary Concept**: Developer Toolbox
- Central icon: Wrench + Code Brackets
- Color scheme: Blue/Purple gradient (tech-focused)
- Style: Modern, flat design with subtle depth
- Mood: Professional, trustworthy, developer-friendly

### Required Sizes (macOS)

- 16x16 (@1x, @2x)
- 32x32 (@1x, @2x)
- 128x128 (@1x, @2x)
- 256x256 (@1x, @2x)
- 512x512 (@1x, @2x)
- 1024x1024 (@1x, @2x)

### Color Palette

- **Primary Blue**: `#007AFF` (iOS/macOS system blue)
- **Dark Blue**: `#0051D5`
- **Purple Accent**: `#5856D6`
- **Background**: White or light gray gradient

### Design Guidelines

**Do's**:
- Keep it simple and recognizable at small sizes
- Use clear, bold shapes
- Maintain visual consistency with macOS design language
- Test at all sizes (especially 16x16)

**Don'ts**:
- Don't use too much detail
- Avoid text or small typography
- Don't use more than 3-4 colors
- Avoid photorealistic effects

---

## Preferences System

### Categories

1. **Appearance**: Theme, fonts, icon size
2. **Behavior**: Default tool, auto-clear, window memory
3. **Clipboard**: Monitoring, notifications, intervals
4. **Formats & Defaults**: Base64, hash, UUID, QR, line breaks
5. **History**: Enable/disable, retention, limits
6. **Advanced**: File size limits, debug logging

### Key Files

- `Services/PreferencesManager.swift` - Manages all preferences
- `Services/HistoryManager.swift` - Tracks tool usage, favorites, history
- `Views/PreferencesView.swift` - Preferences UI (⌘,)

---

## Common Tasks Quick Reference

### Add a Tool (Summary)

1. Add to `Tool.swift` enum
2. Create `Services/[Tool]Service.swift`
3. Create `Tests/[Tool]ServiceTests.swift` (strictly necessary unit tests)
4. Create `Views/[Tool]View.swift` (Prefer GenericTextToolView)
5. Register in `Services/ToolRegistry.swift`
6. Update README.md
7. Run tests and verify build

### Fix a Bug

1. Write a failing test that reproduces the bug
2. Fix the issue in the service
3. Verify test passes
4. Check no regressions
5. Update docs if needed

### Add a Preference

1. Add key to PreferencesManager
2. Add UI to PreferencesView
3. Update relevant tools to read preference
4. Test persistence across app restarts

---

## Project Goals

### Core Principles

1. **Privacy First**: All processing happens locally
2. **Offline First**: No network dependencies
3. **Native Performance**: SwiftUI + Apple frameworks only
4. **Developer UX**: Keyboard shortcuts, minimal friction
5. **Test Coverage**: Comprehensive service tests

### Non-Goals

- Cloud sync or online features
- Mobile apps (macOS only for now)
- External dependencies or npm packages
- Backend services or APIs

---

## Project Vision

**End Goal**: A comprehensive, privacy-focused, offline developer toolbox with 40+ utilities that developers use daily. Think "DevUtils" but open and extensible.

**Current Progress**: 100% complete (40 of 40 tools, all phases finished)

**Status**: Ready for v1.0 release.

---

## External References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Testing Guide](https://developer.apple.com/documentation/testing)
- [CryptoKit](https://developer.apple.com/documentation/cryptokit)

### Inspiration

- [DevUtils](https://devutils.com) - Original inspiration for the project

---

_This guide is maintained by the development team and should be updated as the project evolves. Last updated: December 2025_
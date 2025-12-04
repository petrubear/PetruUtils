# PetruUtils - AI Agent Guide

## Project Overview

**PetruUtils** is a native macOS developer toolbox application built with SwiftUI. It provides 40+ utilities for developers (currently 35 implemented) with a focus on privacy, offline operation, and native performance.

**Current Status**: Phase 9 – Remaining Utilities (35/40 tools implemented ≈ 87.5%)

---

## Quick Start for AI Agents

### Understanding the Project

1. **Read these files first** (in order):
   - `README.md` - Project overview and current status
   - `SPEC.md` - Complete technical specification
   - `IMPLEMENTATION_SUMMARY.md` - What's been built
   - `PHASE5_PREFERENCES_PLAN.md` - Detailed Phase 5 plans

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
│   │   ├── JWTService.swift
│   │   ├── Base64Service.swift
│   │   ├── URLService.swift
│   │   ├── HashService.swift
│   │   ├── UUIDService.swift
│   │   ├── QRCodeService.swift
│   │   └── ClipboardMonitor.swift
│   ├── Views/                     # SwiftUI views
│   │   ├── JWTView.swift
│   │   ├── Base64View.swift
│   │   ├── URLView.swift
│   │   ├── HashView.swift
│   │   ├── UUIDView.swift
│   │   ├── QRCodeView.swift
│   │   └── Components/            # Reusable components
│   │       ├── CodeBlockView.swift
│   │       ├── FocusableTextEditor.swift
│   │       └── SyntaxHighlightedText.swift
│   └── Utilities/
│       └── Extensions/
│           └── Font+Extensions.swift
├── PetruUtilsTests/               # Unit tests
│   ├── JWTServiceTests.swift      (40+ tests)
│   ├── Base64ServiceTests.swift   (25+ tests)
│   ├── URLServiceTests.swift      (30+ tests)
│   ├── HashServiceTests.swift     (30+ tests)
│   ├── UUIDServiceTests.swift     (35+ tests)
│   ├── QRCodeServiceTests.swift   (25+ tests)
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

@MainActor
final class NewToolViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?

    private let service = NewToolService()

    func process() {
        // Call service, handle errors
    }
}
```

**View Guidelines**:

- Follow existing split-pane pattern
- Use `HSplitView` for input/output
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

#### 5. **Add to ContentView** (`ContentView.swift`)

```swift
switch selection {
    // ... existing cases
    case .newTool:
        NewToolView()
}
```

#### 6. **Update Documentation**

- Add tool to `README.md` "Implemented Tools" section
- Update test count
- Update percentage complete
- Mark in `SPEC.md` with ✅

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
2. Check `SPEC.md` for tool specifications
3. Look at similar existing tools for patterns
4. Run tests to ensure baseline: `xcodebuild test -scheme PetruUtils`

### Development Process

1. Create service with business logic
2. Write only the most important test to validate functionality, dont test simple stuff and dont create unnecesary tests
3. Create view following existing patterns
4. Integrate into `Tool.swift` and `ContentView.swift`
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
- [ ] Tool added to enum and ContentView
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
- Markdown ↔ HTML (remaining converter work: cURL→Code + SVG→CSS listed in priorities)

### 🔄 Phase 4: Advanced Tools (In Progress)

- RegExp Tester ✅
- Text Diff/Compare ✅
- XML Formatter ✅
- HTML Formatter ✅
- CSS Formatter ✅ (SCSS/LESS conversion + prefixing pending)
- SQL Formatter ✅
- JSON Formatter ✅ (tree view + JSONPath breadcrumbs pending)
- JavaScript Formatter ✅

### ✅ Phase 5: Polish & Preferences

See `PHASE5_SUMMARY.md` for complete details

- Preferences panel with 6 categories ✅
- App icon & branding (spec complete, icon implementation later)
- History & favorites ✅
- Performance optimization ✅
- Clipboard auto-switch wiring ✅
- GitHub Action release workflow ✅

### ✅ Phase 6: Text Utilities

- Line Sorter
- Line Deduplicator
- Text Replacer
- String Inspector

### ✅ Phase 7: Encoders & Generators

- HTML Entity Encoder/Decoder
- Lorem Ipsum Generator

### ✅ Phase 8: Inspectors & Generators

- URL Parser
- Random String Generator
- Backslash Escape/Unescape
- Base32 Encoder/Decoder
- Cron Expression Parser
- JSON Path Tester

### 🔲 Phase 9: Remaining Utilities

- JavaScript Formatter ✅
- cURL → Code Converter ✅
- SVG → CSS Converter ✅
- Certificate Inspector (X.509)
- IP Utilities (CIDR/subnet calculator, subnet math)
- ASCII Art Generator
- Bcrypt Generator/Verifier
- TOTP Generator

### 🔲 Phase 10: Enhancements & Hardening

- JSON Formatter tree view, JSONPath breadcrumbs, line numbers, validation improvements
- CSS Formatter SCSS/LESS conversion & vendor auto-prefixing
- JWT Debugger RSA/ECDSA/PS algorithm support with public-key inputs and claim validation indicators

### ✅ Phase 11: Release Automation

- GitHub Action workflow to build/test the macOS app and attach artifacts when a version tag is pushed ✅
- Code signing and notarization guide provided in `SIGNING_NOTARIZATION.md` (implementation optional)

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

## Documentation Updates

### Always Update These Files

1. **README.md** - Add to "Implemented Tools", update test count
2. **SPEC.md** - Mark tool as ✅ in appropriate phase
3. **IMPLEMENTATION_SUMMARY.md** - If adding major features

### Version Control

- Phase completion should update all docs
- Keep README.md "Test Status" current
- Update "Last Updated" dates

---

## Common Tasks Quick Reference

### Add a Tool (Summary)

1. Add to `Tool.swift` enum
2. Create `Services/[Tool]Service.swift`
3. Create `Tests/[Tool]ServiceTests.swift` (strictly necessary unit tests)
4. Create `Views/[Tool]View.swift`
5. Add case to `ContentView.swift` switch
6. Update README.md and SPEC.md
7. Run tests and verify build

### Fix a Bug

1. Write a failing test that reproduces the bug
2. Fix the issue in the service
3. Verify test passes
4. Check no regressions
5. Update docs if needed

### Add a Preference

1. Check `PHASE5_PREFERENCES_PLAN.md` for spec
2. Add key to PreferencesManager (when created)
3. Add UI to PreferencesView
4. Update relevant tools to read preference
5. Test persistence across app restarts

---

## Resources

### Project Documentation

- [SPEC.md](SPEC.md) - Complete specification
- [README.md](README.md) - Overview and status
- [PHASE5_PREFERENCES_PLAN.md](PHASE5_PREFERENCES_PLAN.md) - Preferences details
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - What's built

### External References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Testing Guide](https://developer.apple.com/documentation/testing)
- [CryptoKit](https://developer.apple.com/documentation/cryptokit)

### Inspiration

- [DevUtils](https://devutils.com) - Original inspiration for the project

---

## Communication Protocol

### When Starting Work

1. Announce which tool/feature you're implementing
2. Check if it's in the current phase priority
3. Read the SPEC.md section for that tool

### During Development

1. Follow the checklist above
2. Run tests frequently
3. Keep code consistent with existing patterns

### When Completing Work

1. Run full test suite
2. Update all relevant documentation
3. Verify build succeeds
4. Report test count and pass rate
5. Note any issues or deviations from spec

---

## Success Metrics

### For Each Tool

- ✅ Unit tests passing
- ✅ No compiler warnings
- ✅ Follows existing UI patterns
- ✅ Documentation updated
- ✅ Build succeeds

### For Each Phase

- ✅ All planned tools implemented
- ✅ All tests passing (100%)
- ✅ No known bugs
- ✅ Documentation complete
- ✅ Ready for next phase

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

## Getting Help

### Understanding the Project

1. Start with README.md for overview
2. Check SPEC.md for detailed requirements
3. Look at similar existing tools for patterns
4. Review test files to understand expected behavior

### Implementation Questions

1. Check PHASE5_PREFERENCES_PLAN.md for preferences
2. Look at Service files for business logic patterns
3. Review View files for UI patterns
4. Check existing tests for testing patterns

---

## Project Vision

**End Goal**: A comprehensive, privacy-focused, offline developer toolbox with 40+ utilities that developers use daily. Think "DevUtils" but open and extensible.

**Current Progress**: ~82.5% complete (33 of 40 tools)

**Next Milestone**: Ship remaining converters/advanced utilities (cURL → code, SVG → CSS, Certificate Inspector, etc.) and add release automation.

**Long-term**: Finish Phase 5 polish items (release automation), deliver remaining inspector/generator tools, then continue with preferences/performance refinements.

---

_This guide is maintained by the development team and should be updated as the project evolves. Last updated: November 2025_

---

## Current Priorities (December 2025)

1. **Phase 9 – Remaining Utilities**: Ship cURL → Code converter, SVG → CSS converter, Certificate Inspector, IP utilities, ASCII Art generator, Bcrypt helper, and TOTP generator.
2. **Phase 10 – Enhancements**: Add JSON Formatter tree view/breadcrumbs/line numbers, extend CSS Formatter to SCSS/LESS + auto-prefixing, and implement RSA/ECDSA/PS support in the JWT Debugger with public-key inputs.

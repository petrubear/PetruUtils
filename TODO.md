# Project Recommendations & TODOs

This document outlines recommended improvements for the `PetruUtils` project, focusing on architectural scalability, code quality, and user experience.

## 1. Architecture & Refactoring

### Abstract Common Tool Logic (High Priority)
Currently, most tool views (e.g., `Base64View`, `URLView`, `JSONFormatterView`) duplicate significant UI and logic code.
- [x] **Create `TextToolViewModel` Protocol:** Define a standard interface for text-based tools.
  ```swift
  protocol TextToolViewModel: ObservableObject {
      var input: String { get set }
      var output: String { get }
      var errorMessage: String? { get }
      func process()
      func clear()
  }
  ```
- [x] **Create Generic `TextToolView`:** Build a reusable SwiftUI view that accepts any `TextToolViewModel`. It should handle the standard 2-pane layout (Input/Output), Toolbar, and Error display.
- [x] **Refactor Existing Tools:** Migrate simple text tools (Base64, URL, HTML, etc.) to use this generic view, reducing codebase size by ~40%. (Refactored: Base64, URL, BackslashEscape, Base32, LineSorter, LineDeduplicator, TextReplacer)

### Decouple Tool Registration
The `Tool` enum and `ContentView` are tightly coupled. Adding a new tool requires modifying multiple core files.
- [x] **Create `ToolDefinition` Struct:** (Implemented via ToolRegistry mapping) Define a struct that holds tool metadata (name, icon, category) and a view builder closure.
- [x] **Implement Dependency Injection:** Use a `ToolRegistry` singleton or environment object to manage available tools.
- [x] **Dynamic Loading:** Allow tools to register themselves at startup, removing the giant `switch` statement in `ContentView`.

## 2. Localization & Internationalization

The app currently uses hardcoded strings throughout the UI.
- [x] **Create `Localizable.strings`:** Initialize the localization file at `Resources/en.lproj/Localizable.strings`.
- [x] **Extract Strings:** Replace all hardcoded string literals in Views (Tool.swift, ContentView.swift, GenericTextToolView.swift, PreferencesView.swift) with `String(localized:)`.
- [x] **Localized string keys:** Adopt a naming convention (e.g., `tool.base64.title`, `common.action.process`, `preferences.appearance.theme`).

## 3. User Experience (UX) & UI

### Syntax Highlighting
The current `CodeBlockView` appears basic.
- [x] **Integrate Syntax Highlighter:** Adopt a library (like Highlightr or a lightweight custom solution) to provide real syntax highlighting for JSON, XML, HTML, and SQL outputs. (Implemented custom regex-based highlighter in `CodeBlockView` with theme support)
- [x] **Theme Support:** Allow the syntax highlighter to respect the system appearance (Dark/Light mode). (Implemented in `CodeBlockView`)

### Accessibility
- [x] **Improve Custom Components:** Ensure `FocusableTextEditor` and `FocusableTextField` properly expose accessibility labels and hints to the accessibility engine. (Added `accessibilityLabel`, `accessibilityHint` parameters and `setAccessibilityRole`)
- [x] **Audit Views:** Add `.accessibilityLabel` and `.accessibilityHint` to icon-only buttons and critical UI elements. (Added to ContentView: favorite icon, clipboard icon, dismiss button; GenericTextToolView: error message, valid indicator, empty output placeholder, section headers)

## 4. Testing

### ViewModel Testing
While Services have tests, ViewModels (which contain UI state logic) do not.
- [x] **Add ViewModel Tests:** ~~Create unit tests for `Base64ViewModel`, `URLViewModel`, etc.~~ (Skipped - Services already have comprehensive test coverage)

### UI Tests
- [x] **Smoke Tests:** ~~Add a UI test that iterates through the list of tools and asserts that each one loads its view successfully.~~ (Skipped - Focus on service-level tests per AGENTS.md guidelines)

## 5. Feature Enhancements

- [x] **Command Palette:** Add a "Cmd+K" style command palette to quickly jump between tools without using the sidebar. (Implemented `CommandPaletteView` with keyboard navigation, search filtering, and menu integration via FocusedValues)
- [x] **Drag & Drop:** Support dragging text files onto the Input pane to load their content. (Implemented in `GenericTextToolView` with file type detection, size limits, and encoding fallbacks)
- [x] **History/Recent:** Persist the last used input for each tool so users don't lose work if they accidentally switch tools. (Extended `HistoryManager` with `saveLastInput`/`getLastInput`, added `tool` property to `TextToolViewModel` protocol, auto-save on view disappear and auto-load on appear)

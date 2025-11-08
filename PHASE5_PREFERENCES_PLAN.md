# Phase 5: Preferences & Polish - Implementation Plan

## Overview
Phase 5 focuses on adding comprehensive user preferences, app branding, and final polish to make PetruUtils a production-ready application.

---

## 1. Preferences Panel (⌘,)

### Architecture
- **PreferencesView**: SwiftUI view with TabView for categories
- **PreferencesManager**: ObservableObject to manage UserDefaults
- **PreferenceKeys**: Enum-based keys for type-safe access
- **Location**: Settings → Preferences (⌘,)

### Categories

#### 1.1 Appearance
**Purpose**: Customize visual appearance of the app

- **Theme Selection**
  - Options: Light, Dark, Auto (follow system)
  - Key: `appearance.theme`
  - Default: Auto

- **Code Block Font Family**
  - Options:
    - SF Mono (default, system monospace)
    - Menlo
    - Monaco
    - Fira Code (if installed)
    - JetBrains Mono (if installed)
    - Custom (font picker)
  - Key: `appearance.codeFont`
  - Default: "SF Mono"
  - Implementation: Update Font+Extensions.swift

- **Code Block Font Size**
  - Range: 10-24pt
  - Slider with preview
  - Key: `appearance.codeFontSize`
  - Default: 13pt

- **Syntax Highlighting Color Scheme**
  - Options: Default, GitHub, Dracula, Monokai, Solarized
  - Key: `appearance.syntaxTheme`
  - Default: Default (system appropriate)

- **Sidebar Icon Size**
  - Options: Small, Medium, Large
  - Key: `appearance.sidebarIconSize`
  - Default: Medium

---

#### 1.2 Behavior
**Purpose**: Control app behavior and workflow

- **Default Tool on Launch**
  - Dropdown: Last Used, or specific tool
  - Key: `behavior.defaultTool`
  - Default: Last Used

- **Auto-clear Input on Tool Switch**
  - Toggle: Clear input when switching tools
  - Key: `behavior.autoClearInput`
  - Default: false

- **Confirm Before Clearing Large Inputs**
  - Toggle: Show alert if clearing >1000 characters
  - Key: `behavior.confirmClearLarge`
  - Default: true

- **Remember Window Size and Position**
  - Toggle: Restore window geometry
  - Key: `behavior.rememberWindow`
  - Default: true

- **Remember Split Pane Ratios**
  - Toggle: Restore pane sizes per tool
  - Key: `behavior.rememberPanes`
  - Default: true

---

#### 1.3 Clipboard
**Purpose**: Configure smart clipboard detection

- **Enable Clipboard Monitoring**
  - Toggle: Master switch for clipboard monitoring
  - Key: `clipboard.monitoringEnabled`
  - Default: false (privacy first)

- **Show Banner Notifications**
  - Toggle: Display banner when content detected
  - Key: `clipboard.showBanner`
  - Default: true

- **Auto-switch to Suggested Tool**
  - Toggle: Automatically switch to suggested tool
  - Key: `clipboard.autoSwitch`
  - Default: false

- **Clipboard Check Interval**
  - Slider: 0.5s to 5.0s
  - Key: `clipboard.checkInterval`
  - Default: 0.5s

---

#### 1.4 Formats & Defaults
**Purpose**: Set default formats for tools

- **Default Base64 Variant**
  - Options: Standard, URL-safe
  - Key: `defaults.base64Variant`
  - Default: Standard

- **Default Hash Algorithm**
  - Dropdown: MD5, SHA-1, SHA-256, SHA-384, SHA-512
  - Key: `defaults.hashAlgorithm`
  - Default: SHA-256

- **Default UUID Version**
  - Dropdown: v1, v4, v5, ULID
  - Key: `defaults.uuidVersion`
  - Default: v4

- **Default QR Error Correction**
  - Dropdown: Low, Medium, Quartile, High
  - Key: `defaults.qrErrorCorrection`
  - Default: Medium

- **Line Break Style**
  - Dropdown: LF (Unix), CRLF (Windows), CR (Mac Classic)
  - Key: `defaults.lineBreak`
  - Default: LF

---

#### 1.5 History
**Purpose**: Manage conversion history

- **Enable History**
  - Toggle: Track recent conversions per tool
  - Key: `history.enabled`
  - Default: true

- **History Retention Period**
  - Dropdown: 1 day, 1 week, 1 month, 6 months, 1 year, Forever
  - Key: `history.retentionDays`
  - Default: 30 days

- **Max History Items Per Tool**
  - Slider: 10-100 items
  - Key: `history.maxItems`
  - Default: 50

- **Clear All History**
  - Destructive button with confirmation
  - Action: Delete all stored history

---

#### 1.6 Advanced
**Purpose**: Advanced settings for power users

- **Max File Size for Processing**
  - Slider: 1MB to 100MB
  - Key: `advanced.maxFileSize`
  - Default: 10MB
  - Warning shown when exceeded

- **Enable Debug Logging**
  - Toggle: Log to Console.app for troubleshooting
  - Key: `advanced.debugLogging`
  - Default: false

- **Reset All Preferences**
  - Destructive button with confirmation
  - Action: Reset UserDefaults to defaults
  - Note: Requires app restart

---

## 2. App Icon & Branding

### 2.1 Icon Design Requirements

**Concept Ideas:**
1. **Toolbox Theme**: Modern toolbox with code symbols
2. **Hexagon Grid**: Honeycomb pattern with developer icons
3. **Code Blocks**: Stylized code brackets/braces
4. **Swiss Army Knife**: Multi-tool metaphor
5. **Utilities Symbol**: Wrench + code symbol combination

**Design Specifications:**
- Style: Modern, flat design with subtle gradients
- Color Palette: 
  - Primary: Blue/Teal (tech feel)
  - Secondary: Orange/Purple (energy)
  - Avoid: Too many colors (keep it clean)
- Recognizable at small sizes (16x16)
- Works in both light and dark modes

**Required Sizes (macOS):**
- 16x16 (@1x, @2x)
- 32x32 (@1x, @2x)
- 128x128 (@1x, @2x)
- 256x256 (@1x, @2x)
- 512x512 (@1x, @2x)
- 1024x1024 (@1x, @2x)

**Tools for Creation:**
- Sketch / Figma (design)
- SF Symbols (macOS native icons)
- Icon Set Creator (export tool)
- Xcode Assets Catalog

### 2.2 Implementation Steps

1. **Design Icon**
   - Create vector design in Figma/Sketch
   - Export all required sizes
   - Test visibility at small sizes
   - Get feedback on design

2. **Create Asset Catalog**
   - Add to Assets.xcassets/AppIcon.appiconset
   - Include all required sizes
   - Set proper metadata

3. **Update Info.plist**
   - Set CFBundleIconFile
   - Verify bundle identifier

4. **Optional: Launch Screen**
   - Simple centered logo
   - App name below
   - Smooth transition to main window

---

## 3. History & Favorites

### 3.1 Recent Tools
- Track last 10 tools used
- Show in sidebar or separate section
- Keyboard shortcut to cycle through recent

### 3.2 Favorite Tools
- Star icon next to tool name
- Pinned section at top of sidebar
- Persist in UserDefaults

### 3.3 Conversion History
- Store last N conversions per tool
- Format: Input → Output + Timestamp
- Quick access from tool view
- Privacy: Clear on demand

---

## 4. Export/Import

### 4.1 Export Functionality
- Export current output to file
- Batch export (all generated items)
- Format selection where applicable
- Save location picker

### 4.2 Import Functionality
- Import from file to input
- Drag & drop support
- Automatic format detection

---

## 5. Performance Optimization

### 5.1 Lazy Loading
- Load tool views on demand
- Unload inactive tools from memory
- Preload frequently used tools

### 5.2 Large File Handling
- Streaming for files >1MB
- Progress indicators
- Background processing
- Cancel operation support

### 5.3 Memory Management
- Profile with Instruments
- Fix any detected leaks
- Optimize image loading (QR codes)
- Efficient clipboard monitoring

---

## 6. Bug Fixes & Polish

### 6.1 Known Issues
- [ ] Fix clipboard detection hash detection (too eager)
- [ ] Improve QR code custom color support (full ColorPicker)
- [ ] Handle very long single-line inputs gracefully
- [ ] Optimize JSON parsing for large files

### 6.2 UI Polish
- [ ] Consistent spacing across all tools
- [ ] Smooth animations for tool switching
- [ ] Better error message formatting
- [ ] Tooltips for all buttons
- [ ] Accessibility improvements (VoiceOver)

### 6.3 Testing
- [ ] Full manual testing of all tools
- [ ] Edge case testing
- [ ] Performance testing with large inputs
- [ ] Memory leak detection
- [ ] Accessibility audit

---

## Implementation Priority

### High Priority
1. Preferences Panel basic structure
2. Appearance preferences (font, theme)
3. App Icon design and implementation
4. Clipboard preferences UI
5. Basic history/favorites

### Medium Priority
6. Format defaults
7. Export/import functionality
8. Performance optimization
9. History management

### Low Priority
10. Advanced preferences
11. Debug logging
12. Launch screen
13. Additional polish

---

## Estimated Effort

- Preferences Panel: 3-4 days
- App Icon & Branding: 1-2 days
- History & Favorites: 2-3 days
- Export/Import: 1-2 days
- Performance: 2-3 days
- Bug Fixes & Polish: 2-3 days

**Total: ~2 weeks**

---

## Success Criteria

✅ Users can customize fonts and appearance  
✅ All preferences persist across app launches  
✅ App has professional custom icon  
✅ Clipboard monitoring is configurable  
✅ Default formats can be set per tool  
✅ History is accessible and manageable  
✅ No performance issues with large inputs  
✅ All known bugs are fixed  
✅ UI is polished and consistent  

---

*This document serves as the detailed implementation plan for Phase 5 of PetruUtils development.*

import Foundation
import SwiftUI
import Combine

/// Centralized manager for app preferences using UserDefaults
@MainActor
final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Appearance
    
    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: PreferenceKeys.theme) }
    }
    
    @Published var codeFontFamily: String {
        didSet { defaults.set(codeFontFamily, forKey: PreferenceKeys.codeFontFamily) }
    }
    
    @Published var codeFontSize: Double {
        didSet { defaults.set(codeFontSize, forKey: PreferenceKeys.codeFontSize) }
    }
    
    @Published var syntaxTheme: String {
        didSet { defaults.set(syntaxTheme, forKey: PreferenceKeys.syntaxTheme) }
    }
    
    @Published var sidebarIconSize: IconSize {
        didSet { defaults.set(sidebarIconSize.rawValue, forKey: PreferenceKeys.sidebarIconSize) }
    }
    
    // MARK: - Behavior
    
    @Published var defaultTool: String? {
        didSet { defaults.set(defaultTool, forKey: PreferenceKeys.defaultTool) }
    }
    
    @Published var autoClearInput: Bool {
        didSet { defaults.set(autoClearInput, forKey: PreferenceKeys.autoClearInput) }
    }
    
    @Published var confirmClearLarge: Bool {
        didSet { defaults.set(confirmClearLarge, forKey: PreferenceKeys.confirmClearLarge) }
    }
    
    @Published var rememberWindow: Bool {
        didSet { defaults.set(rememberWindow, forKey: PreferenceKeys.rememberWindow) }
    }
    
    @Published var rememberPanes: Bool {
        didSet { defaults.set(rememberPanes, forKey: PreferenceKeys.rememberPanes) }
    }
    
    // MARK: - Clipboard
    
    @Published var clipboardMonitoringEnabled: Bool {
        didSet { defaults.set(clipboardMonitoringEnabled, forKey: PreferenceKeys.clipboardMonitoringEnabled) }
    }
    
    @Published var clipboardShowBanner: Bool {
        didSet { defaults.set(clipboardShowBanner, forKey: PreferenceKeys.clipboardShowBanner) }
    }
    
    @Published var clipboardAutoSwitch: Bool {
        didSet { defaults.set(clipboardAutoSwitch, forKey: PreferenceKeys.clipboardAutoSwitch) }
    }
    
    @Published var clipboardCheckInterval: Double {
        didSet { defaults.set(clipboardCheckInterval, forKey: PreferenceKeys.clipboardCheckInterval) }
    }
    
    // MARK: - Formats & Defaults
    
    @Published var base64Variant: Base64Variant {
        didSet { defaults.set(base64Variant.rawValue, forKey: PreferenceKeys.base64Variant) }
    }
    
    @Published var defaultHashAlgorithm: String {
        didSet { defaults.set(defaultHashAlgorithm, forKey: PreferenceKeys.defaultHashAlgorithm) }
    }
    
    @Published var defaultUUIDVersion: String {
        didSet { defaults.set(defaultUUIDVersion, forKey: PreferenceKeys.defaultUUIDVersion) }
    }
    
    @Published var defaultQRErrorCorrection: String {
        didSet { defaults.set(defaultQRErrorCorrection, forKey: PreferenceKeys.defaultQRErrorCorrection) }
    }
    
    @Published var lineBreakStyle: LineBreakStyle {
        didSet { defaults.set(lineBreakStyle.rawValue, forKey: PreferenceKeys.lineBreakStyle) }
    }
    
    // MARK: - History
    
    @Published var historyEnabled: Bool {
        didSet { defaults.set(historyEnabled, forKey: PreferenceKeys.historyEnabled) }
    }
    
    @Published var historyRetentionDays: Int {
        didSet { defaults.set(historyRetentionDays, forKey: PreferenceKeys.historyRetentionDays) }
    }
    
    @Published var historyMaxItems: Int {
        didSet { defaults.set(historyMaxItems, forKey: PreferenceKeys.historyMaxItems) }
    }
    
    // MARK: - Advanced
    
    @Published var maxFileSize: Int {
        didSet { defaults.set(maxFileSize, forKey: PreferenceKeys.maxFileSize) }
    }
    
    @Published var debugLogging: Bool {
        didSet { defaults.set(debugLogging, forKey: PreferenceKeys.debugLogging) }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Load appearance
        self.theme = AppTheme(rawValue: defaults.string(forKey: PreferenceKeys.theme) ?? "") ?? .auto
        self.codeFontFamily = defaults.string(forKey: PreferenceKeys.codeFontFamily) ?? "SF Mono"
        self.codeFontSize = defaults.double(forKey: PreferenceKeys.codeFontSize) != 0 
            ? defaults.double(forKey: PreferenceKeys.codeFontSize) : 13.0
        self.syntaxTheme = defaults.string(forKey: PreferenceKeys.syntaxTheme) ?? "default"
        self.sidebarIconSize = IconSize(rawValue: defaults.string(forKey: PreferenceKeys.sidebarIconSize) ?? "") ?? .medium
        
        // Load behavior
        self.defaultTool = defaults.string(forKey: PreferenceKeys.defaultTool)
        self.autoClearInput = defaults.bool(forKey: PreferenceKeys.autoClearInput)
        self.confirmClearLarge = defaults.object(forKey: PreferenceKeys.confirmClearLarge) != nil 
            ? defaults.bool(forKey: PreferenceKeys.confirmClearLarge) : true
        self.rememberWindow = defaults.object(forKey: PreferenceKeys.rememberWindow) != nil 
            ? defaults.bool(forKey: PreferenceKeys.rememberWindow) : true
        self.rememberPanes = defaults.object(forKey: PreferenceKeys.rememberPanes) != nil 
            ? defaults.bool(forKey: PreferenceKeys.rememberPanes) : true
        
        // Load clipboard
        self.clipboardMonitoringEnabled = defaults.bool(forKey: PreferenceKeys.clipboardMonitoringEnabled)
        self.clipboardShowBanner = defaults.object(forKey: PreferenceKeys.clipboardShowBanner) != nil 
            ? defaults.bool(forKey: PreferenceKeys.clipboardShowBanner) : true
        self.clipboardAutoSwitch = defaults.bool(forKey: PreferenceKeys.clipboardAutoSwitch)
        self.clipboardCheckInterval = defaults.double(forKey: PreferenceKeys.clipboardCheckInterval) != 0 
            ? defaults.double(forKey: PreferenceKeys.clipboardCheckInterval) : 0.5
        
        // Load formats & defaults
        self.base64Variant = Base64Variant(rawValue: defaults.string(forKey: PreferenceKeys.base64Variant) ?? "") ?? .standard
        self.defaultHashAlgorithm = defaults.string(forKey: PreferenceKeys.defaultHashAlgorithm) ?? "SHA-256"
        self.defaultUUIDVersion = defaults.string(forKey: PreferenceKeys.defaultUUIDVersion) ?? "v4"
        self.defaultQRErrorCorrection = defaults.string(forKey: PreferenceKeys.defaultQRErrorCorrection) ?? "M"
        self.lineBreakStyle = LineBreakStyle(rawValue: defaults.string(forKey: PreferenceKeys.lineBreakStyle) ?? "") ?? .lf
        
        // Load history
        self.historyEnabled = defaults.object(forKey: PreferenceKeys.historyEnabled) != nil 
            ? defaults.bool(forKey: PreferenceKeys.historyEnabled) : true
        self.historyRetentionDays = defaults.integer(forKey: PreferenceKeys.historyRetentionDays) != 0 
            ? defaults.integer(forKey: PreferenceKeys.historyRetentionDays) : 30
        self.historyMaxItems = defaults.integer(forKey: PreferenceKeys.historyMaxItems) != 0 
            ? defaults.integer(forKey: PreferenceKeys.historyMaxItems) : 50
        
        // Load advanced
        self.maxFileSize = defaults.integer(forKey: PreferenceKeys.maxFileSize) != 0 
            ? defaults.integer(forKey: PreferenceKeys.maxFileSize) : 10
        self.debugLogging = defaults.bool(forKey: PreferenceKeys.debugLogging)
    }
    
    // MARK: - Public Methods
    
    /// Reset all preferences to default values
    func resetToDefaults() {
        theme = .auto
        codeFontFamily = "SF Mono"
        codeFontSize = 13.0
        syntaxTheme = "default"
        sidebarIconSize = .medium
        
        defaultTool = nil
        autoClearInput = false
        confirmClearLarge = true
        rememberWindow = true
        rememberPanes = true
        
        clipboardMonitoringEnabled = false
        clipboardShowBanner = true
        clipboardAutoSwitch = false
        clipboardCheckInterval = 0.5
        
        base64Variant = .standard
        defaultHashAlgorithm = "SHA-256"
        defaultUUIDVersion = "v4"
        defaultQRErrorCorrection = "M"
        lineBreakStyle = .lf
        
        historyEnabled = true
        historyRetentionDays = 30
        historyMaxItems = 50
        
        maxFileSize = 10
        debugLogging = false
    }
    
    /// Clear all history data
    func clearAllHistory() {
        Task { @MainActor in
            HistoryManager.shared.clearAllHistory()
        }
    }
}

// MARK: - Supporting Types

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "Auto (System)"
        }
    }
}

enum IconSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var imageScale: Image.Scale {
        switch self {
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        }
    }
}

enum Base64Variant: String, CaseIterable {
    case standard = "standard"
    case urlSafe = "urlSafe"
    
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .urlSafe: return "URL-Safe"
        }
    }
}

enum LineBreakStyle: String, CaseIterable {
    case lf = "lf"
    case crlf = "crlf"
    case cr = "cr"
    
    var displayName: String {
        switch self {
        case .lf: return "LF (Unix)"
        case .crlf: return "CRLF (Windows)"
        case .cr: return "CR (Mac Classic)"
        }
    }
    
    var characters: String {
        switch self {
        case .lf: return "\n"
        case .crlf: return "\r\n"
        case .cr: return "\r"
        }
    }
}

// MARK: - Preference Keys

private struct PreferenceKeys {
    // Appearance
    static let theme = "appearance.theme"
    static let codeFontFamily = "appearance.codeFont"
    static let codeFontSize = "appearance.codeFontSize"
    static let syntaxTheme = "appearance.syntaxTheme"
    static let sidebarIconSize = "appearance.sidebarIconSize"
    
    // Behavior
    static let defaultTool = "behavior.defaultTool"
    static let autoClearInput = "behavior.autoClearInput"
    static let confirmClearLarge = "behavior.confirmClearLarge"
    static let rememberWindow = "behavior.rememberWindow"
    static let rememberPanes = "behavior.rememberPanes"
    
    // Clipboard
    static let clipboardMonitoringEnabled = "clipboard.monitoringEnabled"
    static let clipboardShowBanner = "clipboard.showBanner"
    static let clipboardAutoSwitch = "clipboard.autoSwitch"
    static let clipboardCheckInterval = "clipboard.checkInterval"
    
    // Formats & Defaults
    static let base64Variant = "defaults.base64Variant"
    static let defaultHashAlgorithm = "defaults.hashAlgorithm"
    static let defaultUUIDVersion = "defaults.uuidVersion"
    static let defaultQRErrorCorrection = "defaults.qrErrorCorrection"
    static let lineBreakStyle = "defaults.lineBreak"
    
    // History
    static let historyEnabled = "history.enabled"
    static let historyRetentionDays = "history.retentionDays"
    static let historyMaxItems = "history.maxItems"
    
    // Advanced
    static let maxFileSize = "advanced.maxFileSize"
    static let debugLogging = "advanced.debugLogging"
}

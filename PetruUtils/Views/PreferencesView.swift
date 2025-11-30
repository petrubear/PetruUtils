import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferences = PreferencesManager.shared
    @State private var selectedTab = 0
    @State private var showResetConfirmation = false
    @State private var showClearHistoryConfirmation = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AppearancePreferencesView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
                .tag(0)
            
            BehaviorPreferencesView()
                .tabItem {
                    Label("Behavior", systemImage: "gearshape")
                }
                .tag(1)
            
            ClipboardPreferencesView()
                .tabItem {
                    Label("Clipboard", systemImage: "doc.on.clipboard")
                }
                .tag(2)
            
            FormatsPreferencesView()
                .tabItem {
                    Label("Formats", systemImage: "doc.text")
                }
                .tag(3)
            
            HistoryPreferencesView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(4)
            
            AdvancedPreferencesView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
                .tag(5)
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Appearance Preferences

struct AppearancePreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $preferences.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            }
            
            Section {
                Picker("Font Family", selection: $preferences.codeFontFamily) {
                    Text("SF Mono").tag("SF Mono")
                    Text("Menlo").tag("Menlo")
                    Text("Monaco").tag("Monaco")
                    Text("Courier New").tag("Courier New")
                }
                
                HStack {
                    Text("Font Size")
                    Slider(value: $preferences.codeFontSize, in: 10...24, step: 1)
                    Text("\(Int(preferences.codeFontSize))pt")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
                
                // Preview
                Text("The quick brown fox jumps over the lazy dog")
                    .font(.custom(preferences.codeFontFamily, size: preferences.codeFontSize))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
            } header: {
                Text("Code Block")
            }
            
            Section {
                Picker("Sidebar Icon Size", selection: $preferences.sidebarIconSize) {
                    ForEach(IconSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Sidebar")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Behavior Preferences

struct BehaviorPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section {
                Picker("Default Tool on Launch", selection: $preferences.defaultTool) {
                    Text("Last Used").tag(nil as String?)
                    Divider()
                    ForEach(Tool.allCases) { tool in
                        Text(tool.title).tag(tool.rawValue as String?)
                    }
                }
            } header: {
                Text("Startup")
            } footer: {
                Text("Choose which tool to show when the app launches")
            }
            
            Section {
                Toggle("Auto-clear Input on Tool Switch", isOn: $preferences.autoClearInput)
                
                Toggle("Confirm Before Clearing Large Inputs", isOn: $preferences.confirmClearLarge)
                
                Toggle("Remember Window Size and Position", isOn: $preferences.rememberWindow)
                
                Toggle("Remember Split Pane Ratios", isOn: $preferences.rememberPanes)
            } header: {
                Text("Workflow")
            } footer: {
                Text("Customize how the app behaves during your workflow")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Clipboard Preferences

struct ClipboardPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Clipboard Monitoring", isOn: $preferences.clipboardMonitoringEnabled)
                    .fontWeight(.medium)
            } header: {
                Text("Monitoring")
            } footer: {
                Text("When enabled, the app will monitor your clipboard and suggest appropriate tools")
            }
            
            Section {
                Toggle("Show Banner Notifications", isOn: $preferences.clipboardShowBanner)
                    .disabled(!preferences.clipboardMonitoringEnabled)
                
                Toggle("Auto-switch to Suggested Tool", isOn: $preferences.clipboardAutoSwitch)
                    .disabled(!preferences.clipboardMonitoringEnabled)
                
                HStack {
                    Text("Check Interval")
                    Slider(value: $preferences.clipboardCheckInterval, in: 0.5...5.0, step: 0.5)
                        .disabled(!preferences.clipboardMonitoringEnabled)
                    Text("\(preferences.clipboardCheckInterval, specifier: "%.1f")s")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Behavior")
            } footer: {
                Text("Configure how clipboard detection behaves")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Formats Preferences

struct FormatsPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    
    var body: some View {
        Form {
            Section {
                Picker("Base64 Variant", selection: $preferences.base64Variant) {
                    ForEach(Base64Variant.allCases, id: \.self) { variant in
                        Text(variant.displayName).tag(variant)
                    }
                }
                
                Picker("Hash Algorithm", selection: $preferences.defaultHashAlgorithm) {
                    Text("MD5").tag("MD5")
                    Text("SHA-1").tag("SHA-1")
                    Text("SHA-256").tag("SHA-256")
                    Text("SHA-384").tag("SHA-384")
                    Text("SHA-512").tag("SHA-512")
                }
                
                Picker("UUID Version", selection: $preferences.defaultUUIDVersion) {
                    Text("UUID v1 (Time-based)").tag("v1")
                    Text("UUID v4 (Random)").tag("v4")
                    Text("UUID v5 (Name-based)").tag("v5")
                    Text("ULID").tag("ULID")
                }
                
                Picker("QR Error Correction", selection: $preferences.defaultQRErrorCorrection) {
                    Text("Low (7%)").tag("L")
                    Text("Medium (15%)").tag("M")
                    Text("Quartile (25%)").tag("Q")
                    Text("High (30%)").tag("H")
                }
                
                Picker("Line Break Style", selection: $preferences.lineBreakStyle) {
                    ForEach(LineBreakStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            } header: {
                Text("Default Formats")
            } footer: {
                Text("These defaults will be used when tools are first opened")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - History Preferences

struct HistoryPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var showClearConfirmation = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable History", isOn: $preferences.historyEnabled)
                    .fontWeight(.medium)
            } header: {
                Text("History Tracking")
            } footer: {
                Text("When enabled, recent conversions will be saved for quick access")
            }
            
            Section {
                Picker("Retention Period", selection: $preferences.historyRetentionDays) {
                    Text("1 day").tag(1)
                    Text("1 week").tag(7)
                    Text("1 month").tag(30)
                    Text("6 months").tag(180)
                    Text("1 year").tag(365)
                    Text("Forever").tag(999999)
                }
                .disabled(!preferences.historyEnabled)
                
                HStack {
                    Text("Max Items Per Tool")
                    Slider(value: Binding(
                        get: { Double(preferences.historyMaxItems) },
                        set: { preferences.historyMaxItems = Int($0) }
                    ), in: 10...100, step: 10)
                        .disabled(!preferences.historyEnabled)
                    Text("\(preferences.historyMaxItems)")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Settings")
            }
            
            Section {
                Button(role: .destructive, action: {
                    showClearConfirmation = true
                }) {
                    Label("Clear All History", systemImage: "trash")
                }
                .disabled(!preferences.historyEnabled)
                .confirmationDialog(
                    "Clear All History?",
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Clear All History", role: .destructive) {
                        preferences.clearAllHistory()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will permanently delete all saved conversion history. This action cannot be undone.")
                }
            } header: {
                Text("Management")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Advanced Preferences

struct AdvancedPreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var showResetConfirmation = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Max File Size")
                    Slider(value: Binding(
                        get: { Double(preferences.maxFileSize) },
                        set: { preferences.maxFileSize = Int($0) }
                    ), in: 1...100, step: 1)
                    Text("\(preferences.maxFileSize) MB")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Enable Debug Logging", isOn: $preferences.debugLogging)
            } header: {
                Text("Performance")
            } footer: {
                Text("Files larger than the maximum size will show a warning before processing")
            }
            
            Section {
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    Label("Reset All Preferences", systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog(
                    "Reset All Preferences?",
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Reset to Defaults", role: .destructive) {
                        preferences.resetToDefaults()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This will reset all preferences to their default values. The app may need to be restarted.")
                }
            } header: {
                Text("Reset")
            } footer: {
                Text("Reset all preferences to their default values")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview


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
                    Label(String(localized: "preferences.tab.appearance"), systemImage: "paintbrush")
                }
                .tag(0)

            BehaviorPreferencesView()
                .tabItem {
                    Label(String(localized: "preferences.tab.behavior"), systemImage: "gearshape")
                }
                .tag(1)

            ClipboardPreferencesView()
                .tabItem {
                    Label(String(localized: "preferences.tab.clipboard"), systemImage: "doc.on.clipboard")
                }
                .tag(2)

            FormatsPreferencesView()
                .tabItem {
                    Label(String(localized: "preferences.tab.formats"), systemImage: "doc.text")
                }
                .tag(3)

            HistoryPreferencesView()
                .tabItem {
                    Label(String(localized: "preferences.tab.history"), systemImage: "clock")
                }
                .tag(4)

            AdvancedPreferencesView()
                .tabItem {
                    Label(String(localized: "preferences.tab.advanced"), systemImage: "wrench.and.screwdriver")
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
                Picker(String(localized: "preferences.appearance.theme"), selection: $preferences.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text(String(localized: "preferences.appearance.title"))
            }

            Section {
                Picker(String(localized: "preferences.appearance.fontFamily"), selection: $preferences.codeFontFamily) {
                    Text(String(localized: "font.sfMono")).tag("SF Mono")
                    Text(String(localized: "font.menlo")).tag("Menlo")
                    Text(String(localized: "font.monaco")).tag("Monaco")
                    Text(String(localized: "font.courierNew")).tag("Courier New")
                }

                HStack {
                    Text(String(localized: "preferences.appearance.fontSize"))
                    Slider(value: $preferences.codeFontSize, in: 10...24, step: 1)
                    Text("\(Int(preferences.codeFontSize))pt")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                // Preview
                Text(String(localized: "preferences.appearance.preview"))
                    .font(.custom(preferences.codeFontFamily, size: preferences.codeFontSize))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .cornerRadius(6)
            } header: {
                Text(String(localized: "preferences.appearance.codeBlock"))
            }

            Section {
                Picker(String(localized: "preferences.appearance.sidebarIconSize"), selection: $preferences.sidebarIconSize) {
                    ForEach(IconSize.allCases, id: \.self) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text(String(localized: "preferences.appearance.sidebar"))
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
                Picker(String(localized: "preferences.behavior.defaultTool"), selection: $preferences.defaultTool) {
                    Text(String(localized: "preferences.behavior.lastUsed")).tag(nil as String?)
                    Divider()
                    ForEach(Tool.allCases) { tool in
                        Text(tool.title).tag(tool.rawValue as String?)
                    }
                }
            } header: {
                Text(String(localized: "preferences.behavior.startup"))
            } footer: {
                Text(String(localized: "preferences.behavior.chooseWhichTool"))
            }

            Section {
                Toggle(String(localized: "preferences.behavior.autoClear"), isOn: $preferences.autoClearInput)

                Toggle(String(localized: "preferences.behavior.confirmClearLarge"), isOn: $preferences.confirmClearLarge)

                Toggle(String(localized: "preferences.behavior.rememberWindow"), isOn: $preferences.rememberWindow)

                Toggle(String(localized: "preferences.behavior.rememberPanes"), isOn: $preferences.rememberPanes)
            } header: {
                Text(String(localized: "preferences.behavior.workflow"))
            } footer: {
                Text(String(localized: "preferences.behavior.customizeWorkflow"))
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
                Toggle(String(localized: "preferences.clipboard.enableMonitoring"), isOn: $preferences.clipboardMonitoringEnabled)
                    .fontWeight(.medium)
            } header: {
                Text(String(localized: "preferences.clipboard.monitoring"))
            } footer: {
                Text(String(localized: "preferences.clipboard.monitoringFooter"))
            }

            Section {
                Toggle(String(localized: "preferences.clipboard.showBanner"), isOn: $preferences.clipboardShowBanner)
                    .disabled(!preferences.clipboardMonitoringEnabled)

                Toggle(String(localized: "preferences.clipboard.autoSwitch"), isOn: $preferences.clipboardAutoSwitch)
                    .disabled(!preferences.clipboardMonitoringEnabled)

                HStack {
                    Text(String(localized: "preferences.clipboard.checkInterval"))
                    Slider(value: $preferences.clipboardCheckInterval, in: 0.5...5.0, step: 0.5)
                        .disabled(!preferences.clipboardMonitoringEnabled)
                    Text("\(preferences.clipboardCheckInterval, specifier: "%.1f")s")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text(String(localized: "preferences.clipboard.behavior"))
            } footer: {
                Text(String(localized: "preferences.clipboard.configureDetection"))
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
                Picker(String(localized: "preferences.formats.base64Variant"), selection: $preferences.base64Variant) {
                    ForEach(Base64Variant.allCases, id: \.self) { variant in
                        Text(variant.displayName).tag(variant)
                    }
                }

                Picker(String(localized: "preferences.formats.hashAlgorithm"), selection: $preferences.defaultHashAlgorithm) {
                    Text(String(localized: "hash.md5")).tag("MD5")
                    Text(String(localized: "hash.sha1")).tag("SHA-1")
                    Text(String(localized: "hash.sha256")).tag("SHA-256")
                    Text(String(localized: "hash.sha384")).tag("SHA-384")
                    Text(String(localized: "hash.sha512")).tag("SHA-512")
                }

                Picker(String(localized: "preferences.formats.uuidVersion"), selection: $preferences.defaultUUIDVersion) {
                    Text(String(localized: "preferences.formats.uuidV1")).tag("v1")
                    Text(String(localized: "preferences.formats.uuidV4")).tag("v4")
                    Text(String(localized: "preferences.formats.uuidV5")).tag("v5")
                    Text(String(localized: "preferences.formats.ulid")).tag("ULID")
                }

                Picker(String(localized: "preferences.formats.qrErrorCorrection"), selection: $preferences.defaultQRErrorCorrection) {
                    Text(String(localized: "preferences.formats.qrLow")).tag("L")
                    Text(String(localized: "preferences.formats.qrMedium")).tag("M")
                    Text(String(localized: "preferences.formats.qrQuartile")).tag("Q")
                    Text(String(localized: "preferences.formats.qrHigh")).tag("H")
                }

                Picker(String(localized: "preferences.formats.lineBreakStyle"), selection: $preferences.lineBreakStyle) {
                    ForEach(LineBreakStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
            } header: {
                Text(String(localized: "preferences.formats.defaultFormats"))
            } footer: {
                Text(String(localized: "preferences.formats.defaultsFooter"))
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
                Toggle(String(localized: "preferences.history.enable"), isOn: $preferences.historyEnabled)
                    .fontWeight(.medium)
            } header: {
                Text(String(localized: "preferences.history.tracking"))
            } footer: {
                Text(String(localized: "preferences.history.enableFooter"))
            }

            Section {
                Picker(String(localized: "preferences.history.retentionPeriod"), selection: $preferences.historyRetentionDays) {
                    Text(String(localized: "preferences.history.retention.1day")).tag(1)
                    Text(String(localized: "preferences.history.retention.1week")).tag(7)
                    Text(String(localized: "preferences.history.retention.1month")).tag(30)
                    Text(String(localized: "preferences.history.retention.6months")).tag(180)
                    Text(String(localized: "preferences.history.retention.1year")).tag(365)
                    Text(String(localized: "preferences.history.retention.forever")).tag(999999)
                }
                .disabled(!preferences.historyEnabled)

                HStack {
                    Text(String(localized: "preferences.history.maxItemsPerTool"))
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
                Text(String(localized: "preferences.history.settings"))
            }

            Section {
                Button(role: .destructive, action: {
                    showClearConfirmation = true
                }) {
                    Label(String(localized: "preferences.history.clearAll"), systemImage: "trash")
                }
                .disabled(!preferences.historyEnabled)
                .confirmationDialog(
                    String(localized: "preferences.history.clearConfirmTitle"),
                    isPresented: $showClearConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(String(localized: "preferences.history.clearAll"), role: .destructive) {
                        preferences.clearAllHistory()
                    }
                    Button(String(localized: "common.action.cancel"), role: .cancel) {}
                } message: {
                    Text(String(localized: "preferences.history.clearConfirmMessage"))
                }
            } header: {
                Text(String(localized: "preferences.history.management"))
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
                    Text(String(localized: "preferences.advanced.maxFileSize"))
                    Slider(value: Binding(
                        get: { Double(preferences.maxFileSize) },
                        set: { preferences.maxFileSize = Int($0) }
                    ), in: 1...100, step: 1)
                    Text("\(preferences.maxFileSize) MB")
                        .frame(width: 60, alignment: .trailing)
                        .foregroundColor(.secondary)
                }

                Toggle(String(localized: "preferences.advanced.enableDebugLogging"), isOn: $preferences.debugLogging)
            } header: {
                Text(String(localized: "preferences.advanced.performance"))
            } footer: {
                Text(String(localized: "preferences.advanced.fileSizeWarning"))
            }

            Section {
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    Label(String(localized: "preferences.advanced.resetAll"), systemImage: "arrow.counterclockwise")
                }
                .confirmationDialog(
                    String(localized: "preferences.advanced.resetConfirmTitle"),
                    isPresented: $showResetConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(String(localized: "preferences.advanced.resetToDefaults"), role: .destructive) {
                        preferences.resetToDefaults()
                    }
                    Button(String(localized: "common.action.cancel"), role: .cancel) {}
                } message: {
                    Text(String(localized: "preferences.advanced.resetConfirmMessage"))
                }
            } header: {
                Text(String(localized: "preferences.advanced.reset"))
            } footer: {
                Text(String(localized: "preferences.advanced.resetFooter"))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview


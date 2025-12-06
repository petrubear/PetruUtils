//
//  ContentView.swift
//  PetruUtils
//
//  Created by Edison Martinez on 2/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var clipboardMonitor = ClipboardMonitor()
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var preferences = PreferencesManager.shared
    @State private var selection: Tool? = .jwt
    @State private var showClipboardBanner: Bool = false
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Clipboard detection banner
                if let suggestedTool = clipboardMonitor.suggestedTool,
                   let detectedType = clipboardMonitor.lastDetectedType,
                   showClipboardBanner {
                    clipboardBanner(detectedType: detectedType, suggestedTool: suggestedTool)
                }
                
                List(selection: $selection) {
                    // Favorites section
                    if !historyManager.sortedFavorites.isEmpty {
                        Section(String(localized: "sidebar.section.favorites")) {
                            ForEach(historyManager.sortedFavorites) { tool in
                                toolRow(for: tool)
                                    .tag(tool)
                            }
                        }
                    }
                    
                    // Recent tools section (limited to 5)
                    if !historyManager.recentTools.isEmpty {
                        Section(String(localized: "sidebar.section.recent")) {
                            ForEach(historyManager.recentTools.prefix(5)) { tool in
                                toolRow(for: tool)
                                    .tag(tool)
                            }
                        }
                    }

                    // All tools section (sorted alphabetically)
                    Section(String(localized: "sidebar.section.allTools")) {
                        ForEach(Tool.allCases.sorted { $0.title.lowercased() < $1.title.lowercased() }) { tool in
                            toolRow(for: tool)
                                .tag(tool)
                        }
                    }
                }
                .navigationTitle(String(localized: "sidebar.title"))
                
                // Clipboard monitoring toggle
                Divider()
                Toggle(String(localized: "sidebar.toggle.monitorClipboard"), isOn: $clipboardMonitor.isMonitoring)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: clipboardMonitor.isMonitoring) { _, isOn in
                        if isOn {
                            clipboardMonitor.startMonitoring()
                        } else {
                            clipboardMonitor.stopMonitoring()
                        }
                    }
            }
            .onChange(of: clipboardMonitor.suggestedTool) { _, newTool in
                guard let tool = newTool else {
                    showClipboardBanner = false
                    return
                }
                
                if preferences.clipboardAutoSwitch {
                    selection = tool
                    showClipboardBanner = false
                } else {
                    showClipboardBanner = true
                }
            }
            .onChange(of: preferences.clipboardAutoSwitch) { _, isEnabled in
                guard isEnabled, let tool = clipboardMonitor.suggestedTool else { return }
                selection = tool
                showClipboardBanner = false
            }
        } detail: {
            if let selectedTool = selection {
                LazyToolView(tool: selectedTool)
            } else {
                Text(String(localized: "common.label.selectTool"))
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            // Load default tool from preferences
            if let defaultToolRaw = preferences.defaultTool,
               let defaultTool = Tool(rawValue: defaultToolRaw) {
                selection = defaultTool
            } else if let lastTool = historyManager.recentTools.first {
                selection = lastTool
            }
        }
        .onChange(of: selection) { _, newTool in
            if let tool = newTool {
                historyManager.recordToolUsage(tool)
            }
        }
    }
    
    // MARK: - Tool Row
    
    @ViewBuilder
    private func toolRow(for tool: Tool) -> some View {
        HStack {
            Label(tool.title, systemImage: tool.iconName)
            
            Spacer()
            
            // Show favorite indicator
            if historyManager.isFavorite(tool) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
            
            // Show clipboard indicator if this is the suggested tool
            if clipboardMonitor.suggestedTool == tool {
                Image(systemName: "clipboard.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
            }
        }
        .contextMenu {
            Button {
                historyManager.toggleFavorite(tool)
            } label: {
                Label(
                    historyManager.isFavorite(tool) ? String(localized: "sidebar.action.removeFromFavorites") : String(localized: "sidebar.action.addToFavorites"),
                    systemImage: historyManager.isFavorite(tool) ? "star.slash" : "star"
                )
            }
        }
    }
    
    @ViewBuilder
    private func clipboardBanner(detectedType: ClipboardMonitor.DetectedContentType, suggestedTool: Tool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clipboard")
                .font(.title3)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(detectedType.displayName) \(String(localized: "clipboard.detected"))")
                    .font(.subheadline.weight(.semibold))
                Text("\(String(localized: "clipboard.suggested")) \(suggestedTool.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(String(localized: "common.action.open")) {
                selection = suggestedTool
                showClipboardBanner = false
            }
            .buttonStyle(.borderedProminent)
            
            Button(action: {
                showClipboardBanner = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Lazy Tool View

/// Lazy-loaded view for tool selection to improve performance
struct LazyToolView: View {
    let tool: Tool
    
    var body: some View {
        ToolRegistry.shared.view(for: tool)
            .id(tool) // Force view recreation when tool changes
    }
}


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
                        Section("Favorites") {
                            ForEach(historyManager.sortedFavorites) { tool in
                                toolRow(for: tool)
                                    .tag(tool)
                            }
                        }
                    }
                    
                    // Recent tools section
                    if !historyManager.recentTools.isEmpty {
                        Section("Recent") {
                            ForEach(historyManager.recentTools) { tool in
                                toolRow(for: tool)
                                    .tag(tool)
                            }
                        }
                    }
                    
                    // All tools section
                    Section("All Tools") {
                        ForEach(Tool.allCases) { tool in
                            toolRow(for: tool)
                                .tag(tool)
                        }
                    }
                }
                .navigationTitle("Tools")
                
                // Clipboard monitoring toggle
                Divider()
                Toggle("Monitor Clipboard", isOn: $clipboardMonitor.isMonitoring)
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
                if newTool != nil {
                    showClipboardBanner = true
                }
            }
        } detail: {
            if let selectedTool = selection {
                LazyToolView(tool: selectedTool)
            } else {
                Text("Select a tool")
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
                    historyManager.isFavorite(tool) ? "Remove from Favorites" : "Add to Favorites",
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
                Text("\(detectedType.displayName) Detected")
                    .font(.subheadline.weight(.semibold))
                Text("Suggested: \(suggestedTool.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Open") {
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
        Group {
            switch tool {
            case .jwt:
                JWTView()
            case .base64:
                Base64View()
            case .urlEncoder:
                URLView()
            case .hash:
                HashView()
            case .uuid:
                UUIDView()
            case .qr:
                QRCodeView()
            case .numberBase:
                NumberBaseView()
            case .unixTimestamp:
                UnixTimestampView()
            case .caseConverter:
                CaseConverterView()
            case .colorConverter:
                ColorConverterView()
            case .jsonYAML:
                JSONYAMLView()
            case .jsonCSV:
                JSONCSVView()
            case .markdownHTML:
                MarkdownHTMLView()
            case .jsonFormatter:
                JSONFormatterView()
            case .regexpTester:
                RegExpTesterView()
            case .textDiff:
                TextDiffView()
            case .xmlFormatter:
                XMLFormatterView()
            case .htmlFormatter:
                HTMLFormatterView()
            case .cssFormatter:
                CSSFormatterView()
            case .sqlFormatter:
                SQLFormatterView()
            case .lineSorter:
                LineSorterView()
            case .lineDeduplicator:
                LineDeduplicatorView()
            case .textReplacer:
                TextReplacerView()
            case .stringInspector:
                StringInspectorView()
            case .htmlEntity:
                HTMLEntityView()
            case .loremIpsum:
                LoremIpsumView()
            case .urlParser:
                URLParserView()
            }
        }
        .id(tool) // Force view recreation when tool changes
    }
}

// Placeholder view for unimplemented tools
struct PlaceholderView: View {
    let toolName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text(toolName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}

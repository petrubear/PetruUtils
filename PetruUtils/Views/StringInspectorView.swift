import SwiftUI
import Combine

struct StringInspectorView: View {
    @StateObject private var vm = StringInspectorViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HSplitView {
                inputPane
                statsPane
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("String Inspector")
                .font(.headline)
            
            Spacer()
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
            .help("Clear all (⌘K)")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "text.alignleft", title: "Input Text", color: .blue)

            FocusableTextEditor(text: $vm.input)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .font(.system(.body, design: .monospaced))
                .onChange(of: vm.input) { _, _ in
                    vm.analyze()
                }

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Usage")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text("Paste or type any text to analyze character counts, byte sizes, and frequency.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(4)
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    private var statsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let stats = vm.stats {
                    // Basic counts
                    statsSection(title: "Counts", icon: "number.square", color: .purple) {
                        statRow(label: "Characters", value: "\(stats.characters)")
                        Divider()
                        statRow(label: "Characters (no spaces)", value: "\(stats.charactersNoSpaces)")
                        Divider()
                        statRow(label: "Words", value: "\(stats.words)")
                        Divider()
                        statRow(label: "Lines", value: "\(stats.lines)")
                        Divider()
                        statRow(label: "Paragraphs", value: "\(stats.paragraphs)")
                        Divider()
                        statRow(label: "Unicode Scalars", value: "\(stats.unicodeScalars)")
                    }
                    
                    // Byte sizes
                    statsSection(title: "Byte Sizes", icon: "memorychip", color: .orange) {
                        statRow(label: "UTF-8", value: "\(stats.bytesUTF8) bytes")
                        Divider()
                        statRow(label: "UTF-16", value: "\(stats.bytesUTF16) bytes")
                    }
                    
                    // Analysis
                    statsSection(title: "Analysis", icon: "chart.bar", color: .green) {
                        statRow(label: "Entropy", value: String(format: "%.2f bits", stats.entropy))
                        Divider()
                        statRow(label: "Line Ending", value: stats.lineEnding)
                        Divider()
                        statRow(label: "Contains Emoji", value: stats.hasEmoji ? "Yes" : "No")
                    }
                    
                    // Character frequency (top 10)
                    if !vm.input.isEmpty {
                        statsSection(title: "Frequency (Top 10)", icon: "chart.pie", color: .teal) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(vm.topFrequency.prefix(10).enumerated()), id: \.offset) { _, item in
                                    HStack {
                                        Text(item.character == "\n" ? "\\n" : item.character == "\t" ? "\\t" : String(item.character))
                                            .font(.system(.body, design: .monospaced))
                                            .frame(width: 30)
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(4)
                                        Text("×\(item.count)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        let percentage = Double(item.count) / Double(stats.characters) * 100
                                        Text(String(format: "%.1f%%", percentage))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter text to see statistics")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding()
        }
    }
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }
    
    @ViewBuilder
    private func statsSection<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: icon, title: title, color: color)
            
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
}

@MainActor
final class StringInspectorViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var stats: StringInspectorService.Statistics?
    @Published var topFrequency: [(character: Character, count: Int)] = []
    
    private let service = StringInspectorService()
    
    func analyze() {
        guard !input.isEmpty else {
            stats = nil
            topFrequency = []
            return
        }
        
        stats = service.analyze(input)
        topFrequency = service.characterFrequency(input)
    }
    
    func clear() {
        input = ""
        stats = nil
        topFrequency = []
    }
}
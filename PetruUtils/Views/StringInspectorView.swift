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
        .padding()
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input")
                    .font(.subheadline.weight(.medium))
                Spacer()
            }
            
            FocusableTextEditor(text: $vm.input)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: vm.input) { _, _ in
                    vm.analyze()
                }
        }
        .padding()
    }
    
    private var statsPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let stats = vm.stats {
                    // Basic counts
                    statsSection(title: "Counts") {
                        statRow(label: "Characters", value: "\(stats.characters)")
                        statRow(label: "Characters (no spaces)", value: "\(stats.charactersNoSpaces)")
                        statRow(label: "Words", value: "\(stats.words)")
                        statRow(label: "Lines", value: "\(stats.lines)")
                        statRow(label: "Paragraphs", value: "\(stats.paragraphs)")
                        statRow(label: "Unicode Scalars", value: "\(stats.unicodeScalars)")
                    }
                    
                    // Byte sizes
                    statsSection(title: "Byte Sizes") {
                        statRow(label: "UTF-8", value: "\(stats.bytesUTF8) bytes")
                        statRow(label: "UTF-16", value: "\(stats.bytesUTF16) bytes")
                    }
                    
                    // Analysis
                    statsSection(title: "Analysis") {
                        statRow(label: "Entropy", value: String(format: "%.2f bits", stats.entropy))
                        statRow(label: "Line Ending", value: stats.lineEnding)
                        statRow(label: "Contains Emoji", value: stats.hasEmoji ? "Yes" : "No")
                    }
                    
                    // Character frequency (top 10)
                    if !vm.input.isEmpty {
                        statsSection(title: "Character Frequency (Top 10)") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(vm.topFrequency.prefix(10).enumerated()), id: \.offset) { _, item in
                                    HStack {
                                        Text(item.character == "\n" ? "\\n" : item.character == "\t" ? "\\t" : String(item.character))
                                            .font(.system(.body, design: .monospaced))
                                            .frame(width: 30)
                                        Text("×\(item.count)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        let percentage = Double(item.count) / Double(stats.characters) * 100
                                        Text(String(format: "%.1f%%", percentage))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("Enter text to see statistics")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func statsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(.leading, 8)
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
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
        }
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


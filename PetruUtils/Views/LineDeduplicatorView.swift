import SwiftUI
import Combine

struct LineDeduplicatorView: View {
    @StateObject private var vm = LineDeduplicatorViewModel()
    
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
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("Line Deduplicator")
                .font(.headline)
            
            Spacer()
            
            Picker("Keep", selection: $vm.keepOption) {
                Text("First").tag(LineDeduplicatorService.KeepOption.first)
                Text("Last").tag(LineDeduplicatorService.KeepOption.last)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
            
            Toggle("Case Sensitive", isOn: $vm.caseSensitive)
            Toggle("Sort After", isOn: $vm.sortAfter)
            
            if vm.showStats {
                Text("\(vm.stats.duplicates) dupes, \(vm.stats.unique) unique")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Remove Duplicates") { vm.deduplicate() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(vm.inputLineCount) lines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            FocusableTextEditor(text: $vm.input)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: vm.input) { _, _ in
                    vm.updateStats()
                }
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(vm.outputLineCount) lines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !vm.output.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .help("Copy output to clipboard")
                }
            }
            
            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            ScrollView {
                Text(vm.output.isEmpty ? "Deduplicated lines will appear here" : vm.output)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(vm.output.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .padding()
    }
}

@MainActor
final class LineDeduplicatorViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var keepOption: LineDeduplicatorService.KeepOption = .first
    @Published var caseSensitive: Bool = true
    @Published var sortAfter: Bool = false
    @Published var stats: (total: Int, unique: Int, duplicates: Int) = (0, 0, 0)
    @Published var showStats: Bool = false
    
    private let service = LineDeduplicatorService()
    
    var inputLineCount: Int {
        let lines = input.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.count
    }
    
    var outputLineCount: Int {
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        return lines.count
    }
    
    func updateStats() {
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showStats = false
            return
        }
        
        stats = service.getStatistics(input, caseSensitive: caseSensitive)
        showStats = stats.duplicates > 0
    }
    
    func deduplicate() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            return
        }
        
        output = service.deduplicate(input, caseSensitive: caseSensitive, keep: keepOption, sortAfter: sortAfter)
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        showStats = false
        stats = (0, 0, 0)
    }
}

#Preview {
    LineDeduplicatorView()
}

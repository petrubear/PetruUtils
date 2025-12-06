import SwiftUI
import Combine

struct LineDeduplicatorView: View {
    @StateObject private var vm = LineDeduplicatorViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "Line Deduplicator",
            inputTitle: "Input Lines",
            outputTitle: "Output",
            inputIcon: "text.alignleft",
            outputIcon: "text.alignleft",
            toolbarContent: {
                Button("Remove Duplicates") { vm.deduplicate() }
                    .keyboardShortcut(.return, modifiers: [.command])
            },
            configContent: {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.purple)
                        Text("Configuration")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Keep Option")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $vm.keepOption) {
                                Text("Keep First").tag(LineDeduplicatorService.KeepOption.first)
                                Text("Keep Last").tag(LineDeduplicatorService.KeepOption.last)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                            .labelsHidden()
                        }
                        
                        Divider()
                        
                        Toggle("Case Sensitive", isOn: $vm.caseSensitive)
                            .toggleStyle(.switch)
                        
                        Divider()
                        
                        Toggle("Sort After Deduplication", isOn: $vm.sortAfter)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            },
            helpContent: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Usage")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("Enter lines with duplicates. Choose to keep first or last occurrence of each unique line.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                .padding(.top, 4)
            },
            inputFooter: {
                HStack {
                    Text("\(vm.inputLineCount) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if vm.showStats {
                        Text("\(vm.stats.duplicates) duplicates found")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            },
            outputFooter: {
                if !vm.output.isEmpty {
                    Text("\(vm.outputLineCount) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                }
            }
        )
        .onChange(of: vm.input) { _, _ in
            vm.updateStats()
        }
    }
}

@MainActor
final class LineDeduplicatorViewModel: TextToolViewModel {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
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
    
    func process() {
        deduplicate()
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
            output = ""
            isValid = false
            return
        }
        
        output = service.deduplicate(input, caseSensitive: caseSensitive, keep: keepOption, sortAfter: sortAfter)
        isValid = true
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        showStats = false
        isValid = false
        stats = (0, 0, 0)
    }
}
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
            
            Button("Remove Duplicates") { vm.deduplicate() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "text.alignleft", title: "Input Lines", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: vm.input) { _, _ in
                            vm.updateStats()
                        }
                    
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
                }
                
                Divider()
                
                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)
                
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
                
                // Help text
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
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.outputLineCount) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    
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
            .padding()
            
            Divider()
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
            }
            
            if !vm.output.isEmpty {
                ScrollView {
                    Text(vm.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Deduplicated lines will appear here")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
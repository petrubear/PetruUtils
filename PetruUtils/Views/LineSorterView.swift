import SwiftUI
import Combine

struct LineSorterView: View {
    @StateObject private var vm = LineSorterViewModel()
    
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
            Text("Line Sorter")
                .font(.headline)
            
            Spacer()
            
            Button("Sort") { vm.sort() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Reverse") { vm.reverse() }
            Button("Shuffle") { vm.shuffle() }
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
                    
                    HStack {
                        Text("\(vm.inputLineCount) lines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                
                Divider()
                
                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Sort Order")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.sortOrder) {
                            Text("Ascending").tag(LineSorterService.SortOrder.ascending)
                            Text("Descending").tag(LineSorterService.SortOrder.descending)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    Toggle("Case Sensitive", isOn: $vm.caseSensitive)
                        .toggleStyle(.switch)
                    
                    Divider()
                    
                    Toggle("Natural Sort", isOn: $vm.naturalSort)
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
                    Text("Enter one item per line. Sort alphabetically, reverse, or shuffle.")
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
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Sorted lines will appear here")
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
final class LineSorterViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var sortOrder: LineSorterService.SortOrder = .ascending
    @Published var caseSensitive: Bool = true
    @Published var naturalSort: Bool = false
    
    private let service = LineSorterService()
    
    var inputLineCount: Int {
        service.lineCount(input)
    }
    
    var outputLineCount: Int {
        service.lineCount(output)
    }
    
    func sort() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            return
        }
        
        output = service.sortLines(input, order: sortOrder, caseSensitive: caseSensitive, naturalSort: naturalSort)
    }
    
    func reverse() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            return
        }
        
        output = service.reverseLines(input)
    }
    
    func shuffle() {
        errorMessage = nil
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Input is empty"
            return
        }
        
        output = service.shuffleLines(input)
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
    }
}
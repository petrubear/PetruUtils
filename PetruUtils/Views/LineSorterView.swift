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
            
            Picker("", selection: $vm.sortOrder) {
                Text("Asc").tag(LineSorterService.SortOrder.ascending)
                Text("Desc").tag(LineSorterService.SortOrder.descending)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .labelsHidden()
            
            Toggle("Case Sensitive", isOn: $vm.caseSensitive)
            Toggle("Natural", isOn: $vm.naturalSort)
            
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
                Text(vm.output.isEmpty ? "Sorted lines will appear here" : vm.output)
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

#Preview {
    LineSorterView()
}

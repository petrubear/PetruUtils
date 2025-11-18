import SwiftUI
import Combine

struct TextReplacerView: View {
    @StateObject private var vm = TextReplacerViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            VStack(spacing: 0) {
                // Find/Replace controls
                searchPanel
                Divider()
                
                // Text areas
                HSplitView {
                    inputPane
                    outputPane
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("Text Replacer")
                .font(.headline)
            
            Spacer()
            
            if vm.matchCount > 0 {
                Text("\(vm.matchCount) match\(vm.matchCount == 1 ? "" : "es")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
            }
            
            Button("Replace All") {
                vm.replaceAll()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .help("Replace all occurrences (⌘Return)")
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
            .help("Clear all (⌘K)")
        }
        .padding()
    }
    
    private var searchPanel: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("Search pattern", text: $vm.findPattern)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: vm.findPattern) { _, _ in
                            vm.updateMatchCount()
                        }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Replace With")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    TextField("Replacement text", text: $vm.replaceWith)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            HStack(spacing: 16) {
                Toggle("Regex", isOn: $vm.useRegex)
                    .toggleStyle(.checkbox)
                    .onChange(of: vm.useRegex) { _, _ in
                        vm.updateMatchCount()
                    }
                
                if !vm.useRegex {
                    Toggle("Case Sensitive", isOn: $vm.caseSensitive)
                        .toggleStyle(.checkbox)
                        .onChange(of: vm.caseSensitive) { _, _ in
                            vm.updateMatchCount()
                        }
                    
                    Toggle("Whole Word", isOn: $vm.wholeWord)
                        .toggleStyle(.checkbox)
                        .help("Match whole words only")
                } else {
                    Toggle("Case Sensitive", isOn: $vm.caseSensitive)
                        .toggleStyle(.checkbox)
                        .onChange(of: vm.caseSensitive) { _, _ in
                            vm.updateMatchCount()
                        }
                    
                    if let error = vm.regexError {
                        Text("Invalid regex: \(error)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
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
                    vm.updateMatchCount()
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
                Text(vm.output.isEmpty ? "Replaced text will appear here" : vm.output)
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
final class TextReplacerViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var findPattern: String = ""
    @Published var replaceWith: String = ""
    @Published var useRegex: Bool = false
    @Published var caseSensitive: Bool = true
    @Published var wholeWord: Bool = false
    @Published var matchCount: Int = 0
    @Published var errorMessage: String?
    @Published var regexError: String?
    
    private let service = TextReplacerService()
    
    func updateMatchCount() {
        regexError = nil
        
        guard !input.isEmpty && !findPattern.isEmpty else {
            matchCount = 0
            return
        }
        
        if useRegex {
            if !service.validateRegex(findPattern) {
                regexError = "Invalid pattern"
                matchCount = 0
                return
            }
        }
        
        matchCount = service.countOccurrences(in: input, find: findPattern, caseSensitive: caseSensitive, isRegex: useRegex)
    }
    
    func replaceAll() {
        errorMessage = nil
        regexError = nil
        
        guard !input.isEmpty else {
            errorMessage = "Input is empty"
            return
        }
        
        guard !findPattern.isEmpty else {
            errorMessage = "Find pattern is empty"
            return
        }
        
        do {
            if useRegex {
                output = try service.replaceWithRegex(input, pattern: findPattern, replaceWith: replaceWith, caseSensitive: caseSensitive)
            } else {
                output = try service.replace(input, find: findPattern, replaceWith: replaceWith, caseSensitive: caseSensitive, wholeWord: wholeWord)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        input = ""
        output = ""
        findPattern = ""
        replaceWith = ""
        errorMessage = nil
        regexError = nil
        matchCount = 0
    }
}

#Preview {
    TextReplacerView()
}

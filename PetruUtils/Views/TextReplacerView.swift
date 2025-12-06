import SwiftUI
import Combine

struct TextReplacerView: View {
    @StateObject private var vm = TextReplacerViewModel()
    
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
            Text("Text Replacer")
                .font(.headline)
            
            Spacer()
            
            Button("Replace All") {
                vm.replaceAll()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "text.quote", title: "Input Text", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: vm.input) { _, _ in
                            vm.updateMatchCount()
                        }
                    
                    HStack {
                        Text("\(vm.input.count) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if vm.matchCount > 0 {
                            Text("\(vm.matchCount) matches found")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Divider()
                
                sectionHeader(icon: "magnifyingglass", title: "Search & Replace", color: .purple)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Find
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Find")
                            .font(.subheadline.weight(.medium))
                        TextField("Search pattern", text: $vm.findPattern)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: vm.findPattern) { _, _ in
                                vm.updateMatchCount()
                            }
                    }
                    
                    // Replace
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Replace With")
                            .font(.subheadline.weight(.medium))
                        TextField("Replacement text", text: $vm.replaceWith)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Divider()
                    
                    // Options
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Regular Expression", isOn: $vm.useRegex)
                            .toggleStyle(.switch)
                            .onChange(of: vm.useRegex) { _, _ in
                                vm.updateMatchCount()
                            }
                        
                        Toggle("Case Sensitive", isOn: $vm.caseSensitive)
                            .toggleStyle(.switch)
                            .onChange(of: vm.caseSensitive) { _, _ in
                                vm.updateMatchCount()
                            }
                        
                        if !vm.useRegex {
                            Toggle("Match Whole Word", isOn: $vm.wholeWord)
                                .toggleStyle(.switch)
                        }
                    }
                    
                    if let regexError = vm.regexError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text("Invalid Regex: \(regexError)")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
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
                    Text("\(vm.output.count) characters")
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
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Replaced text will appear here")
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
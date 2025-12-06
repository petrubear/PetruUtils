import SwiftUI
import Combine

struct TextReplacerView: View {
    @StateObject private var vm = TextReplacerViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "Text Replacer",
            inputTitle: "Input Text",
            outputTitle: "Output",
            inputIcon: "text.quote",
            outputIcon: "text.quote",
            toolbarContent: {
                Button("Replace All") {
                    vm.replaceAll()
                }
                .keyboardShortcut(.return, modifiers: [.command])
            },
            configContent: {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.purple)
                        Text("Search & Replace")
                            .font(.subheadline.weight(.semibold))
                    }
                    
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
                }
            },
            helpContent: {
                EmptyView()
            },
            inputFooter: {
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
            },
            outputFooter: {
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                }
            }
        )
        .onChange(of: vm.input) { _, _ in
            vm.updateMatchCount()
        }
    }
}

@MainActor
final class TextReplacerViewModel: TextToolViewModel {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var findPattern: String = ""
    @Published var replaceWith: String = ""
    @Published var useRegex: Bool = false
    @Published var caseSensitive: Bool = true
    @Published var wholeWord: Bool = false
    @Published var matchCount: Int = 0
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    @Published var regexError: String?
    
    private let service = TextReplacerService()
    
    func process() {
        replaceAll()
    }
    
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
        isValid = false
        
        guard !input.isEmpty else {
            errorMessage = "Input is empty"
            output = ""
            return
        }
        
        guard !findPattern.isEmpty else {
            errorMessage = "Find pattern is empty"
            output = ""
            return
        }
        
        do {
            if useRegex {
                output = try service.replaceWithRegex(input, pattern: findPattern, replaceWith: replaceWith, caseSensitive: caseSensitive)
            } else {
                output = try service.replace(input, find: findPattern, replaceWith: replaceWith, caseSensitive: caseSensitive, wholeWord: wholeWord)
            }
            isValid = true
        } catch {
            errorMessage = error.localizedDescription
            output = ""
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
        isValid = false
    }
}
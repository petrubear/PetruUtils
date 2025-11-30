import SwiftUI
import Combine

struct JSONFormatterView: View {
    @StateObject private var vm = JSONFormatterViewModel()
    
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
        HStack {
            Text("JSON Formatter").font(.headline)
            Spacer()
            
            Picker("Indent", selection: $vm.indentStyle) {
                Text("2 Spaces").tag(JSONFormatterService.IndentStyle.twoSpaces)
                Text("4 Spaces").tag(JSONFormatterService.IndentStyle.fourSpaces)
                Text("Tabs").tag(JSONFormatterService.IndentStyle.tabs)
            }.frame(width: 120)
            
            Toggle("Sort Keys", isOn: $vm.sortKeys)
            
            Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
            Button("Validate") { vm.validate() }.keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input JSON").font(.headline)
            FocusableTextEditor(text: $vm.input)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            
            HStack {
                if !vm.input.isEmpty {
                    Text("\(vm.input.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let validation = vm.validationResult, !validation.isValid {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                        if let line = validation.lineNumber, let col = validation.columnNumber {
                            Text("Error at line \(line), column \(col)")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else {
                            Text("Invalid JSON")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } else if let validation = vm.validationResult, validation.isValid {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Valid JSON").font(.caption).foregroundStyle(.green)
                    }
                }
            }
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Output").font(.headline)
            ScrollView {
                SyntaxHighlightedText(text: vm.output, language: .json)
                    .padding(8)
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            
            HStack {
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !vm.output.isEmpty {
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
        }
        .padding()
    }
}

@MainActor
final class JSONFormatterViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var errorMessage: String?
    @Published var validationResult: JSONFormatterService.ValidationResult?
    @Published var indentStyle: JSONFormatterService.IndentStyle = .twoSpaces
    @Published var sortKeys = false
    
    private let service = JSONFormatterService()
    
    func format() {
        errorMessage = nil
        validationResult = nil
        guard !input.isEmpty else { return }
        
        do {
            output = try service.format(input, indent: indentStyle, sortKeys: sortKeys)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func minify() {
        errorMessage = nil
        validationResult = nil
        guard !input.isEmpty else { return }
        
        do {
            output = try service.minify(input)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func validate() {
        errorMessage = nil
        output = ""
        guard !input.isEmpty else { return }
        
        validationResult = service.validate(input)
        if let result = validationResult, !result.isValid {
            errorMessage = result.error
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        validationResult = nil
    }
    
    func copyOutput() {
        guard !output.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}


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
        HStack(spacing: 12) {
            Text("JSON Formatter").font(.headline)
            Spacer()
            
            Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
            Button("Validate") { vm.validate() }.keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "doc.text", title: "Input JSON", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        if !vm.input.isEmpty {
                            Text("\(vm.input.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                
                Divider()
                
                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Indentation")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.indentStyle) {
                            Text("2 Spaces").tag(JSONFormatterService.IndentStyle.twoSpaces)
                            Text("4 Spaces").tag(JSONFormatterService.IndentStyle.fourSpaces)
                            Text("Tabs").tag(JSONFormatterService.IndentStyle.tabs)
                        }
                        .frame(width: 120)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    Toggle("Sort Keys", isOn: $vm.sortKeys)
                        .toggleStyle(.switch)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text(#"{"name":"John","age":30,"city":"NYC"}"#)
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
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                        
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if let validation = vm.validationResult {
                HStack(spacing: 8) {
                    Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(validation.isValid ? .green : .red)
                    
                    if validation.isValid {
                        Text("Valid JSON")
                            .foregroundStyle(.green)
                    } else {
                        Text(validation.error ?? "Invalid JSON")
                            .foregroundStyle(.red)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(validation.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            }
            
            if !vm.output.isEmpty {
                ScrollView {
                    SyntaxHighlightedText(text: vm.output, language: .json)
                        .padding(8)
                }
            } else if vm.validationResult == nil {
                VStack(spacing: 12) {
                    Image(systemName: "curlybraces")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Format, minify, or validate JSON")
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
            // We display the error in the output pane, so we don't strictly need errorMessage here unless for other errors
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
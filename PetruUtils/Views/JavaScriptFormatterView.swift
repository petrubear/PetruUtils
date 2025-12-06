import SwiftUI
import Combine
import AppKit

struct JavaScriptFormatterView: View {
    @StateObject private var vm = JavaScriptFormatterViewModel()
    
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
            Text("JavaScript Formatter").font(.headline)
            Spacer()
            
            Button("Format") { vm.format() }
                .keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }
                .keyboardShortcut("m", modifiers: [.command])
            Button("Validate") { vm.validate() }
                .keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "curlybraces", title: "Input JavaScript", color: .blue)
                
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
                            ForEach(JavaScriptFormatterService.IndentStyle.allCases) {
                                style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .frame(width: 140)
                        .labelsHidden()
                    }
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
                    Text("function hello(){return\"world\"}")
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
                    
                    Text(validation.isValid ? "Valid JavaScript" : (validation.message ?? "Invalid"))
                        .foregroundStyle(validation.isValid ? .green : .red)
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(validation.isValid ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            }
            
            if !vm.output.isEmpty {
                CodeBlock(text: vm.output, language: .javascript)
                    .padding(8)
            } else if vm.validationResult == nil {
                VStack(spacing: 12) {
                    Image(systemName: "curlybraces.square")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Format, minify, or validate JavaScript")
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
final class JavaScriptFormatterViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var validationResult: JavaScriptFormatterService.ValidationResult?
    @Published var indentStyle: JavaScriptFormatterService.IndentStyle = .fourSpaces
    
    private let service = JavaScriptFormatterService()
    
    func format() {
        guard !input.isEmpty else { return }
        errorMessage = nil
        validationResult = nil
        do {
            output = try service.format(input, indentStyle: indentStyle)
        } catch {
            output = ""
            errorMessage = error.localizedDescription
        }
    }
    
    func minify() {
        guard !input.isEmpty else { return }
        errorMessage = nil
        validationResult = nil
        do {
            output = try service.minify(input)
        } catch {
            output = ""
            errorMessage = error.localizedDescription
        }
    }
    
    func validate() {
        guard !input.isEmpty else { return }
        errorMessage = nil
        let result = service.validate(input)
        validationResult = result
        if !result.isValid {
            // Error is shown in validation block
        }
    }
    
    func clear() {
        input.removeAll()
        output.removeAll()
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
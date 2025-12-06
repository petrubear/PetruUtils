import SwiftUI
import Combine

struct CaseConverterView: View {
    @StateObject private var vm = CaseConverterViewModel()
    
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
            Text("Case Converter")
                .font(.headline)
            
            Spacer()
            
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
            
            Button("Copy All") { vm.copyAll() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(vm.result == nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "text.cursor", title: "Input", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text to Convert")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., hello_world or HelloWorld", text: $vm.input, onCommit: { vm.convert() })
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Press Return to convert")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Examples")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("hello_world → helloWorld, HelloWorld, hello-world")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("myVariableName → my_variable_name, MY_VARIABLE_NAME")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let result = vm.result {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "textformat", title: "Conversions", color: .purple)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            caseRow(title: "camelCase", value: result.camelCase, icon: "c.square")
                            Divider()
                            caseRow(title: "PascalCase", value: result.pascalCase, icon: "p.square")
                            Divider()
                            caseRow(title: "snake_case", value: result.snakeCase, icon: "s.square")
                            Divider()
                            caseRow(title: "kebab-case", value: result.kebabCase, icon: "k.square")
                            Divider()
                            caseRow(title: "UPPER CASE", value: result.upperCase, icon: "u.square")
                            Divider()
                            caseRow(title: "lower case", value: result.lowerCase, icon: "l.square")
                            Divider()
                            caseRow(title: "Title Case", value: result.titleCase, icon: "t.square")
                            Divider()
                            caseRow(title: "Sentence case", value: result.sentenceCase, icon: "s.square.fill")
                            Divider()
                            caseRow(title: "CONSTANT_CASE", value: result.constantCase, icon: "exclamationmark.square")
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "textformat")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter text to convert")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Supports camelCase, snake_case, kebab-case, and more")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding()
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
    
    @ViewBuilder
    private func caseRow(title: String, value: String, icon: String) -> some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .font(.title3)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { vm.copyValue(value) }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Copy \(title)")
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ViewModel

@MainActor
final class CaseConverterViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var result: CaseConverterService.ConversionResult?
    @Published var errorMessage: String?
    
    private let service = CaseConverterService()
    
    func convert() {
        guard !input.isEmpty else {
            clear()
            return
        }
        
        errorMessage = nil
        
        do {
            result = try service.convertAll(input)
        } catch {
            errorMessage = error.localizedDescription
            result = nil
        }
    }
    
    func clear() {
        input = ""
        result = nil
        errorMessage = nil
    }
    
    func copyValue(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
    
    func copyAll() {
        guard let result = result else { return }
        
        let output = """
        camelCase: \(result.camelCase)
        PascalCase: \(result.pascalCase)
        snake_case: \(result.snakeCase)
        kebab-case: \(result.kebabCase)
        UPPER CASE: \(result.upperCase)
        lower case: \(result.lowerCase)
        Title Case: \(result.titleCase)
        Sentence case: \(result.sentenceCase)
        CONSTANT_CASE: \(result.constantCase)
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}
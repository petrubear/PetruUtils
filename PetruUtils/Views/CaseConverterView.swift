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
        VStack(alignment: .leading, spacing: 16) {
            Text("Input")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Text to Convert")
                    .font(.subheadline.weight(.semibold))
                TextField("e.g., hello_world or HelloWorld", text: $vm.input, onCommit: { vm.convert() })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text("Press Return to convert")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Output")
                    .font(.headline)
                
                if let result = vm.result {
                    VStack(alignment: .leading, spacing: 12) {
                        caseRow(title: "camelCase", value: result.camelCase, icon: "c.square")
                        caseRow(title: "PascalCase", value: result.pascalCase, icon: "p.square")
                        caseRow(title: "snake_case", value: result.snakeCase, icon: "s.square")
                        caseRow(title: "kebab-case", value: result.kebabCase, icon: "k.square")
                        caseRow(title: "UPPER CASE", value: result.upperCase, icon: "u.square")
                        caseRow(title: "lower case", value: result.lowerCase, icon: "l.square")
                        caseRow(title: "Title Case", value: result.titleCase, icon: "t.square")
                        caseRow(title: "Sentence case", value: result.sentenceCase, icon: "s.square.fill")
                        caseRow(title: "CONSTANT_CASE", value: result.constantCase, icon: "exclamationmark.square")
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
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func caseRow(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(action: { vm.copyValue(value) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Copy \(title)")
            }
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(6)
        }
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

// MARK: - Preview

#Preview {
    CaseConverterView()
}

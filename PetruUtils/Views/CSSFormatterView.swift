import SwiftUI
import Combine

struct CSSFormatterView: View {
    @StateObject private var vm = CSSFormatterViewModel()
    
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
            Text("CSS Formatter").font(.headline)
            Spacer()
            Toggle("Sort Properties", isOn: $vm.sortProperties)
            Picker("Indent", selection: $vm.indentStyle) {
                ForEach(CSSFormatterService.IndentStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .frame(width: 120)
            Button("Format") { vm.format() }.keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { vm.minify() }.keyboardShortcut("m", modifiers: [.command])
            Button("Validate") { vm.validate() }.keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal).padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input").font(.headline)
                Spacer()
                Text("\(vm.input.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            FocusableTextEditor(text: $vm.input)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output").font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            
            if let errorMessage = vm.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Error")
                            .font(.headline)
                    }
                    Text(errorMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else if let validationMessage = vm.validationMessage {
                HStack {
                    Image(systemName: vm.validationIsValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(vm.validationIsValid ? .green : .red)
                    Text(validationMessage)
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((vm.validationIsValid ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(8)
            } else {
                ScrollView {
                    SyntaxHighlightedText(text: vm.output, language: .css)
                        .padding(8)
                }
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }
        }
        .padding()
    }
}

@MainActor
final class CSSFormatterViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var errorMessage: String?
    @Published var validationMessage: String?
    @Published var validationIsValid = false
    @Published var indentStyle: CSSFormatterService.IndentStyle = .twoSpaces
    @Published var sortProperties = false
    
    private let service = CSSFormatterService()
    
    func format() {
        errorMessage = nil
        validationMessage = nil
        
        do {
            output = try service.format(input, indentStyle: indentStyle, sortProperties: sortProperties)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func minify() {
        errorMessage = nil
        validationMessage = nil
        
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
        
        let result = service.validate(input)
        validationMessage = result.message
        validationIsValid = result.isValid
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        validationMessage = nil
    }
    
    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
}

#Preview { CSSFormatterView() }

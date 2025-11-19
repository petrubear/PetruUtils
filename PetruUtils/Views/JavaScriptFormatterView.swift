import SwiftUI
import Combine
import AppKit

struct JavaScriptFormatterView: View {
    @StateObject private var viewModel = JavaScriptFormatterViewModel()
    
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
            Text("JavaScript Formatter").font(.headline)
            Spacer()
            
            Picker("Indent", selection: $viewModel.indentStyle) {
                ForEach(JavaScriptFormatterService.IndentStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .frame(width: 140)
            
            Button("Format") { viewModel.format() }
                .keyboardShortcut("f", modifiers: [.command])
            Button("Minify") { viewModel.minify() }
                .keyboardShortcut("m", modifiers: [.command])
            Button("Validate") { viewModel.validate() }
                .keyboardShortcut("v", modifiers: [.command])
            Button("Clear") { viewModel.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Input JavaScript").font(.headline)
            FocusableTextEditor(text: $viewModel.input)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            
            HStack {
                if !viewModel.input.isEmpty {
                    Text("\(viewModel.input.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let validation = viewModel.validationResult, !validation.isValid {
                    Label(validation.message ?? "Invalid", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                } else if let validation = viewModel.validationResult, validation.isValid {
                    Label("Valid JavaScript", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
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
            HStack {
                Text("Output").font(.headline)
                Spacer()
                if !viewModel.output.isEmpty {
                    Button("Copy") { viewModel.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            ScrollView {
                SyntaxHighlightedText(text: viewModel.output, language: .javascript)
                    .padding(8)
            }
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            
            if !viewModel.output.isEmpty {
                Text("\(viewModel.output.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
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
            errorMessage = result.message
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

#Preview {
    JavaScriptFormatterView()
        .frame(width: 900, height: 600)
}

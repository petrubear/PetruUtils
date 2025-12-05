import SwiftUI
import Combine
import AppKit

struct CurlConverterView: View {
    @StateObject private var viewModel = CurlConverterViewModel()

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
            Text("cURL Converter")
                .font(.headline)
            
            Spacer()
            
            Picker("", selection: $viewModel.selectedLanguage) {
                ForEach(TargetLanguage.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .labelsHidden()
            .frame(width: 180)
            .pickerStyle(.menu)

            Button("Convert") { viewModel.convert() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { viewModel.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "terminal", title: "cURL Command", color: .blue)

                FocusableTextEditor(text: $viewModel.input)
                    .frame(minHeight: 200)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .font(.system(.body, design: .monospaced))

                HStack {
                    if !viewModel.input.isEmpty {
                        Text("\(viewModel.input.count) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
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
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("curl -X POST -H 'Content-Type: application/json' -d '{\"key\":\"value\"}' https://api.example.com/endpoint")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding()
        }
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Generated Code")
                    .font(.headline)
                Spacer()
                if !viewModel.output.isEmpty {
                    Text(viewModel.selectedLanguage.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                        
                    Button("Copy") { viewModel.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()

            if !viewModel.output.isEmpty {
                ScrollView {
                    SyntaxHighlightedText(text: viewModel.output, language: languageForSyntax())
                        .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Enter a cURL command to convert")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Select your target language and press ⌘Return")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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

    private func languageForSyntax() -> SyntaxLanguage {
        switch viewModel.selectedLanguage {
        case .javascript:
            return .javascript
        default:
            return .plain
        }
    }
}

@MainActor
final class CurlConverterViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var selectedLanguage: TargetLanguage = .swift

    private let service = CurlConverterService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Auto-convert when language changes (if there's input and previous output)
        $selectedLanguage
            .dropFirst()
            .sink { [weak self] _ in
                if let self = self, !self.input.isEmpty, !self.output.isEmpty {
                    self.convert()
                }
            }
            .store(in: &cancellables)
    }

    func convert() {
        guard !input.isEmpty else {
            errorMessage = "Please enter a cURL command"
            return
        }

        errorMessage = nil
        output = ""

        do {
            let request = try service.parseCurl(input)
            output = service.generateCode(from: request, language: selectedLanguage)
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }

    func clear() {
        input = ""
        output = ""
        errorMessage = nil
    }

    func copyOutput() {
        guard !output.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}
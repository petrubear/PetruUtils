import SwiftUI
import Combine

struct ASCIIArtGeneratorView: View {
    @StateObject private var vm = ASCIIArtGeneratorViewModel()

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
            Text("ASCII Art Generator")
                .font(.headline)

            Spacer()

            Button("Generate") { vm.generate() }
                .keyboardShortcut(.return, modifiers: [.command])

            Button("Clear") { vm.clear() }
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
                        .frame(minHeight: 100)
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
                        Text("Font Style")
                            .font(.subheadline)
                        Spacer()
                    }
                    
                    Picker("", selection: $vm.selectedFont) {
                        ForEach(ASCIIArtService.ASCIIFont.allCases) { asciiFont in
                            Text(asciiFont.displayName).tag(asciiFont)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    
                    // Preview of font style if possible, or just description
                    Text("Selected style: \(vm.selectedFont.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        Text("Supported Characters")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("A-Z, 0-9, space, and common punctuation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Generated Art")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.filter { $0 == "\n" }.count + 1) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    
                    Button(action: { vm.copyOutput() }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider() 
            
            ScrollView([.horizontal, .vertical]) {
                if vm.output.isEmpty {
                     VStack(spacing: 12) {
                        Image(systemName: "textformat.abc")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter text to generate ASCII art")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else {
                    Text(vm.output)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color.white) // Better contrast for ASCII art
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

// MARK: - ViewModel

@MainActor
final class ASCIIArtGeneratorViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var selectedFont: ASCIIArtService.ASCIIFont = .banner
    @Published var errorMessage: String?

    private let service = ASCIIArtService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Auto-generate when font changes (if there's input)
        $selectedFont
            .dropFirst()
            .sink { [weak self] _ in
                guard let self = self, !self.input.isEmpty else { return }
                self.generate()
            }
            .store(in: &cancellables)
            
        // Auto-generate when input changes (debounce)
        $input
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self, !self.input.isEmpty else { 
                    self?.output = ""
                    return 
                }
                self.generate()
            }
            .store(in: &cancellables)
    }

    func generate() {
        guard !input.isEmpty else {
            clear()
            return
        }

        errorMessage = nil

        do {
            output = try service.generateASCIIArt(from: input, font: selectedFont)
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
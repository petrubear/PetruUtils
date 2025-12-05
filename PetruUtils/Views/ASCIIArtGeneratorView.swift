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

            Picker("Font", selection: $vm.selectedFont) {
                ForEach(ASCIIArtService.ASCIIFont.allCases) { font in
                    Text(font.displayName).tag(font)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)

            Button("Generate") { vm.generate() }
                .keyboardShortcut(.return, modifiers: [.command])

            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])

            Button("Copy") { vm.copyOutput() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(vm.output.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Input")
                    .font(.headline)
                Spacer()
                Text("\(vm.input.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $vm.input)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                Text("Supported characters:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("A-Z, 0-9, space, and common punctuation")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Error display
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.filter { $0 == "\n" }.count + 1) lines")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if vm.output.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "textformat.abc")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Enter text and click Generate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Press ⌘Return to generate")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(vm.output)
                        .font(.system(size: 12, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                }
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }

            // Font preview
            if !vm.output.isEmpty {
                HStack {
                    Text("Font: \(vm.selectedFont.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button(action: { vm.copyOutput() }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
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

// MARK: - Preview

#Preview {
    ASCIIArtGeneratorView()
}

import SwiftUI
import Combine

struct MarkdownHTMLView: View {
    @StateObject private var vm = MarkdownHTMLViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Markdown ↔ HTML Converter").font(.headline)
                Spacer()
                Picker("Mode", selection: $vm.mode) {
                    Text("Markdown → HTML").tag(true)
                    Text("HTML → Markdown").tag(false)
                }.pickerStyle(.segmented).frame(width: 250)
                Button("Convert") { vm.convert() }.keyboardShortcut(.return, modifiers: [.command])
                Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
            }.padding(.horizontal).padding(.vertical, 8)
            Divider()
            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input").font(.headline)
                    FocusableTextEditor(text: $vm.input).padding(4).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    if let error = vm.errorMessage { Text(error).foregroundStyle(.red).font(.callout) }
                    // Help text
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Examples:")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        if vm.mode {
                            Text("Markdown: # Heading, **bold**, *italic*, [link](url)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("HTML: <h1>Heading</h1>, <b>bold</b>, <i>italic</i>")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }.padding()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output").font(.headline)
                    ScrollView {
                        SyntaxHighlightedText(text: vm.output, language: vm.mode ? .html : .plain)
                            .padding(8)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                }.padding()
            }
        }
    }
}

@MainActor
final class MarkdownHTMLViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var mode = true
    @Published var errorMessage: String?
    private let service = MarkdownHTMLService()
    
    func convert() {
        errorMessage = nil
        output = ""
        guard !input.isEmpty else { return }
        do {
            output = mode ? try service.markdownToHTML(input) : try service.htmlToMarkdown(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func clear() { input = ""; output = ""; errorMessage = nil }
}


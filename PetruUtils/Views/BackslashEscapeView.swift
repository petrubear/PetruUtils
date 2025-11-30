import SwiftUI
import Combine

struct BackslashEscapeView: View {
    @StateObject private var vm = BackslashEscapeViewModel()
    
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
            Text("Backslash Escape/Unescape")
                .font(.headline)
            
            Spacer()
            
            Picker("", selection: $vm.mode) {
                Text("Escape").tag(BackslashEscapeViewModel.Mode.escape)
                Text("Unescape").tag(BackslashEscapeViewModel.Mode.unescape)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .labelsHidden()
            
            if vm.mode == .escape {
                Picker("", selection: $vm.escapeMode) {
                    Text("Standard").tag(BackslashEscapeService.EscapeMode.standard)
                    Text("Unicode").tag(BackslashEscapeService.EscapeMode.unicode)
                    Text("JSON").tag(BackslashEscapeService.EscapeMode.json)
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
                .labelsHidden()
            }
            
            Button("Convert") { vm.convert() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(vm.input.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            FocusableTextEditor(text: $vm.input)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(vm.output.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !vm.output.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
            
            ScrollView {
                Text(vm.output.isEmpty ? "Converted text will appear here" : vm.output)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(vm.output.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .padding()
    }
}

@MainActor
final class BackslashEscapeViewModel: ObservableObject {
    enum Mode {
        case escape
        case unescape
    }
    
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: Mode = .escape
    @Published var escapeMode: BackslashEscapeService.EscapeMode = .standard
    
    private let service = BackslashEscapeService()
    
    func convert() {
        guard !input.isEmpty else {
            output = ""
            return
        }
        
        switch mode {
        case .escape:
            output = service.escape(input, mode: escapeMode)
        case .unescape:
            output = service.unescape(input)
        }
    }
    
    func clear() {
        input = ""
        output = ""
    }
}


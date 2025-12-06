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
            Text("Backslash Escaper")
                .font(.headline)
            
            Spacer()
            
            Button("Convert") { vm.convert() }
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
                sectionHeader(icon: vm.mode == .escape ? "text.quote" : "chevron.left.slash.chevron.right", 
                              title: vm.mode == .escape ? "Input Text" : "Input Escaped Text", 
                              color: .blue)
                
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
                        Text("Mode")
                            .font(.subheadline)
                        Spacer()
                        Picker("", selection: $vm.mode) {
                            Text("Escape").tag(BackslashEscapeViewModel.Mode.escape)
                            Text("Unescape").tag(BackslashEscapeViewModel.Mode.unescape)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .labelsHidden()
                    }
                    
                    if vm.mode == .escape {
                        Divider() 
                        
                        HStack {
                            Text("Escape Style")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $vm.escapeMode) {
                                Text("Standard").tag(BackslashEscapeService.EscapeMode.standard)
                                Text("Unicode").tag(BackslashEscapeService.EscapeMode.unicode)
                                Text("JSON").tag(BackslashEscapeService.EscapeMode.json)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 120)
                            .labelsHidden()
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    if vm.mode == .escape {
                        Text("newline → \\n, tab → \\t, quote → \\\"")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                    } else {
                        Text("\\n → newline, \\t → tab")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                    }
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
                Text(vm.mode == .escape ? "Escaped Output" : "Unescaped Output")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .help("Copy output to clipboard")
                }
            }
            .padding()
            
            Divider() 
            
            if !vm.output.isEmpty {
                ScrollView {
                    Text(vm.output)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: vm.mode == .escape ? "chevron.left.slash.chevron.right" : "text.quote")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Result will appear here")
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
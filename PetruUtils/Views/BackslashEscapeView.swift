import SwiftUI
import Combine

struct BackslashEscapeView: View {
    @StateObject private var vm = BackslashEscapeViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "Backslash Escaper",
            inputTitle: vm.mode == .escape ? "Input Text" : "Input Escaped Text",
            outputTitle: vm.mode == .escape ? "Escaped Output" : "Unescaped Output",
            inputIcon: vm.mode == .escape ? "text.quote" : "chevron.left.slash.chevron.right",
            outputIcon: vm.mode == .escape ? "chevron.left.slash.chevron.right" : "text.quote",
            toolbarContent: {
                Button("Convert") { vm.convert() }
                    .keyboardShortcut(.return, modifiers: [.command])
            },
            configContent: {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.purple)
                        Text("Configuration")
                            .font(.subheadline.weight(.semibold))
                    }
                    
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
                }
            },
            helpContent: {
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
            }
        )
    }
}

@MainActor
final class BackslashEscapeViewModel: TextToolViewModel {
    enum Mode {
        case escape
        case unescape
    }
    
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: Mode = .escape
    @Published var escapeMode: BackslashEscapeService.EscapeMode = .standard
    @Published var errorMessage: String?
    @Published var isValid: Bool = false

    let tool: Tool = .backslashEscape
    private let service = BackslashEscapeService()
    
    func process() {
        convert()
    }
    
    func convert() {
        guard !input.isEmpty else {
            output = ""
            isValid = false
            return
        }
        
        switch mode {
        case .escape:
            output = service.escape(input, mode: escapeMode)
        case .unescape:
            output = service.unescape(input)
        }
        isValid = true
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
}
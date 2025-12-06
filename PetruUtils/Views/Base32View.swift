import SwiftUI
import Combine

struct Base32View: View {
    @StateObject private var vm = Base32ViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "Base32 Converter",
            inputTitle: vm.mode == .encode ? "Input Text" : "Input Base32",
            outputTitle: vm.mode == .encode ? "Output Base32" : "Output Text",
            inputIcon: vm.mode == .encode ? "text.quote" : "textformat.123",
            outputIcon: vm.mode == .encode ? "textformat.123" : "text.quote",
            toolbarContent: {
                EmptyView()
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
                                Text("Encode").tag(Base32ViewModel.Mode.encode)
                                Text("Decode").tag(Base32ViewModel.Mode.decode)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                            .labelsHidden()
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Variant")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $vm.variant) {
                                Text("Standard (RFC 4648)").tag(Base32Service.Variant.standard)
                                Text("Hex (RFC 4648)").tag(Base32Service.Variant.hex)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 180)
                            .labelsHidden()
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
                    if vm.mode == .encode {
                        Text("Hello → JBSWY3DP")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                    } else {
                        Text("JBSWY3DP → Hello")
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
        .onChange(of: vm.input) { _, _ in
            vm.process()
        }
    }
}

@MainActor
final class Base32ViewModel: TextToolViewModel {
    enum Mode {
        case encode
        case decode
    }
    
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: Mode = .encode {
        didSet { process() }
    }
    @Published var variant: Base32Service.Variant = .standard {
        didSet { process() }
    }
    @Published var errorMessage: String?
    @Published var isValid: Bool = false

    let tool: Tool = .base32
    private let service = Base32Service()
    
    func process() {
        errorMessage = nil
        isValid = false
        
        guard !input.isEmpty else {
            output = ""
            return
        }
        
        do {
            switch mode {
            case .encode:
                output = try service.encode(input, variant: variant)
                isValid = true
            case .decode:
                output = try service.decode(input, variant: variant)
                isValid = true
            }
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
}
import SwiftUI
import Combine

struct Base64View: View {
    @StateObject private var vm = Base64ViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "Base64 Converter",
            inputTitle: vm.mode == .encode ? "Input Text" : "Base64 Input",
            outputTitle: vm.mode == .encode ? "Base64 Output" : "Decoded Text",
            inputIcon: vm.mode == .encode ? "text.alignleft" : "textformat.123",
            outputIcon: vm.mode == .encode ? "textformat.123" : "text.alignleft",
            toolbarContent: {
                HStack {
                    Picker("", selection: $vm.mode) {
                        Text("Encode").tag(Base64Mode.encode)
                        Text("Decode").tag(Base64Mode.decode)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 150)
                    
                    Picker("", selection: $vm.variant) {
                        Text("Standard").tag(Base64Service.Base64Variant.standard)
                        Text("URL-Safe").tag(Base64Service.Base64Variant.urlSafe)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 100)
                }
            },
            configContent: {
                EmptyView()
            },
            helpContent: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    if vm.mode == .encode {
                        Text("Hello, World! → SGVsbG8sIFdvcmxkIQ==")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                    } else {
                        Text("SGVsbG8sIFdvcmxkIQ== → Hello, World!")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                    }
                }
                .padding(.top, 8)
            }
        )
    }
}

// MARK: - ViewModel

@MainActor
final class Base64ViewModel: TextToolViewModel {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: Base64Mode = .encode
    @Published var variant: Base64Service.Base64Variant = .standard
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let service = Base64Service()
    
    func process() {
        errorMessage = nil
        output = ""
        isValid = false
        
        guard !input.isEmpty else {
            errorMessage = "Input cannot be empty"
            return
        }
        
        do {
            switch mode {
            case .encode:
                output = try service.encodeText(input, variant: variant)
                isValid = true
            case .decode:
                output = try service.decodeText(input, variant: variant)
                isValid = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
}

// MARK: - Types

enum Base64Mode {
    case encode
    case decode
}
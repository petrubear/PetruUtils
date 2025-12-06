import SwiftUI
import Combine

struct URLView: View {
    @StateObject private var vm = URLViewModel()
    
    var body: some View {
        GenericTextToolView(
            vm: vm,
            title: "URL Encoder",
            inputTitle: "Input",
            outputTitle: "Output",
            inputIcon: "link",
            outputIcon: "link",
            toolbarContent: {
                Button("Auto-Detect") { vm.autoDetect(); vm.process() }
                    .keyboardShortcut("d", modifiers: [.command])
            },
            configContent: {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.purple)
                        Text("Configuration")
                            .font(.subheadline.weight(.semibold))
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mode")
                                .font(.subheadline)
                            Picker("", selection: $vm.mode) {
                                ForEach(URLViewModel.ProcessMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Component Type")
                                .font(.subheadline)
                            Picker("", selection: $vm.componentType) {
                                Text("Full URL").tag(URLComponentType.fullURL)
                                Text("Query Param").tag(URLComponentType.queryParameter)
                                Text("Path Segment").tag(URLComponentType.pathSegment)
                                Text("Form Data").tag(URLComponentType.formData)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
            },
            helpContent: {
                EmptyView()
            }
        )
        // Keep the onChange to auto-process input changes if desired, 
        // though the original only processed on explicit command or button in Base64View, 
        // but URLView had .onChange(of: vm.input)
        .onChange(of: vm.input) { _, _ in
            vm.process()
        }
    }
}

// MARK: - URL View Model

@MainActor
class URLViewModel: TextToolViewModel {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: ProcessMode = .encode
    @Published var componentType: URLComponentType = .queryParameter
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let service = URLService()
    
    enum ProcessMode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
    }
    
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
                output = try service.encode(input, type: componentType)
                isValid = true
            case .decode:
                output = try service.decode(input, type: componentType)
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
    
    func autoDetect() {
        if service.isURLEncoded(input) || service.isFormEncoded(input) {
            mode = .decode
        } else {
            mode = .encode
        }
    }
}
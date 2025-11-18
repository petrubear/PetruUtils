import SwiftUI
import Combine

struct Base32View: View {
    @StateObject private var vm = Base32ViewModel()
    
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
            Picker("", selection: $vm.mode) {
                Text("Encode").tag(Base32ViewModel.Mode.encode)
                Text("Decode").tag(Base32ViewModel.Mode.decode)
            }
            .pickerStyle(.segmented)
            .frame(width: 160)
            .labelsHidden()
            
            Picker("", selection: $vm.variant) {
                Text("Standard").tag(Base32Service.Variant.standard)
                Text("Hex").tag(Base32Service.Variant.hex)
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .labelsHidden()
            
            Spacer()
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(vm.mode == .encode ? "Text" : "Base32")
                    .font(.headline)
                Spacer()
                Text("\(vm.input.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding([.horizontal, .top], 8)
            
            FocusableTextEditor(text: $vm.input)
                .font(.custom("JetBrains Mono", size: 12))
                .onChange(of: vm.input) {
                    vm.process()
                }
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(vm.mode == .encode ? "Base32" : "Text")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !vm.output.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding([.horizontal, .top], 8)
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
            }
            
            ScrollView {
                Text(vm.output)
                    .font(.custom("JetBrains Mono", size: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding([.horizontal, .bottom], 8)
        }
    }
}

@MainActor
final class Base32ViewModel: ObservableObject {
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
    
    private let service = Base32Service()
    
    func process() {
        errorMessage = nil
        
        guard !input.isEmpty else {
            output = ""
            return
        }
        
        do {
            switch mode {
            case .encode:
                output = try service.encode(input, variant: variant)
            case .decode:
                output = try service.decode(input, variant: variant)
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
    }
}

#Preview {
    Base32View()
        .frame(width: 800, height: 600)
}

import SwiftUI
import Combine

struct Base64View: View {
    @StateObject private var vm = Base64ViewModel()
    
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
            Picker("Mode", selection: $vm.mode) {
                Text("Encode").tag(Base64Mode.encode)
                Text("Decode").tag(Base64Mode.decode)
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            
            Picker("Variant", selection: $vm.variant) {
                Text("Standard").tag(Base64Service.Base64Variant.standard)
                Text("URL-Safe").tag(Base64Service.Base64Variant.urlSafe)
            }
            .pickerStyle(.menu)
            
            Spacer()
            
            Button("Process") { vm.process() }
                .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
            
            Button("Copy Output") { vm.copyOutput() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(vm.output.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.mode == .encode ? "Input Text" : "Base64 Input")
                .font(.headline)
            
            FocusableTextEditor(text: $vm.input)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .background(.background)
            
            HStack {
                if !vm.input.isEmpty {
                    Text("\(vm.input.count) characters")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .textSelection(.enabled)
                }
            }
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.mode == .encode ? "Base64 Output" : "Decoded Text")
                .font(.headline)
            
            CodeBlock(text: vm.output)
            
            HStack {
                if !vm.output.isEmpty {
                    if vm.mode == .encode {
                        Text("\(vm.output.count) characters")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        Text("\(vm.output.count) characters")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                if vm.isValidBase64 && vm.mode == .decode {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Valid Base64")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - ViewModel

@MainActor
final class Base64ViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: Base64Mode = .encode
    @Published var variant: Base64Service.Base64Variant = .standard
    @Published var errorMessage: String?
    @Published var isValidBase64: Bool = false
    
    private let service = Base64Service()
    
    func process() {
        errorMessage = nil
        output = ""
        isValidBase64 = false
        
        guard !input.isEmpty else {
            errorMessage = "Input cannot be empty"
            return
        }
        
        do {
            switch mode {
            case .encode:
                output = try service.encodeText(input, variant: variant)
            case .decode:
                output = try service.decodeText(input, variant: variant)
                isValidBase64 = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValidBase64 = false
    }
    
    func copyOutput() {
        guard !output.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}

// MARK: - Types

enum Base64Mode {
    case encode
    case decode
}

// MARK: - Preview


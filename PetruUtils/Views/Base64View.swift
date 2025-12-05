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
            Text("Base64 Converter")
                .font(.headline)
            
            Spacer()
            
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
            
            Button("Process") { vm.process() }
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
                sectionHeader(icon: vm.mode == .encode ? "text.alignleft" : "textformat.123", 
                              title: vm.mode == .encode ? "Input Text" : "Base64 Input", 
                              color: .blue)
                
                FocusableTextEditor(text: $vm.input)
                    .frame(minHeight: 200)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .font(.system(.body, design: .monospaced))
                    .background(.background)
                
                HStack {
                    if !vm.input.isEmpty {
                        Text("\(vm.input.count) characters")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }

                    Spacer()
                }

                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // Help text
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
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(vm.mode == .encode ? "Base64 Output" : "Decoded Text")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Button("Copy") { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !vm.output.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                             sectionHeader(icon: vm.mode == .encode ? "textformat.123" : "text.alignleft", 
                                          title: "Result", 
                                          color: .green)
                            
                            CodeBlock(text: vm.output)
                            
                            HStack {
                                Text("\(vm.output.count) characters")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                
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
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: vm.mode == .encode ? "textformat.123" : "text.alignleft")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text(vm.mode == .encode ? "Enter text to encode" : "Enter Base64 to decode")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding()
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
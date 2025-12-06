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
            Text("Base32 Converter")
                .font(.headline)
            
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: vm.mode == .encode ? "text.quote" : "textformat.123", 
                              title: vm.mode == .encode ? "Input Text" : "Input Base32", 
                              color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: vm.input) { _, _ in
                            vm.process()
                        }
                    
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
                
                // Help text
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
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(vm.mode == .encode ? "Output Base32" : "Output Text")
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
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
            }
            
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
                    Image(systemName: vm.mode == .encode ? "textformat.123" : "text.quote")
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
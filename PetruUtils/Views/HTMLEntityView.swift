import SwiftUI
import Combine

struct HTMLEntityView: View {
    @StateObject private var vm = HTMLEntityViewModel()
    
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
            Text("HTML Entity Encoder")
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
                sectionHeader(icon: vm.mode == .encode ? "text.quote" : "chevron.left.forwardslash.chevron.right", 
                              title: vm.mode == .encode ? "Input Text" : "Input HTML Entities", 
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
                            Text("Encode").tag(HTMLEntityViewModel.Mode.encode)
                            Text("Decode").tag(HTMLEntityViewModel.Mode.decode)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                        .labelsHidden()
                    }
                    
                    if vm.mode == .encode {
                        Divider()
                        
                        HStack {
                            Text("Entity Type")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $vm.entityType) {
                                Text("Named (&amp;)").tag(HTMLEntityViewModel.EntityType.named)
                                Text("Decimal (&#38;)").tag(HTMLEntityViewModel.EntityType.decimal)
                                Text("Hex (&#x26;)").tag(HTMLEntityViewModel.EntityType.hex)
                            }
                            .pickerStyle(.menu)
                            .frame(width: 160)
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
                    if vm.mode == .encode {
                        Text("<div> → &lt;div&gt;")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(4)
                    } else {
                        Text("&amp; → &")
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
                Text(vm.mode == .encode ? "Encoded Output" : "Decoded Output")
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
                    Image(systemName: vm.mode == .encode ? "chevron.left.forwardslash.chevron.right" : "text.quote")
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
final class HTMLEntityViewModel: ObservableObject {
    enum Mode {
        case encode
        case decode
    }
    
    enum EntityType {
        case named
        case decimal
        case hex
    }
    
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var errorMessage: String?
    @Published var mode: Mode = .encode
    @Published var entityType: EntityType = .named
    
    private let service = HTMLEntityService()
    
    func convert() {
        errorMessage = nil
        guard !input.isEmpty else {
            output = ""
            return
        }
        
        switch mode {
        case .encode:
            switch entityType {
            case .named:
                output = service.encode(input, useNamedEntities: true, useNumericEntities: false)
            case .decimal:
                output = service.encode(input, useNamedEntities: false, useNumericEntities: true)
            case .hex:
                output = service.encodeToHex(input)
            }
        case .decode:
            output = service.decode(input)
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
    }
}
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
            Text("HTML Entity Encoder/Decoder")
                .font(.headline)
            
            Spacer()
            
            Picker("", selection: $vm.mode) {
                Text("Encode").tag(HTMLEntityViewModel.Mode.encode)
                Text("Decode").tag(HTMLEntityViewModel.Mode.decode)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
            .labelsHidden()
            
            if vm.mode == .encode {
                Picker("", selection: $vm.entityType) {
                    Text("Named").tag(HTMLEntityViewModel.EntityType.named)
                    Text("Decimal").tag(HTMLEntityViewModel.EntityType.decimal)
                    Text("Hex").tag(HTMLEntityViewModel.EntityType.hex)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                .labelsHidden()
            }
            
            Button("Convert") { vm.convert() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Input")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(vm.input.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            FocusableTextEditor(text: $vm.input)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Output")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(vm.output.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !vm.output.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
            
            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            ScrollView {
                Text(vm.output.isEmpty ? "Converted text will appear here" : vm.output)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(vm.output.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .padding()
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

#Preview {
    HTMLEntityView()
}

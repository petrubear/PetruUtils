import SwiftUI
import Combine

struct NumberBaseView: View {
    @StateObject private var vm = NumberBaseViewModel()
    
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
            Text("Number Base Converter")
                .font(.headline)
            
            Spacer()
            
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
            
            Button("Copy All") { vm.copyAll() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Input")
                .font(.headline)
            
            // Binary Input
            inputField(
                title: "Binary (Base 2)",
                placeholder: "e.g., 101010",
                text: $vm.binaryInput,
                iconName: "01.square",
                onCommit: { vm.convertFromBinary() }
            )
            
            // Octal Input
            inputField(
                title: "Octal (Base 8)",
                placeholder: "e.g., 52",
                text: $vm.octalInput,
                iconName: "8.square",
                onCommit: { vm.convertFromOctal() }
            )
            
            // Decimal Input
            inputField(
                title: "Decimal (Base 10)",
                placeholder: "e.g., 42",
                text: $vm.decimalInput,
                iconName: "number.square",
                onCommit: { vm.convertFromDecimal() }
            )
            
            // Hexadecimal Input
            inputField(
                title: "Hexadecimal (Base 16)",
                placeholder: "e.g., 2A",
                text: $vm.hexInput,
                iconName: "x.square",
                onCommit: { vm.convertFromHex() }
            )
            
            // Error display
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
            
            Spacer()
        }
        .padding()
    }
    
    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Output")
                    .font(.headline)
                
                if vm.hasResult {
                    // Conversion Results
                    resultSection(title: "Binary", value: vm.result?.binary ?? "", icon: "01.square")
                    resultSection(title: "Octal", value: vm.result?.octal ?? "", icon: "8.square")
                    resultSection(title: "Decimal", value: vm.result?.decimalString ?? "", icon: "number.square")
                    resultSection(title: "Hexadecimal", value: vm.result?.hex ?? "", icon: "x.square")
                    
                    Divider()
                    
                    // Bit Representation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "square.grid.3x3")
                                .foregroundStyle(.blue)
                            Text("64-Bit Representation")
                                .font(.subheadline.weight(.semibold))
                        }
                        
                        Text(vm.result?.bitRepresentation ?? "")
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // Byte Representation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cube")
                                .foregroundStyle(.purple)
                            Text("Byte Representation")
                                .font(.subheadline.weight(.semibold))
                        }
                        
                        Text(vm.result?.byteRepresentation ?? "")
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                    }
                    
                    // Sign indicator
                    if vm.result?.isSigned == true {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text("Negative number (two's complement)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "function")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter a number in any base")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Press Return to convert")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func inputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        iconName: String,
        onCommit: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            
            TextField(placeholder, text: text, onCommit: onCommit)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
        }
    }
    
    @ViewBuilder
    private func resultSection(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.green)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                
                Spacer()
                
                Button(action: { vm.copyValue(value) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Copy \(title)")
            }
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.05))
                .cornerRadius(6)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class NumberBaseViewModel: ObservableObject {
    @Published var binaryInput: String = ""
    @Published var octalInput: String = ""
    @Published var decimalInput: String = ""
    @Published var hexInput: String = ""
    
    @Published var result: NumberBaseService.ConversionResult?
    @Published var errorMessage: String?
    
    private let service = NumberBaseService()
    
    var hasResult: Bool {
        result != nil
    }
    
    func convertFromBinary() {
        guard !binaryInput.isEmpty else {
            clear()
            return
        }
        
        errorMessage = nil
        
        do {
            result = try service.convertFromBinary(binaryInput)
            updateInputFields(skipBinary: true)
        } catch {
            errorMessage = error.localizedDescription
            result = nil
        }
    }
    
    func convertFromOctal() {
        guard !octalInput.isEmpty else {
            clear()
            return
        }
        
        errorMessage = nil
        
        do {
            result = try service.convertFromOctal(octalInput)
            updateInputFields(skipOctal: true)
        } catch {
            errorMessage = error.localizedDescription
            result = nil
        }
    }
    
    func convertFromDecimal() {
        guard !decimalInput.isEmpty else {
            clear()
            return
        }
        
        errorMessage = nil
        
        do {
            result = try service.convertFromDecimal(decimalInput)
            updateInputFields(skipDecimal: true)
        } catch {
            errorMessage = error.localizedDescription
            result = nil
        }
    }
    
    func convertFromHex() {
        guard !hexInput.isEmpty else {
            clear()
            return
        }
        
        errorMessage = nil
        
        do {
            result = try service.convertFromHex(hexInput)
            updateInputFields(skipHex: true)
        } catch {
            errorMessage = error.localizedDescription
            result = nil
        }
    }
    
    private func updateInputFields(
        skipBinary: Bool = false,
        skipOctal: Bool = false,
        skipDecimal: Bool = false,
        skipHex: Bool = false
    ) {
        guard let result = result else { return }
        
        if !skipBinary {
            binaryInput = result.binary
        }
        if !skipOctal {
            octalInput = result.octal
        }
        if !skipDecimal {
            decimalInput = result.decimalString
        }
        if !skipHex {
            hexInput = result.hex
        }
    }
    
    func clear() {
        binaryInput = ""
        octalInput = ""
        decimalInput = ""
        hexInput = ""
        result = nil
        errorMessage = nil
    }
    
    func copyValue(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
    
    func copyAll() {
        guard let result = result else { return }
        
        let output = """
        Binary: \(result.binary)
        Octal: \(result.octal)
        Decimal: \(result.decimalString)
        Hexadecimal: \(result.hex)
        
        64-Bit: \(result.bitRepresentation)
        Bytes: \(result.byteRepresentation)
        """
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}

// MARK: - Preview


import SwiftUI
import Combine
import UniformTypeIdentifiers

struct QRCodeView: View {
    @StateObject private var vm = QRCodeViewModel()
    
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
        HStack(spacing: 16) {
            Picker("Error Correction", selection: $vm.errorCorrection) {
                ForEach(QRCodeService.ErrorCorrectionLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
            .help(vm.errorCorrection.description)
            
            Stepper("Size: \(Int(vm.size))px", value: $vm.size, in: 128...2048, step: 128)
                .frame(width: 180)
            
            Spacer()
            
            Button("Generate") {
                vm.generate()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(vm.input.isEmpty)
            
            Button("Export...") {
                vm.export()
            }
            .keyboardShortcut("e", modifiers: [.command])
            .disabled(vm.qrImage == nil)
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content to Encode")
                .font(.headline)
            
            FocusableTextEditor(text: $vm.input)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .background(.background)
            
            HStack {
                if !vm.input.isEmpty {
                    let charCount = vm.input.count
                    let capacity = vm.service.estimatedCapacity(for: vm.errorCorrection)
                    let percentage = Double(charCount) / Double(capacity) * 100
                    
                    HStack(spacing: 8) {
                        Text("\(charCount) / \(capacity) characters")
                            .foregroundStyle(charCount > capacity ? .red : .secondary)
                            .font(.caption)
                        
                        ProgressView(value: min(Double(charCount), Double(capacity)), total: Double(capacity))
                            .frame(width: 100)
                            .tint(percentage > 80 ? .orange : .blue)
                    }
                }
                
                Spacer()
                
                if let error = vm.errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.orange)
                            .font(.callout)
                    }
                }
            }
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(spacing: 12) {
            HStack {
                Text("QR Code")
                    .font(.headline)
                
                Spacer()
                
                // Color pickers
                ColorPicker("Foreground", selection: $vm.foregroundColor)
                    .labelsHidden()
                    .help("Foreground color")
                    .onChange(of: vm.foregroundColor) { _, _ in
                        if vm.qrImage != nil {
                            vm.generate()
                        }
                    }
                
                ColorPicker("Background", selection: $vm.backgroundColor)
                    .labelsHidden()
                    .help("Background color")
                    .onChange(of: vm.backgroundColor) { _, _ in
                        if vm.qrImage != nil {
                            vm.generate()
                        }
                    }
                
                Button(action: {
                    vm.foregroundColor = .black
                    vm.backgroundColor = .white
                    if vm.qrImage != nil {
                        vm.generate()
                    }
                }) {
                    Text("Reset Colors")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            if let image = vm.qrImage {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 512, maxHeight: 512)
                    .background(vm.backgroundColor)
                    .cornerRadius(8)
                    .shadow(radius: 2)
                
                HStack(spacing: 16) {
                    Button(action: vm.copyImage) {
                        Label("Copy Image", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    
                    Button(action: vm.export) {
                        Label("Export PNG...", systemImage: "square.and.arrow.up")
                    }
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    
                    Text("Enter content and click Generate")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding()
    }
}

// MARK: - ViewModel

@MainActor
final class QRCodeViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var qrImage: NSImage?
    @Published var size: CGFloat = 512
    @Published var errorCorrection: QRCodeService.ErrorCorrectionLevel = .medium
    @Published var foregroundColor: Color = .black
    @Published var backgroundColor: Color = .white
    @Published var errorMessage: String?
    
    let service = QRCodeService()
    
    func generate() {
        errorMessage = nil
        
        guard !input.isEmpty else {
            errorMessage = "Content cannot be empty"
            qrImage = nil
            return
        }
        
        do {
            let fg = convertColor(foregroundColor)
            let bg = convertColor(backgroundColor)
            
            qrImage = try service.generateQRCode(
                from: input,
                size: size,
                errorCorrection: errorCorrection,
                foregroundColor: fg,
                backgroundColor: bg
            )
        } catch {
            errorMessage = error.localizedDescription
            qrImage = nil
        }
    }
    
    func clear() {
        input = ""
        qrImage = nil
        errorMessage = nil
    }
    
    func copyImage() {
        guard let image = qrImage else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }
    
    func export() {
        guard let image = qrImage else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "qrcode.png"
        savePanel.title = "Export QR Code"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            do {
                try self.service.exportToFile(image, to: url)
            } catch {
                self.errorMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Color Extensions

extension QRCodeViewModel {
    /// Converts SwiftUI Color to NSColor (supports system colors only for safety)
    func convertColor(_ color: Color) -> NSColor {
        // For now, only support system colors to avoid hanging
        // Custom colors from ColorPicker will fallback to black
        if color == .black { return .black }
        if color == .white { return .white }
        if color == .red { return .red }
        if color == .blue { return .blue }
        if color == .green { return .green }
        if color == .yellow { return .yellow }
        if color == .orange { return .orange }
        if color == .purple { return .purple }
        if color == .pink { return .systemPink }
        if color == .gray { return .gray }
        if color == .clear { return .clear }
        if color == .brown { return .brown }
        if color == .cyan { return .cyan }
        if color == .indigo { return .systemIndigo }
        if color == .mint { return .systemMint }
        if color == .teal { return .systemTeal }
        
        // For custom colors, default to black
        // This prevents hanging while we work on a proper solution
        return .black
    }
}

// MARK: - Preview

#Preview {
    QRCodeView()
}

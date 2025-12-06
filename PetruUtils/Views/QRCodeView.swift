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
            Text("QR Code Generator")
                .font(.headline)
            
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "text.quote", title: "Content", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 150)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
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
                    }
                }
                
                Divider()
                
                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Error Correction
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Error Correction")
                            .font(.subheadline.weight(.medium))
                        Picker("", selection: $vm.errorCorrection) {
                            ForEach(QRCodeService.ErrorCorrectionLevel.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                        
                        Text(vm.errorCorrection.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    // Size
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Size: \(Int(vm.size))px")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                        Slider(value: $vm.size, in: 128...2048, step: 128)
                    }
                    
                    Divider()
                    
                    // Colors
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Foreground")
                                .font(.subheadline.weight(.medium))
                            ColorPicker("", selection: $vm.foregroundColor)
                                .labelsHidden()
                                .onChange(of: vm.foregroundColor) { _, _ in
                                    if vm.qrImage != nil { vm.generate() }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Background")
                                .font(.subheadline.weight(.medium))
                            ColorPicker("", selection: $vm.backgroundColor)
                                .labelsHidden()
                                .onChange(of: vm.backgroundColor) { _, _ in
                                    if vm.qrImage != nil { vm.generate() }
                                }
                        }
                        
                        Spacer()
                        
                        Button("Reset Colors") {
                            vm.foregroundColor = .black
                            vm.backgroundColor = .white
                            if vm.qrImage != nil { vm.generate() }
                        }
                        .font(.caption)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)

                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Examples")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("URL: https://example.com")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("WiFi: WIFI:T:WPA;S:NetworkName;P:password;;")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                Text("Preview")
                    .font(.headline)
                Spacer()
                if vm.qrImage != nil {
                    Button(action: vm.copyImage) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    
                    Button(action: vm.export) {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.caption)
                    }
                }
            }
            .padding()
            
            Divider()
            
            ZStack {
                Color(nsColor: .controlBackgroundColor)
                
                if let image = vm.qrImage {
                    VStack {
                        Image(nsImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 400, maxHeight: 400)
                            .background(vm.backgroundColor)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .padding()
                        
                        Text("\(Int(vm.size)) x \(Int(vm.size)) px")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 64))
                            .foregroundStyle(.secondary)
                        
                        Text("Enter content and click Generate")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
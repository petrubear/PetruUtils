import SwiftUI
import Combine

struct ColorConverterView: View {
    @StateObject private var vm = ColorConverterViewModel()
    
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
            Text("Color Converter")
                .font(.headline)
            Spacer()
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "paintpalette", title: "Input", color: .blue)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Color Picker
                    HStack {
                        ColorPicker("Pick a Color", selection: $vm.pickedColor)
                            .onChange(of: vm.pickedColor) { _, _ in vm.convertFromPicker() }
                            .labelsHidden()
                        Text("Pick a color from picker")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // HEX Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("HEX")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("#FF5733", text: $vm.hexInput, onCommit: { vm.convertFromHex() })
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    // RGB Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("RGB")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("255, 87, 51", text: $vm.rgbInput, onCommit: { vm.convertFromRGB() })
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Examples")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HEX: #FF5733, #F00, FF5733")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("RGB: 255, 87, 51 or rgb(255, 87, 51)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(4)
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let result = vm.result {
                    // Color Preview
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "eye", title: "Preview", color: .orange)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(result.color)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(radius: 2)
                    }
                    
                    Divider()
                    
                    // Color Formats
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "list.bullet", title: "Formats", color: .purple)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            colorRow(title: "HEX", value: result.hex, icon: "number")
                            Divider()
                            colorRow(title: "RGB", value: result.rgb.toString(), icon: "circle.hexagongrid")
                            Divider()
                            colorRow(title: "HSL", value: result.hsl.toString(), icon: "paintpalette")
                            Divider()
                            colorRow(title: "HSV", value: result.hsv.toString(), icon: "dial.min")
                            Divider()
                            colorRow(title: "CMYK", value: result.cmyk.toString(), icon: "printer")
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "paintpalette")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Pick or enter a color")
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
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }
    
    @ViewBuilder
    private func colorRow(title: String, value: String, icon: String) -> some View {
        HStack {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.purple)
                    .frame(width: 16)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { vm.copyValue(value) }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

@MainActor
final class ColorConverterViewModel: ObservableObject {
    @Published var pickedColor: Color = .blue
    @Published var hexInput: String = ""
    @Published var rgbInput: String = ""
    @Published var result: ColorConverterService.ConversionResult?
    @Published var errorMessage: String?
    
    private let service = ColorConverterService()
    
    func convertFromPicker() {
        errorMessage = nil
        result = service.convertFromColor(pickedColor)
        hexInput = result!.hex
        rgbInput = result!.rgb.toString()
    }
    
    func convertFromHex() {
        guard !hexInput.isEmpty else { return }
        errorMessage = nil
        do {
            result = try service.convertFromHex(hexInput)
            pickedColor = result!.color
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func convertFromRGB() {
        guard !rgbInput.isEmpty else { return }
        errorMessage = nil
        do {
            result = try service.convertFromRGB(rgbInput)
            pickedColor = result!.color
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        hexInput = ""
        rgbInput = ""
        result = nil
        errorMessage = nil
        pickedColor = .blue
    }
    
    func copyValue(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
}
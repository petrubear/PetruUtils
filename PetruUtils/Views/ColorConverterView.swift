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
        VStack(alignment: .leading, spacing: 16) {
            Text("Input")
                .font(.headline)
            
            ColorPicker("Pick a Color", selection: $vm.pickedColor)
                .onChange(of: vm.pickedColor) { _, _ in vm.convertFromPicker() }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("HEX")
                    .font(.subheadline.weight(.semibold))
                TextField("#FF5733", text: $vm.hexInput, onCommit: { vm.convertFromHex() })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("RGB")
                    .font(.subheadline.weight(.semibold))
                TextField("255, 87, 51", text: $vm.rgbInput, onCommit: { vm.convertFromRGB() })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
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
                
                if let result = vm.result {
                    // Color Preview
                    RoundedRectangle(cornerRadius: 12)
                        .fill(result.color)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                    
                    Divider()
                    
                    colorRow(title: "HEX", value: result.hex, icon: "number")
                    colorRow(title: "RGB", value: result.rgb.toString(), icon: "circle.hexagongrid")
                    colorRow(title: "HSL", value: result.hsl.toString(), icon: "paintpalette")
                    colorRow(title: "HSV", value: result.hsv.toString(), icon: "eye")
                    colorRow(title: "CMYK", value: result.cmyk.toString(), icon: "printer")
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
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func colorRow(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.purple)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(action: { vm.copyValue(value) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
        }
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


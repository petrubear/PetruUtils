import SwiftUI
import Combine

struct UnixTimestampView: View {
    @StateObject private var vm = UnixTimestampViewModel()
    
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
            Text("Unix Timestamp Converter")
                .font(.headline)
            
            Spacer()
            
            Picker("Timezone", selection: $vm.selectedTimezone) {
                ForEach(UnixTimestampService.commonTimezones, id: \.identifier) { tz in
                    Text(UnixTimestampService.timezoneName(tz)).tag(tz)
                }
            }
            .frame(width: 200)
            
            Button("Now") { vm.useCurrentTimestamp() }
            
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
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Unix Timestamp")
                    .font(.subheadline.weight(.semibold))
                TextField("e.g., 1704067200 or 1704067200000", text: $vm.input, onCommit: { vm.convert() })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                Text("Auto-detects seconds or milliseconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    VStack(alignment: .leading, spacing: 12) {
                        resultRow(title: "Timestamp (seconds)", value: String(result.timestamp), icon: "clock")
                        resultRow(title: "Timestamp (milliseconds)", value: String(result.timestampMilliseconds), icon: "clock.fill")
                        
                        Divider()
                        
                        resultRow(title: "ISO 8601", value: result.iso8601, icon: "calendar")
                        resultRow(title: "RFC 2822", value: result.rfc2822, icon: "envelope")
                        resultRow(title: "Full", value: result.full, icon: "textformat")
                        resultRow(title: "Long", value: result.long, icon: "textformat")
                        resultRow(title: "Medium", value: result.medium, icon: "textformat")
                        resultRow(title: "Short", value: result.short, icon: "textformat")
                        resultRow(title: "Custom", value: result.custom, icon: "textformat")
                        
                        Divider()
                        
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.blue)
                            Text("Relative Time")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(result.relativeTime)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter a Unix timestamp")
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
    private func resultRow(title: String, value: String, icon: String) -> some View {
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
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class UnixTimestampViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var result: UnixTimestampService.ConversionResult?
    @Published var errorMessage: String?
    @Published var selectedTimezone: TimeZone = .current
    
    private let service = UnixTimestampService()
    
    func convert() {
        guard !input.isEmpty else {
            clear()
            return
        }
        
        errorMessage = nil
        
        do {
            result = try service.convert(input, timezone: selectedTimezone)
        } catch {
            errorMessage = error.localizedDescription
            result = nil
        }
    }
    
    func useCurrentTimestamp() {
        result = service.convertCurrent(timezone: selectedTimezone)
        input = String(result!.timestamp)
    }
    
    func clear() {
        input = ""
        result = nil
        errorMessage = nil
    }
    
    func copyValue(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }
}

// MARK: - Preview


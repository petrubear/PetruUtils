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
        HStack(spacing: 12) {
            Text("Unix Timestamp")
                .font(.headline)
            
            Spacer()
            
            Picker("Timezone", selection: $vm.selectedTimezone) {
                ForEach(UnixTimestampService.commonTimezones, id: \.identifier) { tz in
                    Text(UnixTimestampService.timezoneName(tz)).tag(tz)
                }
            }
            .frame(width: 220)
            .pickerStyle(.menu)
            
            Button("Now") { vm.useCurrentTimestamp() }
            
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "clock.arrow.circlepath", title: "Input", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unix Timestamp")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., 1704067200 or 1704067200000", text: $vm.input, onCommit: { vm.convert() })
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    Text("Auto-detects seconds or milliseconds")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
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
                        Text("Seconds: 1704067200 (Jan 1, 2024)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Milliseconds: 1704067200000")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let result = vm.result {
                    // Timestamps
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "number", title: "Timestamps", color: .purple)
                        
                        VStack(alignment: .leading, spacing: 8) {
                             resultRow(title: "Seconds", value: String(result.timestamp), icon: "clock")
                             Divider()
                             resultRow(title: "Milliseconds", value: String(result.timestampMilliseconds), icon: "clock.fill")
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // Date Formats
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "calendar", title: "Date Formats", color: .orange)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            resultRow(title: "ISO 8601", value: result.iso8601, icon: "globe")
                            Divider()
                            resultRow(title: "RFC 2822", value: result.rfc2822, icon: "envelope")
                            Divider()
                            resultRow(title: "Full Date", value: result.full, icon: "calendar.badge.clock")
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    // Relative Time
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "hourglass", title: "Relative Time", color: .green)
                        
                        HStack {
                            Text(result.relativeTime)
                                .font(.system(.title3, design: .rounded).weight(.medium))
                                .padding()
                            Spacer()
                        }
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Other Formats
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "text.alignleft", title: "Other Styles", color: .gray)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            resultRow(title: "Long", value: result.long, icon: "text.quote")
                            Divider()
                            resultRow(title: "Medium", value: result.medium, icon: "text.quote")
                            Divider()
                            resultRow(title: "Short", value: result.short, icon: "text.quote")
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter a timestamp to convert")
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
    private func resultRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            Button(action: { vm.copyValue(value) }) {
                Image(systemName: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("Copy \(title)")
        }
        .padding(.vertical, 2)
    }
}

// MARK: - ViewModel (Unchanged)

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
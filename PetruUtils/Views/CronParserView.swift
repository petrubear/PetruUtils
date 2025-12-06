import SwiftUI
import Combine

struct CronParserView: View {
    @StateObject private var vm = CronParserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            content
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("Cron Parser")
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
    
    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Input section
                sectionHeader(icon: "clock.arrow.circlepath", title: "Cron Expression", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("e.g., */5 * * * *", text: $vm.input)
                        .font(.system(.body, design: .monospaced))
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: vm.input) { _, _ in
                            vm.parse()
                        }
                    
                    Text("Format: minute hour day month weekday")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let error = vm.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
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
                        Text("Examples")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("*/5 * * * * (every 5 minutes)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("0 9 * * 1-5 (9 AM weekdays)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 20)
                }
                
                if let cron = vm.parsedExpression {
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "text.alignleft", title: "Description", color: .purple)
                        
                        Text(cron.description)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(8)
                    }
                    
                    // Fields breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(icon: "tablecells", title: "Fields", color: .orange)
                        
                        HStack(spacing: 12) {
                            fieldView(label: "Minute", value: cron.minute)
                            fieldView(label: "Hour", value: cron.hour)
                            fieldView(label: "Day", value: cron.dayOfMonth)
                            fieldView(label: "Month", value: cron.month)
                            fieldView(label: "Weekday", value: cron.dayOfWeek)
                        }
                    }
                    
                    // Next executions
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            sectionHeader(icon: "calendar", title: "Next 10 Executions", color: .green)
                            
                            Spacer()
                            
                            Picker("", selection: $vm.selectedTimezone) {
                                ForEach(vm.availableTimezones, id: \.self) { tz in
                                    Text(tz.identifier).tag(tz)
                                }
                            }
                            .frame(width: 200)
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(vm.nextExecutions.enumerated()), id: \.offset) { index, date in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .trailing)
                                    
                                    Text(vm.formatDate(date))
                                        .font(.system(.body, design: .monospaced))
                                }
                                .padding(.vertical, 6)
                                .padding(.horizontal, 8)
                                .background(index % 2 == 0 ? Color.secondary.opacity(0.02) : Color.clear)
                            }
                        }
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
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
    
    private func fieldView(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
final class CronParserViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var parsedExpression: CronService.CronExpression?
    @Published var nextExecutions: [Date] = []
    @Published var errorMessage: String?
    @Published var selectedTimezone: TimeZone = .current {
        didSet {
            parse()
        }
    }
    
    let availableTimezones: [TimeZone] = [
        TimeZone.current,
        TimeZone(identifier: "UTC")!,
        TimeZone(identifier: "America/New_York")!,
        TimeZone(identifier: "America/Los_Angeles")!,
        TimeZone(identifier: "America/Chicago")!,
        TimeZone(identifier: "Europe/London")!,
        TimeZone(identifier: "Europe/Paris")!,
        TimeZone(identifier: "Asia/Tokyo")!,
        TimeZone(identifier: "Asia/Shanghai")!,
        TimeZone(identifier: "Australia/Sydney")!
    ]
    
    private let service = CronService()
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    func parse() {
        errorMessage = nil
        parsedExpression = nil
        nextExecutions = []
        
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        do {
            let expression = try service.parse(input)
            parsedExpression = expression
            
            nextExecutions = try service.getNextExecutions(input, count: 10, timezone: selectedTimezone)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func formatDate(_ date: Date) -> String {
        dateFormatter.timeZone = selectedTimezone
        return dateFormatter.string(from: date)
    }
    
    func clear() {
        input = ""
        parsedExpression = nil
        nextExecutions = []
        errorMessage = nil
    }
}
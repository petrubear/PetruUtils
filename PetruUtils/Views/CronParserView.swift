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
            Text("Cron Expression Parser")
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
        VStack(spacing: 16) {
            // Input section
            VStack(alignment: .leading, spacing: 8) {
                Text("Cron Expression")
                    .font(.headline)
                
                TextField("e.g., */5 * * * *", text: $vm.input)
                    .font(.custom("JetBrains Mono", size: 14))
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: vm.input) {
                        vm.parse()
                    }
                
                Text("Format: minute hour day month weekday")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Examples:")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Text("*/5 * * * * (every 5 minutes)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("0 9 * * 1-5 (9 AM weekdays)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding()
            
            if let cron = vm.parsedExpression {
                Divider()
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    Text(cron.description)
                        .font(.body)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Fields breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cron Fields")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        fieldView(label: "Minute", value: cron.minute)
                        fieldView(label: "Hour", value: cron.hour)
                        fieldView(label: "Day", value: cron.dayOfMonth)
                        fieldView(label: "Month", value: cron.month)
                        fieldView(label: "Weekday", value: cron.dayOfWeek)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Next executions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Next 10 Executions")
                            .font(.headline)
                        
                        Spacer()
                        
                        Picker("", selection: $vm.selectedTimezone) {
                            ForEach(vm.availableTimezones, id: \.self) { tz in
                                Text(tz.identifier).tag(tz)
                            }
                        }
                        .frame(width: 200)
                        .labelsHidden()
                    }
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(vm.nextExecutions.enumerated()), id: \.offset) { index, date in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.custom("JetBrains Mono", size: 12))
                                        .foregroundColor(.secondary)
                                        .frame(width: 30, alignment: .trailing)
                                    
                                    Text(vm.formatDate(date))
                                        .font(.custom("JetBrains Mono", size: 12))
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    private func fieldView(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.custom("JetBrains Mono", size: 13))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
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


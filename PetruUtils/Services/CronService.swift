import Foundation

struct CronService {
    enum CronError: LocalizedError {
        case invalidFormat
        case invalidField(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid cron format. Expected: minute hour day month weekday"
            case .invalidField(let field):
                return "Invalid \(field) field"
            }
        }
    }
    
    struct CronExpression {
        let minute: String
        let hour: String
        let dayOfMonth: String
        let month: String
        let dayOfWeek: String
        let description: String
        
        var parts: [String] {
            [minute, hour, dayOfMonth, month, dayOfWeek]
        }
    }
    
    func parse(_ expression: String) throws -> CronExpression {
        let parts = expression.split(separator: " ").map(String.init)
        
        guard parts.count == 5 else {
            throw CronError.invalidFormat
        }
        
        let minute = parts[0]
        let hour = parts[1]
        let dayOfMonth = parts[2]
        let month = parts[3]
        let dayOfWeek = parts[4]
        
        let description = try generateDescription(
            minute: minute,
            hour: hour,
            dayOfMonth: dayOfMonth,
            month: month,
            dayOfWeek: dayOfWeek
        )
        
        return CronExpression(
            minute: minute,
            hour: hour,
            dayOfMonth: dayOfMonth,
            month: month,
            dayOfWeek: dayOfWeek,
            description: description
        )
    }
    
    func getNextExecutions(_ expression: String, count: Int = 10, timezone: TimeZone = .current) throws -> [Date] {
        let cron = try parse(expression)
        var dates: [Date] = []
        var currentDate = Date()
        
        while dates.count < count {
            if let nextDate = findNextExecution(from: currentDate, cron: cron, timezone: timezone) {
                dates.append(nextDate)
                currentDate = nextDate.addingTimeInterval(60) // Move to next minute
            } else {
                break
            }
        }
        
        return dates
    }
    
    private func findNextExecution(from date: Date, cron: CronExpression, timezone: TimeZone) -> Date? {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        // Try next 365 days to find a match
        for _ in 0..<525600 { // 365 days * 24 hours * 60 minutes
            guard let checkDate = calendar.date(from: components) else { return nil }
            
            if matches(date: checkDate, cron: cron, calendar: calendar) {
                return checkDate
            }
            
            // Move to next minute
            components.minute? += 1
            if let normalized = calendar.date(from: components) {
                components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: normalized)
            }
        }
        
        return nil
    }
    
    private func matches(date: Date, cron: CronExpression, calendar: Calendar) -> Bool {
        let components = calendar.dateComponents([.minute, .hour, .day, .month, .weekday], from: date)
        
        guard let minute = components.minute,
              let hour = components.hour,
              let day = components.day,
              let month = components.month,
              let weekday = components.weekday else {
            return false
        }
        
        // Convert Sunday (1) to 0 for cron compatibility
        let cronWeekday = weekday == 1 ? 0 : weekday - 1
        
        return matchesField(cron.minute, value: minute, range: 0...59) &&
               matchesField(cron.hour, value: hour, range: 0...23) &&
               matchesField(cron.dayOfMonth, value: day, range: 1...31) &&
               matchesField(cron.month, value: month, range: 1...12) &&
               matchesField(cron.dayOfWeek, value: cronWeekday, range: 0...6)
    }
    
    private func matchesField(_ field: String, value: Int, range: ClosedRange<Int>) -> Bool {
        if field == "*" { return true }
        
        // Handle lists (e.g., "1,3,5")
        if field.contains(",") {
            let values = field.split(separator: ",").compactMap { Int($0) }
            return values.contains(value)
        }
        
        // Handle ranges (e.g., "1-5")
        if field.contains("-") {
            let parts = field.split(separator: "-").compactMap { Int($0) }
            if parts.count == 2 {
                return value >= parts[0] && value <= parts[1]
            }
        }
        
        // Handle steps (e.g., "*/5" or "0-30/5")
        if field.contains("/") {
            let parts = field.split(separator: "/")
            if parts.count == 2, let step = Int(parts[1]) {
                if parts[0] == "*" {
                    return value % step == 0
                } else if parts[0].contains("-") {
                    let rangeParts = parts[0].split(separator: "-").compactMap { Int($0) }
                    if rangeParts.count == 2 {
                        let start = rangeParts[0]
                        let end = rangeParts[1]
                        return value >= start && value <= end && (value - start) % step == 0
                    }
                }
            }
        }
        
        // Handle exact match
        if let fieldValue = Int(field) {
            return fieldValue == value
        }
        
        return false
    }
    
    private func generateDescription(minute: String, hour: String, dayOfMonth: String, month: String, dayOfWeek: String) throws -> String {
        var parts: [String] = []
        
        // Time part
        if minute == "*" && hour == "*" {
            parts.append("Every minute")
        } else if minute.starts(with: "*/") {
            let step = minute.dropFirst(2)
            parts.append("Every \(step) minutes")
        } else if hour == "*" {
            parts.append("At minute \(describeField(minute))")
        } else {
            parts.append("At \(describeField(hour)):\(minute == "*" ? "00" : String(format: "%02d", Int(minute) ?? 0))")
        }
        
        // Day part
        if dayOfMonth != "*" && dayOfWeek != "*" {
            parts.append("on day \(describeField(dayOfMonth)) of the month and on \(describeDayOfWeek(dayOfWeek))")
        } else if dayOfMonth != "*" {
            parts.append("on day \(describeField(dayOfMonth)) of the month")
        } else if dayOfWeek != "*" {
            parts.append("on \(describeDayOfWeek(dayOfWeek))")
        }
        
        // Month part
        if month != "*" {
            parts.append("in \(describeMonth(month))")
        }
        
        return parts.joined(separator: ", ")
    }
    
    private func describeField(_ field: String) -> String {
        if field == "*" { return "every" }
        if field.contains(",") {
            return field.split(separator: ",").map(String.init).joined(separator: ", ")
        }
        if field.contains("-") {
            let parts = field.split(separator: "-")
            return "\(parts[0]) through \(parts[1])"
        }
        if field.contains("/") {
            let parts = field.split(separator: "/")
            return "every \(parts[1]) starting from \(parts[0])"
        }
        return field
    }
    
    private func describeDayOfWeek(_ field: String) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        
        if field == "*" { return "every day" }
        if let day = Int(field), day >= 0 && day <= 6 {
            return days[day]
        }
        if field.contains(",") {
            return field.split(separator: ",")
                .compactMap { Int($0) }
                .filter { $0 >= 0 && $0 <= 6 }
                .map { days[$0] }
                .joined(separator: ", ")
        }
        return field
    }
    
    private func describeMonth(_ field: String) -> String {
        let months = ["", "January", "February", "March", "April", "May", "June",
                      "July", "August", "September", "October", "November", "December"]
        
        if field == "*" { return "every month" }
        if let month = Int(field), month >= 1 && month <= 12 {
            return months[month]
        }
        if field.contains(",") {
            return field.split(separator: ",")
                .compactMap { Int($0) }
                .filter { $0 >= 1 && $0 <= 12 }
                .map { months[$0] }
                .joined(separator: ", ")
        }
        return field
    }
}

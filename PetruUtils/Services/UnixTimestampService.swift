import Foundation

/// Service for converting between Unix timestamps and human-readable dates
struct UnixTimestampService {
    
    // MARK: - Error Types
    
    enum TimestampError: LocalizedError {
        case invalidTimestamp
        case invalidDateString
        case emptyInput
        case timestampOutOfRange
        
        var errorDescription: String? {
            switch self {
            case .invalidTimestamp:
                return "Invalid timestamp format. Expected a number."
            case .invalidDateString:
                return "Invalid date string format."
            case .emptyInput:
                return "Input cannot be empty."
            case .timestampOutOfRange:
                return "Timestamp is out of valid range."
            }
        }
    }
    
    // MARK: - Date Format Types
    
    enum DateFormatType: String, CaseIterable {
        case iso8601 = "ISO 8601"
        case rfc2822 = "RFC 2822"
        case full = "Full"
        case long = "Long"
        case medium = "Medium"
        case short = "Short"
        case custom = "Custom"
        
        var format: String? {
            switch self {
            case .iso8601:
                return nil // Use ISO8601DateFormatter
            case .rfc2822:
                return "EEE, dd MMM yyyy HH:mm:ss Z"
            case .full, .long, .medium, .short:
                return nil // Use DateFormatter.Style
            case .custom:
                return "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
    
    // MARK: - Conversion Results
    
    struct ConversionResult {
        let timestamp: Int64
        let timestampMilliseconds: Int64
        let date: Date
        let timezone: TimeZone
        
        // Formatted strings
        let iso8601: String
        let rfc2822: String
        let full: String
        let long: String
        let medium: String
        let short: String
        let custom: String
        let relativeTime: String
    }
    
    // MARK: - Timestamp Conversion
    
    /// Get current Unix timestamp in seconds
    func currentTimestamp() -> Int64 {
        Int64(Date().timeIntervalSince1970)
    }
    
    /// Get current Unix timestamp in milliseconds
    func currentTimestampMilliseconds() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    /// Convert Unix timestamp (seconds) to Date
    func timestampToDate(_ timestamp: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }
    
    /// Convert Unix timestamp (milliseconds) to Date
    func millisecondsToDate(_ milliseconds: Int64) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
    }
    
    /// Convert Date to Unix timestamp (seconds)
    func dateToTimestamp(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970)
    }
    
    /// Convert Date to Unix timestamp (milliseconds)
    func dateToMilliseconds(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1000)
    }
    
    /// Parse timestamp string (auto-detects seconds vs milliseconds)
    func parseTimestamp(_ input: String) throws -> Int64 {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else {
            throw TimestampError.emptyInput
        }
        
        guard let value = Int64(cleaned) else {
            throw TimestampError.invalidTimestamp
        }
        
        return value
    }
    
    /// Detect if timestamp is in seconds or milliseconds
    func isMilliseconds(_ timestamp: Int64) -> Bool {
        // Timestamps > year 2286 in seconds would be ~10B
        // Millisecond timestamps are typically 13 digits
        // Second timestamps are typically 10 digits
        return timestamp > 10_000_000_000
    }
    
    // MARK: - Date Formatting
    
    /// Format date as ISO 8601
    func formatISO8601(_ date: Date, timezone: TimeZone = .current) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    /// Format date as RFC 2822
    func formatRFC2822(_ date: Date, timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.timeZone = timezone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    /// Format date with style
    func formatDate(_ date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style, timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    /// Format date with custom format string
    func formatCustom(_ date: Date, format: String, timezone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
    
    /// Get relative time string (e.g., "2 hours ago", "in 3 days")
    func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // MARK: - Full Conversion
    
    /// Convert timestamp to all formats
    func convert(_ input: String, timezone: TimeZone = .current) throws -> ConversionResult {
        let timestamp = try parseTimestamp(input)
        
        // Determine if seconds or milliseconds
        let isMillis = isMilliseconds(timestamp)
        let date = isMillis ? millisecondsToDate(timestamp) : timestampToDate(timestamp)
        let timestampSeconds = isMillis ? timestamp / 1000 : timestamp
        let timestampMillis = isMillis ? timestamp : timestamp * 1000
        
        // Validate date is reasonable (between 1970 and 2100)
        let epochStart = Date(timeIntervalSince1970: 0)
        let futureLimit = Date(timeIntervalSince1970: 4_102_444_800) // 2100-01-01
        
        guard date >= epochStart && date <= futureLimit else {
            throw TimestampError.timestampOutOfRange
        }
        
        return ConversionResult(
            timestamp: timestampSeconds,
            timestampMilliseconds: timestampMillis,
            date: date,
            timezone: timezone,
            iso8601: formatISO8601(date, timezone: timezone),
            rfc2822: formatRFC2822(date, timezone: timezone),
            full: formatDate(date, dateStyle: .full, timeStyle: .full, timezone: timezone),
            long: formatDate(date, dateStyle: .long, timeStyle: .long, timezone: timezone),
            medium: formatDate(date, dateStyle: .medium, timeStyle: .medium, timezone: timezone),
            short: formatDate(date, dateStyle: .short, timeStyle: .short, timezone: timezone),
            custom: formatCustom(date, format: "yyyy-MM-dd HH:mm:ss", timezone: timezone),
            relativeTime: relativeTime(from: date)
        )
    }
    
    /// Convert current time to all formats
    func convertCurrent(timezone: TimeZone = .current) -> ConversionResult {
        let timestamp = currentTimestamp()
        let date = Date()
        
        return ConversionResult(
            timestamp: timestamp,
            timestampMilliseconds: timestamp * 1000,
            date: date,
            timezone: timezone,
            iso8601: formatISO8601(date, timezone: timezone),
            rfc2822: formatRFC2822(date, timezone: timezone),
            full: formatDate(date, dateStyle: .full, timeStyle: .full, timezone: timezone),
            long: formatDate(date, dateStyle: .long, timeStyle: .long, timezone: timezone),
            medium: formatDate(date, dateStyle: .medium, timeStyle: .medium, timezone: timezone),
            short: formatDate(date, dateStyle: .short, timeStyle: .short, timezone: timezone),
            custom: formatCustom(date, format: "yyyy-MM-dd HH:mm:ss", timezone: timezone),
            relativeTime: "now"
        )
    }
    
    // MARK: - Common Timezones
    
    static let commonTimezones: [TimeZone] = [
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
    
    static func timezoneName(_ timezone: TimeZone) -> String {
        if timezone == TimeZone.current {
            return "Local (\(timezone.identifier))"
        }
        return timezone.identifier
    }
}

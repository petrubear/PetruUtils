import Testing
import Foundation
@testable import PetruUtils

@Suite("Unix Timestamp Service Tests")
struct UnixTimestampServiceTests {
    let service = UnixTimestampService()
    
    // MARK: - Current Timestamp Tests
    
    @Test("Get current timestamp")
    func testCurrentTimestamp() {
        let timestamp = service.currentTimestamp()
        let now = Int64(Date().timeIntervalSince1970)
        
        // Should be within 1 second
        #expect(abs(timestamp - now) <= 1)
    }
    
    @Test("Get current timestamp in milliseconds")
    func testCurrentTimestampMilliseconds() {
        let timestamp = service.currentTimestampMilliseconds()
        let now = Int64(Date().timeIntervalSince1970 * 1000)
        
        // Should be within 1000 milliseconds
        #expect(abs(timestamp - now) <= 1000)
    }
    
    // MARK: - Timestamp to Date Tests
    
    @Test("Convert epoch to date")
    func testEpochToDate() {
        let date = service.timestampToDate(0)
        let expected = Date(timeIntervalSince1970: 0)
        
        #expect(date.timeIntervalSince1970 == expected.timeIntervalSince1970)
    }
    
    @Test("Convert specific timestamp to date")
    func testTimestampToDate() {
        // 2024-01-01 00:00:00 UTC = 1704067200
        let date = service.timestampToDate(1704067200)
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }
    
    @Test("Convert milliseconds to date")
    func testMillisecondsToDate() {
        let milliseconds: Int64 = 1704067200000 // 2024-01-01 00:00:00 UTC
        let date = service.millisecondsToDate(milliseconds)
        
        #expect(abs(date.timeIntervalSince1970 - 1704067200.0) < 0.001)
    }
    
    // MARK: - Date to Timestamp Tests
    
    @Test("Convert date to timestamp")
    func testDateToTimestamp() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let timestamp = service.dateToTimestamp(date)
        
        #expect(timestamp == 1704067200)
    }
    
    @Test("Convert date to milliseconds")
    func testDateToMilliseconds() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let milliseconds = service.dateToMilliseconds(date)
        
        #expect(milliseconds == 1704067200000)
    }
    
    // MARK: - Parse Timestamp Tests
    
    @Test("Parse valid timestamp")
    func testParseValidTimestamp() throws {
        let result = try service.parseTimestamp("1704067200")
        #expect(result == 1704067200)
    }
    
    @Test("Parse timestamp with whitespace")
    func testParseTimestampWithWhitespace() throws {
        let result = try service.parseTimestamp("  1704067200  ")
        #expect(result == 1704067200)
    }
    
    @Test("Empty timestamp throws error")
    func testEmptyTimestamp() {
        #expect(throws: UnixTimestampService.TimestampError.emptyInput) {
            _ = try service.parseTimestamp("")
        }
    }
    
    @Test("Invalid timestamp throws error")
    func testInvalidTimestamp() {
        #expect(throws: UnixTimestampService.TimestampError.invalidTimestamp) {
            _ = try service.parseTimestamp("not a number")
        }
    }
    
    // MARK: - Milliseconds Detection Tests
    
    @Test("Detect seconds timestamp")
    func testDetectSeconds() {
        let isMillis = service.isMilliseconds(1704067200)
        #expect(isMillis == false)
    }
    
    @Test("Detect milliseconds timestamp")
    func testDetectMilliseconds() {
        let isMillis = service.isMilliseconds(1704067200000)
        #expect(isMillis == true)
    }
    
    // MARK: - Date Formatting Tests
    
    @Test("Format date as ISO 8601")
    func testFormatISO8601() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let formatted = service.formatISO8601(date, timezone: TimeZone(identifier: "UTC")!)
        
        #expect(formatted.contains("2024"))
    }
    
    @Test("Format date as RFC 2822")
    func testFormatRFC2822() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let formatted = service.formatRFC2822(date, timezone: TimeZone(identifier: "UTC")!)
        
        #expect(formatted.contains("2024"))
        #expect(formatted.contains("Jan"))
    }
    
    @Test("Format date with custom format")
    func testFormatCustom() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let formatted = service.formatCustom(date, format: "yyyy-MM-dd", timezone: TimeZone(identifier: "UTC")!)
        
        #expect(formatted == "2024-01-01")
    }
    
    // MARK: - Full Conversion Tests
    
    @Test("Convert seconds timestamp")
    func testConvertSecondsTimestamp() throws {
        let result = try service.convert("1704067200", timezone: TimeZone(identifier: "UTC")!)
        
        #expect(result.timestamp == 1704067200)
        #expect(result.timestampMilliseconds == 1704067200000)
        #expect(result.iso8601.contains("2024"))
    }
    
    @Test("Convert milliseconds timestamp")
    func testConvertMillisecondsTimestamp() throws {
        let result = try service.convert("1704067200000", timezone: TimeZone(identifier: "UTC")!)
        
        #expect(result.timestamp == 1704067200)
        #expect(result.timestampMilliseconds == 1704067200000)
    }
    
    @Test("Convert with different timezone")
    func testConvertWithTimezone() throws {
        let utcResult = try service.convert("1704067200", timezone: TimeZone(identifier: "UTC")!)
        let nyResult = try service.convert("1704067200", timezone: TimeZone(identifier: "America/New_York")!)
        
        // Same timestamp, different formatted strings
        #expect(utcResult.timestamp == nyResult.timestamp)
        #expect(utcResult.full != nyResult.full) // Different timezone formatting
    }
    
    @Test("Timestamp out of range throws error")
    func testTimestampOutOfRange() {
        // Very far future (year 2200, beyond 2100 limit)
        #expect(throws: UnixTimestampService.TimestampError.timestampOutOfRange) {
            _ = try service.convert("7258118400")
        }
    }
    
    // MARK: - Relative Time Tests
    
    @Test("Relative time for past date")
    func testRelativeTimePast() {
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let relative = service.relativeTime(from: pastDate)
        
        #expect(relative.contains("ago") || relative.contains("hour"))
    }
    
    @Test("Relative time for future date")
    func testRelativeTimeFuture() {
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let relative = service.relativeTime(from: futureDate)
        
        #expect(relative.contains("in") || relative.contains("hour"))
    }
    
    // MARK: - Round-trip Tests
    
    @Test("Round-trip seconds conversion")
    func testRoundTripSeconds() throws {
        let original: Int64 = 1704067200
        let date = service.timestampToDate(original)
        let backToTimestamp = service.dateToTimestamp(date)
        
        #expect(backToTimestamp == original)
    }
    
    @Test("Round-trip milliseconds conversion")
    func testRoundTripMilliseconds() throws {
        let original: Int64 = 1704067200000
        let date = service.millisecondsToDate(original)
        let backToMillis = service.dateToMilliseconds(date)
        
        #expect(backToMillis == original)
    }
    
    // MARK: - Edge Cases
    
    @Test("Convert epoch zero")
    func testEpochZero() throws {
        let result = try service.convert("0", timezone: TimeZone(identifier: "UTC")!)
        
        #expect(result.timestamp == 0)
        #expect(result.iso8601.contains("1970"))
    }
    
    @Test("Convert negative timestamp")
    func testNegativeTimestamp() {
        // Negative timestamps (before 1970) should throw out of range
        #expect(throws: UnixTimestampService.TimestampError.timestampOutOfRange) {
            _ = try service.convert("-1000")
        }
    }
}

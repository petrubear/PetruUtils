import Testing
import Foundation
@testable import PetruUtils

@Suite("Line Deduplicator Service Tests")
struct LineDeduplicatorServiceTests {
    let service = LineDeduplicatorService()
    
    @Test("Remove duplicates keeping first")
    func testDeduplicateKeepFirst() {
        let input = "apple\nbanana\napple\ncherry\nbanana"
        let result = service.deduplicate(input, keep: .first)
        #expect(result == "apple\nbanana\ncherry")
    }
    
    @Test("Remove duplicates keeping last")
    func testDeduplicateKeepLast() {
        let input = "apple\nbanana\napple\ncherry\nbanana"
        let result = service.deduplicate(input, keep: .last)
        #expect(result == "apple\ncherry\nbanana")
    }
    
    @Test("Case-insensitive deduplication")
    func testCaseInsensitive() {
        let input = "Apple\napple\nAPPLE\nBanana"
        let result = service.deduplicate(input, caseSensitive: false)
        #expect(result == "Apple\nBanana")
    }
    
    @Test("Case-sensitive deduplication")
    func testCaseSensitive() {
        let input = "Apple\napple\nAPPLE\nBanana"
        let result = service.deduplicate(input, caseSensitive: true)
        let lines = result.components(separatedBy: "\n")
        #expect(lines.count == 4) // All are unique when case-sensitive
    }
    
    @Test("Deduplicate with sort")
    func testDeduplicateWithSort() {
        let input = "zebra\napple\nbanana\napple"
        let result = service.deduplicate(input, sortAfter: true)
        #expect(result == "apple\nbanana\nzebra")
    }
    
    @Test("Count duplicates")
    func testCountDuplicates() {
        let input = "apple\nbanana\napple\ncherry\nbanana\napple"
        let count = service.countDuplicates(input)
        #expect(count == 3) // 2 extra apples + 1 extra banana
    }
    
    @Test("Get statistics")
    func testStatistics() {
        let input = "apple\nbanana\napple\ncherry\nbanana"
        let stats = service.getStatistics(input)
        #expect(stats.total == 5)
        #expect(stats.unique == 3)
        #expect(stats.duplicates == 2)
    }
    
    @Test("Handle empty lines")
    func testEmptyLines() {
        let input = "apple\n\nbanana\n\napple"
        let result = service.deduplicate(input)
        #expect(result.contains("apple"))
        #expect(result.contains("banana"))
    }
    
    @Test("No duplicates")
    func testNoDuplicates() {
        let input = "apple\nbanana\ncherry"
        let result = service.deduplicate(input)
        #expect(result == input)
    }
}

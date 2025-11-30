import Testing
import Foundation
@testable import PetruUtils

@Suite("Cron Service Tests")
struct CronServiceTests {
    let service = CronService()
    
    @Test("Parse weekly noon cron")
    func parseDescription() throws {
        let expression = try service.parse("0 12 * * 1")
        #expect(expression.description.contains("12:00"))
        #expect(expression.description.contains("Monday"))
    }
    
    @Test("Reject malformed expression")
    func invalidFormat() {
        #expect(throws: CronService.CronError.invalidFormat) {
            _ = try service.parse("0 12 * *")
        }
    }
    
    @Test("Generate next executions")
    func nextExecutions() throws {
        let results = try service.getNextExecutions("*/30 * * * *", count: 2)
        #expect(results.count == 2)
        #expect(results[0] < results[1])
        #expect(results[1].timeIntervalSince(results[0]) >= 60) // at least one minute apart
    }
}

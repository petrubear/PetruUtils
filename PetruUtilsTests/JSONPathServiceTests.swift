import Testing
import Foundation
@testable import PetruUtils

@Suite("JSONPath Service Tests")
struct JSONPathServiceTests {
    let service = JSONPathService()
    let sampleJSON = """
    {
        "users": [
            { "name": "Alice", "age": 30 },
            { "name": "Bob", "age": 25 }
        ]
    }
    """
    
    @Test("Select single property")
    func selectSingleValue() throws {
        let result = try service.evaluate(json: sampleJSON, path: "$.users[1].name")
        #expect(result.matches == 1)
        #expect(result.value as? String == "Bob")
        let formatted = try service.formatResult(result)
        #expect(formatted.contains("Bob"))
    }
    
    @Test("Recursive descent collects matches")
    func recursiveDescent() throws {
        let result = try service.evaluate(json: sampleJSON, path: "$..name")
        #expect(result.matches == 2)
        #expect((result.value as? [Any])?.count == 2)
    }
    
    @Test("No matches throws")
    func noMatches() {
        #expect(throws: JSONPathService.JSONPathError.noMatches) {
            _ = try service.evaluate(json: sampleJSON, path: "$.missing")
        }
    }
}

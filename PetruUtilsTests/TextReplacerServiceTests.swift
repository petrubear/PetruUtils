import Testing
import Foundation
@testable import PetruUtils

@Suite("Text Replacer Service Tests")
struct TextReplacerServiceTests {
    let service = TextReplacerService()
    
    @Test("Replace plain text case-sensitive")
    func testReplaceCaseSensitive() throws {
        let input = "Hello world, hello universe"
        let result = try service.replace(input, find: "hello", replaceWith: "hi", caseSensitive: true)
        #expect(result == "Hello world, hi universe")
    }
    
    @Test("Replace plain text case-insensitive")
    func testReplaceCaseInsensitive() throws {
        let input = "Hello world, hello universe"
        let result = try service.replace(input, find: "hello", replaceWith: "hi", caseSensitive: false)
        #expect(result == "hi world, hi universe")
    }
    
    @Test("Replace whole word only")
    func testReplaceWholeWord() throws {
        let input = "The theater is there"
        let result = try service.replace(input, find: "the", replaceWith: "a", caseSensitive: false, wholeWord: true)
        #expect(result == "a theater is there")
    }
    
    @Test("Replace with regex simple pattern")
    func testReplaceWithRegex() throws {
        let input = "Phone: 123-456-7890"
        let result = try service.replaceWithRegex(input, pattern: "\\d{3}-\\d{3}-\\d{4}", replaceWith: "XXX-XXX-XXXX")
        #expect(result == "Phone: XXX-XXX-XXXX")
    }
    
    @Test("Replace with regex capture groups")
    func testReplaceWithCaptureGroups() throws {
        let input = "John Doe"
        let result = try service.replaceWithRegex(input, pattern: "(\\w+) (\\w+)", replaceWith: "$2, $1")
        #expect(result == "Doe, John")
    }
    
    @Test("Count occurrences case-sensitive")
    func testCountCaseSensitive() {
        let input = "Apple apple APPLE"
        let count = service.countOccurrences(in: input, find: "apple", caseSensitive: true)
        #expect(count == 1)
    }
    
    @Test("Count occurrences case-insensitive")
    func testCountCaseInsensitive() {
        let input = "Apple apple APPLE"
        let count = service.countOccurrences(in: input, find: "apple", caseSensitive: false)
        #expect(count == 3)
    }
    
    @Test("Count occurrences with regex")
    func testCountWithRegex() {
        let input = "foo123 bar456 baz789"
        let count = service.countOccurrences(in: input, find: "\\d+", caseSensitive: true, isRegex: true)
        #expect(count == 3)
    }
    
    @Test("Validate valid regex")
    func testValidateValidRegex() {
        #expect(service.validateRegex("\\d+"))
        #expect(service.validateRegex("[a-zA-Z]+"))
        #expect(service.validateRegex("^hello.*world$"))
    }
    
    @Test("Validate invalid regex")
    func testValidateInvalidRegex() {
        #expect(!service.validateRegex("[unclosed"))
        #expect(!service.validateRegex("(unmatched"))
        #expect(!service.validateRegex(""))
    }
    
    @Test("Replace empty search throws error")
    func testEmptySearchThrows() {
        #expect(throws: TextReplacerService.TextReplacerError.self) {
            try service.replace("text", find: "", replaceWith: "replacement")
        }
    }
    
    @Test("Replace with invalid regex throws error")
    func testInvalidRegexThrows() {
        #expect(throws: TextReplacerService.TextReplacerError.self) {
            try service.replaceWithRegex("text", pattern: "[unclosed", replaceWith: "replacement")
        }
    }
}

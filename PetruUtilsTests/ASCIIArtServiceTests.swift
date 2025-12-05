import Testing
import Foundation
@testable import PetruUtils

@Suite("ASCII Art Service Tests")
struct ASCIIArtServiceTests {
    let service = ASCIIArtService()

    // MARK: - Basic Generation Tests

    @Test("Generate ASCII art for single letter")
    func testSingleLetter() throws {
        let result = try service.generateASCIIArt(from: "A", font: .banner)
        #expect(!result.isEmpty)
        #expect(result.contains("#"))
        #expect(result.components(separatedBy: "\n").count == 7) // Banner font is 7 lines
    }

    @Test("Generate ASCII art for word")
    func testWord() throws {
        let result = try service.generateASCIIArt(from: "HELLO", font: .banner)
        #expect(!result.isEmpty)
        #expect(result.components(separatedBy: "\n").count == 7)
    }

    @Test("Generate ASCII art with spaces")
    func testWithSpaces() throws {
        let result = try service.generateASCIIArt(from: "HI THERE", font: .banner)
        #expect(!result.isEmpty)
        #expect(result.components(separatedBy: "\n").count == 7)
    }

    // MARK: - Font Tests

    @Test("Generate with block font")
    func testBlockFont() throws {
        let result = try service.generateASCIIArt(from: "TEST", font: .block)
        #expect(!result.isEmpty)
        #expect(result.components(separatedBy: "\n").count == 5) // Block font is 5 lines
        #expect(result.contains("█"))
    }

    @Test("Generate with small font")
    func testSmallFont() throws {
        let result = try service.generateASCIIArt(from: "ABC", font: .small)
        #expect(!result.isEmpty)
        #expect(result.components(separatedBy: "\n").count == 3) // Small font is 3 lines
    }

    @Test("Generate with mini font")
    func testMiniFont() throws {
        let result = try service.generateASCIIArt(from: "XY", font: .mini)
        #expect(!result.isEmpty)
        #expect(result.components(separatedBy: "\n").count == 2) // Mini font is 2 lines
    }

    @Test("All fonts produce different output")
    func testAllFontsProduceDifferentOutput() throws {
        let text = "A"
        var outputs: [String] = []

        for font in ASCIIArtService.ASCIIFont.allCases {
            let result = try service.generateASCIIArt(from: text, font: font)
            outputs.append(result)
        }

        // Each font should produce unique output
        let uniqueOutputs = Set(outputs)
        #expect(uniqueOutputs.count == ASCIIArtService.ASCIIFont.allCases.count)
    }

    // MARK: - Case Handling Tests

    @Test("Lowercase is converted to uppercase")
    func testLowercaseConversion() throws {
        let lowercase = try service.generateASCIIArt(from: "hello", font: .banner)
        let uppercase = try service.generateASCIIArt(from: "HELLO", font: .banner)
        #expect(lowercase == uppercase)
    }

    @Test("Mixed case produces same result as uppercase")
    func testMixedCase() throws {
        let mixed = try service.generateASCIIArt(from: "HeLLo", font: .block)
        let upper = try service.generateASCIIArt(from: "HELLO", font: .block)
        #expect(mixed == upper)
    }

    // MARK: - Number Tests

    @Test("Generate ASCII art for numbers")
    func testNumbers() throws {
        let result = try service.generateASCIIArt(from: "12345", font: .banner)
        #expect(!result.isEmpty)
        #expect(result.components(separatedBy: "\n").count == 7)
    }

    @Test("Generate ASCII art for mixed letters and numbers")
    func testMixedAlphanumeric() throws {
        let result = try service.generateASCIIArt(from: "ABC123", font: .block)
        #expect(!result.isEmpty)
    }

    // MARK: - Error Tests

    @Test("Empty input throws error")
    func testEmptyInput() throws {
        #expect(throws: ASCIIArtService.ASCIIArtError.emptyInput) {
            try service.generateASCIIArt(from: "", font: .banner)
        }
    }

    @Test("Whitespace only throws error")
    func testWhitespaceOnly() throws {
        #expect(throws: ASCIIArtService.ASCIIArtError.emptyInput) {
            try service.generateASCIIArt(from: "   ", font: .banner)
        }
    }

    // MARK: - Character Support Tests

    @Test("Check character support")
    func testCharacterSupport() {
        // Letters should be supported
        #expect(service.isCharacterSupported("A", font: .banner))
        #expect(service.isCharacterSupported("Z", font: .banner))
        #expect(service.isCharacterSupported("a", font: .banner)) // lowercase should work too

        // Numbers should be supported
        #expect(service.isCharacterSupported("0", font: .banner))
        #expect(service.isCharacterSupported("9", font: .banner))

        // Space should be supported
        #expect(service.isCharacterSupported(" ", font: .banner))
    }

    @Test("Supported characters list is not empty")
    func testSupportedCharactersList() {
        let chars = service.supportedCharacters(for: .banner)
        #expect(!chars.isEmpty)
        #expect(chars.count >= 36) // At least A-Z and 0-9
    }

    // MARK: - Punctuation Tests

    @Test("Generate with punctuation")
    func testPunctuation() throws {
        let result = try service.generateASCIIArt(from: "HI!", font: .banner)
        #expect(!result.isEmpty)
    }

    @Test("Generate with question mark")
    func testQuestionMark() throws {
        let result = try service.generateASCIIArt(from: "WHY?", font: .banner)
        #expect(!result.isEmpty)
    }
}

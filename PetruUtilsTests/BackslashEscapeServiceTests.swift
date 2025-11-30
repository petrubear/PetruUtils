import Testing
import Foundation
@testable import PetruUtils

@Suite("Backslash Escape Service Tests")
struct BackslashEscapeServiceTests {
    let service = BackslashEscapeService()
    
    @Test("Escape standard control characters")
    func escapeStandard() {
        let input = "Line\nTab\t"
        let escaped = service.escape(input)
        #expect(escaped == "Line\\nTab\\t")
    }
    
    @Test("Unescape sequences")
    func unescape() {
        let result = service.unescape("Hello\\nWorld")
        #expect(result == "Hello\nWorld")
    }
    
    @Test("Unicode escaping for non-ASCII")
    func unicodeEscape() {
        let escaped = service.escape("é", mode: .json)
        #expect(escaped == "\\u00e9")
    }
}

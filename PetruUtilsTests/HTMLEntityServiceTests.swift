import Testing
import Foundation
@testable import PetruUtils

@Suite("HTML Entity Service Tests")
struct HTMLEntityServiceTests {
    let service = HTMLEntityService()
    
    @Test("Round-trip encode/decode with special chars")
    func roundTrip() {
        let input = "<div class=\"test\">& Hello ©</div>"
        let encoded = service.encode(input)
        let decoded = service.decode(encoded)
        #expect(decoded == input)
    }
    
    @Test("Hex entity encoding")
    func hexEncoding() {
        let result = service.encodeToHex("Ā")
        #expect(result == "&#x100;")
    }
    
    @Test("Decode numeric entity")
    func decodeNumeric() {
        let decoded = service.decode("Hello &#169;")
        #expect(decoded == "Hello ©")
    }
}

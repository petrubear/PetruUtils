import Testing
import Foundation
@testable import PetruUtils

@Suite("Base32 Service Tests")
struct Base32ServiceTests {
    let service = Base32Service()
    
    @Test("Encode and decode standard variant")
    func standardRoundTrip() throws {
        let encoded = try service.encode("hello", variant: .standard)
        #expect(encoded == "NBSWY3DP")
        let decoded = try service.decode(encoded, variant: .standard)
        #expect(decoded == "hello")
    }
    
    @Test("Encode and decode hex variant")
    func hexRoundTrip() throws {
        let text = "12345"
        let encoded = try service.encode(text, variant: .hex)
        let decoded = try service.decode(encoded, variant: .hex)
        #expect(decoded == text)
    }
    
    @Test("Reject invalid characters")
    func invalidCharacters() {
        #expect(throws: Base32Service.Base32Error.invalidBase32Input) {
            _ = try service.decode("!!!???", variant: .standard)
        }
        #expect(service.isValidBase32("ABC123$$") == false)
    }
}

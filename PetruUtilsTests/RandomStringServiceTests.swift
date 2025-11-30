import Testing
import Foundation
@testable import PetruUtils

@Suite("Random String Service Tests")
struct RandomStringServiceTests {
    let service = RandomStringService()
    
    @Test("Generate string with selected sets")
    func generateBasic() throws {
        let result = try service.generate(length: 16, characterSets: [.lowercase, .numbers])
        #expect(result.count == 16)
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789")
        #expect(result.unicodeScalars.allSatisfy { allowed.contains($0) })
    }
    
    @Test("Exclude ambiguous characters")
    func excludeAmbiguous() throws {
        let result = try service.generate(length: 24, characterSets: [.uppercase, .numbers], excludeAmbiguous: true)
        let forbidden = CharacterSet(charactersIn: "0O1I")
        #expect(result.unicodeScalars.allSatisfy { !forbidden.contains($0) })
    }
    
    @Test("Reject invalid length")
    func invalidLength() {
        #expect(throws: RandomStringService.RandomStringError.invalidLength) {
            _ = try service.generate(length: 0, characterSets: [.lowercase])
        }
    }
}

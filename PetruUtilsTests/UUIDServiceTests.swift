import Testing
import Foundation
@testable import PetruUtils

@Suite("UUID Service Tests")
struct UUIDServiceTests {
    let service = UUIDService()
    
    // MARK: - UUID v4 Tests
    
    @Test("Generate UUID v4")
    func testGenerateUUIDv4() throws {
        let uuid = try service.generateUUID(version: .v4)
        #expect(service.isValidUUID(uuid))
        #expect(uuid.count == 36) // With hyphens
    }
    
    @Test("UUID v4 generates unique values")
    func testUUIDv4Uniqueness() throws {
        let uuid1 = try service.generateUUID(version: .v4)
        let uuid2 = try service.generateUUID(version: .v4)
        #expect(uuid1 != uuid2)
    }
    
    // MARK: - UUID v1 Tests
    
    @Test("Generate UUID v1")
    func testGenerateUUIDv1() throws {
        let uuid = try service.generateUUID(version: .v1)
        #expect(service.isValidUUID(uuid))
        #expect(uuid.count == 36)
    }
    
    @Test("UUID v1 contains version bit")
    func testUUIDv1VersionBit() throws {
        let uuid = try service.generateUUID(version: .v1)
        let parts = uuid.split(separator: "-")
        #expect(parts.count == 5)
        // Version 1 should have '1' in the version field (third group, first char)
        let versionChar = parts[2].first
        #expect(versionChar == "1")
    }
    
    // MARK: - UUID v5 Tests
    
    @Test("Generate UUID v5 with namespace and name")
    func testGenerateUUIDv5() throws {
        let uuid = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceDNS,
            name: "example.com"
        )
        #expect(service.isValidUUID(uuid))
    }
    
    @Test("UUID v5 is deterministic")
    func testUUIDv5Deterministic() throws {
        let uuid1 = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceURL,
            name: "https://example.com"
        )
        let uuid2 = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceURL,
            name: "https://example.com"
        )
        #expect(uuid1 == uuid2)
    }
    
    @Test("UUID v5 different names produce different UUIDs")
    func testUUIDv5DifferentNames() throws {
        let uuid1 = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceDNS,
            name: "example.com"
        )
        let uuid2 = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceDNS,
            name: "test.com"
        )
        #expect(uuid1 != uuid2)
    }
    
    @Test("UUID v5 requires namespace")
    func testUUIDv5RequiresNamespace() {
        #expect(throws: UUIDService.UUIDError.v5RequiresNamespace) {
            try service.generateUUID(version: .v5, namespace: nil, name: "test")
        }
    }
    
    @Test("UUID v5 requires name")
    func testUUIDv5RequiresName() {
        #expect(throws: UUIDService.UUIDError.v5RequiresName) {
            try service.generateUUID(version: .v5, namespace: UUIDService.namespaceDNS, name: nil)
        }
    }
    
    @Test("UUID v5 rejects invalid namespace")
    func testUUIDv5InvalidNamespace() {
        #expect(throws: UUIDService.UUIDError.invalidNamespace) {
            try service.generateUUID(version: .v5, namespace: "invalid", name: "test")
        }
    }
    
    // MARK: - ULID Tests
    
    @Test("Generate ULID")
    func testGenerateULID() throws {
        let ulid = try service.generateUUID(version: .ulid)
        #expect(ulid.count == 26)
        #expect(service.isValidULID(ulid))
    }
    
    @Test("ULID generates unique values")
    func testULIDUniqueness() throws {
        let ulid1 = try service.generateUUID(version: .ulid)
        let ulid2 = try service.generateUUID(version: .ulid)
        #expect(ulid1 != ulid2)
    }
    
    @Test("ULID is lexicographically sortable")
    func testULIDSortable() throws {
        let ulid1 = try service.generateUUID(version: .ulid)
        Thread.sleep(forTimeInterval: 0.01) // Wait 10ms
        let ulid2 = try service.generateUUID(version: .ulid)
        
        // Later ULID should be lexicographically greater
        #expect(ulid1 < ulid2)
    }
    
    // MARK: - Bulk Generation Tests
    
    @Test("Generate bulk UUIDs")
    func testGenerateBulk() throws {
        let uuids = try service.generateBulk(count: 10, version: .v4)
        #expect(uuids.count == 10)
        
        // Check all are valid
        for uuid in uuids {
            #expect(service.isValidUUID(uuid))
        }
        
        // Check all are unique
        let uniqueSet = Set(uuids)
        #expect(uniqueSet.count == 10)
    }
    
    @Test("Bulk generation respects maximum count")
    func testBulkGenerationMaxCount() throws {
        let uuids = try service.generateBulk(count: 2000, version: .v4)
        #expect(uuids.count == 1000) // Should cap at 1000
    }
    
    @Test("Bulk generation respects minimum count")
    func testBulkGenerationMinCount() throws {
        let uuids = try service.generateBulk(count: 0, version: .v4)
        #expect(uuids.count == 1) // Should generate at least 1
    }
    
    @Test("Bulk generate ULIDs")
    func testBulkGenerateULIDs() throws {
        let ulids = try service.generateBulk(count: 5, version: .ulid)
        #expect(ulids.count == 5)
        
        for ulid in ulids {
            #expect(service.isValidULID(ulid))
        }
    }
    
    // MARK: - Formatting Tests
    
    @Test("Format UUID as lowercase")
    func testFormatLowercase() {
        let uuid = "550E8400-E29B-41D4-A716-446655440000"
        let formatted = service.format(uuid, as: .lowercase)
        #expect(formatted == "550e8400-e29b-41d4-a716-446655440000")
    }
    
    @Test("Format UUID as uppercase")
    func testFormatUppercase() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let formatted = service.format(uuid, as: .uppercase)
        #expect(formatted == "550E8400-E29B-41D4-A716-446655440000")
    }
    
    @Test("Format UUID without hyphens")
    func testFormatWithoutHyphens() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let formatted = service.format(uuid, as: .withoutHyphens)
        #expect(formatted == "550e8400e29b41d4a716446655440000")
        #expect(formatted.count == 32)
    }
    
    @Test("Format UUID with hyphens from unhyphenated")
    func testFormatAddHyphens() {
        let uuid = "550e8400e29b41d4a716446655440000"
        let formatted = service.format(uuid, as: .withHyphens)
        #expect(formatted == "550e8400-e29b-41d4-a716-446655440000")
    }
    
    @Test("Format bulk UUIDs")
    func testFormatBulk() throws {
        let uuids = try service.generateBulk(count: 3, version: .v4)
        let formatted = service.formatBulk(uuids, as: .uppercase)
        
        #expect(formatted.count == 3)
        for uuid in formatted {
            #expect(uuid == uuid.uppercased())
        }
    }
    
    // MARK: - Validation Tests
    
    @Test("Validate correct UUID format")
    func testValidateCorrectUUID() {
        #expect(service.isValidUUID("550e8400-e29b-41d4-a716-446655440000"))
        #expect(service.isValidUUID("550E8400-E29B-41D4-A716-446655440000"))
    }
    
    @Test("Validate UUID without hyphens")
    func testValidateUUIDWithoutHyphens() {
        #expect(service.isValidUUID("550e8400e29b41d4a716446655440000"))
    }
    
    @Test("Reject invalid UUID formats")
    func testRejectInvalidUUIDs() {
        #expect(!service.isValidUUID("not-a-uuid"))
        #expect(!service.isValidUUID("550e8400-e29b-41d4-a716"))
        #expect(!service.isValidUUID(""))
        #expect(!service.isValidUUID("550e8400-e29b-41d4-a716-446655440000-extra"))
    }
    
    @Test("Validate correct ULID format")
    func testValidateCorrectULID() {
        #expect(service.isValidULID("01ARZ3NDEKTSV4RRFFQ69G5FAV"))
        #expect(service.isValidULID("01BX5ZZKBKACTAV9WEVGEMMVRZ"))
    }
    
    @Test("Reject invalid ULID formats")
    func testRejectInvalidULIDs() {
        #expect(!service.isValidULID("not-a-ulid"))
        #expect(!service.isValidULID("01ARZ3NDEKTSV4RRFFQ69G5FA")) // Too short
        #expect(!service.isValidULID("01ARZ3NDEKTSV4RRFFQ69G5FAVX")) // Too long
        #expect(!service.isValidULID("01ARZ3NDEKTSV4RRFFQ69G5FAV!")) // Invalid char
        #expect(!service.isValidULID(""))
    }
    
    // MARK: - Common Namespace Tests
    
    @Test("Common namespaces are valid UUIDs")
    func testCommonNamespaces() {
        #expect(service.isValidUUID(UUIDService.namespaceURL))
        #expect(service.isValidUUID(UUIDService.namespaceDNS))
        #expect(service.isValidUUID(UUIDService.namespaceOID))
        #expect(service.isValidUUID(UUIDService.namespaceX500))
    }
    
    @Test("UUID v5 with common namespaces")
    func testUUIDv5WithCommonNamespaces() throws {
        let url = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceURL,
            name: "https://example.com"
        )
        
        let dns = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceDNS,
            name: "example.com"
        )
        
        #expect(service.isValidUUID(url))
        #expect(service.isValidUUID(dns))
        #expect(url != dns) // Same name, different namespace = different UUID
    }
    
    // MARK: - Edge Cases
    
    @Test("Handle Unicode in UUID v5 names")
    func testUUIDv5Unicode() throws {
        let uuid = try service.generateUUID(
            version: .v5,
            namespace: UUIDService.namespaceDNS,
            name: "测试.中国"
        )
        #expect(service.isValidUUID(uuid))
    }
    
    @Test("Handle empty string edge cases")
    func testEmptyStringEdgeCases() {
        #expect(throws: UUIDService.UUIDError.v5RequiresNamespace) {
            try service.generateUUID(version: .v5, namespace: "", name: "test")
        }
        
        #expect(throws: UUIDService.UUIDError.v5RequiresName) {
            try service.generateUUID(version: .v5, namespace: UUIDService.namespaceDNS, name: "")
        }
    }
    
    @Test("Bulk generation with UUID v5")
    func testBulkUUIDv5() throws {
        let uuids = try service.generateBulk(
            count: 5,
            version: .v5,
            namespace: UUIDService.namespaceDNS,
            namePrefix: "test"
        )
        
        #expect(uuids.count == 5)
        
        // All should be valid
        for uuid in uuids {
            #expect(service.isValidUUID(uuid))
        }
        
        // All should be unique (different names)
        let uniqueSet = Set(uuids)
        #expect(uniqueSet.count == 5)
    }
}

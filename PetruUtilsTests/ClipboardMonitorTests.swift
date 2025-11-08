import Testing
import Foundation
@testable import PetruUtils

@Suite("Clipboard Monitor Tests")
struct ClipboardMonitorTests {
    let detector = ContentDetector()
    
    // MARK: - JWT Detection
    
    @Test("Detect valid JWT token")
    func testDetectJWT() {
        let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"
        let type = detector.detect(jwt)
        #expect(type == .jwt)
    }
    
    @Test("Reject non-JWT with three parts")
    func testRejectInvalidJWT() {
        let notJWT = "part1.part2.part3"
        let type = detector.detect(notJWT)
        #expect(type != .jwt)
    }
    
    // MARK: - JSON Detection
    
    @Test("Detect JSON object")
    func testDetectJSONObject() {
        let json = "{\"key\": \"value\", \"number\": 42}"
        let type = detector.detect(json)
        #expect(type == .json)
    }
    
    @Test("Detect JSON array")
    func testDetectJSONArray() {
        let json = "[1, 2, 3, \"test\"]"
        let type = detector.detect(json)
        #expect(type == .json)
    }
    
    @Test("Reject invalid JSON")
    func testRejectInvalidJSON() {
        let notJSON = "{invalid json"
        let type = detector.detect(notJSON)
        #expect(type != .json)
    }
    
    // MARK: - UUID Detection
    
    @Test("Detect UUID with hyphens")
    func testDetectUUID() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let type = detector.detect(uuid)
        #expect(type == .uuid)
    }
    
    @Test("Detect UUID without hyphens")
    func testDetectUUIDWithoutHyphens() {
        let uuid = "550e8400e29b41d4a716446655440000"
        let type = detector.detect(uuid)
        #expect(type == .uuid)
    }
    
    @Test("Detect uppercase UUID")
    func testDetectUUIDUppercase() {
        let uuid = "550E8400-E29B-41D4-A716-446655440000"
        let type = detector.detect(uuid)
        #expect(type == .uuid)
    }
    
    // MARK: - ULID Detection
    
    @Test("Detect valid ULID")
    func testDetectULID() {
        let ulid = "01ARZ3NDEKTSV4RRFFQ69G5FAV"
        let type = detector.detect(ulid)
        #expect(type == .ulid)
    }
    
    @Test("Reject invalid ULID length")
    func testRejectInvalidULIDLength() {
        let notULID = "01ARZ3NDEKTSV4RRFFQ"
        let type = detector.detect(notULID)
        #expect(type != .ulid)
    }
    
    // MARK: - Base64 Detection
    
    @Test("Detect Base64 encoded text")
    func testDetectBase64() {
        let base64 = "SGVsbG8gV29ybGQ="
        let type = detector.detect(base64)
        #expect(type == .base64)
    }
    
    @Test("Detect long Base64")
    func testDetectLongBase64() {
        let base64 = String(repeating: "ABCD", count: 50)
        let type = detector.detect(base64)
        #expect(type == .base64)
    }
    
    // MARK: - URL Detection
    
    @Test("Detect HTTP URL")
    func testDetectHTTPURL() {
        let url = "https://example.com/path/to/resource"
        let type = detector.detect(url)
        #expect(type == .url)
    }
    
    @Test("Detect domain-only URL")
    func testDetectDomainURL() {
        let url = "example.com"
        let type = detector.detect(url)
        #expect(type == .url)
    }
    
    @Test("Detect mailto URL")
    func testDetectMailtoURL() {
        let url = "mailto:test@example.com"
        let type = detector.detect(url)
        #expect(type == .url)
    }
    
    // MARK: - Hash Detection
    
    @Test("Detect MD5 hash")
    func testDetectMD5() {
        let hash = "5d41402abc4b2a76b9719d911017c592"
        let type = detector.detect(hash)
        #expect(type == .hash)
    }
    
    @Test("Detect SHA1 hash")
    func testDetectSHA1() {
        let hash = "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"
        let type = detector.detect(hash)
        #expect(type == .hash)
    }
    
    @Test("Detect SHA256 hash")
    func testDetectSHA256() {
        let hash = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
        let type = detector.detect(hash)
        #expect(type == .hash)
    }
    
    @Test("Detect SHA512 hash")
    func testDetectSHA512() {
        let hash = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff"
        let type = detector.detect(hash)
        #expect(type == .hash)
    }
    
    @Test("Reject non-hex hash")
    func testRejectNonHexHash() {
        let notHash = "g94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
        let type = detector.detect(notHash)
        #expect(type != .hash)
    }
    
    // MARK: - XML Detection
    
    @Test("Detect XML")
    func testDetectXML() {
        let xml = "<root><element>value</element></root>"
        let type = detector.detect(xml)
        #expect(type == .xml)
    }
    
    @Test("Detect HTML as XML")
    func testDetectHTML() {
        let html = "<html><body><h1>Title</h1></body></html>"
        let type = detector.detect(html)
        #expect(type == .xml)
    }
    
    // MARK: - Priority Tests (specific formats take precedence)
    
    @Test("JWT takes precedence over Base64")
    func testJWTPrecedence() {
        // JWT should be detected before Base64, even though JWT segments are base64url
        let jwt = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.abc123"
        let type = detector.detect(jwt)
        #expect(type == .jwt)
    }
    
    @Test("ULID takes precedence over hash")
    func testULIDPrecedence() {
        // ULID is 26 chars of alphanumeric, should be detected before checking for hash
        let ulid = "01ARZ3NDEKTSV4RRFFQ69G5FAV"
        let type = detector.detect(ulid)
        #expect(type == .ulid)
    }
    
    @Test("UUID takes precedence over hash")
    func testUUIDPrecedence() {
        let uuid = "550e8400-e29b-41d4-a716-446655440000"
        let type = detector.detect(uuid)
        #expect(type == .uuid)
    }
    
    // MARK: - Unknown Type
    
    @Test("Plain text is unknown")
    func testPlainTextUnknown() {
        let text = "This is just plain text"
        let type = detector.detect(text)
        #expect(type == .unknown)
    }
    
    @Test("Numbers are unknown")
    func testNumbersUnknown() {
        let numbers = "1234567890"
        let type = detector.detect(numbers)
        #expect(type == .unknown)
    }
    
    // MARK: - Edge Cases
    
    @Test("Whitespace trimming works")
    func testWhitespaceTrimming() {
        let jwt = "  eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.abc123  \n"
        let type = detector.detect(jwt)
        #expect(type == .jwt)
    }
    
    @Test("Empty string is unknown")
    func testEmptyString() {
        let empty = ""
        let type = detector.detect(empty)
        #expect(type == .unknown)
    }
    
    @Test("Very long UUID without hyphens")
    func testLongUUIDWithoutHyphens() {
        let uuid = "123456789012345678901234567890ab"
        let type = detector.detect(uuid)
        #expect(type == .uuid)
    }
}

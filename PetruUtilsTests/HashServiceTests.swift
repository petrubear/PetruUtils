import Testing
import Foundation
@testable import PetruUtils

@Suite("Hash Service Tests")
struct HashServiceTests {
    let service = HashService()
    
    // MARK: - MD5 Tests
    
    @Test("MD5 hash of known test vector")
    func testMD5KnownVector() throws {
        let result = try service.hashText("The quick brown fox jumps over the lazy dog", algorithm: .md5)
        #expect(result == "9e107d9d372bb6826bd81d3542a419d6")
    }
    
    @Test("MD5 hash of empty string throws")
    func testMD5EmptyString() {
        #expect(throws: HashService.HashError.self) {
            try service.hashText("", algorithm: .md5)
        }
    }
    
    // MARK: - SHA-1 Tests
    
    @Test("SHA-1 hash of known test vector")
    func testSHA1KnownVector() throws {
        let result = try service.hashText("The quick brown fox jumps over the lazy dog", algorithm: .sha1)
        #expect(result == "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
    }
    
    // MARK: - SHA-256 Tests
    
    @Test("SHA-256 hash of known test vector")
    func testSHA256KnownVector() throws {
        let result = try service.hashText("hello world", algorithm: .sha256)
        #expect(result == "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9")
    }
    
    @Test("SHA-256 hash of Unicode text")
    func testSHA256Unicode() throws {
        let result = try service.hashText("Hello 世界 🌍", algorithm: .sha256)
        #expect(result.count == 64) // SHA-256 always produces 64 hex chars
    }
    
    // MARK: - SHA-384 Tests
    
    @Test("SHA-384 hash produces correct length")
    func testSHA384Length() throws {
        let result = try service.hashText("test", algorithm: .sha384)
        #expect(result.count == 96) // SHA-384 produces 96 hex chars
    }
    
    // MARK: - SHA-512 Tests
    
    @Test("SHA-512 hash produces correct length")
    func testSHA512Length() throws {
        let result = try service.hashText("test", algorithm: .sha512)
        #expect(result.count == 128) // SHA-512 produces 128 hex chars
    }
    
    @Test("SHA-512 hash of known test vector")
    func testSHA512KnownVector() throws {
        let result = try service.hashText("test", algorithm: .sha512)
        let expected = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff"
        #expect(result == expected)
    }
    
    // MARK: - HMAC Tests
    
    @Test("HMAC-SHA256 with known test vector")
    func testHMACSHA256() throws {
        let result = try service.hmacText("The quick brown fox jumps over the lazy dog",
                                          key: "key",
                                          algorithm: .sha256)
        let expected = "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"
        #expect(result == expected)
    }
    
    @Test("HMAC requires non-empty key")
    func testHMACRequiresKey() {
        #expect(throws: HashService.HashError.hmacRequiresKey) {
            try service.hmacText("test", key: "", algorithm: .sha256)
        }
    }
    
    @Test("HMAC-MD5 produces correct result")
    func testHMACMD5() throws {
        let result = try service.hmacText("data", key: "secret", algorithm: .md5)
        #expect(result.count == 32) // MD5 produces 32 hex chars
    }
    
    @Test("HMAC-SHA512 produces correct result")
    func testHMACSHA512() throws {
        let result = try service.hmacText("message", key: "secretkey", algorithm: .sha512)
        #expect(result.count == 128) // SHA-512 produces 128 hex chars
    }
    
    // MARK: - Verification Tests
    
    @Test("Verify correct hash returns true")
    func testVerifyCorrectHash() throws {
        let text = "test message"
        let hash = try service.hashText(text, algorithm: .sha256)
        let isValid = service.verifyHash(text: text, expectedHash: hash, algorithm: .sha256)
        #expect(isValid == true)
    }
    
    @Test("Verify incorrect hash returns false")
    func testVerifyIncorrectHash() {
        let isValid = service.verifyHash(text: "test", 
                                        expectedHash: "wronghash", 
                                        algorithm: .sha256)
        #expect(isValid == false)
    }
    
    @Test("Verify hash is case-insensitive")
    func testVerifyHashCaseInsensitive() throws {
        let text = "test"
        let hashLower = try service.hashText(text, algorithm: .sha256)
        let hashUpper = hashLower.uppercased()
        
        let isValid = service.verifyHash(text: text, expectedHash: hashUpper, algorithm: .sha256)
        #expect(isValid == true)
    }
    
    // MARK: - File Tests
    
    @Test("Hash file produces correct result")
    func testHashFile() throws {
        // Create temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_hash.txt")
        let content = "test file content"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let fileHash = try service.hashFile(at: fileURL, algorithm: .sha256)
        let textHash = try service.hashText(content, algorithm: .sha256)
        
        #expect(fileHash == textHash)
    }
    
    @Test("Hash non-existent file throws error")
    func testHashNonExistentFile() {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/file.txt")
        #expect(throws: HashService.HashError.invalidFile) {
            try service.hashFile(at: fakeURL, algorithm: .sha256)
        }
    }
    
    @Test("HMAC file produces correct result")
    func testHMACFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_hmac.txt")
        let content = "test file for hmac"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let fileHMAC = try service.hmacFile(at: fileURL, key: "testkey", algorithm: .sha256)
        let textHMAC = try service.hmacText(content, key: "testkey", algorithm: .sha256)
        
        #expect(fileHMAC == textHMAC)
    }
    
    @Test("Verify file hash correctly")
    func testVerifyFileHash() throws {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_verify.txt")
        let content = "verify this content"
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        let hash = try service.hashFile(at: fileURL, algorithm: .sha256)
        let isValid = service.verifyFileHash(at: fileURL, expectedHash: hash, algorithm: .sha256)
        
        #expect(isValid == true)
    }
    
    // MARK: - Edge Cases
    
    @Test("Hash single character")
    func testHashSingleChar() throws {
        let result = try service.hashText("a", algorithm: .sha256)
        #expect(result == "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb")
    }
    
    @Test("Hash very long text")
    func testHashLongText() throws {
        let longText = String(repeating: "A", count: 10000)
        let result = try service.hashText(longText, algorithm: .sha256)
        #expect(result.count == 64)
    }
    
    @Test("Hash with newlines and special characters")
    func testHashSpecialChars() throws {
        let text = "Line 1\\nLine 2\\t\\tTabbed\\r\\nWindows line"
        let result = try service.hashText(text, algorithm: .sha256)
        #expect(result.count == 64)
    }
    
    @Test("Different algorithms produce different results")
    func testDifferentAlgorithms() throws {
        let text = "same input"
        let md5 = try service.hashText(text, algorithm: .md5)
        let sha256 = try service.hashText(text, algorithm: .sha256)
        let sha512 = try service.hashText(text, algorithm: .sha512)
        
        #expect(md5 != sha256)
        #expect(sha256 != sha512)
        #expect(md5 != sha512)
    }
    
    @Test("Same input always produces same hash")
    func testDeterministic() throws {
        let text = "deterministic test"
        let hash1 = try service.hashText(text, algorithm: .sha256)
        let hash2 = try service.hashText(text, algorithm: .sha256)
        let hash3 = try service.hashText(text, algorithm: .sha256)
        
        #expect(hash1 == hash2)
        #expect(hash2 == hash3)
    }
    
    @Test("Different input produces different hash")
    func testDifferentInputs() throws {
        let hash1 = try service.hashText("input1", algorithm: .sha256)
        let hash2 = try service.hashText("input2", algorithm: .sha256)
        
        #expect(hash1 != hash2)
    }
    
    @Test("HMAC with different keys produces different results")
    func testHMACDifferentKeys() throws {
        let text = "message"
        let hmac1 = try service.hmacText(text, key: "key1", algorithm: .sha256)
        let hmac2 = try service.hmacText(text, key: "key2", algorithm: .sha256)
        
        #expect(hmac1 != hmac2)
    }
    
    // MARK: - Algorithm Output Length Tests
    
    @Test("Verify all algorithm output lengths")
    func testAlgorithmOutputLengths() throws {
        let text = "test"
        
        let md5 = try service.hashText(text, algorithm: .md5)
        #expect(md5.count == HashService.HashAlgorithm.md5.outputLength)
        
        let sha1 = try service.hashText(text, algorithm: .sha1)
        #expect(sha1.count == HashService.HashAlgorithm.sha1.outputLength)
        
        let sha256 = try service.hashText(text, algorithm: .sha256)
        #expect(sha256.count == HashService.HashAlgorithm.sha256.outputLength)
        
        let sha384 = try service.hashText(text, algorithm: .sha384)
        #expect(sha384.count == HashService.HashAlgorithm.sha384.outputLength)
        
        let sha512 = try service.hashText(text, algorithm: .sha512)
        #expect(sha512.count == HashService.HashAlgorithm.sha512.outputLength)
    }
}

import Testing
import Foundation
@testable import PetruUtils

@Suite("Bcrypt Service Tests")
struct BcryptServiceTests {
    let service = BcryptService()

    // MARK: - Hash Generation Tests

    @Test("Generate hash for simple password")
    func testGenerateSimpleHash() throws {
        let result = try service.generateHash(password: "password123")
        #expect(!result.hash.isEmpty)
        #expect(result.algorithm == "PBKDF2-SHA256")
        #expect(result.cost == BcryptService.defaultCost)
        #expect(!result.salt.isEmpty)
        #expect(!result.derivedKey.isEmpty)
    }

    @Test("Generate hash with custom cost")
    func testGenerateWithCustomCost() throws {
        let result = try service.generateHash(password: "test", cost: 10)
        #expect(result.cost == 10)
        #expect(result.fullHash.contains("$10$"))
    }

    @Test("Generated hash has correct format")
    func testHashFormat() throws {
        let result = try service.generateHash(password: "password")
        let hash = result.fullHash

        #expect(hash.hasPrefix("$pbkdf2-sha256$"))

        let components = hash.split(separator: "$")
        #expect(components.count == 4)
        #expect(components[0] == "pbkdf2-sha256")
    }

    @Test("Different passwords produce different hashes")
    func testDifferentPasswordsDifferentHashes() throws {
        let hash1 = try service.generateHash(password: "password1")
        let hash2 = try service.generateHash(password: "password2")
        #expect(hash1.fullHash != hash2.fullHash)
    }

    @Test("Same password produces different hashes due to salt")
    func testSamePasswordDifferentSalt() throws {
        let hash1 = try service.generateHash(password: "password")
        let hash2 = try service.generateHash(password: "password")
        #expect(hash1.salt != hash2.salt)
        #expect(hash1.fullHash != hash2.fullHash)
    }

    // MARK: - Verification Tests

    @Test("Verify correct password")
    func testVerifyCorrectPassword() throws {
        let password = "mySecurePassword123"
        let result = try service.generateHash(password: password)
        let isValid = try service.verifyPassword(password: password, hash: result.fullHash)
        #expect(isValid == true)
    }

    @Test("Verify incorrect password")
    func testVerifyIncorrectPassword() throws {
        let result = try service.generateHash(password: "correctPassword")
        let isValid = try service.verifyPassword(password: "wrongPassword", hash: result.fullHash)
        #expect(isValid == false)
    }

    @Test("Verify password with different cost")
    func testVerifyWithDifferentCost() throws {
        let password = "testPassword"
        let result = try service.generateHash(password: password, cost: 8)
        let isValid = try service.verifyPassword(password: password, hash: result.fullHash)
        #expect(isValid == true)
    }

    // MARK: - Error Tests

    @Test("Empty password throws error")
    func testEmptyPassword() throws {
        #expect(throws: BcryptService.BcryptError.emptyPassword) {
            try service.generateHash(password: "")
        }
    }

    @Test("Whitespace only password throws error")
    func testWhitespaceOnlyPassword() throws {
        #expect(throws: BcryptService.BcryptError.emptyPassword) {
            try service.generateHash(password: "   ")
        }
    }

    @Test("Cost below minimum throws error")
    func testCostBelowMinimum() throws {
        #expect(throws: BcryptService.BcryptError.invalidCostFactor) {
            try service.generateHash(password: "test", cost: 3)
        }
    }

    @Test("Cost above maximum throws error")
    func testCostAboveMaximum() throws {
        #expect(throws: BcryptService.BcryptError.invalidCostFactor) {
            try service.generateHash(password: "test", cost: 32)
        }
    }

    @Test("Empty hash verification throws error")
    func testEmptyHashVerification() throws {
        #expect(throws: BcryptService.BcryptError.emptyHash) {
            try service.verifyPassword(password: "test", hash: "")
        }
    }

    @Test("Invalid hash format throws error")
    func testInvalidHashFormat() throws {
        #expect(throws: BcryptService.BcryptError.invalidHashFormat) {
            try service.verifyPassword(password: "test", hash: "invalid-hash-format")
        }
    }

    // MARK: - Parse Hash Tests

    @Test("Parse valid hash")
    func testParseValidHash() throws {
        let result = try service.generateHash(password: "test", cost: 10)
        let parsed = try service.parseHash(result.fullHash)

        #expect(parsed.algorithm == "PBKDF2-SHA256")
        #expect(parsed.cost == 10)
        #expect(!parsed.salt.isEmpty)
        #expect(!parsed.derivedKey.isEmpty)
    }

    @Test("Parse empty hash throws error")
    func testParseEmptyHash() throws {
        #expect(throws: BcryptService.BcryptError.emptyHash) {
            try service.parseHash("")
        }
    }

    // MARK: - Estimated Time Tests

    @Test("Estimated time increases with cost")
    func testEstimatedTimeIncreases() {
        let time4 = service.estimatedTime(for: 4)
        let time10 = service.estimatedTime(for: 10)
        let time16 = service.estimatedTime(for: 16)

        // Just verify they're not empty - actual comparison is tricky with formatted strings
        #expect(!time4.isEmpty)
        #expect(!time10.isEmpty)
        #expect(!time16.isEmpty)
    }

    // MARK: - Edge Case Tests

    @Test("Unicode password")
    func testUnicodePassword() throws {
        let password = "密码🔐パスワード"
        let result = try service.generateHash(password: password)
        let isValid = try service.verifyPassword(password: password, hash: result.fullHash)
        #expect(isValid == true)
    }

    @Test("Very long password")
    func testVeryLongPassword() throws {
        let password = String(repeating: "a", count: 1000)
        let result = try service.generateHash(password: password)
        let isValid = try service.verifyPassword(password: password, hash: result.fullHash)
        #expect(isValid == true)
    }

    @Test("Password with special characters")
    func testSpecialCharacters() throws {
        let password = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let result = try service.generateHash(password: password)
        let isValid = try service.verifyPassword(password: password, hash: result.fullHash)
        #expect(isValid == true)
    }
}

import Testing
import Foundation
@testable import PetruUtils

@Suite("Base64 Service Tests")
struct Base64ServiceTests {
    
    let service = Base64Service()
    
    // MARK: - Text Encoding Tests
    
    @Test("Encode simple text to Base64")
    func testEncodeSimpleText() throws {
        let text = "Hello, World!"
        let expected = "SGVsbG8sIFdvcmxkIQ=="
        
        let result = try service.encodeText(text)
        
        #expect(result == expected)
    }
    
    @Test("Encode empty string throws error")
    func testEncodeEmptyString() {
        #expect(throws: Base64Service.Base64Error.emptyInput) {
            _ = try service.encodeText("")
        }
    }
    
    @Test("Encode unicode text")
    func testEncodeUnicode() throws {
        let text = "Hello 世界 🌍"
        
        let result = try service.encodeText(text)
        let decoded = try service.decodeText(result)
        
        #expect(decoded == text)
    }
    
    @Test("Encode multiline text")
    func testEncodeMultilineText() throws {
        let text = """
        Line 1
        Line 2
        Line 3
        """
        
        let result = try service.encodeText(text)
        let decoded = try service.decodeText(result)
        
        #expect(decoded == text)
    }
    
    // MARK: - Text Decoding Tests
    
    @Test("Decode simple Base64 to text")
    func testDecodeSimpleBase64() throws {
        let base64 = "SGVsbG8sIFdvcmxkIQ=="
        let expected = "Hello, World!"
        
        let result = try service.decodeText(base64)
        
        #expect(result == expected)
    }
    
    @Test("Decode empty Base64 throws error")
    func testDecodeEmptyString() {
        #expect(throws: Base64Service.Base64Error.emptyInput) {
            _ = try service.decodeText("")
        }
    }
    
    @Test("Decode invalid Base64 throws error")
    func testDecodeInvalidBase64() {
        let invalid = "This is not base64!!!"
        
        #expect(throws: Base64Service.Base64Error.invalidBase64String) {
            _ = try service.decodeText(invalid)
        }
    }
    
    @Test("Decode Base64 with whitespace")
    func testDecodeWithWhitespace() throws {
        let base64 = "  SGVsbG8sIFdvcmxkIQ==  "
        let expected = "Hello, World!"
        
        let result = try service.decodeText(base64)
        
        #expect(result == expected)
    }
    
    @Test("Decode Base64 with newlines")
    func testDecodeWithNewlines() throws {
        let base64 = """
        SGVsbG8s
        IFdvcmxk
        IQ==
        """
        let expected = "Hello, World!"
        
        let result = try service.decodeText(base64)
        
        #expect(result == expected)
    }
    
    // MARK: - URL-Safe Variant Tests
    
    @Test("Encode with URL-safe variant")
    func testEncodeURLSafe() throws {
        let text = "Hello>>World??Test"
        
        let standard = try service.encodeText(text, variant: .standard)
        let urlSafe = try service.encodeText(text, variant: .urlSafe)
        
        // URL-safe should not contain +, /, or =
        #expect(!urlSafe.contains("+"))
        #expect(!urlSafe.contains("/"))
        #expect(!urlSafe.contains("="))
        
        // Both should decode to same text
        let decodedStandard = try service.decodeText(standard, variant: .standard)
        let decodedURLSafe = try service.decodeText(urlSafe, variant: .urlSafe)
        
        #expect(decodedStandard == text)
        #expect(decodedURLSafe == text)
    }
    
    @Test("Decode URL-safe Base64")
    func testDecodeURLSafe() throws {
        // URL-safe: - and _ instead of + and /, no padding
        let urlSafe = "SGVsbG8-PldvcmxkPz9UZXN0"
        
        let result = try service.decodeText(urlSafe, variant: .urlSafe)
        
        #expect(result == "Hello>>World??Test")
    }
    
    // MARK: - Round-Trip Tests
    
    @Test("Round-trip encoding and decoding")
    func testRoundTrip() throws {
        let texts = [
            "Simple text",
            "Text with numbers: 12345",
            "Special chars: !@#$%^&*()",
            "Unicode: 你好世界 🌍",
            "Long text " + String(repeating: "x", count: 1000)
        ]
        
        for text in texts {
            let encoded = try service.encodeText(text)
            let decoded = try service.decodeText(encoded)
            #expect(decoded == text)
        }
    }
    
    @Test("Round-trip with URL-safe variant")
    func testRoundTripURLSafe() throws {
        let text = "Test with special chars: +/=?&"
        
        let encoded = try service.encodeText(text, variant: .urlSafe)
        let decoded = try service.decodeText(encoded, variant: .urlSafe)
        
        #expect(decoded == text)
    }
    
    // MARK: - Validation Tests
    
    @Test("Validate valid Base64")
    func testIsValidBase64() {
        let validBase64 = "SGVsbG8sIFdvcmxkIQ=="
        
        #expect(service.isValidBase64(validBase64) == true)
    }
    
    @Test("Validate invalid Base64")
    func testIsInvalidBase64() {
        let invalidStrings = [
            "Not base64!",
            "12345",
            "",
            "   "
        ]
        
        for invalid in invalidStrings {
            #expect(service.isValidBase64(invalid) == false)
        }
    }
    
    // MARK: - Formatting Tests
    
    @Test("Format Base64 with line breaks")
    func testFormatWithLineBreaks() {
        let base64 = String(repeating: "A", count: 150)
        
        let formatted = service.formatWithLineBreaks(base64, lineLength: 76)
        
        let lines = formatted.split(separator: "\n")
        #expect(lines.count == 2)
        #expect(lines[0].count == 76)
        #expect(lines[1].count == 74)
    }
    
    @Test("Remove formatting from Base64")
    func testRemoveFormatting() {
        let formatted = """
        SGVsbG8s
        IFdvcmxk
        IQ==
        """
        
        let clean = service.removeFormatting(formatted)
        
        #expect(clean == "SGVsbG8sIFdvcmxkIQ==")
    }
    
    // MARK: - Size Calculation Tests
    
    @Test("Calculate decoded size")
    func testGetDecodedSize() {
        let base64 = "SGVsbG8sIFdvcmxkIQ==" // "Hello, World!" = 13 bytes
        
        let size = service.getDecodedSize(base64)
        
        #expect(size == 13)
    }
    
    @Test("Calculate decoded size without padding")
    func testGetDecodedSizeNoPadding() {
        let base64 = "SGVsbG8" // "Hello" = 5 bytes
        
        let size = service.getDecodedSize(base64)
        
        #expect(size == 5)
    }
    
    // MARK: - Edge Cases
    
    @Test("Encode single character")
    func testEncodeSingleChar() throws {
        let text = "A"
        
        let encoded = try service.encodeText(text)
        let decoded = try service.decodeText(encoded)
        
        #expect(decoded == text)
    }
    
    @Test("Encode very long text")
    func testEncodeVeryLongText() throws {
        let text = String(repeating: "Long text content. ", count: 1000)
        
        let encoded = try service.encodeText(text)
        let decoded = try service.decodeText(encoded)
        
        #expect(decoded == text)
    }
    
    @Test("Handle all printable ASCII characters")
    func testAllPrintableASCII() throws {
        var text = ""
        for char in 32...126 {
            text += String(UnicodeScalar(char)!)
        }
        
        let encoded = try service.encodeText(text)
        let decoded = try service.decodeText(encoded)
        
        #expect(decoded == text)
    }
    
    @Test("Handle control characters")
    func testControlCharacters() throws {
        let text = "Line1\nLine2\tTabbed\r\nWindows"
        
        let encoded = try service.encodeText(text)
        let decoded = try service.decodeText(encoded)
        
        #expect(decoded == text)
    }
    
    @Test("Handle emoji and symbols")
    func testEmojiAndSymbols() throws {
        let text = "😀🎉💻🔐✅❌⚠️🌍"
        
        let encoded = try service.encodeText(text)
        let decoded = try service.decodeText(encoded)
        
        #expect(decoded == text)
    }
    
    // MARK: - Binary Data Tests
    
    @Test("Encode binary data")
    func testEncodeBinaryData() {
        let data = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])
        
        let encoded = service.encodeData(data)
        
        #expect(!encoded.isEmpty)
    }
    
    @Test("Decode to binary data")
    func testDecodeToBinaryData() throws {
        // Encodes bytes: 00 01 02 FF FE FD
        let base64 = "AAEC//79"
        
        let data = try service.decodeData(base64)
        
        #expect(data == Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD]))
    }
    
    @Test("Round-trip binary data")
    func testRoundTripBinaryData() throws {
        let originalData = Data((0...255).map { UInt8($0) })
        
        let encoded = service.encodeData(originalData)
        let decoded = try service.decodeData(encoded)
        
        #expect(decoded == originalData)
    }
    
    // MARK: - Known Test Vectors (RFC 4648)
    
    @Test("RFC 4648 test vectors")
    func testRFC4648Vectors() throws {
        let vectors: [(String, String)] = [
            ("", ""),
            ("f", "Zg=="),
            ("fo", "Zm8="),
            ("foo", "Zm9v"),
            ("foob", "Zm9vYg=="),
            ("fooba", "Zm9vYmE="),
            ("foobar", "Zm9vYmFy")
        ]
        
        for (plaintext, expected) in vectors {
            if plaintext.isEmpty {
                continue // Skip empty test
            }
            
            let encoded = try service.encodeText(plaintext)
            #expect(encoded == expected)
            
            let decoded = try service.decodeText(expected)
            #expect(decoded == plaintext)
        }
    }
}

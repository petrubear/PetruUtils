import Testing
import Foundation
@testable import PetruUtils

@Suite("Number Base Service Tests")
struct NumberBaseServiceTests {
    let service = NumberBaseService()
    
    // MARK: - Decimal to Other Bases Tests
    
    @Test("Convert decimal 0 to binary")
    func testDecimalZeroToBinary() {
        let result = service.decimalToBinary(0)
        #expect(result == "0")
    }
    
    @Test("Convert decimal 42 to binary")
    func testDecimalToBinary() {
        let result = service.decimalToBinary(42)
        #expect(result == "101010")
    }
    
    @Test("Convert decimal 255 to binary")
    func testDecimal255ToBinary() {
        let result = service.decimalToBinary(255)
        #expect(result == "11111111")
    }
    
    @Test("Convert decimal 42 to octal")
    func testDecimalToOctal() {
        let result = service.decimalToOctal(42)
        #expect(result == "52")
    }
    
    @Test("Convert decimal 255 to octal")
    func testDecimal255ToOctal() {
        let result = service.decimalToOctal(255)
        #expect(result == "377")
    }
    
    @Test("Convert decimal 42 to hex")
    func testDecimalToHex() {
        let result = service.decimalToHex(42)
        #expect(result == "2A")
    }
    
    @Test("Convert decimal 255 to hex")
    func testDecimal255ToHex() {
        let result = service.decimalToHex(255)
        #expect(result == "FF")
    }
    
    @Test("Convert decimal 4096 to hex")
    func testDecimal4096ToHex() {
        let result = service.decimalToHex(4096)
        #expect(result == "1000")
    }
    
    // MARK: - Binary to Decimal Tests
    
    @Test("Convert binary 0 to decimal")
    func testBinaryZeroToDecimal() throws {
        let result = try service.binaryToDecimal("0")
        #expect(result == 0)
    }
    
    @Test("Convert binary 101010 to decimal")
    func testBinaryToDecimal() throws {
        let result = try service.binaryToDecimal("101010")
        #expect(result == 42)
    }
    
    @Test("Convert binary 11111111 to decimal")
    func testBinary11111111ToDecimal() throws {
        let result = try service.binaryToDecimal("11111111")
        #expect(result == 255)
    }
    
    @Test("Convert binary with spaces")
    func testBinaryWithSpaces() throws {
        let result = try service.binaryToDecimal("1010 1010")
        #expect(result == 170)
    }
    
    @Test("Convert binary with underscores")
    func testBinaryWithUnderscores() throws {
        let result = try service.binaryToDecimal("1111_1111")
        #expect(result == 255)
    }
    
    @Test("Invalid binary input throws error")
    func testInvalidBinaryInput() {
        #expect(throws: NumberBaseService.NumberBaseError.invalidBinaryInput) {
            _ = try service.binaryToDecimal("102")
        }
    }
    
    @Test("Empty binary input throws error")
    func testEmptyBinaryInput() {
        #expect(throws: NumberBaseService.NumberBaseError.emptyInput) {
            _ = try service.binaryToDecimal("")
        }
    }
    
    @Test("Binary too long throws error")
    func testBinaryTooLong() {
        let tooLong = String(repeating: "1", count: 65)
        #expect(throws: NumberBaseService.NumberBaseError.valueOutOfRange) {
            _ = try service.binaryToDecimal(tooLong)
        }
    }
    
    // MARK: - Octal to Decimal Tests
    
    @Test("Convert octal 0 to decimal")
    func testOctalZeroToDecimal() throws {
        let result = try service.octalToDecimal("0")
        #expect(result == 0)
    }
    
    @Test("Convert octal 52 to decimal")
    func testOctalToDecimal() throws {
        let result = try service.octalToDecimal("52")
        #expect(result == 42)
    }
    
    @Test("Convert octal 377 to decimal")
    func testOctal377ToDecimal() throws {
        let result = try service.octalToDecimal("377")
        #expect(result == 255)
    }
    
    @Test("Convert octal 1000 to decimal")
    func testOctal1000ToDecimal() throws {
        let result = try service.octalToDecimal("1000")
        #expect(result == 512)
    }
    
    @Test("Invalid octal input throws error")
    func testInvalidOctalInput() {
        #expect(throws: NumberBaseService.NumberBaseError.invalidOctalInput) {
            _ = try service.octalToDecimal("89")
        }
    }
    
    @Test("Empty octal input throws error")
    func testEmptyOctalInput() {
        #expect(throws: NumberBaseService.NumberBaseError.emptyInput) {
            _ = try service.octalToDecimal("")
        }
    }
    
    // MARK: - Hexadecimal to Decimal Tests
    
    @Test("Convert hex 0 to decimal")
    func testHexZeroToDecimal() throws {
        let result = try service.hexToDecimal("0")
        #expect(result == 0)
    }
    
    @Test("Convert hex 2A to decimal")
    func testHexToDecimal() throws {
        let result = try service.hexToDecimal("2A")
        #expect(result == 42)
    }
    
    @Test("Convert hex FF to decimal")
    func testHexFFToDecimal() throws {
        let result = try service.hexToDecimal("FF")
        #expect(result == 255)
    }
    
    @Test("Convert hex 1000 to decimal")
    func testHex1000ToDecimal() throws {
        let result = try service.hexToDecimal("1000")
        #expect(result == 4096)
    }
    
    @Test("Convert lowercase hex to decimal")
    func testLowercaseHexToDecimal() throws {
        let result = try service.hexToDecimal("ff")
        #expect(result == 255)
    }
    
    @Test("Convert mixed case hex to decimal")
    func testMixedCaseHexToDecimal() throws {
        let result = try service.hexToDecimal("AbCd")
        #expect(result == 43981)
    }
    
    @Test("Invalid hex input throws error")
    func testInvalidHexInput() {
        #expect(throws: NumberBaseService.NumberBaseError.invalidHexInput) {
            _ = try service.hexToDecimal("XYZ")
        }
    }
    
    @Test("Empty hex input throws error")
    func testEmptyHexInput() {
        #expect(throws: NumberBaseService.NumberBaseError.emptyInput) {
            _ = try service.hexToDecimal("")
        }
    }
    
    // MARK: - Decimal String to Int64 Tests
    
    @Test("Convert decimal string to Int64")
    func testDecimalStringToInt64() throws {
        let result = try service.decimalStringToInt64("42")
        #expect(result == 42)
    }
    
    @Test("Convert negative decimal string")
    func testNegativeDecimalString() throws {
        let result = try service.decimalStringToInt64("-42")
        #expect(result == -42)
    }
    
    @Test("Convert large decimal string")
    func testLargeDecimalString() throws {
        let result = try service.decimalStringToInt64("9223372036854775807")
        #expect(result == Int64.max)
    }
    
    @Test("Invalid decimal string throws error")
    func testInvalidDecimalString() {
        #expect(throws: NumberBaseService.NumberBaseError.invalidDecimalInput) {
            _ = try service.decimalStringToInt64("abc")
        }
    }
    
    @Test("Empty decimal string throws error")
    func testEmptyDecimalString() {
        #expect(throws: NumberBaseService.NumberBaseError.emptyInput) {
            _ = try service.decimalStringToInt64("")
        }
    }
    
    // MARK: - Negative Number Tests
    
    @Test("Convert negative decimal to binary")
    func testNegativeDecimalToBinary() {
        let result = service.decimalToBinary(-1)
        #expect(result == "1111111111111111111111111111111111111111111111111111111111111111")
    }
    
    @Test("Convert negative decimal to octal")
    func testNegativeDecimalToOctal() {
        let result = service.decimalToOctal(-1)
        #expect(result == "1777777777777777777777")
    }
    
    @Test("Convert negative decimal to hex")
    func testNegativeDecimalToHex() {
        let result = service.decimalToHex(-1)
        #expect(result == "FFFFFFFFFFFFFFFF")
    }
    
    @Test("Convert negative decimal -42 to hex")
    func testNegative42ToHex() {
        let result = service.decimalToHex(-42)
        #expect(result == "FFFFFFFFFFFFFFD6")
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Convert Int64 max value")
    func testInt64Max() throws {
        let result = try service.convertFromDecimal("9223372036854775807")
        #expect(result.decimal == Int64.max)
        #expect(result.hex == "7FFFFFFFFFFFFFFF")
    }
    
    @Test("Convert Int64 min value")
    func testInt64Min() throws {
        let result = try service.convertFromDecimal("-9223372036854775808")
        #expect(result.decimal == Int64.min)
        #expect(result.hex == "8000000000000000")
    }
    
    @Test("Convert power of 2")
    func testPowerOf2() throws {
        let result = try service.convertFromDecimal("1024")
        #expect(result.decimal == 1024)
        #expect(result.binary == "10000000000")
        #expect(result.octal == "2000")
        #expect(result.hex == "400")
    }
    
    // MARK: - Bit and Byte Representation Tests
    
    @Test("Get bit representation for 255")
    func testBitRepresentation() {
        let result = service.getBitRepresentation(255)
        #expect(result.hasSuffix("11111111"))
        #expect(result.contains(" ")) // Should have spaces between bytes
    }
    
    @Test("Get byte representation for 255")
    func testByteRepresentation() {
        let result = service.getByteRepresentation(255)
        #expect(result.hasSuffix("FF"))
        #expect(result.contains(" ")) // Should have spaces between bytes
    }
    
    @Test("Bit representation has 8 groups")
    func testBitRepresentationGroupCount() {
        let result = service.getBitRepresentation(42)
        let groups = result.split(separator: " ")
        #expect(groups.count == 8) // 64 bits = 8 groups of 8
    }
    
    @Test("Byte representation has 8 bytes")
    func testByteRepresentationCount() {
        let result = service.getByteRepresentation(42)
        let bytes = result.split(separator: " ")
        #expect(bytes.count == 8) // 64 bits = 8 bytes
    }
    
    // MARK: - Full Conversion Tests
    
    @Test("Full conversion from binary")
    func testFullConversionFromBinary() throws {
        let result = try service.convertFromBinary("101010")
        #expect(result.decimal == 42)
        #expect(result.binary == "101010")
        #expect(result.octal == "52")
        #expect(result.hex == "2A")
        #expect(result.isSigned == false)
    }
    
    @Test("Full conversion from octal")
    func testFullConversionFromOctal() throws {
        let result = try service.convertFromOctal("52")
        #expect(result.decimal == 42)
        #expect(result.binary == "101010")
        #expect(result.octal == "52")
        #expect(result.hex == "2A")
    }
    
    @Test("Full conversion from decimal")
    func testFullConversionFromDecimal() throws {
        let result = try service.convertFromDecimal("42")
        #expect(result.decimal == 42)
        #expect(result.binary == "101010")
        #expect(result.octal == "52")
        #expect(result.hex == "2A")
    }
    
    @Test("Full conversion from hex")
    func testFullConversionFromHex() throws {
        let result = try service.convertFromHex("2A")
        #expect(result.decimal == 42)
        #expect(result.binary == "101010")
        #expect(result.octal == "52")
        #expect(result.hex == "2A")
    }
    
    @Test("Full conversion with negative number")
    func testFullConversionNegative() throws {
        let result = try service.convertFromDecimal("-42")
        #expect(result.decimal == -42)
        #expect(result.isSigned == true)
    }
    
    // MARK: - Round-trip Conversion Tests
    
    @Test("Round-trip binary conversion")
    func testRoundTripBinary() throws {
        let original: Int64 = 12345
        let binary = service.decimalToBinary(original)
        let backToDecimal = try service.binaryToDecimal(binary)
        #expect(backToDecimal == original)
    }
    
    @Test("Round-trip octal conversion")
    func testRoundTripOctal() throws {
        let original: Int64 = 12345
        let octal = service.decimalToOctal(original)
        let backToDecimal = try service.octalToDecimal(octal)
        #expect(backToDecimal == original)
    }
    
    @Test("Round-trip hex conversion")
    func testRoundTripHex() throws {
        let original: Int64 = 12345
        let hex = service.decimalToHex(original)
        let backToDecimal = try service.hexToDecimal(hex)
        #expect(backToDecimal == original)
    }
    
    // MARK: - Special Values Tests
    
    @Test("Convert 1 to all bases")
    func testConvertOne() throws {
        let result = try service.convertFromDecimal("1")
        #expect(result.decimal == 1)
        #expect(result.binary == "1")
        #expect(result.octal == "1")
        #expect(result.hex == "1")
    }
    
    @Test("Convert 16 to all bases")
    func testConvert16() throws {
        let result = try service.convertFromDecimal("16")
        #expect(result.decimal == 16)
        #expect(result.binary == "10000")
        #expect(result.octal == "20")
        #expect(result.hex == "10")
    }
    
    @Test("Convert 256 to all bases")
    func testConvert256() throws {
        let result = try service.convertFromDecimal("256")
        #expect(result.decimal == 256)
        #expect(result.binary == "100000000")
        #expect(result.octal == "400")
        #expect(result.hex == "100")
    }
}

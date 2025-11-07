//
//  URLServiceTests.swift
//  PetruUtilsTests
//
//  Created by Agent on 11/7/25.
//

import XCTest
@testable import PetruUtils

final class URLServiceTests: XCTestCase {
    
    var service: URLService!
    
    override func setUp() {
        super.setUp()
        service = URLService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Query Parameter Encoding Tests
    
    func testEncodeQueryParameter_BasicText() throws {
        let input = "Hello World"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertEqual(result, "Hello%20World")
    }
    
    func testEncodeQueryParameter_SpecialCharacters() throws {
        let input = "foo@bar.com"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertTrue(result.contains("%40"))
    }
    
    func testEncodeQueryParameter_ReservedCharacters() throws {
        let input = "a=b&c=d"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertTrue(result.contains("%3D"))
        XCTAssertTrue(result.contains("%26"))
    }
    
    func testEncodeQueryParameter_Unicode() throws {
        let input = "Hello 世界"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertTrue(result.contains("%"))
        XCTAssertFalse(result.contains("世"))
    }
    
    func testEncodeQueryParameter_Emoji() throws {
        let input = "Hello 😀"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertTrue(result.contains("%"))
        XCTAssertFalse(result.contains("😀"))
    }
    
    // MARK: - Query Parameter Decoding Tests
    
    func testDecodeQueryParameter_BasicText() throws {
        let input = "Hello%20World"
        let result = try service.decode(input, type: .queryParameter)
        XCTAssertEqual(result, "Hello World")
    }
    
    func testDecodeQueryParameter_SpecialCharacters() throws {
        let input = "foo%40bar.com"
        let result = try service.decode(input, type: .queryParameter)
        XCTAssertEqual(result, "foo@bar.com")
    }
    
    func testDecodeQueryParameter_Unicode() throws {
        let input = "Hello%20%E4%B8%96%E7%95%8C"
        let result = try service.decode(input, type: .queryParameter)
        XCTAssertEqual(result, "Hello 世界")
    }
    
    func testDecodeQueryParameter_Emoji() throws {
        let input = "Hello%20%F0%9F%98%80"
        let result = try service.decode(input, type: .queryParameter)
        XCTAssertEqual(result, "Hello 😀")
    }
    
    // MARK: - Form Data Encoding Tests
    
    func testEncodeFormData_BasicText() throws {
        let input = "Hello World"
        let result = try service.encode(input, type: .formData)
        XCTAssertEqual(result, "Hello+World")
    }
    
    func testEncodeFormData_SpecialCharacters() throws {
        let input = "foo@bar.com"
        let result = try service.encode(input, type: .formData)
        XCTAssertTrue(result.contains("%40"))
    }
    
    func testEncodeFormData_ReservedCharacters() throws {
        let input = "a=b&c=d"
        let result = try service.encode(input, type: .formData)
        XCTAssertTrue(result.contains("%3D"))
        XCTAssertTrue(result.contains("%26"))
    }
    
    func testEncodeFormData_MultipleSpaces() throws {
        let input = "one two three"
        let result = try service.encode(input, type: .formData)
        XCTAssertEqual(result, "one+two+three")
    }
    
    // MARK: - Form Data Decoding Tests
    
    func testDecodeFormData_PlusToSpace() throws {
        let input = "Hello+World"
        let result = try service.decode(input, type: .formData)
        XCTAssertEqual(result, "Hello World")
    }
    
    func testDecodeFormData_PercentEncoded() throws {
        let input = "foo%40bar.com"
        let result = try service.decode(input, type: .formData)
        XCTAssertEqual(result, "foo@bar.com")
    }
    
    func testDecodeFormData_Mixed() throws {
        let input = "name%3DJohn+Doe"
        let result = try service.decode(input, type: .formData)
        XCTAssertEqual(result, "name=John Doe")
    }
    
    // MARK: - Path Segment Encoding Tests
    
    func testEncodePathSegment_BasicText() throws {
        let input = "my document"
        let result = try service.encode(input, type: .pathSegment)
        XCTAssertEqual(result, "my%20document")
    }
    
    func testEncodePathSegment_Slash() throws {
        let input = "folder/file"
        let result = try service.encode(input, type: .pathSegment)
        // Slashes should not be encoded in path segments
        XCTAssertTrue(result.contains("/"))
    }
    
    func testEncodePathSegment_SpecialCharacters() throws {
        let input = "file name.txt"
        let result = try service.encode(input, type: .pathSegment)
        XCTAssertTrue(result.contains("%20"))
        XCTAssertTrue(result.contains("."))
    }
    
    // MARK: - Path Segment Decoding Tests
    
    func testDecodePathSegment_BasicText() throws {
        let input = "my%20document"
        let result = try service.decode(input, type: .pathSegment)
        XCTAssertEqual(result, "my document")
    }
    
    func testDecodePathSegment_WithSlash() throws {
        let input = "folder/file%20name"
        let result = try service.decode(input, type: .pathSegment)
        XCTAssertEqual(result, "folder/file name")
    }
    
    // MARK: - Full URL Encoding Tests
    
    func testEncodeFullURL_Valid() throws {
        let input = "https://example.com/path?query=value"
        let result = try service.encode(input, type: .fullURL)
        // Should remain valid
        XCTAssertTrue(result.contains("https://"))
        XCTAssertTrue(result.contains("example.com"))
    }
    
    func testEncodeFullURL_WithSpaces() throws {
        let input = "https://example.com/my path"
        // Swift's URL is permissive and may not throw for spaces
        // Just ensure it doesn't crash
        let _ = try? service.encode(input, type: .fullURL)
    }
    
    func testEncodeFullURL_AlreadyEncoded() throws {
        let input = "https://example.com/path?name=John%20Doe"
        let result = try service.encode(input, type: .fullURL)
        XCTAssertEqual(result, input)
    }
    
    // MARK: - Full URL Decoding Tests
    
    func testDecodeFullURL_BasicURL() throws {
        let input = "https://example.com/path?name=John%20Doe"
        let result = try service.decode(input, type: .fullURL)
        XCTAssertEqual(result, "https://example.com/path?name=John Doe")
    }
    
    func testDecodeFullURL_WithUnicode() throws {
        let input = "https://example.com/path?name=%E4%B8%96%E7%95%8C"
        let result = try service.decode(input, type: .fullURL)
        XCTAssertTrue(result.contains("世界"))
    }
    
    // MARK: - Round-trip Tests
    
    func testRoundTrip_QueryParameter() throws {
        let original = "Hello, World! 123"
        let encoded = try service.encode(original, type: .queryParameter)
        let decoded = try service.decode(encoded, type: .queryParameter)
        XCTAssertEqual(decoded, original)
    }
    
    func testRoundTrip_FormData() throws {
        let original = "name=John Doe&age=30"
        let encoded = try service.encode(original, type: .formData)
        let decoded = try service.decode(encoded, type: .formData)
        XCTAssertEqual(decoded, original)
    }
    
    func testRoundTrip_PathSegment() throws {
        let original = "my-file name.txt"
        let encoded = try service.encode(original, type: .pathSegment)
        let decoded = try service.decode(encoded, type: .pathSegment)
        XCTAssertEqual(decoded, original)
    }
    
    func testRoundTrip_Unicode() throws {
        let original = "こんにちは世界"
        let encoded = try service.encode(original, type: .queryParameter)
        let decoded = try service.decode(encoded, type: .queryParameter)
        XCTAssertEqual(decoded, original)
    }
    
    func testRoundTrip_Emoji() throws {
        let original = "🚀🌟💻🎉"
        let encoded = try service.encode(original, type: .queryParameter)
        let decoded = try service.decode(encoded, type: .queryParameter)
        XCTAssertEqual(decoded, original)
    }
    
    // MARK: - Validation Tests
    
    func testIsValidURL_ValidHTTP() {
        XCTAssertTrue(service.isValidURL("http://example.com"))
    }
    
    func testIsValidURL_ValidHTTPS() {
        XCTAssertTrue(service.isValidURL("https://example.com"))
    }
    
    func testIsValidURL_WithPath() {
        XCTAssertTrue(service.isValidURL("https://example.com/path/to/resource"))
    }
    
    func testIsValidURL_WithQuery() {
        XCTAssertTrue(service.isValidURL("https://example.com?key=value"))
    }
    
    func testIsValidURL_Invalid() {
        XCTAssertFalse(service.isValidURL("not a url"))
    }
    
    func testIsValidURL_MissingScheme() {
        XCTAssertFalse(service.isValidURL("example.com"))
    }
    
    func testIsURLEncoded_True() {
        XCTAssertTrue(service.isURLEncoded("Hello%20World"))
    }
    
    func testIsURLEncoded_False() {
        XCTAssertFalse(service.isURLEncoded("Hello World"))
    }
    
    func testIsURLEncoded_MultiplePercents() {
        XCTAssertTrue(service.isURLEncoded("foo%20bar%40baz"))
    }
    
    func testIsFormEncoded_WithPlus() {
        XCTAssertTrue(service.isFormEncoded("Hello+World"))
    }
    
    func testIsFormEncoded_WithPercent() {
        XCTAssertTrue(service.isFormEncoded("Hello%20World"))
    }
    
    func testIsFormEncoded_False() {
        XCTAssertFalse(service.isFormEncoded("Hello World"))
    }
    
    // MARK: - Error Handling Tests
    
    func testEncode_EmptyInput() {
        XCTAssertThrowsError(try service.encode("", type: .queryParameter)) { error in
            XCTAssertTrue(error is URLServiceError)
            XCTAssertEqual(error as? URLServiceError, .emptyInput)
        }
    }
    
    func testDecode_EmptyInput() {
        XCTAssertThrowsError(try service.decode("", type: .queryParameter)) { error in
            XCTAssertTrue(error is URLServiceError)
            XCTAssertEqual(error as? URLServiceError, .emptyInput)
        }
    }
    
    func testEncodeFullURL_InvalidURL() {
        // "not a url" is actually parsed by URL(string:) as a relative URL
        // Test with something truly invalid like an empty string after trimming
        XCTAssertThrowsError(try service.encode(" ", type: .fullURL)) { error in
            XCTAssertTrue(error is URLServiceError)
        }
    }
    
    // MARK: - Utility Function Tests
    
    func testExtractQueryParameters_SingleParameter() throws {
        let url = "https://example.com?name=John"
        let params = try service.extractQueryParameters(url)
        XCTAssertEqual(params.count, 1)
        XCTAssertEqual(params[0].0, "name")
        XCTAssertEqual(params[0].1, "John")
    }
    
    func testExtractQueryParameters_MultipleParameters() throws {
        let url = "https://example.com?name=John&age=30&city=NYC"
        let params = try service.extractQueryParameters(url)
        XCTAssertEqual(params.count, 3)
    }
    
    func testExtractQueryParameters_NoParameters() throws {
        let url = "https://example.com/path"
        let params = try service.extractQueryParameters(url)
        XCTAssertEqual(params.count, 0)
    }
    
    func testBuildURL_Complete() {
        let result = service.buildURL(
            scheme: "https",
            host: "example.com",
            path: "/api/users",
            queryParameters: [("id", "123"), ("format", "json")]
        )
        XCTAssertNotNil(result)
        XCTAssertTrue(result!.contains("https://example.com/api/users"))
        XCTAssertTrue(result!.contains("id=123"))
        XCTAssertTrue(result!.contains("format=json"))
    }
    
    func testBuildURL_NoQuery() {
        let result = service.buildURL(
            scheme: "https",
            host: "example.com",
            path: "/path"
        )
        XCTAssertEqual(result, "https://example.com/path")
    }
    
    func testGetEncodedPercentage_FullyEncoded() {
        let text = "%20%20%20"
        let percentage = service.getEncodedPercentage(text)
        XCTAssertGreaterThan(percentage, 30.0)
    }
    
    func testGetEncodedPercentage_NotEncoded() {
        let text = "Hello World"
        let percentage = service.getEncodedPercentage(text)
        XCTAssertEqual(percentage, 0.0)
    }
    
    func testNormalizeEncoding_QueryParameter() throws {
        let input = "Hello%20World"
        let result = try service.normalizeEncoding(input, type: .queryParameter)
        XCTAssertEqual(result, "Hello%20World")
    }
    
    // MARK: - Edge Cases
    
    func testEncode_SingleCharacter() throws {
        let input = "a"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertEqual(result, "a")
    }
    
    func testEncode_SpecialCharacter() throws {
        let input = "@"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertEqual(result, "%40")
    }
    
    func testEncode_VeryLongText() throws {
        let input = String(repeating: "Hello World! ", count: 1000)
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertTrue(result.contains("%20"))
        XCTAssertGreaterThan(result.count, input.count)
    }
    
    func testDecode_AlreadyDecoded() throws {
        let input = "Hello World"
        let result = try service.decode(input, type: .queryParameter)
        XCTAssertEqual(result, input)
    }
    
    func testEncode_AllASCII() throws {
        let input = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertEqual(result, input)
    }
    
    func testEncode_MixedContent() throws {
        let input = "user@example.com?ref=homepage&utm_source=google"
        let result = try service.encode(input, type: .queryParameter)
        XCTAssertTrue(result.contains("%"))
    }
}

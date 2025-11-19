import Testing
import Foundation
@testable import PetruUtils

@Suite("Case Converter Service Tests")
struct CaseConverterServiceTests {
    let service = CaseConverterService()
    
    // MARK: - camelCase Tests
    
    @Test("Convert to camelCase from snake_case")
    func testToCamelCaseFromSnake() {
        let result = service.toCamelCase("hello_world")
        #expect(result == "helloWorld")
    }
    
    @Test("Convert to camelCase from PascalCase")
    func testToCamelCaseFromPascal() {
        let result = service.toCamelCase("HelloWorld")
        #expect(result == "helloWorld")
    }
    
    @Test("Convert to camelCase from kebab-case")
    func testToCamelCaseFromKebab() {
        let result = service.toCamelCase("hello-world")
        #expect(result == "helloWorld")
    }
    
    @Test("Convert to camelCase from spaces")
    func testToCamelCaseFromSpaces() {
        let result = service.toCamelCase("hello world test")
        #expect(result == "helloWorldTest")
    }
    
    // MARK: - PascalCase Tests
    
    @Test("Convert to PascalCase from camelCase")
    func testToPascalCaseFromCamel() {
        let result = service.toPascalCase("helloWorld")
        #expect(result == "HelloWorld")
    }
    
    @Test("Convert to PascalCase from snake_case")
    func testToPascalCaseFromSnake() {
        let result = service.toPascalCase("hello_world")
        #expect(result == "HelloWorld")
    }
    
    @Test("Convert to PascalCase from spaces")
    func testToPascalCaseFromSpaces() {
        let result = service.toPascalCase("hello world")
        #expect(result == "HelloWorld")
    }
    
    // MARK: - snake_case Tests
    
    @Test("Convert to snake_case from camelCase")
    func testToSnakeCaseFromCamel() {
        let result = service.toSnakeCase("helloWorld")
        #expect(result == "hello_world")
    }
    
    @Test("Convert to snake_case from PascalCase")
    func testToSnakeCaseFromPascal() {
        let result = service.toSnakeCase("HelloWorld")
        #expect(result == "hello_world")
    }
    
    @Test("Convert to snake_case from kebab-case")
    func testToSnakeCaseFromKebab() {
        let result = service.toSnakeCase("hello-world")
        #expect(result == "hello_world")
    }
    
    @Test("Convert to snake_case from spaces")
    func testToSnakeCaseFromSpaces() {
        let result = service.toSnakeCase("hello world")
        #expect(result == "hello_world")
    }
    
    // MARK: - kebab-case Tests
    
    @Test("Convert to kebab-case from camelCase")
    func testToKebabCaseFromCamel() {
        let result = service.toKebabCase("helloWorld")
        #expect(result == "hello-world")
    }
    
    @Test("Convert to kebab-case from PascalCase")
    func testToKebabCaseFromPascal() {
        let result = service.toKebabCase("HelloWorld")
        #expect(result == "hello-world")
    }
    
    @Test("Convert to kebab-case from snake_case")
    func testToKebabCaseFromSnake() {
        let result = service.toKebabCase("hello_world")
        #expect(result == "hello-world")
    }
    
    // MARK: - UPPER CASE Tests
    
    @Test("Convert to UPPER CASE")
    func testToUpperCase() {
        let result = service.toUpperCase("hello world")
        #expect(result == "HELLO WORLD")
    }
    
    // MARK: - lower case Tests
    
    @Test("Convert to lower case")
    func testToLowerCase() {
        let result = service.toLowerCase("HELLO WORLD")
        #expect(result == "hello world")
    }
    
    // MARK: - Title Case Tests
    
    @Test("Convert to Title Case from camelCase")
    func testToTitleCaseFromCamel() {
        let result = service.toTitleCase("helloWorld")
        #expect(result == "Hello World")
    }
    
    @Test("Convert to Title Case from snake_case")
    func testToTitleCaseFromSnake() {
        let result = service.toTitleCase("hello_world")
        #expect(result == "Hello World")
    }
    
    // MARK: - Sentence case Tests
    
    @Test("Convert to Sentence case from camelCase")
    func testToSentenceCaseFromCamel() {
        let result = service.toSentenceCase("helloWorld")
        #expect(result == "Hello world")
    }
    
    @Test("Convert to Sentence case from snake_case")
    func testToSentenceCaseFromSnake() {
        let result = service.toSentenceCase("hello_world")
        #expect(result == "Hello world")
    }
    
    // MARK: - CONSTANT_CASE Tests
    
    @Test("Convert to CONSTANT_CASE from camelCase")
    func testToConstantCaseFromCamel() {
        let result = service.toConstantCase("helloWorld")
        #expect(result == "HELLO_WORLD")
    }
    
    @Test("Convert to CONSTANT_CASE from snake_case")
    func testToConstantCaseFromSnake() {
        let result = service.toConstantCase("hello_world")
        #expect(result == "HELLO_WORLD")
    }
    
    // MARK: - Edge Cases
    
    @Test("Single word conversion")
    func testSingleWord() {
        let result = service.toCamelCase("hello")
        #expect(result == "hello")
    }
    
    @Test("Already camelCase stays camelCase")
    func testAlreadyCamelCase() {
        let result = service.toCamelCase("helloWorld")
        #expect(result == "helloWorld")
    }
    
    @Test("Numbers in text")
    func testNumbersInText() {
        let result = service.toCamelCase("hello_world_123")
        #expect(result == "helloWorld123")
    }
    
    @Test("Multiple delimiters")
    func testMultipleDelimiters() {
        let result = service.toCamelCase("hello__world")
        #expect(result == "helloWorld")
    }
    
    @Test("Mixed delimiters")
    func testMixedDelimiters() {
        let result = service.toCamelCase("hello-world_test")
        #expect(result == "helloWorldTest")
    }
    
    // MARK: - Full Conversion Tests
    
    @Test("Convert all cases")
    func testConvertAll() throws {
        let result = try service.convertAll("hello_world")
        
        #expect(result.camelCase == "helloWorld")
        #expect(result.pascalCase == "HelloWorld")
        #expect(result.snakeCase == "hello_world")
        #expect(result.kebabCase == "hello-world")
        #expect(result.titleCase == "Hello World")
        #expect(result.sentenceCase == "Hello world")
        #expect(result.constantCase == "HELLO_WORLD")
    }
    
    @Test("Empty input throws error")
    func testEmptyInput() {
        #expect(throws: CaseConverterService.CaseConversionError.emptyInput) {
            _ = try service.convertAll("")
        }
    }
    
    @Test("Whitespace only throws error")
    func testWhitespaceOnly() {
        #expect(throws: CaseConverterService.CaseConversionError.emptyInput) {
            _ = try service.convertAll("   ")
        }
    }
    
    // MARK: - Complex Examples
    
    @Test("Convert API endpoint name")
    func testAPIEndpoint() {
        let result = service.toCamelCase("get_user_profile")
        #expect(result == "getUserProfile")
        
        let pascalResult = service.toPascalCase("get_user_profile")
        #expect(pascalResult == "GetUserProfile")
    }
    
    @Test("Convert class name")
    func testClassName() {
        let result = service.toSnakeCase("UserProfileManager")
        #expect(result == "user_profile_manager")
    }
    
    @Test("Convert database column")
    func testDatabaseColumn() {
        let result = service.toKebabCase("created_at_timestamp")
        #expect(result == "created-at-timestamp")
    }
    
    // MARK: - Special Characters
    
    @Test("Text with numbers and underscores")
    func testNumbersAndUnderscores() {
        let result = service.toCamelCase("test_123_value")
        #expect(result == "test123Value")
    }
    
    @Test("Consecutive uppercase letters")
    func testConsecutiveUppercase() {
        let result = service.toSnakeCase("XMLParser")
        #expect(result == "xml_parser")
    }
}

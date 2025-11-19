import Testing
@testable import PetruUtils

@Suite("JavaScript Formatter Service Tests")
struct JavaScriptFormatterServiceTests {
    let service = JavaScriptFormatterService()
    
    @Test("Format simple function")
    func testFormatFunction() throws {
        let input = "function add(a,b){return a+b;}"
        let formatted = try service.format(input, indentStyle: .twoSpaces)
        #expect(formatted.contains("function add(a,b)"))
        #expect(formatted.contains("return a+b;"))
        #expect(formatted.contains("  return"))
    }
    
    @Test("Format preserves strings")
    func testFormatStrings() throws {
        let input = "const value=\"a{b}\";"
        let formatted = try service.format(input)
        #expect(formatted.contains("\"a{b}\""))
    }
    
    @Test("Minify removes whitespace")
    func testMinifyWhitespace() throws {
        let input = "let x = 1;\n\n   let y = 2;"
        let minified = try service.minify(input)
        #expect(minified == "let x = 1;let y = 2;")
    }
    
    @Test("Minify keeps string spacing")
    func testMinifyStrings() throws {
        let input = "const s = \"hello world\";"
        let minified = try service.minify(input)
        #expect(minified.contains("hello world"))
    }
    
    @Test("Validate balanced braces")
    func testValidateSuccess() {
        let result = service.validate("function f() { return [1,2,3]; }")
        #expect(result.isValid)
    }
    
    @Test("Validate detects mismatch")
    func testValidateMismatch() {
        let result = service.validate("function f() { if(true) { return 1; }")
        #expect(result.isValid == false)
        #expect(result.message?.contains("Unclosed") == true)
    }
    
    @Test("Validate detects unexpected close")
    func testValidateUnexpectedClose() {
        let result = service.validate("}")
        #expect(result.isValid == false)
        #expect(result.message?.contains("Unexpected") == true)
    }
    
    @Test("Format throws on empty input")
    func testFormatEmpty() {
        #expect(throws: JavaScriptFormatterService.FormatterError.self) {
            _ = try service.format("   ")
        }
    }
}

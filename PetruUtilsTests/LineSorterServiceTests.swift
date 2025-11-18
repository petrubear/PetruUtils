import Testing
import Foundation
@testable import PetruUtils

@Suite("Line Sorter Service Tests")
struct LineSorterServiceTests {
    let service = LineSorterService()
    
    @Test("Sort lines ascending")
    func testSortAscending() {
        let input = "charlie\nalpha\nbravo"
        let result = service.sortLines(input, order: .ascending)
        #expect(result == "alpha\nbravo\ncharlie")
    }
    
    @Test("Sort lines descending")
    func testSortDescending() {
        let input = "alpha\nbravo\ncharlie"
        let result = service.sortLines(input, order: .descending)
        #expect(result == "charlie\nbravo\nalpha")
    }
    
    @Test("Sort case-insensitive")
    func testSortCaseInsensitive() {
        let input = "Banana\napple\nCherry"
        let result = service.sortLines(input, order: .ascending, caseSensitive: false)
        #expect(result == "apple\nBanana\nCherry")
    }
    
    @Test("Sort case-sensitive")
    func testSortCaseSensitive() {
        let input = "Banana\napple\nCherry"
        let result = service.sortLines(input, order: .ascending, caseSensitive: true)
        // Capital letters come before lowercase in ASCII
        #expect(result == "Banana\nCherry\napple")
    }
    
    @Test("Natural sort with numbers")
    func testNaturalSort() {
        let input = "file10.txt\nfile2.txt\nfile1.txt\nfile20.txt"
        let result = service.sortLines(input, order: .ascending, caseSensitive: true, naturalSort: true)
        #expect(result == "file1.txt\nfile2.txt\nfile10.txt\nfile20.txt")
    }
    
    @Test("Reverse lines")
    func testReverse() {
        let input = "first\nsecond\nthird"
        let result = service.reverseLines(input)
        #expect(result == "third\nsecond\nfirst")
    }
    
    @Test("Count lines")
    func testLineCount() {
        let input = "line1\nline2\nline3"
        let count = service.lineCount(input)
        #expect(count == 3)
    }
    
    @Test("Handle empty lines")
    func testEmptyLines() {
        let input = "alpha\n\nbravo\n\ncharlie"
        let result = service.sortLines(input)
        #expect(result.contains("alpha"))
        #expect(result.contains("bravo"))
        #expect(result.contains("charlie"))
    }
    
    @Test("Handle single line")
    func testSingleLine() {
        let input = "single line"
        let result = service.sortLines(input)
        #expect(result == "single line")
    }
    
    @Test("Handle Unicode characters")
    func testUnicode() {
        let input = "zürich\napfel\nösterreich"
        let result = service.sortLines(input, order: .ascending, caseSensitive: false)
        #expect(result.contains("apfel"))
        #expect(result.contains("zürich"))
        #expect(result.contains("österreich"))
    }
}

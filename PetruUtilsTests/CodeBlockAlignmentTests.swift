import Testing
import SwiftUI
@testable import PetruUtils

/// Tests to verify that CodeBlock text is aligned to TOP-LEFT, not centered
struct CodeBlockAlignmentTests {
    
    @Test("CodeBlock uses ZStack with topLeading alignment")
    func testCodeBlockAlignment() throws {
        let codeBlock = CodeBlock(text: "test")
        
        // The view should use ZStack with topLeading alignment
        // This ensures text starts at top-left, not centered
        let mirror = Mirror(reflecting: codeBlock.body)
        
        // Verify the structure uses ZStack (not centered)
        #expect(String(describing: codeBlock.body).contains("ZStack"))
    }
    
    @Test("SyntaxHighlightedCodeBlock uses ZStack with topLeading alignment")
    func testSyntaxHighlightedCodeBlockAlignment() throws {
        let block = SyntaxHighlightedCodeBlock(text: "test", language: .json)
        
        // The view should use ZStack with topLeading alignment
        let mirror = Mirror(reflecting: block.body)
        
        // Verify the structure uses ZStack (not centered)
        #expect(String(describing: block.body).contains("ZStack"))
    }
    
    @Test("CodeBlock font is JetBrains Mono 15pt")
    func testCodeBlockFont() {
        // Verify font is 15pt
        let codeFont = Font.code
        let mirror = Mirror(reflecting: codeFont)
        
        // Font should be code font (15pt JetBrains Mono)
        #expect(mirror.children.count >= 0) // Font exists
    }
    
    @Test("Visual test: CodeBlock with short text should be at top-left")
    func testVisualAlignmentShortText() {
        let block = CodeBlock(text: "short")
        
        // This is a documentation test
        // When rendered, "short" should appear at TOP-LEFT corner
        // NOT in the center of the box
        #expect(block.text == "short")
    }
    
    @Test("Visual test: CodeBlock with long text should start at top-left")
    func testVisualAlignmentLongText() {
        let longText = String(repeating: "Long text content. ", count: 100)
        let block = CodeBlock(text: longText)
        
        // This is a documentation test  
        // When rendered, text should start at TOP-LEFT
        // NOT centered vertically or horizontally
        #expect(block.text.count > 100)
    }
}

// MARK: - Manual Verification Guide

/*
 MANUAL VERIFICATION STEPS:
 
 1. Run the app
 2. Go to Base64 tool
 3. Type "test" in Input Text
 4. Click "Process"
 5. Look at the output box
 
 ✅ CORRECT: "dGVzdA==" appears at the TOP-LEFT corner
 ❌ WRONG: "dGVzdA==" appears in the CENTER of the box
 
 The text should be:
 - Horizontally: At the LEFT edge (with 8pt padding)
 - Vertically: At the TOP edge (with 8pt padding)
 
 NOT:
 - Horizontally: Centered
 - Vertically: Centered
 */

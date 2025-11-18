import Testing
import Foundation
@testable import PetruUtils

@Suite("History Manager Tests")
@MainActor
struct HistoryManagerTests {
    
    @Test("Record tool usage adds to recent tools")
    func testRecordToolUsage() async {
        let historyManager = HistoryManager.shared
        historyManager.clearRecentTools()
        
        historyManager.recordToolUsage(.jwt)
        #expect(historyManager.recentTools.count == 1)
        #expect(historyManager.recentTools.first == .jwt)
        
        historyManager.recordToolUsage(.base64)
        #expect(historyManager.recentTools.count == 2)
        #expect(historyManager.recentTools.first == .base64)
    }
    
    @Test("Recent tools limited to 10 items")
    func testRecentToolsLimit() async {
        let historyManager = HistoryManager.shared
        historyManager.clearRecentTools()
        
        // Add 15 tools
        for i in 0..<15 {
            let tools: [Tool] = [.jwt, .base64, .urlEncoder, .hash, .uuid, 
                                .qr, .numberBase, .unixTimestamp, .caseConverter, 
                                .colorConverter, .jsonYAML, .jsonCSV, .markdownHTML, 
                                .jsonFormatter, .regexpTester]
            historyManager.recordToolUsage(tools[i])
        }
        
        #expect(historyManager.recentTools.count == 10)
    }
    
    @Test("Toggle favorite adds and removes tool")
    func testToggleFavorite() async {
        let historyManager = HistoryManager.shared
        
        // Start with no favorites
        if historyManager.isFavorite(.jwt) {
            historyManager.toggleFavorite(.jwt)
        }
        
        #expect(!historyManager.isFavorite(.jwt))
        
        historyManager.toggleFavorite(.jwt)
        #expect(historyManager.isFavorite(.jwt))
        
        historyManager.toggleFavorite(.jwt)
        #expect(!historyManager.isFavorite(.jwt))
    }
    
    @Test("Sorted favorites returns alphabetically sorted list")
    func testSortedFavorites() async {
        let historyManager = HistoryManager.shared
        
        // Clear existing favorites
        for tool in historyManager.sortedFavorites {
            historyManager.toggleFavorite(tool)
        }
        
        historyManager.toggleFavorite(.uuid)
        historyManager.toggleFavorite(.base64)
        historyManager.toggleFavorite(.jwt)
        
        let sorted = historyManager.sortedFavorites
        #expect(sorted.count == 3)
        #expect(sorted[0] == .base64)
        #expect(sorted[1] == .jwt)
        #expect(sorted[2] == .uuid)
        
        // Cleanup
        for tool in sorted {
            historyManager.toggleFavorite(tool)
        }
    }
    
    @Test("Add conversion to history")
    func testAddConversion() async {
        let historyManager = HistoryManager.shared
        let prefsManager = PreferencesManager.shared
        
        // Enable history
        prefsManager.historyEnabled = true
        
        let item = HistoryItem(input: "test input", output: "test output")
        historyManager.addConversion(item, for: .jwt)
        
        let history = historyManager.getHistory(for: .jwt)
        #expect(!history.isEmpty)
        #expect(history.first?.input == "test input")
        #expect(history.first?.output == "test output")
    }
    
    @Test("Clear history for specific tool")
    func testClearHistoryForTool() async {
        let historyManager = HistoryManager.shared
        let prefsManager = PreferencesManager.shared
        
        prefsManager.historyEnabled = true
        
        let item = HistoryItem(input: "test", output: "result")
        historyManager.addConversion(item, for: .base64)
        
        #expect(!historyManager.getHistory(for: .base64).isEmpty)
        
        historyManager.clearHistory(for: .base64)
        #expect(historyManager.getHistory(for: .base64).isEmpty)
    }
    
    @Test("History respects max items limit")
    func testHistoryMaxItemsLimit() async {
        let historyManager = HistoryManager.shared
        let prefsManager = PreferencesManager.shared
        
        prefsManager.historyEnabled = true
        prefsManager.historyMaxItems = 5
        
        // Clear existing history
        historyManager.clearHistory(for: .hash)
        
        // Add 10 items
        for i in 0..<10 {
            let item = HistoryItem(input: "input \(i)", output: "output \(i)")
            historyManager.addConversion(item, for: .hash)
        }
        
        let history = historyManager.getHistory(for: .hash)
        #expect(history.count == 5)
        #expect(history.first?.input == "input 9") // Most recent
    }
    
    @Test("History item preview truncation")
    func testHistoryItemPreview() async {
        let longInput = String(repeating: "a", count: 100)
        let shortInput = "short"
        
        let item1 = HistoryItem(input: longInput, output: "output")
        let item2 = HistoryItem(input: shortInput, output: "output")
        
        #expect(item1.inputPreview.count == 53) // 50 chars + "..."
        #expect(item1.inputPreview.hasSuffix("..."))
        #expect(item2.inputPreview == shortInput)
    }
}

import Foundation

struct LineSorterService {
    enum SortOrder {
        case ascending
        case descending
    }
    
    enum LineSorterError: LocalizedError {
        case emptyInput
        
        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input text is empty"
            }
        }
    }
    
    /// Sort lines alphabetically
    func sortLines(
        _ text: String,
        order: SortOrder = .ascending,
        caseSensitive: Bool = true,
        naturalSort: Bool = false
    ) -> String {
        let lines = text.components(separatedBy: .newlines)
        
        let sorted: [String]
        if naturalSort {
            sorted = lines.sorted { lhs, rhs in
                let result = caseSensitive 
                    ? lhs.localizedStandardCompare(rhs)
                    : lhs.localizedCaseInsensitiveCompare(rhs)
                return order == .ascending ? result == .orderedAscending : result == .orderedDescending
            }
        } else {
            sorted = lines.sorted { lhs, rhs in
                let comparison = caseSensitive
                    ? lhs.compare(rhs)
                    : lhs.caseInsensitiveCompare(rhs)
                return order == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
        }
        
        return sorted.joined(separator: "\n")
    }
    
    /// Reverse line order
    func reverseLines(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        return lines.reversed().joined(separator: "\n")
    }
    
    /// Shuffle lines randomly
    func shuffleLines(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        return lines.shuffled().joined(separator: "\n")
    }
    
    /// Get line count
    func lineCount(_ text: String) -> Int {
        let lines = text.components(separatedBy: .newlines)
        return lines.filter { !$0.isEmpty }.count
    }
}

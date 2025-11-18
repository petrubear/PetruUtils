import Foundation

struct LineDeduplicatorService {
    enum KeepOption {
        case first
        case last
    }
    
    /// Remove duplicate lines
    func deduplicate(
        _ text: String,
        caseSensitive: Bool = true,
        keep: KeepOption = .first,
        sortAfter: Bool = false
    ) -> String {
        let lines = text.components(separatedBy: .newlines)
        
        var uniqueLines: [String] = []
        var seenLines = Set<String>()
        
        if keep == .first {
            for line in lines {
                let key = caseSensitive ? line : line.lowercased()
                if !seenLines.contains(key) {
                    uniqueLines.append(line)
                    seenLines.insert(key)
                }
            }
        } else {
            // Keep last: process in reverse, then reverse result
            var reversedUnique: [String] = []
            for line in lines.reversed() {
                let key = caseSensitive ? line : line.lowercased()
                if !seenLines.contains(key) {
                    reversedUnique.append(line)
                    seenLines.insert(key)
                }
            }
            uniqueLines = reversedUnique.reversed()
        }
        
        if sortAfter {
            if caseSensitive {
                uniqueLines.sort()
            } else {
                uniqueLines.sort { $0.caseInsensitiveCompare($1) == .orderedAscending }
            }
        }
        
        return uniqueLines.joined(separator: "\n")
    }
    
    /// Count duplicate lines
    func countDuplicates(_ text: String, caseSensitive: Bool = true) -> Int {
        let lines = text.components(separatedBy: .newlines)
        var seenLines = Set<String>()
        var duplicateCount = 0
        
        for line in lines {
            let key = caseSensitive ? line : line.lowercased()
            if seenLines.contains(key) {
                duplicateCount += 1
            } else {
                seenLines.insert(key)
            }
        }
        
        return duplicateCount
    }
    
    /// Get statistics about duplicates
    func getStatistics(_ text: String, caseSensitive: Bool = true) -> (total: Int, unique: Int, duplicates: Int) {
        let lines = text.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var seenLines = Set<String>()
        
        for line in lines {
            let key = caseSensitive ? line : line.lowercased()
            seenLines.insert(key)
        }
        
        let total = lines.count
        let unique = seenLines.count
        let duplicates = total - unique
        
        return (total, unique, duplicates)
    }
}

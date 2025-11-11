import Foundation

struct TextDiffService {
    enum DiffType {
        case added, removed, unchanged
    }
    
    struct LineDiff {
        let lineNumber: Int
        let content: String
        let type: DiffType
    }
    
    struct DiffResult {
        let leftLines: [LineDiff]
        let rightLines: [LineDiff]
        let addedCount: Int
        let removedCount: Int
        let unchangedCount: Int
    }
    
    func compare(left: String, right: String, ignoreWhitespace: Bool = false) -> DiffResult {
        var leftText = left
        var rightText = right
        
        if ignoreWhitespace {
            leftText = left.trimmingCharacters(in: .whitespacesAndNewlines)
            rightText = right.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let leftLines = leftText.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        let rightLines = rightText.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        
        let (leftDiffs, rightDiffs) = performDiff(leftLines: leftLines, rightLines: rightLines)
        
        var added = 0
        var removed = 0
        var unchanged = 0
        
        for diff in leftDiffs {
            switch diff.type {
            case .added: added += 1
            case .removed: removed += 1
            case .unchanged: unchanged += 1
            }
        }
        
        return DiffResult(
            leftLines: leftDiffs,
            rightLines: rightDiffs,
            addedCount: added,
            removedCount: removed,
            unchangedCount: unchanged
        )
    }
    
    private func performDiff(leftLines: [String], rightLines: [String]) -> ([LineDiff], [LineDiff]) {
        var leftDiffs: [LineDiff] = []
        var rightDiffs: [LineDiff] = []
        
        var i = 0, j = 0
        
        while i < leftLines.count || j < rightLines.count {
            if i < leftLines.count && j < rightLines.count {
                if leftLines[i] == rightLines[j] {
                    // Lines are the same
                    leftDiffs.append(LineDiff(lineNumber: i + 1, content: leftLines[i], type: .unchanged))
                    rightDiffs.append(LineDiff(lineNumber: j + 1, content: rightLines[j], type: .unchanged))
                    i += 1
                    j += 1
                } else {
                    // Lines differ - check if one was removed and one added
                    leftDiffs.append(LineDiff(lineNumber: i + 1, content: leftLines[i], type: .removed))
                    rightDiffs.append(LineDiff(lineNumber: j + 1, content: rightLines[j], type: .added))
                    i += 1
                    j += 1
                }
            } else if i < leftLines.count {
                // Left has more lines (removed)
                leftDiffs.append(LineDiff(lineNumber: i + 1, content: leftLines[i], type: .removed))
                i += 1
            } else {
                // Right has more lines (added)
                rightDiffs.append(LineDiff(lineNumber: j + 1, content: rightLines[j], type: .added))
                j += 1
            }
        }
        
        return (leftDiffs, rightDiffs)
    }
}

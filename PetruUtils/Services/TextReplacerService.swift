import Foundation

struct TextReplacerService {
    enum TextReplacerError: LocalizedError {
        case invalidRegex(String)
        case emptySearchPattern
        
        var errorDescription: String? {
            switch self {
            case .invalidRegex(let pattern):
                return "Invalid regular expression: \(pattern)"
            case .emptySearchPattern:
                return "Search pattern cannot be empty"
            }
        }
    }
    
    /// Replace text using plain string matching
    func replace(
        _ text: String,
        find: String,
        replaceWith: String,
        caseSensitive: Bool = true,
        wholeWord: Bool = false
    ) throws -> String {
        guard !find.isEmpty else {
            throw TextReplacerError.emptySearchPattern
        }
        
        if wholeWord {
            // Use regex for whole word matching
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: find))\\b"
            let options: NSRegularExpression.Options = caseSensitive ? [] : [.caseInsensitive]
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
                throw TextReplacerError.invalidRegex(pattern)
            }
            
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replaceWith)
        } else {
            var result = text
            if caseSensitive {
                result = result.replacingOccurrences(of: find, with: replaceWith)
            } else {
                result = result.replacingOccurrences(of: find, with: replaceWith, options: .caseInsensitive)
            }
            return result
        }
    }
    
    /// Replace text using regex pattern
    func replaceWithRegex(
        _ text: String,
        pattern: String,
        replaceWith: String,
        caseSensitive: Bool = true
    ) throws -> String {
        guard !pattern.isEmpty else {
            throw TextReplacerError.emptySearchPattern
        }
        
        let options: NSRegularExpression.Options = caseSensitive ? [] : [.caseInsensitive]
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            throw TextReplacerError.invalidRegex(pattern)
        }
        
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replaceWith)
    }
    
    /// Count occurrences
    func countOccurrences(
        in text: String,
        find: String,
        caseSensitive: Bool = true,
        isRegex: Bool = false
    ) -> Int {
        guard !find.isEmpty else { return 0 }
        
        if isRegex {
            let options: NSRegularExpression.Options = caseSensitive ? [] : [.caseInsensitive]
            guard let regex = try? NSRegularExpression(pattern: find, options: options) else {
                return 0
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.numberOfMatches(in: text, range: range)
        } else {
            let searchOptions: String.CompareOptions = caseSensitive ? [] : [.caseInsensitive]
            var count = 0
            var searchRange = text.startIndex..<text.endIndex
            
            while let range = text.range(of: find, options: searchOptions, range: searchRange) {
                count += 1
                searchRange = range.upperBound..<text.endIndex
            }
            
            return count
        }
    }
    
    /// Validate regex pattern
    func validateRegex(_ pattern: String) -> Bool {
        guard !pattern.isEmpty else { return false }
        return (try? NSRegularExpression(pattern: pattern)) != nil
    }
}

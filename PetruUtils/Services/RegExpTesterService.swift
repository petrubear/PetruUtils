import Foundation

struct RegExpTesterService {
    enum RegexError: LocalizedError {
        case invalidPattern(String)
        case emptyPattern
        
        var errorDescription: String? {
            switch self {
            case .invalidPattern(let details): return "Invalid regex: \(details)"
            case .emptyPattern: return "Pattern cannot be empty."
            }
        }
    }
    
    struct Match {
        let range: Range<String.Index>
        let value: String
        let groups: [String]
    }
    
    struct TestResult {
        let matches: [Match]
        let matchCount: Int
        let hasMatches: Bool
    }
    
    func test(pattern: String, in text: String, caseSensitive: Bool = true) throws -> TestResult {
        guard !pattern.isEmpty else { throw RegexError.emptyPattern }
        
        do {
            var options: NSRegularExpression.Options = []
            if !caseSensitive {
                options.insert(.caseInsensitive)
            }
            
            let regex = try NSRegularExpression(pattern: pattern, options: options)
            let range = NSRange(text.startIndex..., in: text)
            let nsMatches = regex.matches(in: text, range: range)
            
            let matches = nsMatches.compactMap { nsMatch -> Match? in
                guard let matchRange = Range(nsMatch.range, in: text) else { return nil }
                let value = String(text[matchRange])
                
                var groups: [String] = []
                for i in 1..<nsMatch.numberOfRanges {
                    if let groupRange = Range(nsMatch.range(at: i), in: text) {
                        groups.append(String(text[groupRange]))
                    } else {
                        groups.append("")
                    }
                }
                
                return Match(range: matchRange, value: value, groups: groups)
            }
            
            return TestResult(matches: matches, matchCount: matches.count, hasMatches: !matches.isEmpty)
        } catch {
            throw RegexError.invalidPattern(error.localizedDescription)
        }
    }
    
    static let commonPatterns: [(name: String, pattern: String, description: String)] = [
        ("Email", #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}"#, "Match email addresses"),
        ("URL", #"https?://[^\s]+"#, "Match HTTP/HTTPS URLs"),
        ("IP Address", #"\b(?:\d{1,3}\.){3}\d{1,3}\b"#, "Match IPv4 addresses"),
        ("Phone (US)", #"\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}"#, "Match US phone numbers"),
        ("Hex Color", #"#[0-9A-Fa-f]{6}\b"#, "Match hex color codes"),
        ("Date (YYYY-MM-DD)", #"\d{4}-\d{2}-\d{2}"#, "Match ISO date format"),
        ("Time (HH:MM)", #"\d{1,2}:\d{2}"#, "Match time format"),
        ("UUID", #"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"#, "Match UUIDs"),
        ("Integer", #"-?\d+"#, "Match integers"),
        ("Decimal", #"-?\d+\.\d+"#, "Match decimal numbers")
    ]
}

import Foundation

struct StringInspectorService {
    struct Statistics {
        let characters: Int
        let charactersNoSpaces: Int
        let words: Int
        let lines: Int
        let paragraphs: Int
        let bytesUTF8: Int
        let bytesUTF16: Int
        let entropy: Double
        let lineEnding: String
        let hasEmoji: Bool
        let unicodeScalars: Int
    }
    
    /// Analyze string and return comprehensive statistics
    func analyze(_ text: String) -> Statistics {
        let characters = text.count
        let charactersNoSpaces = text.filter { !$0.isWhitespace }.count
        let words = countWords(text)
        let lines = countLines(text)
        let paragraphs = countParagraphs(text)
        let bytesUTF8 = text.utf8.count
        let bytesUTF16 = text.utf16.count
        let entropy = calculateEntropy(text)
        let lineEnding = detectLineEnding(text)
        let hasEmoji = containsEmoji(text)
        let unicodeScalars = text.unicodeScalars.count
        
        return Statistics(
            characters: characters,
            charactersNoSpaces: charactersNoSpaces,
            words: words,
            lines: lines,
            paragraphs: paragraphs,
            bytesUTF8: bytesUTF8,
            bytesUTF16: bytesUTF16,
            entropy: entropy,
            lineEnding: lineEnding,
            hasEmoji: hasEmoji,
            unicodeScalars: unicodeScalars
        )
    }
    
    /// Get character frequency analysis
    func characterFrequency(_ text: String) -> [(character: Character, count: Int)] {
        var frequency: [Character: Int] = [:]
        
        for char in text {
            frequency[char, default: 0] += 1
        }
        
        return frequency.map { (character: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
    
    /// Get Unicode code points for each character
    func unicodeCodePoints(_ text: String) -> [(character: String, codePoint: String, name: String)] {
        return text.map { char in
            let scalar = String(char).unicodeScalars.first!
            let codePoint = String(format: "U+%04X", scalar.value)
            let name = scalar.properties.name ?? "Unknown"
            return (character: String(char), codePoint: codePoint, name: name)
        }
    }
    
    // MARK: - Private Helpers
    
    private func countWords(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func countLines(_ text: String) -> Int {
        let lines = text.components(separatedBy: .newlines)
        return max(1, lines.count)
    }
    
    private func countParagraphs(_ text: String) -> Int {
        let paragraphs = text.components(separatedBy: "\n\n")
        return paragraphs.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    
    private func calculateEntropy(_ text: String) -> Double {
        guard !text.isEmpty else { return 0.0 }
        
        var frequency: [Character: Int] = [:]
        for char in text {
            frequency[char, default: 0] += 1
        }
        
        let length = Double(text.count)
        var entropy: Double = 0.0
        
        for count in frequency.values {
            let probability = Double(count) / length
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
    
    private func detectLineEnding(_ text: String) -> String {
        if text.contains("\r\n") {
            return "CRLF (Windows)"
        } else if text.contains("\r") {
            return "CR (Classic Mac)"
        } else if text.contains("\n") {
            return "LF (Unix/Mac)"
        } else {
            return "None"
        }
    }
    
    private func containsEmoji(_ text: String) -> Bool {
        return text.unicodeScalars.contains { scalar in
            scalar.properties.isEmoji
        }
    }
}

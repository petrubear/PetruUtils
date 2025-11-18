import Foundation

struct LoremIpsumService {
    enum GenerationType {
        case paragraphs
        case sentences
        case words
    }
    
    private let loremIpsumWords = [
        "lorem", "ipsum", "dolor", "sit", "amet", "consectetur", "adipiscing", "elit",
        "sed", "do", "eiusmod", "tempor", "incididunt", "ut", "labore", "et", "dolore",
        "magna", "aliqua", "enim", "ad", "minim", "veniam", "quis", "nostrud",
        "exercitation", "ullamco", "laboris", "nisi", "aliquip", "ex", "ea", "commodo",
        "consequat", "duis", "aute", "irure", "in", "reprehenderit", "voluptate",
        "velit", "esse", "cillum", "fugiat", "nulla", "pariatur", "excepteur", "sint",
        "occaecat", "cupidatat", "non", "proident", "sunt", "culpa", "qui", "officia",
        "deserunt", "mollit", "anim", "id", "est", "laborum", "pellentesque", "habitant",
        "morbi", "tristique", "senectus", "netus", "malesuada", "fames", "ac", "turpis",
        "egestas", "vestibulum", "tortor", "quam", "feugiat", "vitae", "ultricies",
        "leo", "integer", "malesuada", "fames", "ante", "primis", "faucibus", "luctus",
        "ultrices", "posuere", "cubilia", "curae", "donec", "velit", "neque", "auctor",
        "ornare", "lectus", "arcu", "bibendum", "varius", "vel", "pharetra", "augue",
        "semper", "porta", "rhoncus", "urna", "cursus", "eget", "nunc", "scelerisque"
    ]
    
    /// Generate lorem ipsum text
    func generate(type: GenerationType, count: Int, startWithLorem: Bool = true) -> String {
        guard count > 0 else { return "" }
        
        switch type {
        case .paragraphs:
            return generateParagraphs(count: count, startWithLorem: startWithLorem)
        case .sentences:
            return generateSentences(count: count, startWithLorem: startWithLorem)
        case .words:
            return generateWords(count: count, startWithLorem: startWithLorem)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateParagraphs(count: Int, startWithLorem: Bool) -> String {
        var paragraphs: [String] = []
        
        for i in 0..<count {
            let sentenceCount = Int.random(in: 4...8)
            let sentences = (0..<sentenceCount).map { _ in
                generateSentence(startWithLorem: startWithLorem && i == 0)
            }
            paragraphs.append(sentences.joined(separator: " "))
        }
        
        return paragraphs.joined(separator: "\n\n")
    }
    
    private func generateSentences(count: Int, startWithLorem: Bool) -> String {
        let sentences = (0..<count).map { i in
            generateSentence(startWithLorem: startWithLorem && i == 0)
        }
        return sentences.joined(separator: " ")
    }
    
    private func generateWords(count: Int, startWithLorem: Bool) -> String {
        var words: [String] = []
        
        if startWithLorem && count >= 2 {
            words.append("Lorem")
            words.append("ipsum")
            
            for _ in 0..<(count - 2) {
                words.append(randomWord())
            }
        } else {
            for _ in 0..<count {
                words.append(randomWord())
            }
        }
        
        return words.joined(separator: " ")
    }
    
    private func generateSentence(startWithLorem: Bool) -> String {
        let wordCount = Int.random(in: 5...15)
        var words: [String] = []
        
        if startWithLorem {
            words.append("Lorem")
            words.append("ipsum")
            for _ in 0..<(wordCount - 2) {
                words.append(randomWord())
            }
        } else {
            words.append(randomWord().capitalized)
            for _ in 0..<(wordCount - 1) {
                words.append(randomWord())
            }
        }
        
        return words.joined(separator: " ") + "."
    }
    
    private func randomWord() -> String {
        loremIpsumWords.randomElement() ?? "lorem"
    }
}

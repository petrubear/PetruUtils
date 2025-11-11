import SwiftUI

/// A view that displays text with syntax highlighting
struct SyntaxHighlightedText: View {
    let text: String
    let language: SyntaxLanguage
    
    var body: some View {
        Text(highlightedText())
            .font(.code)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    
    private func highlightedText() -> AttributedString {
        switch language {
        case .json:
            return highlightJSON(text)
        case .xml:
            return highlightXML(text)
        case .html:
            return highlightHTML(text)
        case .css:
            return highlightCSS(text)
        case .sql:
            return highlightSQL(text)
        case .plain:
            return AttributedString(text)
        }
    }
    
    private func highlightJSON(_ json: String) -> AttributedString {
        var attributed = AttributedString(json)
        
        let keyColor = Color(red: 0.6, green: 0.8, blue: 1.0)
        let stringColor = Color(red: 0.8, green: 0.9, blue: 0.7)
        let numberColor = Color(red: 0.7, green: 0.9, blue: 0.7)
        let booleanColor = Color(red: 0.8, green: 0.6, blue: 1.0)
        let nullColor = Color(red: 1.0, green: 0.6, blue: 0.6)
        
        let patterns: [(regex: String, color: Color)] = [
            (#"\"[^\"]*\"\s*:"#, keyColor),
            (#":\s*\"[^\"]*\""#, stringColor),
            (#"-?\d+\.?\d*([eE][+-]?\d+)?"#, numberColor),
            (#"\b(true|false)\b"#, booleanColor),
            (#"\bnull\b"#, nullColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = json as NSString
                let matches = regex.matches(in: json, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: json),
                       let start = AttributedString.Index(range.lowerBound, within: attributed),
                       let end = AttributedString.Index(range.upperBound, within: attributed) {
                        attributed[start..<end].foregroundColor = color
                    }
                }
            }
        }
        
        return attributed
    }
    
    private func highlightXML(_ xml: String) -> AttributedString {
        var attributed = AttributedString(xml)
        
        let tagColor = Color(red: 0.33, green: 0.67, blue: 0.95)
        let attributeNameColor = Color(red: 0.6, green: 0.8, blue: 1.0)
        let attributeValueColor = Color(red: 0.8, green: 0.9, blue: 0.7)
        let commentColor = Color(red: 0.6, green: 0.6, blue: 0.6)
        
        let patterns: [(regex: String, color: Color)] = [
            (#"<!--[\s\S]*?-->"#, commentColor),
            (#"</?[a-zA-Z][a-zA-Z0-9-]*"#, tagColor),
            (#"\s[a-zA-Z][a-zA-Z0-9-]*="#, attributeNameColor),
            (#"\"[^\"]*\""#, attributeValueColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = xml as NSString
                let matches = regex.matches(in: xml, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: xml),
                       let start = AttributedString.Index(range.lowerBound, within: attributed),
                       let end = AttributedString.Index(range.upperBound, within: attributed) {
                        attributed[start..<end].foregroundColor = color
                    }
                }
            }
        }
        
        return attributed
    }
    
    private func highlightHTML(_ html: String) -> AttributedString {
        var attributed = AttributedString(html)
        
        let tagColor = Color(red: 0.33, green: 0.67, blue: 0.95)
        let attributeNameColor = Color(red: 0.6, green: 0.8, blue: 1.0)
        let attributeValueColor = Color(red: 0.8, green: 0.9, blue: 0.7)
        let commentColor = Color(red: 0.6, green: 0.6, blue: 0.6)
        
        let patterns: [(regex: String, color: Color)] = [
            (#"<!--[\s\S]*?-->"#, commentColor),
            (#"</?[a-zA-Z][a-zA-Z0-9-]*"#, tagColor),
            (#"\s[a-zA-Z][a-zA-Z0-9-]*="#, attributeNameColor),
            (#"\"[^\"]*\""#, attributeValueColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = html as NSString
                let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: html),
                       let start = AttributedString.Index(range.lowerBound, within: attributed),
                       let end = AttributedString.Index(range.upperBound, within: attributed) {
                        attributed[start..<end].foregroundColor = color
                    }
                }
            }
        }
        
        return attributed
    }
    
    private func highlightCSS(_ css: String) -> AttributedString {
        var attributed = AttributedString(css)
        
        let selectorColor = Color(red: 0.8, green: 0.9, blue: 0.7)
        let propertyColor = Color(red: 0.6, green: 0.8, blue: 1.0)
        let valueColor = Color(red: 0.9, green: 0.8, blue: 0.6)
        let commentColor = Color(red: 0.6, green: 0.6, blue: 0.6)
        
        let patterns: [(regex: String, color: Color)] = [
            (#"/\*[\s\S]*?\*/"#, commentColor),
            (#"[a-zA-Z-]+\s*:"#, propertyColor),
            (#":\s*[^;{}]+"#, valueColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsString = css as NSString
                let matches = regex.matches(in: css, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: css),
                       let start = AttributedString.Index(range.lowerBound, within: attributed),
                       let end = AttributedString.Index(range.upperBound, within: attributed) {
                        attributed[start..<end].foregroundColor = color
                    }
                }
            }
        }
        
        return attributed
    }
    
    private func highlightSQL(_ sql: String) -> AttributedString {
        var attributed = AttributedString(sql)
        
        let keywordColor = Color(red: 0.33, green: 0.67, blue: 0.95)
        let stringColor = Color(red: 0.8, green: 0.9, blue: 0.7)
        let numberColor = Color(red: 0.9, green: 0.8, blue: 0.6)
        let commentColor = Color(red: 0.6, green: 0.6, blue: 0.6)
        
        let patterns: [(regex: String, color: Color)] = [
            (#"--[^\n]*"#, commentColor),
            (#"/\*[\s\S]*?\*/"#, commentColor),
            (#"'[^']*'"#, stringColor),
            (#"\"[^\"]*\""#, stringColor),
            (#"\b\d+\.?\d*\b"#, numberColor),
            (#"\b(SELECT|FROM|WHERE|AND|OR|NOT|IN|LIKE|BETWEEN|INSERT|INTO|VALUES|UPDATE|SET|DELETE|CREATE|TABLE|ALTER|DROP|JOIN|LEFT|RIGHT|INNER|OUTER|ON|GROUP|BY|HAVING|ORDER|ASC|DESC|LIMIT|OFFSET|AS|NULL|IS|DISTINCT|UNION|ALL|CASE|WHEN|THEN|ELSE|END)\b"#, keywordColor),
        ]
        
        for (pattern, color) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsString = sql as NSString
                let matches = regex.matches(in: sql, range: NSRange(location: 0, length: nsString.length))
                
                for match in matches {
                    if let range = Range(match.range, in: sql),
                       let start = AttributedString.Index(range.lowerBound, within: attributed),
                       let end = AttributedString.Index(range.upperBound, within: attributed) {
                        attributed[start..<end].foregroundColor = color
                    }
                }
            }
        }
        
        return attributed
    }
}

enum SyntaxLanguage {
    case json
    case xml
    case html
    case css
    case sql
    case plain
}

#Preview {
    VStack {
        SyntaxHighlightedText(
            text: """
            {
              "alg": "HS256",
              "typ": "JWT"
            }
            """,
            language: .json
        )
        .padding()
    }
}

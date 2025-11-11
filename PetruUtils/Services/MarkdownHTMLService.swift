import Foundation

struct MarkdownHTMLService {
    enum ConversionError: LocalizedError {
        case emptyInput, conversionFailed
        var errorDescription: String? {
            switch self {
            case .emptyInput: return "Input cannot be empty."
            case .conversionFailed: return "Conversion failed."
            }
        }
    }
    
    // Basic Markdown to HTML (simplified)
    func markdownToHTML(_ markdown: String) throws -> String {
        let cleaned = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ConversionError.emptyInput }
        
        var html = cleaned
        
        // Headers
        html = html.replacingOccurrences(of: #"######\s+(.+)"#, with: "<h6>$1</h6>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"#####\s+(.+)"#, with: "<h5>$1</h5>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"####\s+(.+)"#, with: "<h4>$1</h4>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"###\s+(.+)"#, with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"##\s+(.+)"#, with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"#\s+(.+)"#, with: "<h1>$1</h1>", options: .regularExpression)
        
        // Bold
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        
        // Italic
        html = html.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)
        
        // Code inline
        html = html.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)
        
        // Links
        html = html.replacingOccurrences(of: #"\[(.+?)\]\((.+?)\)"#, with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        // Line breaks
        html = html.replacingOccurrences(of: "\n\n", with: "<br><br>")
        
        return html
    }
    
    // Basic HTML to Markdown (simplified)
    func htmlToMarkdown(_ html: String) throws -> String {
        let cleaned = html.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ConversionError.emptyInput }
        
        var markdown = cleaned
        
        // Headers
        markdown = markdown.replacingOccurrences(of: #"<h1>(.+?)</h1>"#, with: "# $1", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h2>(.+?)</h2>"#, with: "## $1", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h3>(.+?)</h3>"#, with: "### $1", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h4>(.+?)</h4>"#, with: "#### $1", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h5>(.+?)</h5>"#, with: "##### $1", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<h6>(.+?)</h6>"#, with: "###### $1", options: .regularExpression)
        
        // Bold
        markdown = markdown.replacingOccurrences(of: #"<strong>(.+?)</strong>"#, with: "**$1**", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<b>(.+?)</b>"#, with: "**$1**", options: .regularExpression)
        
        // Italic
        markdown = markdown.replacingOccurrences(of: #"<em>(.+?)</em>"#, with: "*$1*", options: .regularExpression)
        markdown = markdown.replacingOccurrences(of: #"<i>(.+?)</i>"#, with: "*$1*", options: .regularExpression)
        
        // Code
        markdown = markdown.replacingOccurrences(of: #"<code>(.+?)</code>"#, with: "`$1`", options: .regularExpression)
        
        // Links
        markdown = markdown.replacingOccurrences(of: #"<a href=\"(.+?)\">(.+?)</a>"#, with: "[$2]($1)", options: .regularExpression)
        
        // Line breaks
        markdown = markdown.replacingOccurrences(of: "<br><br>", with: "\n\n")
        markdown = markdown.replacingOccurrences(of: "<br>", with: "\n")
        
        return markdown
    }
}

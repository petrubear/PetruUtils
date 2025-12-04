import Foundation

/// Service for converting SVG to CSS data URIs
struct SVGToCSSService {

    enum SVGToCSSError: LocalizedError {
        case invalidSVG
        case emptySVG
        case optimizationFailed

        var errorDescription: String? {
            switch self {
            case .invalidSVG:
                return "Invalid SVG markup. Please provide valid SVG code."
            case .emptySVG:
                return "SVG content is empty. Please provide SVG markup."
            case .optimizationFailed:
                return "Failed to optimize SVG. The SVG may have malformed content."
            }
        }
    }

    /// Output format for CSS
    enum OutputFormat {
        case backgroundImage
        case backgroundProperty
        case maskImage
        case listStyleImage
        case borderImage
        case contentProperty
    }

    /// Converts SVG to CSS data URI
    /// - Parameters:
    ///   - svg: SVG markup string
    ///   - optimize: Whether to optimize/minify the SVG
    ///   - format: CSS property format to generate
    /// - Returns: CSS code with data URI
    func convertToCSS(svg: String, optimize: Bool = true, format: OutputFormat = .backgroundImage) throws -> String {
        var processedSVG = svg.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !processedSVG.isEmpty else {
            throw SVGToCSSError.emptySVG
        }

        // Basic validation
        guard processedSVG.lowercased().contains("<svg") else {
            throw SVGToCSSError.invalidSVG
        }

        // Optimize if requested
        if optimize {
            processedSVG = try optimizeSVG(processedSVG)
        }

        // Create data URI
        let dataURI = try createDataURI(from: processedSVG)

        // Generate CSS based on format
        return generateCSS(dataURI: dataURI, format: format)
    }

    /// Optimizes SVG by removing unnecessary content
    /// - Parameter svg: Original SVG markup
    /// - Returns: Optimized SVG markup
    func optimizeSVG(_ svg: String) throws -> String {
        var optimized = svg

        // Remove XML declaration
        optimized = optimized.replacingOccurrences(
            of: #"<\?xml[^>]*\?>"#,
            with: "",
            options: .regularExpression
        )

        // Remove comments
        optimized = optimized.replacingOccurrences(
            of: #"<!--[\s\S]*?-->"#,
            with: "",
            options: .regularExpression
        )

        // Remove metadata
        optimized = optimized.replacingOccurrences(
            of: #"<metadata[\s\S]*?</metadata>"#,
            with: "",
            options: .regularExpression
        )

        // Remove title elements (usually not needed for CSS backgrounds)
        optimized = optimized.replacingOccurrences(
            of: #"<title[\s\S]*?</title>"#,
            with: "",
            options: .regularExpression
        )

        // Remove desc elements
        optimized = optimized.replacingOccurrences(
            of: #"<desc[\s\S]*?</desc>"#,
            with: "",
            options: .regularExpression
        )

        // Remove unnecessary whitespace between tags
        optimized = optimized.replacingOccurrences(
            of: #">\s+<"#,
            with: "><",
            options: .regularExpression
        )

        // Remove leading/trailing whitespace
        optimized = optimized.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove extra spaces in attributes
        optimized = optimized.replacingOccurrences(
            of: #"\s{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return optimized
    }

    /// Creates a data URI from SVG content
    /// - Parameter svg: SVG markup
    /// - Returns: Data URI string
    func createDataURI(from svg: String) throws -> String {
        // URL-encode the SVG for use in data URI
        // We use a custom encoding that's more efficient than base64 for SVG
        var encoded = svg

        // Essential characters to encode for data URIs
        // IMPORTANT: Encode % FIRST to avoid double-encoding
        let replacements: [(String, String)] = [
            ("%", "%25"),  // Encode % first!
            ("#", "%23"),
            ("\"", "'"),  // Replace double quotes with single quotes (more compact)
            ("<", "%3C"),
            (">", "%3E"),
            ("\n", "%0A"),
            ("\r", "")
        ]

        for (char, replacement) in replacements {
            encoded = encoded.replacingOccurrences(of: char, with: replacement)
        }

        return "data:image/svg+xml,\(encoded)"
    }

    /// Generates CSS code with the data URI
    /// - Parameters:
    ///   - dataURI: The SVG data URI
    ///   - format: CSS property format
    /// - Returns: Formatted CSS code
    func generateCSS(dataURI: String, format: OutputFormat) -> String {
        switch format {
        case .backgroundImage:
            return """
            background-image: url('\(dataURI)');
            """

        case .backgroundProperty:
            return """
            background: url('\(dataURI)') no-repeat center center;
            background-size: contain;
            """

        case .maskImage:
            return """
            mask-image: url('\(dataURI)');
            -webkit-mask-image: url('\(dataURI)');
            """

        case .listStyleImage:
            return """
            list-style-image: url('\(dataURI)');
            """

        case .borderImage:
            return """
            border-image: url('\(dataURI)') 30 round;
            """

        case .contentProperty:
            return """
            content: url('\(dataURI)');
            """
        }
    }

    /// Extracts SVG dimensions if present
    /// - Parameter svg: SVG markup
    /// - Returns: Tuple of (width, height) or nil if not found
    func extractDimensions(from svg: String) -> (width: String?, height: String?)? {
        let widthPattern = #"width=["\']([^"\']+)["\']"#
        let heightPattern = #"height=["\']([^"\']+)["\']"#

        let widthRegex = try? NSRegularExpression(pattern: widthPattern)
        let heightRegex = try? NSRegularExpression(pattern: heightPattern)

        let nsString = svg as NSString
        let range = NSRange(location: 0, length: nsString.length)

        var width: String?
        var height: String?

        if let widthMatch = widthRegex?.firstMatch(in: svg, range: range),
           widthMatch.numberOfRanges > 1 {
            width = nsString.substring(with: widthMatch.range(at: 1))
        }

        if let heightMatch = heightRegex?.firstMatch(in: svg, range: range),
           heightMatch.numberOfRanges > 1 {
            height = nsString.substring(with: heightMatch.range(at: 1))
        }

        return width != nil || height != nil ? (width, height) : nil
    }

    /// Validates if a string contains valid SVG markup
    /// - Parameter svg: String to validate
    /// - Returns: true if valid SVG
    func isValidSVG(_ svg: String) -> Bool {
        let trimmed = svg.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return false }

        // Check for SVG tag
        guard trimmed.lowercased().contains("<svg") else { return false }

        // Check for closing tag
        guard trimmed.lowercased().contains("</svg>") else { return false }

        return true
    }

    /// Gets the size of the data URI
    /// - Parameter dataURI: The data URI string
    /// - Returns: Size in bytes
    func getDataURISize(_ dataURI: String) -> Int {
        return dataURI.utf8.count
    }

    /// Formats file size in human-readable format
    /// - Parameter bytes: Size in bytes
    /// - Returns: Formatted string (e.g., "1.2 KB")
    func formatFileSize(_ bytes: Int) -> String {
        let kb = Double(bytes) / 1024.0

        if kb < 1 {
            return "\(bytes) bytes"
        } else if kb < 1024 {
            return String(format: "%.1f KB", kb)
        } else {
            let mb = kb / 1024.0
            return String(format: "%.2f MB", mb)
        }
    }
}

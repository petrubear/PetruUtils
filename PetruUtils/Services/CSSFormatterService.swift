import Foundation

struct CSSFormatterService {
    enum CSSError: LocalizedError {
        case emptyInput
        case invalidSCSS(String)
        case invalidLESS(String)

        var errorDescription: String? {
            switch self {
            case .emptyInput:
                return "Input is empty"
            case .invalidSCSS(let detail):
                return "Invalid SCSS: \(detail)"
            case .invalidLESS(let detail):
                return "Invalid LESS: \(detail)"
            }
        }
    }

    enum IndentStyle: String, CaseIterable {
        case twoSpaces = "2 Spaces"
        case fourSpaces = "4 Spaces"
        case tabs = "Tabs"

        var string: String {
            switch self {
            case .twoSpaces: return "  "
            case .fourSpaces: return "    "
            case .tabs: return "\t"
            }
        }
    }

    enum InputFormat: String, CaseIterable {
        case css = "CSS"
        case scss = "SCSS"
        case less = "LESS"
    }
    
    // MARK: - Format CSS
    
    func format(_ css: String, indentStyle: IndentStyle = .twoSpaces, sortProperties: Bool = false) throws -> String {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }
        
        let indent = indentStyle.string
        var formatted = ""
        var depth = 0
        var inSelector = true
        var currentLine = ""
        var properties: [String] = []
        
        var i = css.startIndex
        
        while i < css.endIndex {
            let char = css[i]
            
            switch char {
            case "{":
                // Opening brace - start of rule block
                formatted += currentLine.trimmingCharacters(in: .whitespacesAndNewlines) + " {\n"
                currentLine = ""
                depth += 1
                inSelector = false
                properties = []
                
            case "}":
                // Closing brace - end of rule block
                if !currentLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    properties.append(currentLine.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentLine = ""
                }
                
                // Sort properties if requested
                if sortProperties {
                    properties.sort()
                }
                
                // Add properties
                for property in properties {
                    if !property.isEmpty {
                        formatted += String(repeating: indent, count: depth) + property
                        if !property.hasSuffix(";") {
                            formatted += ";"
                        }
                        formatted += "\n"
                    }
                }
                
                depth = max(0, depth - 1)
                formatted += String(repeating: indent, count: depth) + "}\n"
                inSelector = true
                properties = []
                
            case ";":
                // End of property
                if !inSelector {
                    properties.append(currentLine.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentLine = ""
                } else {
                    currentLine.append(char)
                }
                
            case "\n", "\r":
                // Ignore newlines, we'll add our own
                break
                
            default:
                if !char.isWhitespace || !currentLine.isEmpty {
                    currentLine.append(char)
                }
            }
            
            i = css.index(after: i)
        }
        
        // Handle any remaining content
        if !currentLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formatted += currentLine.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
        }
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Minify CSS
    
    func minify(_ css: String) throws -> String {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }
        
        var result = css
        
        // Remove comments
        result = result.replacingOccurrences(of: "/\\*[\\s\\S]*?\\*/", with: "", options: .regularExpression)
        
        // Remove all whitespace around special characters
        result = result.replacingOccurrences(of: "\\s*([{};:,])\\s*", with: "$1", options: .regularExpression)
        
        // Remove leading/trailing whitespace
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Collapse multiple spaces into one
        result = result.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)
        
        // Add space after colon for readability
        result = result.replacingOccurrences(of: ":", with: ": ", options: .literal)
        
        // Add space after comma in selectors
        result = result.replacingOccurrences(of: ",", with: ", ", options: .literal)
        
        // Remove unnecessary spaces
        result = result.replacingOccurrences(of: ": \\s+", with: ": ", options: .regularExpression)
        result = result.replacingOccurrences(of: ", \\s+", with: ", ", options: .regularExpression)
        
        return result
    }
    
    // MARK: - Validate CSS (Basic)

    func validate(_ css: String) -> (isValid: Bool, message: String) {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (false, "Input is empty")
        }

        var braceCount = 0
        var issues: [String] = []

        for char in css {
            if char == "{" {
                braceCount += 1
            } else if char == "}" {
                braceCount -= 1
                if braceCount < 0 {
                    issues.append("Mismatched closing brace")
                    break
                }
            }
        }

        if braceCount > 0 {
            issues.append("Missing \(braceCount) closing brace(s)")
        } else if braceCount < 0 {
            issues.append("Extra closing brace(s)")
        }

        if issues.isEmpty {
            return (true, "✓ Valid CSS syntax")
        } else {
            return (false, "✗ " + issues.joined(separator: ", "))
        }
    }

    // MARK: - SCSS to CSS Conversion

    func convertSCSSToCSS(_ scss: String) throws -> String {
        guard !scss.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }

        var css = scss
        var variables: [String: String] = [:]

        // Extract and store SCSS variables ($variable: value;)
        let variablePattern = #"\$([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*([^;]+);"#
        if let regex = try? NSRegularExpression(pattern: variablePattern) {
            let matches = regex.matches(in: css, range: NSRange(css.startIndex..., in: css))
            for match in matches.reversed() {
                if let nameRange = Range(match.range(at: 1), in: css),
                   let valueRange = Range(match.range(at: 2), in: css),
                   let fullRange = Range(match.range, in: css) {
                    let name = String(css[nameRange])
                    let value = String(css[valueRange]).trimmingCharacters(in: .whitespaces)
                    variables[name] = value
                    css.removeSubrange(fullRange)
                }
            }
        }

        // Replace variable usages with their values
        for (name, value) in variables {
            css = css.replacingOccurrences(of: "$\(name)", with: value)
        }

        // Convert nested rules (basic flattening)
        css = flattenNestedRules(css)

        // Remove SCSS-specific syntax that doesn't apply
        // Remove @import statements (simplified - in real SCSS these would be resolved)
        css = css.replacingOccurrences(of: #"@import\s+[^;]+;"#, with: "", options: .regularExpression)

        // Convert @mixin and @include (basic support)
        css = processMixins(css)

        // Remove @extend (not fully supported without full compilation)
        css = css.replacingOccurrences(of: #"@extend\s+[^;]+;"#, with: "/* @extend removed */", options: .regularExpression)

        // Clean up empty lines
        css = css.replacingOccurrences(of: #"\n\s*\n\s*\n"#, with: "\n\n", options: .regularExpression)

        return css.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func flattenNestedRules(_ scss: String) -> String {
        var result = ""
        var stack: [(selector: String, properties: String)] = []
        var currentSelector = ""
        var currentProperties = ""
        var braceDepth = 0
        var i = scss.startIndex

        while i < scss.endIndex {
            let char = scss[i]

            if char == "{" {
                braceDepth += 1
                if braceDepth == 1 {
                    currentSelector = currentSelector.trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    // Nested rule - push current to stack
                    stack.append((selector: currentSelector, properties: currentProperties))
                    let nestedSelector = currentProperties.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Combine parent and child selectors
                    if nestedSelector.contains("&") {
                        currentSelector = nestedSelector.replacingOccurrences(of: "&", with: currentSelector)
                    } else {
                        currentSelector = currentSelector + " " + nestedSelector
                    }
                    currentProperties = ""
                }
            } else if char == "}" {
                braceDepth -= 1
                if braceDepth == 0 {
                    // Output the rule
                    let props = currentProperties.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !props.isEmpty && props.contains(":") {
                        result += "\(currentSelector) {\n\(formatProperties(props))\n}\n\n"
                    }
                    currentSelector = ""
                    currentProperties = ""
                } else if !stack.isEmpty {
                    // Pop from stack - output current nested rule first
                    let props = currentProperties.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !props.isEmpty && props.contains(":") {
                        result += "\(currentSelector) {\n\(formatProperties(props))\n}\n\n"
                    }
                    let parent = stack.removeLast()
                    currentSelector = parent.selector
                    currentProperties = parent.properties
                }
            } else {
                currentProperties.append(char)
            }

            i = scss.index(after: i)
        }

        return result.isEmpty ? scss : result
    }

    private func formatProperties(_ props: String) -> String {
        let lines = props.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.contains(":") }
            .map { "  \($0);" }
        return lines.joined(separator: "\n")
    }

    private func processMixins(_ scss: String) -> String {
        var css = scss
        var mixins: [String: String] = [:]

        // Extract @mixin definitions
        let mixinPattern = #"@mixin\s+([a-zA-Z_][a-zA-Z0-9_-]*)\s*(?:\([^)]*\))?\s*\{([^}]+)\}"#
        if let regex = try? NSRegularExpression(pattern: mixinPattern, options: .dotMatchesLineSeparators) {
            let matches = regex.matches(in: css, range: NSRange(css.startIndex..., in: css))
            for match in matches.reversed() {
                if let nameRange = Range(match.range(at: 1), in: css),
                   let bodyRange = Range(match.range(at: 2), in: css),
                   let fullRange = Range(match.range, in: css) {
                    let name = String(css[nameRange])
                    let body = String(css[bodyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    mixins[name] = body
                    css.removeSubrange(fullRange)
                }
            }
        }

        // Replace @include with mixin content
        for (name, body) in mixins {
            let includePattern = "@include\\s+\(name)\\s*(?:\\([^)]*\\))?\\s*;"
            css = css.replacingOccurrences(of: includePattern, with: body, options: .regularExpression)
        }

        return css
    }

    // MARK: - LESS to CSS Conversion

    func convertLESSToCSS(_ less: String) throws -> String {
        guard !less.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }

        var css = less
        var variables: [String: String] = [:]

        // Extract and store LESS variables (@variable: value;)
        let variablePattern = #"@([a-zA-Z_][a-zA-Z0-9_-]*)\s*:\s*([^;]+);"#
        if let regex = try? NSRegularExpression(pattern: variablePattern) {
            let matches = regex.matches(in: css, range: NSRange(css.startIndex..., in: css))
            for match in matches.reversed() {
                if let nameRange = Range(match.range(at: 1), in: css),
                   let valueRange = Range(match.range(at: 2), in: css),
                   let fullRange = Range(match.range, in: css) {
                    let name = String(css[nameRange])
                    // Skip CSS at-rules
                    if ["media", "keyframes", "import", "font-face", "supports", "charset"].contains(name) {
                        continue
                    }
                    let value = String(css[valueRange]).trimmingCharacters(in: .whitespaces)
                    variables[name] = value
                    css.removeSubrange(fullRange)
                }
            }
        }

        // Replace variable usages with their values
        for (name, value) in variables {
            css = css.replacingOccurrences(of: "@\(name)", with: value)
        }

        // Convert nested rules (basic flattening - same as SCSS)
        css = flattenNestedRules(css)

        // Clean up empty lines
        css = css.replacingOccurrences(of: #"\n\s*\n\s*\n"#, with: "\n\n", options: .regularExpression)

        return css.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Vendor Auto-Prefixing

    func addVendorPrefixes(_ css: String) throws -> String {
        guard !css.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CSSError.emptyInput
        }

        var result = css

        // Properties that need vendor prefixes
        let prefixedProperties: [String: [String]] = [
            "transform": ["-webkit-transform", "-ms-transform"],
            "transform-origin": ["-webkit-transform-origin", "-ms-transform-origin"],
            "transition": ["-webkit-transition", "-o-transition"],
            "transition-property": ["-webkit-transition-property", "-o-transition-property"],
            "transition-duration": ["-webkit-transition-duration", "-o-transition-duration"],
            "transition-timing-function": ["-webkit-transition-timing-function", "-o-transition-timing-function"],
            "transition-delay": ["-webkit-transition-delay", "-o-transition-delay"],
            "animation": ["-webkit-animation"],
            "animation-name": ["-webkit-animation-name"],
            "animation-duration": ["-webkit-animation-duration"],
            "animation-timing-function": ["-webkit-animation-timing-function"],
            "animation-delay": ["-webkit-animation-delay"],
            "animation-iteration-count": ["-webkit-animation-iteration-count"],
            "animation-direction": ["-webkit-animation-direction"],
            "animation-fill-mode": ["-webkit-animation-fill-mode"],
            "animation-play-state": ["-webkit-animation-play-state"],
            "flex": ["-webkit-flex", "-ms-flex"],
            "flex-direction": ["-webkit-flex-direction", "-ms-flex-direction"],
            "flex-wrap": ["-webkit-flex-wrap", "-ms-flex-wrap"],
            "flex-flow": ["-webkit-flex-flow", "-ms-flex-flow"],
            "flex-grow": ["-webkit-flex-grow", "-ms-flex-positive"],
            "flex-shrink": ["-webkit-flex-shrink", "-ms-flex-negative"],
            "flex-basis": ["-webkit-flex-basis", "-ms-flex-preferred-size"],
            "justify-content": ["-webkit-justify-content", "-ms-flex-pack"],
            "align-items": ["-webkit-align-items", "-ms-flex-align"],
            "align-self": ["-webkit-align-self", "-ms-flex-item-align"],
            "align-content": ["-webkit-align-content", "-ms-flex-line-pack"],
            "order": ["-webkit-order", "-ms-flex-order"],
            "box-shadow": ["-webkit-box-shadow"],
            "box-sizing": ["-webkit-box-sizing", "-moz-box-sizing"],
            "border-radius": ["-webkit-border-radius", "-moz-border-radius"],
            "user-select": ["-webkit-user-select", "-moz-user-select", "-ms-user-select"],
            "appearance": ["-webkit-appearance", "-moz-appearance"],
            "backdrop-filter": ["-webkit-backdrop-filter"],
            "background-clip": ["-webkit-background-clip"],
            "clip-path": ["-webkit-clip-path"],
            "filter": ["-webkit-filter"],
            "hyphens": ["-webkit-hyphens", "-ms-hyphens"],
            "mask": ["-webkit-mask"],
            "mask-image": ["-webkit-mask-image"],
            "object-fit": ["-o-object-fit"],
            "object-position": ["-o-object-position"],
            "perspective": ["-webkit-perspective"],
            "perspective-origin": ["-webkit-perspective-origin"],
            "backface-visibility": ["-webkit-backface-visibility"],
            "text-size-adjust": ["-webkit-text-size-adjust", "-ms-text-size-adjust"],
            "text-overflow": ["-o-text-overflow"],
            "writing-mode": ["-webkit-writing-mode", "-ms-writing-mode"],
        ]

        // Values that need prefixes
        let prefixedValues: [String: [String]] = [
            "linear-gradient": ["-webkit-linear-gradient", "-o-linear-gradient"],
            "radial-gradient": ["-webkit-radial-gradient", "-o-radial-gradient"],
            "repeating-linear-gradient": ["-webkit-repeating-linear-gradient", "-o-repeating-linear-gradient"],
            "repeating-radial-gradient": ["-webkit-repeating-radial-gradient", "-o-repeating-radial-gradient"],
            "calc": ["-webkit-calc"],
            "sticky": ["-webkit-sticky"],
        ]

        // Process each property
        for (property, prefixes) in prefixedProperties {
            let pattern = #"(\s*)"# + NSRegularExpression.escapedPattern(for: property) + #"\s*:\s*([^;]+);"#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                var searchRange = NSRange(result.startIndex..., in: result)
                while let match = regex.firstMatch(in: result, range: searchRange) {
                    if let indentRange = Range(match.range(at: 1), in: result),
                       let valueRange = Range(match.range(at: 2), in: result) {
                        let indent = String(result[indentRange])
                        let value = String(result[valueRange])
                        var prefixedLines = prefixes.map { "\(indent)\($0): \(value);" }
                        prefixedLines.append("\(indent)\(property): \(value);")
                        let replacement = prefixedLines.joined(separator: "\n")

                        if let fullRange = Range(match.range, in: result) {
                            result.replaceSubrange(fullRange, with: replacement)
                        }
                    }
                    // Update search range
                    let newStart = result.index(result.startIndex, offsetBy: match.range.location + 1, limitedBy: result.endIndex) ?? result.endIndex
                    searchRange = NSRange(newStart..., in: result)
                }
            }
        }

        // Note: Value prefixing (gradients, calc) is complex and skipped for now
        // The prefixedValues dictionary is defined for future use
        _ = prefixedValues

        // Apply property prefixing
        result = css
        for (property, prefixes) in prefixedProperties {
            let pattern = #"([ \t]*)"# + NSRegularExpression.escapedPattern(for: property) + #"\s*:\s*([^;]+);"#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                var offset = 0
                let matches = regex.matches(in: result, range: NSRange(result.startIndex..., in: result))
                for match in matches {
                    let adjustedRange = NSRange(location: match.range.location + offset, length: match.range.length)
                    if let fullRange = Range(adjustedRange, in: result) {
                        let matchString = String(result[fullRange])
                        // Extract indent and value from the match
                        if let indentMatch = Range(NSRange(location: match.range(at: 1).location + offset, length: match.range(at: 1).length), in: result),
                           let valueMatch = Range(NSRange(location: match.range(at: 2).location + offset, length: match.range(at: 2).length), in: result) {
                            let indent = String(result[indentMatch])
                            let value = String(result[valueMatch])

                            var prefixedLines = prefixes.map { "\(indent)\($0): \(value);" }
                            prefixedLines.append(matchString.trimmingCharacters(in: .whitespaces))
                            let replacement = prefixedLines.joined(separator: "\n\(indent)")
                            let finalReplacement = indent + replacement.trimmingCharacters(in: .whitespaces)

                            result.replaceSubrange(fullRange, with: finalReplacement)
                            offset += finalReplacement.count - matchString.count
                        }
                    }
                }
            }
        }

        return result
    }
}

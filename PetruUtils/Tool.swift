import Foundation

/// Enum for the available developer tools in your app
enum Tool: String, CaseIterable, Identifiable {
    case jwt
    case base64
    case urlEncoder
    case hash
    case uuid
    case qr
    case numberBase
    case unixTimestamp
    case caseConverter
    case colorConverter
    case jsonYAML
    case jsonCSV
    case markdownHTML
    case jsonFormatter
    case regexpTester
    case textDiff
    case xmlFormatter
    case htmlFormatter
    case cssFormatter
    case sqlFormatter
    case lineSorter
    case lineDeduplicator
    case textReplacer
    case stringInspector
    case htmlEntity
    case loremIpsum

    // For use in SwiftUI List / ForEach
    var id: String { rawValue }

    // Sidebar title
    var title: String {
        switch self {
        case .jwt: return "JWT Debugger"
        case .base64: return "Base64"
        case .urlEncoder: return "URL Encoder"
        case .hash: return "Hash Generator"
        case .uuid: return "UUID/ULID Generator"
        case .qr: return "QR Code"
        case .numberBase: return "Number Base Converter"
        case .unixTimestamp: return "Unix Timestamp"
        case .caseConverter: return "Case Converter"
        case .colorConverter: return "Color Converter"
        case .jsonYAML: return "JSON ↔ YAML"
        case .jsonCSV: return "JSON ↔ CSV"
        case .markdownHTML: return "Markdown ↔ HTML"
        case .jsonFormatter: return "JSON Formatter"
        case .regexpTester: return "RegExp Tester"
        case .textDiff: return "Text Diff"
        case .xmlFormatter: return "XML Formatter"
        case .htmlFormatter: return "HTML Formatter"
        case .cssFormatter: return "CSS Formatter"
        case .sqlFormatter: return "SQL Formatter"
        case .lineSorter: return "Line Sorter"
        case .lineDeduplicator: return "Line Deduplicator"
        case .textReplacer: return "Text Replacer"
        case .stringInspector: return "String Inspector"
        case .htmlEntity: return "HTML Entity"
        case .loremIpsum: return "Lorem Ipsum"
        }
    }

    // Optional: system SF Symbol for icon
    var iconName: String {
        switch self {
        case .jwt: return "lock.shield"
        case .base64: return "textformat.123"
        case .urlEncoder: return "link"
        case .hash: return "number.square"
        case .uuid: return "key.fill"
        case .qr: return "qrcode"
        case .numberBase: return "function"
        case .unixTimestamp: return "clock"
        case .caseConverter: return "textformat"
        case .colorConverter: return "paintpalette"
        case .jsonYAML: return "arrow.left.arrow.right"
        case .jsonCSV: return "tablecells"
        case .markdownHTML: return "doc.richtext"
        case .jsonFormatter: return "curlybraces"
        case .regexpTester: return "asterisk.circle"
        case .textDiff: return "arrow.left.arrow.right.square"
        case .xmlFormatter: return "chevron.left.forwardslash.chevron.right"
        case .htmlFormatter: return "doc.text"
        case .cssFormatter: return "paintbrush"
        case .sqlFormatter: return "cylinder"
        case .lineSorter: return "line.3.horizontal.decrease"
        case .lineDeduplicator: return "list.bullet.rectangle"
        case .textReplacer: return "text.magnifyingglass"
        case .stringInspector: return "info.circle"
        case .htmlEntity: return "chevron.left.forwardslash.chevron.right"
        case .loremIpsum: return "text.alignleft"
        }
    }
}

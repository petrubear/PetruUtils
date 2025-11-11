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
        }
    }
}

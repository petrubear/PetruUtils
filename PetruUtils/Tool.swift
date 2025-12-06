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
    case javascriptFormatter
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
    case urlParser
    case randomString
    case backslashEscape
    case base32
    case cronParser
    case jsonPath
    case curlConverter
    case svgToCSS
    case certificateInspector
    case ipUtilities
    case asciiArtGenerator
    case bcryptGenerator
    case totpGenerator

    // For use in SwiftUI List / ForEach
    var id: String { rawValue }

    // Sidebar title (localized)
    var title: String {
        switch self {
        case .jwt: return String(localized: "tool.jwt.title")
        case .base64: return String(localized: "tool.base64.title")
        case .urlEncoder: return String(localized: "tool.urlEncoder.title")
        case .hash: return String(localized: "tool.hash.title")
        case .uuid: return String(localized: "tool.uuid.title")
        case .qr: return String(localized: "tool.qr.title")
        case .numberBase: return String(localized: "tool.numberBase.title")
        case .unixTimestamp: return String(localized: "tool.unixTimestamp.title")
        case .caseConverter: return String(localized: "tool.caseConverter.title")
        case .colorConverter: return String(localized: "tool.colorConverter.title")
        case .jsonYAML: return String(localized: "tool.jsonYAML.title")
        case .jsonCSV: return String(localized: "tool.jsonCSV.title")
        case .markdownHTML: return String(localized: "tool.markdownHTML.title")
        case .jsonFormatter: return String(localized: "tool.jsonFormatter.title")
        case .javascriptFormatter: return String(localized: "tool.javascriptFormatter.title")
        case .regexpTester: return String(localized: "tool.regexpTester.title")
        case .textDiff: return String(localized: "tool.textDiff.title")
        case .xmlFormatter: return String(localized: "tool.xmlFormatter.title")
        case .htmlFormatter: return String(localized: "tool.htmlFormatter.title")
        case .cssFormatter: return String(localized: "tool.cssFormatter.title")
        case .sqlFormatter: return String(localized: "tool.sqlFormatter.title")
        case .lineSorter: return String(localized: "tool.lineSorter.title")
        case .lineDeduplicator: return String(localized: "tool.lineDeduplicator.title")
        case .textReplacer: return String(localized: "tool.textReplacer.title")
        case .stringInspector: return String(localized: "tool.stringInspector.title")
        case .htmlEntity: return String(localized: "tool.htmlEntity.title")
        case .loremIpsum: return String(localized: "tool.loremIpsum.title")
        case .urlParser: return String(localized: "tool.urlParser.title")
        case .randomString: return String(localized: "tool.randomString.title")
        case .backslashEscape: return String(localized: "tool.backslashEscape.title")
        case .base32: return String(localized: "tool.base32.title")
        case .cronParser: return String(localized: "tool.cronParser.title")
        case .jsonPath: return String(localized: "tool.jsonPath.title")
        case .curlConverter: return String(localized: "tool.curlConverter.title")
        case .svgToCSS: return String(localized: "tool.svgToCSS.title")
        case .certificateInspector: return String(localized: "tool.certificateInspector.title")
        case .ipUtilities: return String(localized: "tool.ipUtilities.title")
        case .asciiArtGenerator: return String(localized: "tool.asciiArtGenerator.title")
        case .bcryptGenerator: return String(localized: "tool.bcryptGenerator.title")
        case .totpGenerator: return String(localized: "tool.totpGenerator.title")
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
        case .javascriptFormatter: return "curlybraces.square"
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
        case .urlParser: return "link.circle"
        case .randomString: return "lock.rectangle.stack"
        case .backslashEscape: return "chevron.left.slash.chevron.right"
        case .base32: return "textformat.123"
        case .cronParser: return "clock.arrow.circlepath"
        case .jsonPath: return "arrow.triangle.branch"
        case .curlConverter: return "arrow.triangle.2.circlepath"
        case .svgToCSS: return "photo.badge.arrow.down"
        case .certificateInspector: return "doc.text.magnifyingglass"
        case .ipUtilities: return "network"
        case .asciiArtGenerator: return "textformat.abc"
        case .bcryptGenerator: return "lock.rectangle"
        case .totpGenerator: return "clock.badge.checkmark"
        }
    }
}

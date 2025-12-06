import SwiftUI

@MainActor
final class ToolRegistry {
    static let shared = ToolRegistry()
    
    private var toolViews: [Tool: () -> AnyView] = [:]
    
    init() {
        registerAllTools()
    }
    
    func register(_ tool: Tool, viewBuilder: @escaping () -> AnyView) {
        toolViews[tool] = viewBuilder
    }
    
    func view(for tool: Tool) -> AnyView {
        if let builder = toolViews[tool] {
            return builder()
        }
        return AnyView(PlaceholderView(toolName: tool.title))
    }
    
    private func registerAllTools() {
        register(.jwt) { AnyView(JWTView()) }
        register(.base64) { AnyView(Base64View()) }
        register(.urlEncoder) { AnyView(URLView()) }
        register(.hash) { AnyView(HashView()) }
        register(.uuid) { AnyView(UUIDView()) }
        register(.qr) { AnyView(QRCodeView()) }
        register(.numberBase) { AnyView(NumberBaseView()) }
        register(.unixTimestamp) { AnyView(UnixTimestampView()) }
        register(.caseConverter) { AnyView(CaseConverterView()) }
        register(.colorConverter) { AnyView(ColorConverterView()) }
        register(.jsonYAML) { AnyView(JSONYAMLView()) }
        register(.jsonCSV) { AnyView(JSONCSVView()) }
        register(.markdownHTML) { AnyView(MarkdownHTMLView()) }
        register(.jsonFormatter) { AnyView(JSONFormatterView()) }
        register(.javascriptFormatter) { AnyView(JavaScriptFormatterView()) }
        register(.regexpTester) { AnyView(RegExpTesterView()) }
        register(.textDiff) { AnyView(TextDiffView()) }
        register(.xmlFormatter) { AnyView(XMLFormatterView()) }
        register(.htmlFormatter) { AnyView(HTMLFormatterView()) }
        register(.cssFormatter) { AnyView(CSSFormatterView()) }
        register(.sqlFormatter) { AnyView(SQLFormatterView()) }
        register(.lineSorter) { AnyView(LineSorterView()) }
        register(.lineDeduplicator) { AnyView(LineDeduplicatorView()) }
        register(.textReplacer) { AnyView(TextReplacerView()) }
        register(.stringInspector) { AnyView(StringInspectorView()) }
        register(.htmlEntity) { AnyView(HTMLEntityView()) }
        register(.loremIpsum) { AnyView(LoremIpsumView()) }
        register(.urlParser) { AnyView(URLParserView()) }
        register(.randomString) { AnyView(RandomStringView()) }
        register(.backslashEscape) { AnyView(BackslashEscapeView()) }
        register(.base32) { AnyView(Base32View()) }
        register(.cronParser) { AnyView(CronParserView()) }
        register(.jsonPath) { AnyView(JSONPathView()) }
        register(.curlConverter) { AnyView(CurlConverterView()) }
        register(.svgToCSS) { AnyView(SVGToCSSView()) }
        register(.certificateInspector) { AnyView(CertificateInspectorView()) }
        register(.ipUtilities) { AnyView(IPUtilitiesView()) }
        register(.asciiArtGenerator) { AnyView(ASCIIArtGeneratorView()) }
        register(.bcryptGenerator) { AnyView(BcryptGeneratorView()) }
        register(.totpGenerator) { AnyView(TOTPGeneratorView()) }
    }
}

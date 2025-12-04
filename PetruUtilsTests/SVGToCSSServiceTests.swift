import Testing
import Foundation
@testable import PetruUtils

@Suite("SVG to CSS Service Tests")
struct SVGToCSSServiceTests {
    let service = SVGToCSSService()

    // MARK: - Basic Conversion Tests

    @Test("Convert simple SVG to CSS background-image")
    func testSimpleSVGConversion() throws {
        let svg = """
        <svg width="100" height="100" xmlns="http://www.w3.org/2000/svg">
          <circle cx="50" cy="50" r="40" fill="red"/>
        </svg>
        """

        let result = try service.convertToCSS(svg: svg, optimize: false, format: .backgroundImage)

        #expect(result.contains("background-image:"))
        #expect(result.contains("data:image/svg+xml,"))
        #expect(result.contains("url('"))
    }

    @Test("Convert SVG to background property with positioning")
    func testBackgroundPropertyFormat() throws {
        let svg = "<svg><rect width=\"10\" height=\"10\"/></svg>"

        let result = try service.convertToCSS(svg: svg, format: .backgroundProperty)

        #expect(result.contains("background:"))
        #expect(result.contains("no-repeat"))
        #expect(result.contains("center center"))
        #expect(result.contains("background-size: contain"))
    }

    @Test("Convert SVG to mask-image")
    func testMaskImageFormat() throws {
        let svg = "<svg><circle r=\"50\"/></svg>"

        let result = try service.convertToCSS(svg: svg, format: .maskImage)

        #expect(result.contains("mask-image:"))
        #expect(result.contains("-webkit-mask-image:"))
    }

    // MARK: - Optimization Tests

    @Test("Optimize SVG removes XML declaration")
    func testRemoveXMLDeclaration() throws {
        let svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg><rect/></svg>
        """

        let optimized = try service.optimizeSVG(svg)

        #expect(!optimized.contains("<?xml"))
        #expect(optimized.contains("<svg>"))
    }

    @Test("Optimize SVG removes comments")
    func testRemoveComments() throws {
        let svg = """
        <svg>
          <!-- This is a comment -->
          <rect/>
        </svg>
        """

        let optimized = try service.optimizeSVG(svg)

        #expect(!optimized.contains("<!--"))
        #expect(!optimized.contains("This is a comment"))
    }

    @Test("Optimize SVG removes metadata")
    func testRemoveMetadata() throws {
        let svg = """
        <svg>
          <metadata>
            <rdf:RDF>Some metadata</rdf:RDF>
          </metadata>
          <rect/>
        </svg>
        """

        let optimized = try service.optimizeSVG(svg)

        #expect(!optimized.contains("<metadata"))
        #expect(!optimized.contains("Some metadata"))
    }

    @Test("Optimize SVG removes title and desc")
    func testRemoveTitleAndDesc() throws {
        let svg = """
        <svg>
          <title>My SVG</title>
          <desc>Description here</desc>
          <rect/>
        </svg>
        """

        let optimized = try service.optimizeSVG(svg)

        #expect(!optimized.contains("<title"))
        #expect(!optimized.contains("<desc"))
        #expect(!optimized.contains("My SVG"))
    }

    @Test("Optimize SVG removes excess whitespace")
    func testRemoveWhitespace() throws {
        let svg = """
        <svg>    <rect    width="10"    />    </svg>
        """

        let optimized = try service.optimizeSVG(svg)

        #expect(!optimized.contains("    "))
        #expect(optimized.contains("<rect"))
    }

    @Test("Optimization maintains SVG structure")
    func testOptimizationPreservesStructure() throws {
        let svg = """
        <?xml version="1.0"?>
        <svg width="100" height="100">
          <!-- Comment -->
          <title>Test</title>
          <circle cx="50" cy="50" r="40" fill="blue"/>
        </svg>
        """

        let optimized = try service.optimizeSVG(svg)

        #expect(optimized.contains("<svg"))
        #expect(optimized.contains("<circle"))
        #expect(optimized.contains("fill=\"blue\""))
        #expect(!optimized.contains("<?xml"))
        #expect(!optimized.contains("<!--"))
    }

    // MARK: - Data URI Tests

    @Test("Create data URI encodes special characters")
    func testDataURIEncoding() throws {
        let svg = "<svg><rect fill=\"#ff0000\"/></svg>"

        let dataURI = try service.createDataURI(from: svg)

        #expect(dataURI.hasPrefix("data:image/svg+xml,"))
        // # should be encoded, and quotes should be replaced
        #expect(dataURI.contains("%23ff0000"))
        #expect(!dataURI.contains("\""))  // No double quotes
    }

    @Test("Data URI handles quotes correctly")
    func testDataURIQuoteHandling() throws {
        let svg = "<svg width=\"100\" height=\"100\"></svg>"

        let dataURI = try service.createDataURI(from: svg)

        // Should replace double quotes with single quotes or encode them
        #expect(!dataURI.contains("\"") || dataURI.contains("'"))
    }

    // MARK: - Validation Tests

    @Test("Validate correct SVG")
    func testValidSVG() {
        let svg = "<svg><rect/></svg>"
        #expect(service.isValidSVG(svg))
    }

    @Test("Validate SVG with namespace")
    func testValidSVGWithNamespace() {
        let svg = """
        <svg xmlns="http://www.w3.org/2000/svg">
          <circle r="50"/>
        </svg>
        """
        #expect(service.isValidSVG(svg))
    }

    @Test("Reject empty string")
    func testInvalidEmptySVG() {
        #expect(!service.isValidSVG(""))
        #expect(!service.isValidSVG("   "))
    }

    @Test("Reject non-SVG content")
    func testInvalidNonSVG() {
        #expect(!service.isValidSVG("<div>Not SVG</div>"))
        #expect(!service.isValidSVG("Just plain text"))
    }

    @Test("Reject incomplete SVG")
    func testInvalidIncompleteSVG() {
        #expect(!service.isValidSVG("<svg><rect/>"))  // Missing closing tag
    }

    // MARK: - Error Handling Tests

    @Test("Throw error for empty SVG")
    func testEmptySVGError() {
        #expect(throws: SVGToCSSService.SVGToCSSError.emptySVG) {
            try service.convertToCSS(svg: "", optimize: false)
        }
    }

    @Test("Throw error for invalid SVG")
    func testInvalidSVGError() {
        #expect(throws: SVGToCSSService.SVGToCSSError.invalidSVG) {
            try service.convertToCSS(svg: "<div>Not SVG</div>", optimize: false)
        }
    }

    // MARK: - Dimension Extraction Tests

    @Test("Extract width and height from SVG")
    func testExtractDimensions() {
        let svg = "<svg width=\"200\" height=\"100\"><rect/></svg>"

        if let dims = service.extractDimensions(from: svg) {
            #expect(dims.width == "200")
            #expect(dims.height == "100")
        } else {
            Issue.record("Should extract dimensions")
        }
    }

    @Test("Extract dimensions with single quotes")
    func testExtractDimensionsSingleQuotes() {
        let svg = "<svg width='300' height='150'><rect/></svg>"

        if let dims = service.extractDimensions(from: svg) {
            #expect(dims.width == "300")
            #expect(dims.height == "150")
        } else {
            Issue.record("Should extract dimensions with single quotes")
        }
    }

    @Test("Handle missing dimensions")
    func testMissingDimensions() {
        let svg = "<svg viewBox=\"0 0 100 100\"><rect/></svg>"

        let dims = service.extractDimensions(from: svg)
        #expect(dims == nil)
    }

    // MARK: - File Size Tests

    @Test("Calculate data URI size")
    func testDataURISize() {
        let dataURI = "data:image/svg+xml,%3Csvg%3E%3C/svg%3E"
        let size = service.getDataURISize(dataURI)

        #expect(size > 0)
        #expect(size == dataURI.utf8.count)
    }

    @Test("Format file size in bytes")
    func testFormatSizeBytes() {
        let formatted = service.formatFileSize(500)
        #expect(formatted.contains("500"))
        #expect(formatted.contains("bytes"))
    }

    @Test("Format file size in KB")
    func testFormatSizeKB() {
        let formatted = service.formatFileSize(2048)  // 2 KB
        #expect(formatted.contains("2.0"))
        #expect(formatted.contains("KB"))
    }

    @Test("Format file size in MB")
    func testFormatSizeMB() {
        let formatted = service.formatFileSize(2_097_152)  // 2 MB
        #expect(formatted.contains("2.0"))
        #expect(formatted.contains("MB"))
    }

    // MARK: - Integration Tests

    @Test("Full conversion workflow with optimization")
    func testFullWorkflow() throws {
        let svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
          <!-- Icon -->
          <title>Circle Icon</title>
          <circle cx="50" cy="50" r="40" fill="#3498db"/>
        </svg>
        """

        let result = try service.convertToCSS(svg: svg, optimize: true, format: .backgroundProperty)

        // Should have CSS property
        #expect(result.contains("background:"))

        // Should have data URI
        #expect(result.contains("data:image/svg+xml,"))

        // Should have URL wrapper
        #expect(result.contains("url('"))

        // Should have background properties
        #expect(result.contains("no-repeat"))
        #expect(result.contains("center"))
    }

    @Test("Conversion preserves SVG color values")
    func testColorPreservation() throws {
        let svg = "<svg><rect fill=\"#ff5733\" stroke=\"#c70039\"/></svg>"

        let result = try service.convertToCSS(svg: svg, optimize: false)

        // Colors should be encoded (#  becomes %23)
        #expect(result.contains("%23ff5733"))
        #expect(result.contains("%23c70039"))
    }

    @Test("Handle complex SVG with multiple elements")
    func testComplexSVG() throws {
        let svg = """
        <svg viewBox="0 0 100 100">
          <rect x="10" y="10" width="30" height="30" fill="red"/>
          <circle cx="75" cy="25" r="15" fill="blue"/>
          <path d="M 50 50 L 60 60 L 50 70 Z" fill="green"/>
        </svg>
        """

        let result = try service.convertToCSS(svg: svg, optimize: true, format: .backgroundImage)

        #expect(result.contains("background-image:"))
        #expect(result.contains("data:image/svg+xml,"))
    }
}

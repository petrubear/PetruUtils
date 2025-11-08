import Testing
import Foundation
import AppKit
@testable import PetruUtils

@Suite("QR Code Service Tests")
struct QRCodeServiceTests {
    let service = QRCodeService()
    
    // MARK: - Generation Tests
    
    @Test("Generate QR code from simple text")
    func testGenerateSimpleQR() throws {
        let image = try service.generateQRCode(from: "Hello World", size: 256)
        #expect(image.size.width == 256)
        #expect(image.size.height == 256)
    }
    
    @Test("Generate QR code with different sizes")
    func testGenerateDifferentSizes() throws {
        let sizes: [CGFloat] = [128, 256, 512, 1024]
        
        for size in sizes {
            let image = try service.generateQRCode(from: "Test", size: size)
            #expect(image.size.width == size)
            #expect(image.size.height == size)
        }
    }
    
    @Test("Generate QR code with different error correction levels")
    func testGenerateDifferentErrorLevels() throws {
        for level in QRCodeService.ErrorCorrectionLevel.allCases {
            let image = try service.generateQRCode(
                from: "Test content",
                size: 256,
                errorCorrection: level
            )
            #expect(image.size.width > 0)
        }
    }
    
    @Test("Generate QR code with custom colors")
    func testGenerateCustomColors() throws {
        let image = try service.generateQRCode(
            from: "Colored QR",
            size: 256,
            foregroundColor: .blue,
            backgroundColor: .yellow
        )
        #expect(image.size.width == 256)
    }
    
    @Test("Empty content throws error")
    func testEmptyContentThrows() {
        #expect(throws: QRCodeService.QRCodeError.emptyContent) {
            try service.generateQRCode(from: "", size: 256)
        }
    }
    
    @Test("Invalid size throws error")
    func testInvalidSizeThrows() {
        #expect(throws: QRCodeService.QRCodeError.invalidSize) {
            try service.generateQRCode(from: "Test", size: 0)
        }
        
        #expect(throws: QRCodeService.QRCodeError.invalidSize) {
            try service.generateQRCode(from: "Test", size: -100)
        }
    }
    
    // MARK: - Scan and Roundtrip Tests
    
    @Test("Roundtrip: Generate and scan QR code")
    func testRoundtrip() throws {
        let originalText = "Hello, QR Code!"
        let image = try service.generateQRCode(from: originalText, size: 512)
        let scannedText = try service.scanQRCode(from: image)
        
        #expect(scannedText == originalText)
    }
    
    @Test("Roundtrip with long text")
    func testRoundtripLongText() throws {
        let originalText = String(repeating: "ABCD", count: 100)
        let image = try service.generateQRCode(from: originalText, size: 1024)
        let scannedText = try service.scanQRCode(from: image)
        
        #expect(scannedText == originalText)
    }
    
    @Test("Roundtrip with special characters")
    func testRoundtripSpecialChars() throws {
        let originalText = "Special: !@#$%^&*(){}[]|\\:;\"'<>,.?/~`"
        let image = try service.generateQRCode(from: originalText, size: 512)
        let scannedText = try service.scanQRCode(from: image)
        
        #expect(scannedText == originalText)
    }
    
    @Test("Roundtrip with Unicode")
    func testRoundtripUnicode() throws {
        let originalText = "Unicode: 你好世界 🌍 مرحبا"
        let image = try service.generateQRCode(from: originalText, size: 512)
        let scannedText = try service.scanQRCode(from: image)
        
        #expect(scannedText == originalText)
    }
    
    @Test("Roundtrip with URL")
    func testRoundtripURL() throws {
        let originalText = "https://example.com/path?query=value&foo=bar"
        let image = try service.generateQRCode(from: originalText, size: 512)
        let scannedText = try service.scanQRCode(from: image)
        
        #expect(scannedText == originalText)
    }
    
    // MARK: - Export Tests
    
    @Test("Export QR code to PNG")
    func testExportPNG() throws {
        let image = try service.generateQRCode(from: "Export test", size: 256)
        let pngData = try service.exportPNG(image)
        
        #expect(pngData.count > 0)
        
        // Verify it's valid PNG data
        #expect(pngData.starts(with: [0x89, 0x50, 0x4E, 0x47])) // PNG signature
    }
    
    @Test("Export QR code to file")
    func testExportToFile() throws {
        let image = try service.generateQRCode(from: "File export", size: 256)
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_qr.png")
        
        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        try service.exportToFile(image, to: fileURL)
        
        #expect(FileManager.default.fileExists(atPath: fileURL.path))
        
        // Verify we can scan it back
        let scannedText = try service.scanQRCode(from: fileURL)
        #expect(scannedText == "File export")
    }
    
    // MARK: - Utility Tests
    
    @Test("Recommended size calculation")
    func testRecommendedSize() {
        #expect(service.recommendedSize(for: "Short") == 256)
        #expect(service.recommendedSize(for: String(repeating: "A", count: 100)) == 384)
        #expect(service.recommendedSize(for: String(repeating: "A", count: 300)) == 512)
        #expect(service.recommendedSize(for: String(repeating: "A", count: 700)) == 768)
        #expect(service.recommendedSize(for: String(repeating: "A", count: 1500)) == 1024)
    }
    
    @Test("Estimated capacity per error level")
    func testEstimatedCapacity() {
        #expect(service.estimatedCapacity(for: .low) == 2953)
        #expect(service.estimatedCapacity(for: .medium) == 2331)
        #expect(service.estimatedCapacity(for: .quartile) == 1663)
        #expect(service.estimatedCapacity(for: .high) == 1273)
    }
    
    // MARK: - Edge Cases
    
    @Test("Generate very small QR code")
    func testVerySmallSize() throws {
        let image = try service.generateQRCode(from: "Tiny", size: 32)
        #expect(image.size.width == 32)
    }
    
    @Test("Generate very large QR code")
    func testVeryLargeSize() throws {
        let image = try service.generateQRCode(from: "Large", size: 2048)
        #expect(image.size.width == 2048)
    }
    
    @Test("Single character QR code")
    func testSingleChar() throws {
        let image = try service.generateQRCode(from: "A", size: 256)
        let scanned = try service.scanQRCode(from: image)
        #expect(scanned == "A")
    }
    
    @Test("Numeric only QR code")
    func testNumericOnly() throws {
        let originalText = "1234567890"
        let image = try service.generateQRCode(from: originalText, size: 256)
        let scanned = try service.scanQRCode(from: image)
        #expect(scanned == originalText)
    }
    
    @Test("Whitespace and newlines")
    func testWhitespaceNewlines() throws {
        let originalText = "Line 1\nLine 2\n\tTabbed"
        let image = try service.generateQRCode(from: originalText, size: 512)
        let scanned = try service.scanQRCode(from: image)
        #expect(scanned == originalText)
    }
}

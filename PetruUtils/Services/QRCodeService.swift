import Foundation
import CoreImage
import AppKit

/// Service for generating and reading QR codes
struct QRCodeService {
    
    // MARK: - Types
    
    enum ErrorCorrectionLevel: String, CaseIterable, Identifiable {
        case low = "L"
        case medium = "M"
        case quartile = "Q"
        case high = "H"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .low: return "Low (7%)"
            case .medium: return "Medium (15%)"
            case .quartile: return "Quartile (25%)"
            case .high: return "High (30%)"
            }
        }
        
        var description: String {
            switch self {
            case .low: return "Can recover from 7% damage"
            case .medium: return "Can recover from 15% damage"
            case .quartile: return "Can recover from 25% damage"
            case .high: return "Can recover from 30% damage"
            }
        }
    }
    
    enum QRCodeError: LocalizedError {
        case emptyContent
        case generationFailed
        case invalidSize
        case exportFailed
        case scanningFailed
        case noQRCodeFound
        
        var errorDescription: String? {
            switch self {
            case .emptyContent:
                return "Content cannot be empty"
            case .generationFailed:
                return "Failed to generate QR code"
            case .invalidSize:
                return "Invalid size specified"
            case .exportFailed:
                return "Failed to export QR code"
            case .scanningFailed:
                return "Failed to scan image"
            case .noQRCodeFound:
                return "No QR code found in image"
            }
        }
    }
    
    // MARK: - QR Code Generation
    
    /// Generates a QR code image from text
    /// - Parameters:
    ///   - content: Text to encode in QR code
    ///   - size: Size of the output image in points
    ///   - errorCorrection: Error correction level
    ///   - foregroundColor: Foreground color (default black)
    ///   - backgroundColor: Background color (default white)
    /// - Returns: NSImage of the QR code
    func generateQRCode(
        from content: String,
        size: CGFloat = 512,
        errorCorrection: ErrorCorrectionLevel = .medium,
        foregroundColor: NSColor = .black,
        backgroundColor: NSColor = .white
    ) throws -> NSImage {
        guard !content.isEmpty else {
            throw QRCodeError.emptyContent
        }
        
        guard size > 0 else {
            throw QRCodeError.invalidSize
        }
        
        // Create QR code filter
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRCodeError.generationFailed
        }
        
        // Set input data
        guard let data = content.data(using: .utf8) else {
            throw QRCodeError.generationFailed
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue(errorCorrection.rawValue, forKey: "inputCorrectionLevel")
        
        // Get output image
        guard let outputImage = filter.outputImage else {
            throw QRCodeError.generationFailed
        }
        
        // Scale to desired size
        let scaleX = size / outputImage.extent.width
        let scaleY = size / outputImage.extent.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Apply colors if not default
        let coloredImage: CIImage
        if foregroundColor != .black || backgroundColor != .white {
            coloredImage = applyColors(to: scaledImage, foreground: foregroundColor, background: backgroundColor)
        } else {
            coloredImage = scaledImage
        }
        
        // Convert to NSImage
        let rep = NSCIImageRep(ciImage: coloredImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        
        return nsImage
    }
    
    /// Applies custom colors to QR code
    private func applyColors(to image: CIImage, foreground: NSColor, background: NSColor) -> CIImage {
        guard let colorFilter = CIFilter(name: "CIFalseColor") else {
            return image
        }
        
        colorFilter.setValue(image, forKey: "inputImage")
        colorFilter.setValue(CIColor(color: foreground), forKey: "inputColor0")
        colorFilter.setValue(CIColor(color: background), forKey: "inputColor1")
        
        return colorFilter.outputImage ?? image
    }
    
    // MARK: - Export
    
    /// Exports QR code to PNG data
    /// - Parameter image: NSImage to export
    /// - Returns: PNG data
    func exportPNG(_ image: NSImage) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw QRCodeError.exportFailed
        }
        return pngData
    }
    
    /// Exports QR code to file
    /// - Parameters:
    ///   - image: NSImage to export
    ///   - url: Destination file URL
    func exportToFile(_ image: NSImage, to url: URL) throws {
        let pngData = try exportPNG(image)
        try pngData.write(to: url)
    }
    
    // MARK: - Scanning
    
    /// Scans QR code from image
    /// - Parameter image: NSImage containing QR code
    /// - Returns: Decoded string from QR code
    func scanQRCode(from image: NSImage) throws -> String {
        guard let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            throw QRCodeError.scanningFailed
        }
        
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                context: context,
                                options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature],
              let firstFeature = features.first,
              let messageString = firstFeature.messageString else {
            throw QRCodeError.noQRCodeFound
        }
        
        return messageString
    }
    
    /// Scans QR code from file
    /// - Parameter url: URL of image file
    /// - Returns: Decoded string from QR code
    func scanQRCode(from url: URL) throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw QRCodeError.scanningFailed
        }
        return try scanQRCode(from: image)
    }
    
    // MARK: - Utilities
    
    /// Calculates optimal size for QR code based on content length
    /// - Parameter content: Content to encode
    /// - Returns: Recommended size in points
    func recommendedSize(for content: String) -> CGFloat {
        let length = content.count
        
        switch length {
        case 0..<50:
            return 256
        case 50..<200:
            return 384
        case 200..<500:
            return 512
        case 500..<1000:
            return 768
        default:
            return 1024
        }
    }
    
    /// Estimates capacity for given error correction level
    /// - Parameter level: Error correction level
    /// - Returns: Approximate maximum characters
    func estimatedCapacity(for level: ErrorCorrectionLevel) -> Int {
        switch level {
        case .low: return 2953
        case .medium: return 2331
        case .quartile: return 1663
        case .high: return 1273
        }
    }
}

// MARK: - NSColor Extension

extension CIColor {
    convenience init(color: NSColor) {
        let color = color.usingColorSpace(.deviceRGB) ?? color
        self.init(red: color.redComponent,
                  green: color.greenComponent,
                  blue: color.blueComponent,
                  alpha: color.alphaComponent)
    }
}

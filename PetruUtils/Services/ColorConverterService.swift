import Foundation
import SwiftUI

/// Service for converting colors between different formats
struct ColorConverterService {
    
    // MARK: - Error Types
    
    enum ColorError: LocalizedError {
        case invalidHex
        case invalidRGB
        case invalidHSL
        case invalidHSV
        case invalidCMYK
        case emptyInput
        
        var errorDescription: String? {
            switch self {
            case .invalidHex: return "Invalid HEX format. Use #RRGGBB or #RGB."
            case .invalidRGB: return "Invalid RGB values. Use 0-255 for each component."
            case .invalidHSL: return "Invalid HSL values. H: 0-360, S/L: 0-100."
            case .invalidHSV: return "Invalid HSV values. H: 0-360, S/V: 0-100."
            case .invalidCMYK: return "Invalid CMYK values. Use 0-100 for each component."
            case .emptyInput: return "Input cannot be empty."
            }
        }
    }
    
    // MARK: - Color Components
    
    struct RGB {
        let r: Double // 0-255
        let g: Double
        let b: Double
        
        func toString() -> String {
            "rgb(\(Int(r)), \(Int(g)), \(Int(b)))"
        }
    }
    
    struct HSL {
        let h: Double // 0-360
        let s: Double // 0-100
        let l: Double // 0-100
        
        func toString() -> String {
            "hsl(\(Int(h)), \(Int(s))%, \(Int(l))%)"
        }
    }
    
    struct HSV {
        let h: Double // 0-360
        let s: Double // 0-100
        let v: Double // 0-100
        
        func toString() -> String {
            "hsv(\(Int(h)), \(Int(s))%, \(Int(v))%)"
        }
    }
    
    struct CMYK {
        let c: Double // 0-100
        let m: Double
        let y: Double
        let k: Double
        
        func toString() -> String {
            "cmyk(\(Int(c))%, \(Int(m))%, \(Int(y))%, \(Int(k))%)"
        }
    }
    
    struct ConversionResult {
        let hex: String
        let rgb: RGB
        let hsl: HSL
        let hsv: HSV
        let cmyk: CMYK
        let color: Color
    }
    
    // MARK: - HEX Conversion
    
    func parseHex(_ hex: String) throws -> RGB {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned = String(cleaned.dropFirst()) }
        
        guard !cleaned.isEmpty else { throw ColorError.emptyInput }
        
        // Handle 3-digit hex
        if cleaned.count == 3 {
            cleaned = cleaned.map { "\($0)\($0)" }.joined()
        }
        
        guard cleaned.count == 6 else { throw ColorError.invalidHex }
        
        guard let value = Int(cleaned, radix: 16) else { throw ColorError.invalidHex }
        
        let r = Double((value >> 16) & 0xFF)
        let g = Double((value >> 8) & 0xFF)
        let b = Double(value & 0xFF)
        
        return RGB(r: r, g: g, b: b)
    }
    
    func rgbToHex(_ rgb: RGB) -> String {
        String(format: "#%02X%02X%02X", Int(rgb.r), Int(rgb.g), Int(rgb.b))
    }
    
    // MARK: - RGB Conversion
    
    func parseRGB(_ input: String) throws -> RGB {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw ColorError.emptyInput }
        
        // Extract numbers from rgb(r, g, b) or just "r, g, b"
        let numbers = cleaned
            .replacingOccurrences(of: "rgb(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        
        guard numbers.count == 3 else { throw ColorError.invalidRGB }
        guard numbers.allSatisfy({ $0 >= 0 && $0 <= 255 }) else { throw ColorError.invalidRGB }
        
        return RGB(r: numbers[0], g: numbers[1], b: numbers[2])
    }
    
    // MARK: - RGB to other formats
    
    func rgbToHSL(_ rgb: RGB) -> HSL {
        let r = rgb.r / 255.0
        let g = rgb.g / 255.0
        let b = rgb.b / 255.0
        
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        var h: Double = 0
        let l = (max + min) / 2.0
        
        if delta != 0 {
            let s = l > 0.5 ? delta / (2.0 - max - min) : delta / (max + min)
            
            if max == r {
                h = ((g - b) / delta) + (g < b ? 6 : 0)
            } else if max == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            h /= 6.0
        }
        
        let sat = delta == 0 ? 0 : (l > 0.5 ? delta / (2.0 - max - min) : delta / (max + min))
        
        return HSL(h: h * 360, s: sat * 100, l: l * 100)
    }
    
    func rgbToHSV(_ rgb: RGB) -> HSV {
        let r = rgb.r / 255.0
        let g = rgb.g / 255.0
        let b = rgb.b / 255.0
        
        let max = Swift.max(r, g, b)
        let min = Swift.min(r, g, b)
        let delta = max - min
        
        var h: Double = 0
        if delta != 0 {
            if max == r {
                h = ((g - b) / delta) + (g < b ? 6 : 0)
            } else if max == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            h /= 6.0
        }
        
        let s = max == 0 ? 0 : delta / max
        let v = max
        
        return HSV(h: h * 360, s: s * 100, v: v * 100)
    }
    
    func rgbToCMYK(_ rgb: RGB) -> CMYK {
        let r = rgb.r / 255.0
        let g = rgb.g / 255.0
        let b = rgb.b / 255.0
        
        let k = 1 - Swift.max(r, g, b)
        if k == 1 {
            return CMYK(c: 0, m: 0, y: 0, k: 100)
        }
        
        let c = (1 - r - k) / (1 - k)
        let m = (1 - g - k) / (1 - k)
        let y = (1 - b - k) / (1 - k)
        
        return CMYK(c: c * 100, m: m * 100, y: y * 100, k: k * 100)
    }
    
    // MARK: - Full Conversion
    
    func convertFromHex(_ hex: String) throws -> ConversionResult {
        let rgb = try parseHex(hex)
        return createResult(from: rgb)
    }
    
    func convertFromRGB(_ input: String) throws -> ConversionResult {
        let rgb = try parseRGB(input)
        return createResult(from: rgb)
    }
    
    func convertFromColor(_ color: Color) -> ConversionResult {
        // Convert SwiftUI Color to RGB (simplified)
        #if canImport(AppKit)
        let nsColor = NSColor(color)
        let r = nsColor.redComponent * 255
        let g = nsColor.greenComponent * 255
        let b = nsColor.blueComponent * 255
        let rgb = RGB(r: r, g: g, b: b)
        #else
        let rgb = RGB(r: 128, g: 128, b: 128) // Fallback
        #endif
        return createResult(from: rgb)
    }
    
    private func createResult(from rgb: RGB) -> ConversionResult {
        ConversionResult(
            hex: rgbToHex(rgb),
            rgb: rgb,
            hsl: rgbToHSL(rgb),
            hsv: rgbToHSV(rgb),
            cmyk: rgbToCMYK(rgb),
            color: Color(red: rgb.r / 255, green: rgb.g / 255, blue: rgb.b / 255)
        )
    }
}

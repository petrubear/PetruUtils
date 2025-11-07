import SwiftUI
import AppKit

extension Font {
    /// JetBrains Mono font for code and monospaced text
    static func jetBrainsMono(size: CGFloat = NSFont.systemFontSize) -> Font {
        if let customFont = NSFont(name: "JetBrainsMono-Regular", size: size) {
            return Font(customFont)
        }
        // Fallback to system monospaced font
        return .system(size: size, design: .monospaced)
    }
    
    /// Standard code font - consistent across all code displays
    static var code: Font {
        jetBrainsMono(size: 15)
    }
    
    /// Larger code font for input areas
    static var codeInput: Font {
        jetBrainsMono(size: 15)
    }
}

extension NSFont {
    /// JetBrains Mono NSFont for AppKit components
    static func jetBrainsMono(size: CGFloat = NSFont.systemFontSize) -> NSFont {
        if let customFont = NSFont(name: "JetBrainsMono-Regular", size: size) {
            return customFont
        }
        // Fallback to system monospaced font
        return .monospacedSystemFont(ofSize: size, weight: .regular)
    }
    
    /// Standard code font for NSFont usage
    static var code: NSFont {
        jetBrainsMono(size: 15)
    }
}

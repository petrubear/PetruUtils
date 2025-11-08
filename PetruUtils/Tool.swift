import Foundation

/// Enum for the available developer tools in your app
enum Tool: String, CaseIterable, Identifiable {
    case jwt
    case base64
    case urlEncoder
    case hash
    case qr

    // For use in SwiftUI List / ForEach
    var id: String { rawValue }

    // Sidebar title
    var title: String {
        switch self {
        case .jwt: return "JWT Debugger"
        case .base64: return "Base64"
        case .urlEncoder: return "URL Encoder"
        case .hash: return "Hash Generator"
        case .qr: return "QR Code"
        }
    }

    // Optional: system SF Symbol for icon
    var iconName: String {
        switch self {
        case .jwt: return "lock.shield"
        case .base64: return "textformat.123"
        case .urlEncoder: return "link"
        case .hash: return "number.square"
        case .qr: return "qrcode"
        }
    }
}

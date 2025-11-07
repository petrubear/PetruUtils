import Foundation

/// Enum for the available developer tools in your app
enum Tool: String, CaseIterable, Identifiable {
    case jwt
    case base64
    case qr

    // For use in SwiftUI List / ForEach
    var id: String { rawValue }

    // Sidebar title
    var title: String {
        switch self {
        case .jwt: return "JWT Debugger"
        case .base64: return "Base64"
        case .qr: return "QR Code"
        }
    }

    // Optional: system SF Symbol for icon
    var iconName: String {
        switch self {
        case .jwt: return "lock.shield"
        case .base64: return "textformat.123"
        case .qr: return "qrcode"
        }
    }
}

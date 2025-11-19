import Foundation
import AppKit
import Combine

/// Service for monitoring clipboard and detecting content types
class ClipboardMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isMonitoring: Bool = false
    @Published var lastDetectedType: DetectedContentType?
    @Published var lastContent: String = ""
    @Published var suggestedTool: Tool?
    
    // MARK: - Types
    
    enum DetectedContentType: String {
        case json
        case base64
        case jwt
        case url
        case uuid
        case ulid
        case hash
        case xml
        case unknown
        
        var displayName: String {
            switch self {
            case .json: return "JSON"
            case .base64: return "Base64"
            case .jwt: return "JWT Token"
            case .url: return "URL"
            case .uuid: return "UUID"
            case .ulid: return "ULID"
            case .hash: return "Hash"
            case .xml: return "XML"
            case .unknown: return "Unknown"
            }
        }
        
        var suggestedTool: Tool? {
            switch self {
            case .json: return nil // Would be JSON formatter when implemented
            case .base64: return .base64
            case .jwt: return .jwt
            case .url: return .urlEncoder
            case .uuid, .ulid: return .uuid
            case .hash: return .hash
            case .xml: return nil
            case .unknown: return nil
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard: NSPasteboard
    private let detector = ContentDetector()

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }
    
    // MARK: - Public Methods
    
    /// Starts monitoring the clipboard
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        lastChangeCount = pasteboard.changeCount
        
        // Poll clipboard every 500ms
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkClipboard()
            }
        }
    }
    
    /// Stops monitoring the clipboard
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }
    
    /// Manually checks clipboard content
    func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        // Only process if clipboard changed
        guard currentChangeCount != lastChangeCount else { return }
        
        // Get string content
        guard let content = pasteboard.string(forType: .string),
              !content.isEmpty,
              content.count < 100_000 else { // Limit size to avoid performance issues
            lastChangeCount = currentChangeCount
            return
        }
        
        // Detect content type
        let detectedType = detector.detect(content)
        
        // Update state
        lastContent = content
        lastDetectedType = detectedType
        suggestedTool = detectedType.suggestedTool
        lastChangeCount = currentChangeCount
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Content Detector

struct ContentDetector {
    
    /// Detects the type of content
    func detect(_ content: String) -> ClipboardMonitor.DetectedContentType {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check in order of specificity
        if isJWT(trimmed) { return .jwt }
        if isULID(trimmed) { return .ulid }
        if isUUID(trimmed) { return .uuid }
        if isJSON(trimmed) { return .json }
        if isXML(trimmed) { return .xml }
        if isBase64(trimmed) { return .base64 }
        if isURL(trimmed) { return .url }
        if isHash(trimmed) { return .hash }
        
        return .unknown
    }
    
    // MARK: - Detection Methods
    
    /// Detects JWT tokens (3 base64url parts separated by dots)
    private func isJWT(_ content: String) -> Bool {
        let parts = content.split(separator: ".")
        guard parts.count == 3 else { return false }
        
        // Check if parts look like base64url
        let base64urlPattern = "^[A-Za-z0-9_-]+$"
        let regex = try? NSRegularExpression(pattern: base64urlPattern)
        
        for part in parts {
            let range = NSRange(part.startIndex..., in: String(part))
            guard regex?.firstMatch(in: String(part), range: range) != nil else {
                return false
            }
        }
        
        return true
    }
    
    /// Detects JSON (starts with { or [)
    private func isJSON(_ content: String) -> Bool {
        guard content.hasPrefix("{") || content.hasPrefix("[") else {
            return false
        }
        
        // Try to parse as JSON
        guard let data = content.data(using: .utf8) else { return false }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return true
        } catch {
            return false
        }
    }
    
    /// Detects XML (starts with < and contains tags)
    private func isXML(_ content: String) -> Bool {
        guard content.hasPrefix("<") else { return false }
        
        // Basic XML pattern check
        let xmlPattern = "<[^>]+>.*</[^>]+>"
        let regex = try? NSRegularExpression(pattern: xmlPattern, options: .dotMatchesLineSeparators)
        let range = NSRange(content.startIndex..., in: content)
        
        return regex?.firstMatch(in: content, range: range) != nil
    }
    
    /// Detects Base64 (high entropy, valid base64 chars)
    private func isBase64(_ content: String) -> Bool {
        // Must be reasonable length
        guard content.count >= 4, content.count <= 10000 else { return false }
        
        // Check for base64 character set
        let base64Chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
        let contentChars = CharacterSet(charactersIn: content)
        
        guard base64Chars.isSuperset(of: contentChars) else { return false }
        
        // Try to decode
        guard Data(base64Encoded: content) != nil else { return false }
        
        // Check entropy (base64 should have decent entropy)
        let entropy = calculateEntropy(content)
        return entropy > 3.5 // Base64 typically has > 4 bits per character
    }
    
    /// Detects URLs
    private func isURL(_ content: String) -> Bool {
        // Check for URL schemes
        let schemes = ["http://", "https://", "ftp://", "file://", "mailto:"]
        if schemes.contains(where: { content.lowercased().hasPrefix($0) }) {
            return URL(string: content) != nil
        }
        
        // Check for URL-like patterns without scheme
        let urlPattern = "^[a-zA-Z0-9-]+(\\.[a-zA-Z0-9-]+)+(/.*)?$"
        let regex = try? NSRegularExpression(pattern: urlPattern)
        let range = NSRange(content.startIndex..., in: content)
        
        return regex?.firstMatch(in: content, range: range) != nil
    }
    
    /// Detects UUIDs
    private func isUUID(_ content: String) -> Bool {
        let uuidPattern = "^[0-9a-fA-F]{8}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{4}-?[0-9a-fA-F]{12}$"
        let regex = try? NSRegularExpression(pattern: uuidPattern)
        let range = NSRange(content.startIndex..., in: content)
        
        return regex?.firstMatch(in: content, range: range) != nil
    }
    
    /// Detects ULIDs
    private func isULID(_ content: String) -> Bool {
        guard content.count == 26 else { return false }
        
        // ULID uses Crockford's Base32
        let ulidChars = CharacterSet(charactersIn: "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
        let contentChars = CharacterSet(charactersIn: content.uppercased())
        
        return ulidChars.isSuperset(of: contentChars)
    }
    
    /// Detects hash values (hex strings of common lengths)
    private func isHash(_ content: String) -> Bool {
        // Common hash lengths: MD5(32), SHA1(40), SHA256(64), SHA384(96), SHA512(128)
        let validLengths = [32, 40, 64, 96, 128]
        guard validLengths.contains(content.count) else { return false }
        
        // Check if it's all hex
        let hexPattern = "^[0-9a-fA-F]+$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(content.startIndex..., in: content)
        
        return regex?.firstMatch(in: content, range: range) != nil
    }
    
    // MARK: - Utilities
    
    /// Calculates Shannon entropy for a string
    private func calculateEntropy(_ string: String) -> Double {
        var frequency: [Character: Int] = [:]
        
        for char in string {
            frequency[char, default: 0] += 1
        }
        
        let length = Double(string.count)
        var entropy = 0.0
        
        for count in frequency.values {
            let probability = Double(count) / length
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
}

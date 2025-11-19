//
//  URLService.swift
//  PetruUtils
//
//  Created by Agent on 11/7/25.
//

import Foundation

// MARK: - URL Component Type

enum URLComponentType {
    case fullURL
    case queryParameter
    case pathSegment
    case formData
}

// MARK: - URL Service Errors

enum URLServiceError: LocalizedError {
    case emptyInput
    case invalidURL
    case encodingFailed
    case decodingFailed
    case invalidCharacters
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input cannot be empty"
        case .invalidURL:
            return "Invalid URL format"
        case .encodingFailed:
            return "Failed to encode URL"
        case .decodingFailed:
            return "Failed to decode URL"
        case .invalidCharacters:
            return "Contains invalid characters"
        }
    }
}

// MARK: - URL Service

struct URLService {
    
    // MARK: - Encoding
    
    /// Encodes text based on URL component type
    func encode(_ text: String, type: URLComponentType = .queryParameter) throws -> String {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw URLServiceError.emptyInput
        }
        
        switch type {
        case .fullURL:
            return try encodeFullURL(text)
        case .queryParameter:
            return encodeQueryParameter(text)
        case .pathSegment:
            return encodePathSegment(text)
        case .formData:
            return encodeFormData(text)
        }
    }
    
    /// Encodes a full URL (only the parts that need encoding)
    private func encodeFullURL(_ urlString: String) throws -> String {
        guard let url = URL(string: urlString) else {
            throw URLServiceError.invalidURL
        }
        
        // If the URL is already valid, return as is
        if let _ = URLComponents(string: urlString) {
            return urlString
        }
        
        // Otherwise, try to encode it properly
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        components.path = url.path
        components.query = url.query
        components.fragment = url.fragment
        
        guard let encodedURL = components.url?.absoluteString else {
            throw URLServiceError.encodingFailed
        }
        
        return encodedURL
    }
    
    /// Encodes text for use in query parameters (RFC 3986)
    private func encodeQueryParameter(_ text: String) -> String {
        var allowedCharacters = CharacterSet.urlQueryAllowed
        // Remove characters that should be encoded in query parameters
        allowedCharacters.remove(charactersIn: "!*'();:@&=+$,/?#[]")
        
        return text.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? text
    }
    
    /// Encodes text for use in path segments (RFC 3986)
    private func encodePathSegment(_ text: String) -> String {
        var allowedCharacters = CharacterSet.urlPathAllowed
        allowedCharacters.remove(charactersIn: "?#[]@!$&'()*+,;=/")
        
        return text.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? text
    }
    
    /// Encodes text for use in form data (application/x-www-form-urlencoded)
    private func encodeFormData(_ text: String) -> String {
        var allowedCharacters = CharacterSet.alphanumerics
        allowedCharacters.insert(charactersIn: "-_.~")
        
        let encoded = text.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? text
        // Replace spaces with plus signs (form encoding convention)
        return encoded.replacingOccurrences(of: "%20", with: "+")
    }
    
    // MARK: - Decoding
    
    /// Decodes URL-encoded text based on component type
    func decode(_ text: String, type: URLComponentType = .queryParameter) throws -> String {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw URLServiceError.emptyInput
        }
        
        switch type {
        case .fullURL:
            return try decodeFullURL(text)
        case .queryParameter:
            return try decodeQueryParameter(text)
        case .pathSegment:
            return try decodePathSegment(text)
        case .formData:
            return try decodeFormData(text)
        }
    }
    
    /// Decodes a full URL
    private func decodeFullURL(_ urlString: String) throws -> String {
        guard let decoded = urlString.removingPercentEncoding else {
            throw URLServiceError.decodingFailed
        }
        return decoded
    }
    
    /// Decodes query parameter text
    private func decodeQueryParameter(_ text: String) throws -> String {
        guard let decoded = text.removingPercentEncoding else {
            throw URLServiceError.decodingFailed
        }
        return decoded
    }
    
    /// Decodes path segment text
    private func decodePathSegment(_ text: String) throws -> String {
        guard let decoded = text.removingPercentEncoding else {
            throw URLServiceError.decodingFailed
        }
        return decoded
    }
    
    /// Decodes form data (converts + to space, then percent-decodes)
    private func decodeFormData(_ text: String) throws -> String {
        let withSpaces = text.replacingOccurrences(of: "+", with: " ")
        guard let decoded = withSpaces.removingPercentEncoding else {
            throw URLServiceError.decodingFailed
        }
        return decoded
    }
    
    // MARK: - Validation
    
    /// Checks if a string is a valid URL
    func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        return url.scheme != nil && url.host != nil
    }
    
    /// Checks if a string contains URL-encoded characters
    func isURLEncoded(_ text: String) -> Bool {
        // Check for percent-encoded characters (%XX)
        let percentPattern = "%[0-9A-Fa-f]{2}"
        let regex = try? NSRegularExpression(pattern: percentPattern)
        let range = NSRange(text.startIndex..., in: text)
        return regex?.firstMatch(in: text, range: range) != nil
    }
    
    /// Checks if a string contains form-encoded characters (+ for space)
    func isFormEncoded(_ text: String) -> Bool {
        return text.contains("+") || isURLEncoded(text)
    }
    
    // MARK: - Utilities
    
    /// Parses a URL into its components
    func parseURL(_ urlString: String) throws -> URLComponents {
        guard let components = URLComponents(string: urlString) else {
            throw URLServiceError.invalidURL
        }
        return components
    }
    
    /// Extracts query parameters from a URL
    func extractQueryParameters(_ urlString: String) throws -> [(String, String)] {
        let components = try parseURL(urlString)
        guard let queryItems = components.queryItems else {
            return []
        }
        return queryItems.compactMap { item in
            guard let value = item.value else { return nil }
            return (item.name, value)
        }
    }
    
    /// Builds a URL from components
    func buildURL(scheme: String? = nil,
                  host: String? = nil,
                  path: String? = nil,
                  queryParameters: [(String, String)]? = nil) -> String? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path ?? ""
        
        if let params = queryParameters {
            components.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
        }
        
        return components.url?.absoluteString
    }
    
    /// Gets the percentage of characters that are URL-encoded in a string
    func getEncodedPercentage(_ text: String) -> Double {
        let encodedCount = text.filter { $0 == "%" }.count
        guard text.count > 0 else { return 0.0 }
        return Double(encodedCount) / Double(text.count) * 100.0
    }
    
    /// Normalizes URL encoding (re-encodes to ensure consistent encoding)
    func normalizeEncoding(_ text: String, type: URLComponentType = .queryParameter) throws -> String {
        let decoded = try decode(text, type: type)
        return try encode(decoded, type: type)
    }
}

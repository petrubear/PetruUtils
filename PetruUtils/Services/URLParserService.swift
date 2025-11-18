import Foundation

struct URLParserService {
    struct ParsedURL {
        let scheme: String?
        let host: String?
        let port: Int?
        let path: String?
        let query: String?
        let fragment: String?
        let queryParameters: [(key: String, value: String)]
        let user: String?
        let password: String?
    }
    
    enum URLParserError: LocalizedError {
        case invalidURL
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL format"
            }
        }
    }
    
    /// Parse a URL string into components
    func parse(_ urlString: String) throws -> ParsedURL {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw URLParserError.invalidURL
        }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        
        // Parse query parameters
        var queryParams: [(key: String, value: String)] = []
        if let queryItems = components?.queryItems {
            queryParams = queryItems.map { ($0.name, $0.value ?? "") }
        }
        
        return ParsedURL(
            scheme: url.scheme,
            host: url.host,
            port: url.port,
            path: url.path.isEmpty ? nil : url.path,
            query: url.query,
            fragment: url.fragment,
            queryParameters: queryParams,
            user: url.user,
            password: url.password
        )
    }
    
    /// Reconstruct URL from components
    func reconstruct(from parsed: ParsedURL) -> String {
        var components = URLComponents()
        components.scheme = parsed.scheme
        components.host = parsed.host
        components.port = parsed.port
        components.path = parsed.path ?? ""
        components.query = parsed.query
        components.fragment = parsed.fragment
        components.user = parsed.user
        components.password = parsed.password
        
        return components.url?.absoluteString ?? ""
    }
}

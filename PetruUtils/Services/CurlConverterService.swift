//
//  CurlConverterService.swift
//  PetruUtils
//
//  Created by Agent on 12/3/25.
//

import Foundation

// MARK: - Language Target

enum TargetLanguage: String, CaseIterable {
    case swift
    case python
    case javascript
    case go
    case php
    case ruby

    var displayName: String {
        switch self {
        case .swift: return "Swift (URLSession)"
        case .python: return "Python (requests)"
        case .javascript: return "JavaScript (fetch)"
        case .go: return "Go (net/http)"
        case .php: return "PHP (cURL)"
        case .ruby: return "Ruby (Net::HTTP)"
        }
    }
}

// MARK: - Curl Request Model

struct CurlRequest {
    var url: String
    var method: String
    var headers: [String: String]
    var body: String?
    var formData: [String: String]
    var queryParams: [String: String]
    var username: String?
    var password: String?

    init(url: String = "",
         method: String = "GET",
         headers: [String: String] = [:],
         body: String? = nil,
         formData: [String: String] = [:],
         queryParams: [String: String] = [:],
         username: String? = nil,
         password: String? = nil) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.formData = formData
        self.queryParams = queryParams
        self.username = username
        self.password = password
    }
}

// MARK: - Service Errors

enum CurlConverterError: LocalizedError {
    case emptyInput
    case invalidCurlCommand
    case missingURL
    case unsupportedOption(String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "cURL command cannot be empty"
        case .invalidCurlCommand:
            return "Invalid cURL command format"
        case .missingURL:
            return "No URL found in cURL command"
        case .unsupportedOption(let option):
            return "Unsupported cURL option: \(option)"
        }
    }
}

// MARK: - Curl Converter Service

struct CurlConverterService {

    // MARK: - Parse cURL Command

    /// Parse a cURL command into a structured request object
    func parseCurl(_ command: String) throws -> CurlRequest {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw CurlConverterError.emptyInput
        }

        // Remove leading "curl" if present
        var cmd = trimmed
        if cmd.lowercased().hasPrefix("curl ") {
            cmd = String(cmd.dropFirst(5))
        }

        var request = CurlRequest()
        var tokens = tokenize(cmd)

        var i = 0
        while i < tokens.count {
            let token = tokens[i]

            // Check for flags
            if token.hasPrefix("-") {
                let flag = token

                switch flag {
                case "-X", "--request":
                    // HTTP method
                    i += 1
                    if i < tokens.count {
                        request.method = tokens[i].uppercased()
                    }

                case "-H", "--header":
                    // Headers
                    i += 1
                    if i < tokens.count {
                        let header = tokens[i]
                        if let colonIndex = header.firstIndex(of: ":") {
                            let key = String(header[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                            let value = String(header[header.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                            request.headers[key] = value
                        }
                    }

                case "-d", "--data", "--data-raw", "--data-binary":
                    // Request body
                    i += 1
                    if i < tokens.count {
                        request.body = tokens[i]
                        if request.method == "GET" {
                            request.method = "POST"
                        }
                    }

                case "-F", "--form":
                    // Form data
                    i += 1
                    if i < tokens.count {
                        let formField = tokens[i]
                        if let equalIndex = formField.firstIndex(of: "=") {
                            let key = String(formField[..<equalIndex])
                            let value = String(formField[formField.index(after: equalIndex)...])
                            request.formData[key] = value
                        }
                        if request.method == "GET" {
                            request.method = "POST"
                        }
                    }

                case "-u", "--user":
                    // Authentication
                    i += 1
                    if i < tokens.count {
                        let auth = tokens[i]
                        if let colonIndex = auth.firstIndex(of: ":") {
                            request.username = String(auth[..<colonIndex])
                            request.password = String(auth[auth.index(after: colonIndex)...])
                        }
                    }

                case "-G", "--get":
                    // Force GET method
                    request.method = "GET"

                case "--compressed", "-L", "--location", "-i", "--include",
                     "-s", "--silent", "-v", "--verbose", "-k", "--insecure":
                    // These flags don't affect code generation significantly
                    break

                default:
                    // Skip unknown flags (don't throw error for flexibility)
                    break
                }
            } else {
                // Assume it's the URL
                request.url = token.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }

            i += 1
        }

        // Validate we have a URL
        guard !request.url.isEmpty else {
            throw CurlConverterError.missingURL
        }

        return request
    }

    // MARK: - Tokenize Command

    /// Tokenize the cURL command, respecting quotes
    private func tokenize(_ command: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var inQuotes = false
        var quoteChar: Character?
        var escapeNext = false

        for char in command {
            if escapeNext {
                currentToken.append(char)
                escapeNext = false
                continue
            }

            if char == "\\" {
                escapeNext = true
                continue
            }

            if char == "\"" || char == "'" {
                if !inQuotes {
                    inQuotes = true
                    quoteChar = char
                } else if char == quoteChar {
                    inQuotes = false
                    quoteChar = nil
                } else {
                    currentToken.append(char)
                }
                continue
            }

            if char.isWhitespace && !inQuotes {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                    currentToken = ""
                }
            } else {
                currentToken.append(char)
            }
        }

        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }

        return tokens
    }

    // MARK: - Code Generation

    /// Generate code for the specified language
    func generateCode(from request: CurlRequest, language: TargetLanguage) -> String {
        switch language {
        case .swift:
            return generateSwift(request)
        case .python:
            return generatePython(request)
        case .javascript:
            return generateJavaScript(request)
        case .go:
            return generateGo(request)
        case .php:
            return generatePHP(request)
        case .ruby:
            return generateRuby(request)
        }
    }

    // MARK: - Swift Generation

    private func generateSwift(_ request: CurlRequest) -> String {
        var code = "import Foundation\n\n"

        // URL
        code += "guard let url = URL(string: \"\(request.url)\") else {\n"
        code += "    print(\"Invalid URL\")\n"
        code += "    return\n"
        code += "}\n\n"

        // Request
        code += "var request = URLRequest(url: url)\n"
        code += "request.httpMethod = \"\(request.method)\"\n\n"

        // Headers
        if !request.headers.isEmpty {
            for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
                code += "request.setValue(\"\(value)\", forHTTPHeaderField: \"\(key)\")\n"
            }
            code += "\n"
        }

        // Body
        if let body = request.body {
            code += "let bodyData = \"\"\"\n\(body)\n\"\"\".data(using: .utf8)\n"
            code += "request.httpBody = bodyData\n\n"
        } else if !request.formData.isEmpty {
            code += "let formData: [String: String] = [\n"
            for (key, value) in request.formData.sorted(by: { $0.key < $1.key }) {
                code += "    \"\(key)\": \"\(value)\",\n"
            }
            code += "]\n"
            code += "request.httpBody = formData.map { \"\\($0.key)=\\($0.value)\" }\n"
            code += "    .joined(separator: \"&\")\n"
            code += "    .data(using: .utf8)\n\n"
        }

        // Authentication
        if let username = request.username, let password = request.password {
            code += "let credentials = \"\(username):\(password)\"\n"
            code += "if let credentialsData = credentials.data(using: .utf8) {\n"
            code += "    let base64Credentials = credentialsData.base64EncodedString()\n"
            code += "    request.setValue(\"Basic \\(base64Credentials)\", forHTTPHeaderField: \"Authorization\")\n"
            code += "}\n\n"
        }

        // Execute request
        code += "let task = URLSession.shared.dataTask(with: request) { data, response, error in\n"
        code += "    if let error = error {\n"
        code += "        print(\"Error: \\(error.localizedDescription)\")\n"
        code += "        return\n"
        code += "    }\n\n"
        code += "    if let data = data, let responseString = String(data: data, encoding: .utf8) {\n"
        code += "        print(\"Response: \\(responseString)\")\n"
        code += "    }\n"
        code += "}\n"
        code += "task.resume()"

        return code
    }

    // MARK: - Python Generation

    private func generatePython(_ request: CurlRequest) -> String {
        var code = "import requests\n\n"

        // URL
        code += "url = \"\(request.url)\"\n\n"

        // Headers
        if !request.headers.isEmpty {
            code += "headers = {\n"
            for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
                code += "    '\(key)': '\(value)',\n"
            }
            code += "}\n\n"
        }

        // Body/Data
        if let body = request.body {
            code += "data = '''\n\(body)\n'''\n\n"
        } else if !request.formData.isEmpty {
            code += "data = {\n"
            for (key, value) in request.formData.sorted(by: { $0.key < $1.key }) {
                code += "    '\(key)': '\(value)',\n"
            }
            code += "}\n\n"
        }

        // Authentication
        var authParam = ""
        if let username = request.username, let password = request.password {
            authParam = ", auth=('\(username)', '\(password)')"
        }

        // Request
        let method = request.method.lowercased()
        let headersParam = request.headers.isEmpty ? "" : ", headers=headers"
        let dataParam: String
        if request.body != nil {
            dataParam = ", data=data"
        } else if !request.formData.isEmpty {
            dataParam = ", data=data"
        } else {
            dataParam = ""
        }

        code += "response = requests.\(method)(url\(headersParam)\(dataParam)\(authParam))\n"
        code += "print(response.text)"

        return code
    }

    // MARK: - JavaScript Generation

    private func generateJavaScript(_ request: CurlRequest) -> String {
        var code = ""

        // Options object
        code += "const options = {\n"
        code += "  method: '\(request.method)',\n"

        // Headers
        if !request.headers.isEmpty || request.username != nil {
            code += "  headers: {\n"
            for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
                code += "    '\(key)': '\(value)',\n"
            }

            // Basic auth
            if let username = request.username, let password = request.password {
                let credentials = "\(username):\(password)"
                if let data = credentials.data(using: .utf8) {
                    let base64 = data.base64EncodedString()
                    code += "    'Authorization': 'Basic \(base64)',\n"
                }
            }

            code += "  },\n"
        }

        // Body
        if let body = request.body {
            code += "  body: `\(body)`\n"
        } else if !request.formData.isEmpty {
            code += "  body: new URLSearchParams({\n"
            for (key, value) in request.formData.sorted(by: { $0.key < $1.key }) {
                code += "    '\(key)': '\(value)',\n"
            }
            code += "  })\n"
        }

        code += "};\n\n"

        // Fetch call
        code += "fetch('\(request.url)', options)\n"
        code += "  .then(response => response.text())\n"
        code += "  .then(data => console.log(data))\n"
        code += "  .catch(error => console.error('Error:', error));"

        return code
    }

    // MARK: - Go Generation

    private func generateGo(_ request: CurlRequest) -> String {
        var code = "package main\n\n"
        code += "import (\n"
        code += "    \"fmt\"\n"
        code += "    \"io\"\n"
        code += "    \"net/http\"\n"
        if request.body != nil || !request.formData.isEmpty {
            code += "    \"strings\"\n"
        }
        code += ")\n\n"

        code += "func main() {\n"

        // Body
        if let body = request.body {
            code += "    payload := strings.NewReader(`\(body)`)\n"
            code += "    req, err := http.NewRequest(\"\(request.method)\", \"\(request.url)\", payload)\n"
        } else if !request.formData.isEmpty {
            let formPairs = request.formData.sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            code += "    payload := strings.NewReader(\"\(formPairs)\")\n"
            code += "    req, err := http.NewRequest(\"\(request.method)\", \"\(request.url)\", payload)\n"
        } else {
            code += "    req, err := http.NewRequest(\"\(request.method)\", \"\(request.url)\", nil)\n"
        }

        code += "    if err != nil {\n"
        code += "        fmt.Println(err)\n"
        code += "        return\n"
        code += "    }\n\n"

        // Headers
        for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
            code += "    req.Header.Add(\"\(key)\", \"\(value)\")\n"
        }

        // Authentication
        if let username = request.username, let password = request.password {
            code += "    req.SetBasicAuth(\"\(username)\", \"\(password)\")\n"
        }

        if !request.headers.isEmpty || request.username != nil {
            code += "\n"
        }

        // Execute
        code += "    client := &http.Client{}\n"
        code += "    resp, err := client.Do(req)\n"
        code += "    if err != nil {\n"
        code += "        fmt.Println(err)\n"
        code += "        return\n"
        code += "    }\n"
        code += "    defer resp.Body.Close()\n\n"
        code += "    body, _ := io.ReadAll(resp.Body)\n"
        code += "    fmt.Println(string(body))\n"
        code += "}"

        return code
    }

    // MARK: - PHP Generation

    private func generatePHP(_ request: CurlRequest) -> String {
        var code = "<?php\n\n"
        code += "$ch = curl_init();\n\n"

        // URL and options
        code += "curl_setopt($ch, CURLOPT_URL, '\(request.url)');\n"
        code += "curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);\n"
        code += "curl_setopt($ch, CURLOPT_CUSTOMREQUEST, '\(request.method)');\n"

        // Headers
        if !request.headers.isEmpty {
            code += "curl_setopt($ch, CURLOPT_HTTPHEADER, [\n"
            for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
                code += "    '\(key): \(value)',\n"
            }
            code += "]);\n"
        }

        // Body
        if let body = request.body {
            code += "curl_setopt($ch, CURLOPT_POSTFIELDS, '\(body)');\n"
        } else if !request.formData.isEmpty {
            code += "curl_setopt($ch, CURLOPT_POSTFIELDS, [\n"
            for (key, value) in request.formData.sorted(by: { $0.key < $1.key }) {
                code += "    '\(key)' => '\(value)',\n"
            }
            code += "]);\n"
        }

        // Authentication
        if let username = request.username, let password = request.password {
            code += "curl_setopt($ch, CURLOPT_USERPWD, '\(username):\(password)');\n"
        }

        code += "\n$response = curl_exec($ch);\n"
        code += "curl_close($ch);\n\n"
        code += "echo $response;"

        return code
    }

    // MARK: - Ruby Generation

    private func generateRuby(_ request: CurlRequest) -> String {
        var code = "require 'net/http'\n"
        code += "require 'uri'\n\n"

        code += "uri = URI.parse('\(request.url)')\n"
        code += "http = Net::HTTP.new(uri.host, uri.port)\n"

        if request.url.hasPrefix("https") {
            code += "http.use_ssl = true\n"
        }

        code += "\n"

        // Request type
        let method = request.method.capitalized
        code += "request = Net::HTTP::\(method).new(uri.request_uri)\n"

        // Headers
        for (key, value) in request.headers.sorted(by: { $0.key < $1.key }) {
            code += "request[\"\(key)\"] = \"\(value)\"\n"
        }

        // Authentication
        if let username = request.username, let password = request.password {
            code += "request.basic_auth('\(username)', '\(password)')\n"
        }

        // Body
        if let body = request.body {
            code += "request.body = '\(body)'\n"
        } else if !request.formData.isEmpty {
            code += "request.set_form_data({\n"
            for (key, value) in request.formData.sorted(by: { $0.key < $1.key }) {
                code += "  '\(key)' => '\(value)',\n"
            }
            code += "})\n"
        }

        code += "\nresponse = http.request(request)\n"
        code += "puts response.body"

        return code
    }
}

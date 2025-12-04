//
//  CurlConverterServiceTests.swift
//  PetruUtilsTests
//
//  Created by Agent on 12/3/25.
//

import Testing
import Foundation
@testable import PetruUtils

@Suite("Curl Converter Service Tests")
struct CurlConverterServiceTests {
    let service = CurlConverterService()

    // MARK: - Basic Parsing Tests

    @Test("Parse simple GET request")
    func testParseSimpleGet() throws {
        let curl = "curl https://api.example.com/users"
        let request = try service.parseCurl(curl)

        #expect(request.url == "https://api.example.com/users")
        #expect(request.method == "GET")
        #expect(request.headers.isEmpty)
        #expect(request.body == nil)
    }

    @Test("Parse GET request with explicit method")
    func testParseGetWithMethod() throws {
        let curl = "curl -X GET https://api.example.com/data"
        let request = try service.parseCurl(curl)

        #expect(request.url == "https://api.example.com/data")
        #expect(request.method == "GET")
    }

    @Test("Parse POST request")
    func testParsePost() throws {
        let curl = "curl -X POST https://api.example.com/users"
        let request = try service.parseCurl(curl)

        #expect(request.url == "https://api.example.com/users")
        #expect(request.method == "POST")
    }

    @Test("Parse without curl prefix")
    func testParseWithoutCurlPrefix() throws {
        let curl = "https://api.example.com/test"
        let request = try service.parseCurl(curl)

        #expect(request.url == "https://api.example.com/test")
        #expect(request.method == "GET")
    }

    // MARK: - Header Tests

    @Test("Parse single header")
    func testParseSingleHeader() throws {
        let curl = "curl -H 'Content-Type: application/json' https://api.example.com"
        let request = try service.parseCurl(curl)

        #expect(request.headers["Content-Type"] == "application/json")
    }

    @Test("Parse multiple headers")
    func testParseMultipleHeaders() throws {
        let curl = """
        curl -H 'Content-Type: application/json' \
             -H 'Authorization: Bearer token123' \
             https://api.example.com
        """
        let request = try service.parseCurl(curl)

        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.headers["Authorization"] == "Bearer token123")
        #expect(request.headers.count == 2)
    }

    // MARK: - Body/Data Tests

    @Test("Parse request with JSON body")
    func testParseJsonBody() throws {
        let curl = #"curl -X POST -d '{"name":"John","age":30}' https://api.example.com/users"#
        let request = try service.parseCurl(curl)

        #expect(request.method == "POST")
        #expect(request.body == #"{"name":"John","age":30}"#)
    }

    @Test("Parse request with form data")
    func testParseFormData() throws {
        let curl = "curl -F 'name=John' -F 'email=john@example.com' https://api.example.com/upload"
        let request = try service.parseCurl(curl)

        #expect(request.method == "POST") // Auto-set to POST with -F
        #expect(request.formData["name"] == "John")
        #expect(request.formData["email"] == "john@example.com")
    }

    @Test("Parse -d data auto-sets POST method")
    func testDataAutoSetsPost() throws {
        let curl = "curl -d 'key=value' https://api.example.com"
        let request = try service.parseCurl(curl)

        #expect(request.method == "POST")
        #expect(request.body == "key=value")
    }

    // MARK: - Authentication Tests

    @Test("Parse basic authentication")
    func testParseBasicAuth() throws {
        let curl = "curl -u user:pass123 https://api.example.com/secure"
        let request = try service.parseCurl(curl)

        #expect(request.username == "user")
        #expect(request.password == "pass123")
    }

    // MARK: - Complex Command Tests

    @Test("Parse complex command with multiple options")
    func testParseComplexCommand() throws {
        let curl = """
        curl -X POST \
             -H 'Content-Type: application/json' \
             -H 'Accept: application/json' \
             -d '{"test": "data"}' \
             -u admin:secret \
             https://api.example.com/endpoint
        """
        let request = try service.parseCurl(curl)

        #expect(request.url == "https://api.example.com/endpoint")
        #expect(request.method == "POST")
        #expect(request.headers["Content-Type"] == "application/json")
        #expect(request.headers["Accept"] == "application/json")
        #expect(request.body == #"{"test": "data"}"#)
        #expect(request.username == "admin")
        #expect(request.password == "secret")
    }

    @Test("Parse command with quoted URL")
    func testParseQuotedUrl() throws {
        let curl = #"curl "https://api.example.com/users""#
        let request = try service.parseCurl(curl)

        #expect(request.url == "https://api.example.com/users")
    }

    // MARK: - Error Tests

    @Test("Throw error for empty input")
    func testEmptyInput() {
        #expect(throws: CurlConverterError.self) {
            try service.parseCurl("")
        }
    }

    @Test("Throw error for whitespace only")
    func testWhitespaceOnly() {
        #expect(throws: CurlConverterError.self) {
            try service.parseCurl("   \n\t  ")
        }
    }

    @Test("Throw error for missing URL")
    func testMissingUrl() {
        #expect(throws: CurlConverterError.self) {
            try service.parseCurl("curl -X POST")
        }
    }

    // MARK: - Code Generation Tests

    @Test("Generate Swift code from simple request")
    func testGenerateSwiftSimple() throws {
        let request = CurlRequest(
            url: "https://api.example.com/users",
            method: "GET"
        )

        let code = service.generateCode(from: request, language: .swift)

        #expect(code.contains("import Foundation"))
        #expect(code.contains("URL(string: \"https://api.example.com/users\")"))
        #expect(code.contains("httpMethod = \"GET\""))
        #expect(code.contains("URLSession.shared.dataTask"))
    }

    @Test("Generate Swift code with headers")
    func testGenerateSwiftWithHeaders() throws {
        let request = CurlRequest(
            url: "https://api.example.com/data",
            method: "GET",
            headers: ["Content-Type": "application/json", "Accept": "application/json"]
        )

        let code = service.generateCode(from: request, language: .swift)

        #expect(code.contains("setValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")"))
        #expect(code.contains("setValue(\"application/json\", forHTTPHeaderField: \"Accept\")"))
    }

    @Test("Generate Swift code with body")
    func testGenerateSwiftWithBody() throws {
        let request = CurlRequest(
            url: "https://api.example.com/users",
            method: "POST",
            body: #"{"name":"John"}"#
        )

        let code = service.generateCode(from: request, language: .swift)

        #expect(code.contains("httpMethod = \"POST\""))
        #expect(code.contains("httpBody"))
        #expect(code.contains(#"{"name":"John"}"#))
    }

    @Test("Generate Python code")
    func testGeneratePython() throws {
        let request = CurlRequest(
            url: "https://api.example.com/users",
            method: "GET",
            headers: ["Authorization": "Bearer token"]
        )

        let code = service.generateCode(from: request, language: .python)

        #expect(code.contains("import requests"))
        #expect(code.contains("url = \"https://api.example.com/users\""))
        #expect(code.contains("'Authorization': 'Bearer token'"))
        #expect(code.contains("requests.get"))
    }

    @Test("Generate JavaScript code")
    func testGenerateJavaScript() throws {
        let request = CurlRequest(
            url: "https://api.example.com/data",
            method: "POST",
            headers: ["Content-Type": "application/json"]
        )

        let code = service.generateCode(from: request, language: .javascript)

        #expect(code.contains("const options"))
        #expect(code.contains("method: 'POST'"))
        #expect(code.contains("'Content-Type': 'application/json'"))
        #expect(code.contains("fetch"))
    }

    @Test("Generate Go code")
    func testGenerateGo() throws {
        let request = CurlRequest(
            url: "https://api.example.com/users",
            method: "GET"
        )

        let code = service.generateCode(from: request, language: .go)

        #expect(code.contains("package main"))
        #expect(code.contains("import"))
        #expect(code.contains("http.NewRequest"))
        #expect(code.contains("\"GET\""))
    }

    @Test("Generate PHP code")
    func testGeneratePHP() throws {
        let request = CurlRequest(
            url: "https://api.example.com/users",
            method: "POST"
        )

        let code = service.generateCode(from: request, language: .php)

        #expect(code.contains("<?php"))
        #expect(code.contains("curl_init()"))
        #expect(code.contains("CURLOPT_URL"))
        #expect(code.contains("'POST'"))
    }

    @Test("Generate Ruby code")
    func testGenerateRuby() throws {
        let request = CurlRequest(
            url: "https://api.example.com/data",
            method: "GET"
        )

        let code = service.generateCode(from: request, language: .ruby)

        #expect(code.contains("require 'net/http'"))
        #expect(code.contains("URI.parse"))
        #expect(code.contains("Net::HTTP::Get"))
    }

    // MARK: - End-to-End Tests

    @Test("Parse and generate Swift code")
    func testParseAndGenerateSwift() throws {
        let curl = """
        curl -X POST \
             -H 'Content-Type: application/json' \
             -d '{"test":"value"}' \
             https://api.example.com/endpoint
        """

        let request = try service.parseCurl(curl)
        let code = service.generateCode(from: request, language: .swift)

        #expect(code.contains("import Foundation"))
        #expect(code.contains("https://api.example.com/endpoint"))
        #expect(code.contains("POST"))
        #expect(code.contains("Content-Type"))
        #expect(code.contains("application/json"))
    }

    @Test("Parse and generate Python code")
    func testParseAndGeneratePython() throws {
        let curl = "curl -u user:pass https://api.example.com/secure"

        let request = try service.parseCurl(curl)
        let code = service.generateCode(from: request, language: .python)

        #expect(code.contains("import requests"))
        #expect(code.contains("auth=('user', 'pass')"))
    }
}

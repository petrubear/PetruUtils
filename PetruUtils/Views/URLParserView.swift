import SwiftUI
import Combine

struct URLParserView: View {
    @StateObject private var vm = URLParserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            inputField
            Divider()
            outputPane
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("URL Parser")
                .font(.headline)
            
            Spacer()
            
            Button("Parse") { vm.parse() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                TextField("Enter URL (e.g., https://example.com:8080/path?key=value#fragment)", text: $vm.input, onCommit: { vm.parse() })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Help text
            Text("Example: https://user:pass@example.com:8080/path?key=value&foo=bar#section")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let parsed = vm.parsed {
                    componentSection(title: "Components") {
                        componentRow(label: "Scheme", value: parsed.scheme ?? "—")
                        componentRow(label: "Host", value: parsed.host ?? "—")
                        if let port = parsed.port {
                            componentRow(label: "Port", value: String(port))
                        }
                        componentRow(label: "Path", value: parsed.path ?? "—")
                        if let user = parsed.user {
                            componentRow(label: "User", value: user)
                        }
                        if let password = parsed.password {
                            componentRow(label: "Password", value: "••••••")
                        }
                        componentRow(label: "Query", value: parsed.query ?? "—")
                        componentRow(label: "Fragment", value: parsed.fragment ?? "—")
                    }
                    
                    if !parsed.queryParameters.isEmpty {
                        Divider()
                        
                        componentSection(title: "Query Parameters (\(parsed.queryParameters.count))") {
                            ForEach(Array(parsed.queryParameters.enumerated()), id: \.offset) { _, param in
                                HStack(alignment: .top, spacing: 8) {
                                    Text(param.key)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .foregroundStyle(.blue)
                                        .frame(width: 120, alignment: .leading)
                                    
                                    Text("=")
                                        .foregroundStyle(.secondary)
                                    
                                    Text(param.value.isEmpty ? "(empty)" : param.value)
                                        .font(.system(.subheadline, design: .monospaced))
                                        .textSelection(.enabled)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "link.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter a URL to parse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func componentSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding(.leading, 8)
        }
    }
    
    @ViewBuilder
    private func componentRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

@MainActor
final class URLParserViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var parsed: URLParserService.ParsedURL?
    @Published var errorMessage: String?
    
    private let service = URLParserService()
    
    func parse() {
        errorMessage = nil
        parsed = nil
        
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        do {
            parsed = try service.parse(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        input = ""
        parsed = nil
        errorMessage = nil
    }
}


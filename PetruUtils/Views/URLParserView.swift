import SwiftUI
import Combine

struct URLParserView: View {
    @StateObject private var vm = URLParserViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            HSplitView {
                inputPane
                outputPane
            }
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
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "link", title: "Input", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL to Parse")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 100)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                    
                    HStack {
                        if !vm.input.isEmpty {
                            Text("\(vm.input.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }

                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                // Help text
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("https://user:pass@example.com:8080/path?key=value&foo=bar#section")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Parsed Components")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let parsed = vm.parsed {
                        // Core Components
                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader(icon: "server.rack", title: "Components", color: .purple)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                componentRow(label: "Scheme", value: parsed.scheme ?? "—", icon: "globe")
                                Divider().padding(.leading, 36)
                                componentRow(label: "Host", value: parsed.host ?? "—", icon: "network")
                                Divider().padding(.leading, 36)
                                if let port = parsed.port {
                                    componentRow(label: "Port", value: String(port), icon: "number")
                                    Divider().padding(.leading, 36)
                                }
                                componentRow(label: "Path", value: parsed.path ?? "—", icon: "folder")
                                
                                if parsed.user != nil || parsed.password != nil {
                                    Divider().padding(.leading, 36)
                                    if let user = parsed.user {
                                        componentRow(label: "User", value: user, icon: "person")
                                    }
                                    if let _ = parsed.password {
                                        if parsed.user != nil { Divider().padding(.leading, 36) }
                                        componentRow(label: "Password", value: "••••••", icon: "key")
                                    }
                                }
                                
                                Divider().padding(.leading, 36)
                                componentRow(label: "Fragment", value: parsed.fragment ?? "—", icon: "number.square")
                            }
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        // Query Parameters
                        if !parsed.queryParameters.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                sectionHeader(icon: "list.bullet", title: "Query Parameters (\(parsed.queryParameters.count))", color: .orange)
                                
                                VStack(spacing: 1) {
                                    ForEach(Array(parsed.queryParameters.enumerated()), id: \.offset) { index, param in
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
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(index % 2 == 0 ? Color.secondary.opacity(0.02) : Color.clear)
                                    }
                                }
                                .background(Color.secondary.opacity(0.05))
                                .cornerRadius(8)
                            }
                        } else {
                             VStack(alignment: .leading, spacing: 8) {
                                sectionHeader(icon: "list.bullet", title: "Query Parameters", color: .orange)
                                Text("No query parameters found")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 8)
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
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
        }
    }
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }
    
    private func componentRow(label: String, value: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
                .padding(.top, 2)
            
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
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
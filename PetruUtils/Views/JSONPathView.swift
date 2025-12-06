import SwiftUI
import Combine

struct JSONPathView: View {
    @StateObject private var vm = JSONPathViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            VStack(spacing: 0) {
                pathInputPane
                Divider()
                HSplitView {
                    jsonInputPane
                    resultPane
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("JSON Path Tester")
                .font(.headline)
            
            Spacer()
            
            Button("Test") {
                vm.test()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var pathInputPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(icon: "arrow.triangle.branch", title: "JSONPath Expression", color: .blue)
                Spacer()
                if vm.matchCount > 0 {
                    Text("\(vm.matchCount) match\(vm.matchCount == 1 ? "" : "es")")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            TextField("e.g., $.store.book[0].title", text: $vm.path)
                .font(.system(.body, design: .monospaced))
                .textFieldStyle(.roundedBorder)
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } else {
                Text("Examples: $.users[0], $.users[*].name, $..email")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.02))
    }
    
    private var jsonInputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader(icon: "curlybraces", title: "Input JSON", color: .purple)
                Spacer()
                Text("\(vm.jsonInput.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            FocusableTextEditor(text: $vm.jsonInput)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Syntax")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text("$ (root), .key (child), [0] (index), [*] (all), ..key (recursive)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    private var resultPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader(icon: "list.bullet.indent", title: "Result", color: .green)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            
            ScrollView {
                SyntaxHighlightedText(text: vm.output, language: .json)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .padding()
    }
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

@MainActor
final class JSONPathViewModel: ObservableObject {
    @Published var jsonInput: String = ""
    @Published var path: String = ""
    @Published var output: String = ""
    @Published var matchCount: Int = 0
    @Published var errorMessage: String?
    
    private let service = JSONPathService()
    
    func test() {
        errorMessage = nil
        output = ""
        matchCount = 0
        
        guard !jsonInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter JSON input"
            return
        }
        
        guard !path.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a JSONPath expression"
            return
        }
        
        do {
            let result = try service.evaluate(json: jsonInput, path: path)
            output = try service.formatResult(result)
            matchCount = result.matches
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        jsonInput = ""
        path = ""
        output = ""
        matchCount = 0
        errorMessage = nil
    }
}
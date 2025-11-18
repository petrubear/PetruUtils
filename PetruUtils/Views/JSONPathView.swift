import SwiftUI
import Combine

struct JSONPathView: View {
    @StateObject private var vm = JSONPathViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            VStack(spacing: 0) {
                pathInput
                Divider()
                HSplitView {
                    jsonInput
                    resultOutput
                }
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Button("Test") {
                vm.test()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            
            Spacer()
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var pathInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("JSONPath Expression")
                    .font(.headline)
                
                Spacer()
                
                if vm.matchCount > 0 {
                    Text("\(vm.matchCount) match\(vm.matchCount == 1 ? "" : "es")")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding([.horizontal, .top], 8)
            
            TextField("e.g., $.store.book[0].title", text: $vm.path)
                .font(.custom("JetBrains Mono", size: 12))
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
            
            Text("Examples: $.users[0], $.users[*].name, $..email")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            
            if let error = vm.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
    }
    
    private var jsonInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("JSON Input")
                    .font(.headline)
                Spacer()
                Text("\(vm.jsonInput.count) chars")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding([.horizontal, .top], 8)
            
            FocusableTextEditor(text: $vm.jsonInput)
                .font(.custom("JetBrains Mono", size: 12))
        }
    }
    
    private var resultOutput: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Result")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) chars")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !vm.output.isEmpty {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding([.horizontal, .top], 8)
            
            ScrollView {
                SyntaxHighlightedText(text: vm.output, language: .json)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .padding([.horizontal, .bottom], 8)
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

#Preview {
    JSONPathView()
        .frame(width: 900, height: 600)
}

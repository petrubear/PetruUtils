import SwiftUI
import Combine

struct JSONYAMLView: View {
    @StateObject private var vm = JSONYAMLViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JSON ↔ YAML Converter").font(.headline)
                Spacer()
                Picker("Mode", selection: $vm.mode) {
                    Text("JSON → YAML").tag(true)
                    Text("YAML → JSON").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                Button("Convert") { vm.convert() }.keyboardShortcut(.return, modifiers: [.command])
                Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
            }
            .padding(.horizontal).padding(.vertical, 8)
            
            Divider()
            
            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input").font(.headline)
                    FocusableTextEditor(text: $vm.input)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    if let error = vm.errorMessage {
                        Text(error).foregroundStyle(.red).font(.callout)
                    }
                }.padding()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output").font(.headline)
                    ScrollView {
                        SyntaxHighlightedText(text: vm.output, language: vm.mode ? .plain : .json)
                            .padding(8)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                }.padding()
            }
        }
    }
}

@MainActor
final class JSONYAMLViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var mode = true // true = JSON to YAML
    @Published var errorMessage: String?
    
    private let service = JSONYAMLService()
    
    func convert() {
        errorMessage = nil
        output = ""
        guard !input.isEmpty else { return }
        
        do {
            output = mode ? try service.jsonToYAML(input) : try service.yamlToJSON(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
    }
}


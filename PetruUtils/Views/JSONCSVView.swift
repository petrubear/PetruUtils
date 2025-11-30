import SwiftUI
import Combine

struct JSONCSVView: View {
    @StateObject private var vm = JSONCSVViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JSON ↔ CSV Converter").font(.headline)
                Spacer()
                Picker("Mode", selection: $vm.mode) {
                    Text("JSON → CSV").tag(true)
                    Text("CSV → JSON").tag(false)
                }.pickerStyle(.segmented).frame(width: 200)
                Picker("Delimiter", selection: $vm.delimiter) {
                    Text(",").tag(",")
                    Text(";").tag(";")
                    Text("Tab").tag("\t")
                }.frame(width: 100)
                Button("Convert") { vm.convert() }.keyboardShortcut(.return, modifiers: [.command])
                Button("Clear") { vm.clear() }.keyboardShortcut("k", modifiers: [.command])
            }.padding(.horizontal).padding(.vertical, 8)
            Divider()
            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Input").font(.headline)
                    FocusableTextEditor(text: $vm.input).padding(4).overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    if let error = vm.errorMessage { Text(error).foregroundStyle(.red).font(.callout) }
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
final class JSONCSVViewModel: ObservableObject {
    @Published var input = ""
    @Published var output = ""
    @Published var mode = true
    @Published var delimiter = ","
    @Published var errorMessage: String?
    private let service = JSONCSVService()
    
    func convert() {
        errorMessage = nil
        output = ""
        guard !input.isEmpty else { return }
        do {
            output = mode ? try service.jsonToCSV(input, delimiter: delimiter) : try service.csvToJSON(input, delimiter: delimiter)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    func clear() { input = ""; output = ""; errorMessage = nil }
}


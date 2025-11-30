import SwiftUI
import Combine

struct LoremIpsumView: View {
    @StateObject private var vm = LoremIpsumViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            outputPane
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("Lorem Ipsum Generator")
                .font(.headline)
            
            Spacer()
            
            Picker("", selection: $vm.generationType) {
                Text("Paragraphs").tag(LoremIpsumService.GenerationType.paragraphs)
                Text("Sentences").tag(LoremIpsumService.GenerationType.sentences)
                Text("Words").tag(LoremIpsumService.GenerationType.words)
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            .labelsHidden()
            
            Stepper("Count: \(vm.count)", value: $vm.count, in: 1...100)
                .frame(width: 140)
            
            Toggle("Start with Lorem", isOn: $vm.startWithLorem)
            
            Button("Generate") { vm.generate() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Generated Text")
                    .font(.subheadline.weight(.medium))
                Spacer()
                
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(vm.output, forType: .string)
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
            
            ScrollView {
                Text(vm.output.isEmpty ? "Click Generate to create lorem ipsum text" : vm.output)
                    .font(.system(.body))
                    .foregroundStyle(vm.output.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .padding()
    }
}

@MainActor
final class LoremIpsumViewModel: ObservableObject {
    @Published var output: String = ""
    @Published var generationType: LoremIpsumService.GenerationType = .paragraphs
    @Published var count: Int = 3
    @Published var startWithLorem: Bool = true
    
    private let service = LoremIpsumService()
    
    func generate() {
        output = service.generate(type: generationType, count: count, startWithLorem: startWithLorem)
    }
    
    func clear() {
        output = ""
    }
}


import SwiftUI
import Combine

struct LoremIpsumView: View {
    @StateObject private var vm = LoremIpsumViewModel()
    
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
            Text("Lorem Ipsum")
                .font(.headline)
            
            Spacer()
            
            Button("Generate") { vm.generate() }
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
                sectionHeader(icon: "gearshape", title: "Configuration", color: .blue)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Type
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Type")
                            .font(.subheadline)
                        Picker("", selection: $vm.generationType) {
                            Text("Paragraphs").tag(LoremIpsumService.GenerationType.paragraphs)
                            Text("Sentences").tag(LoremIpsumService.GenerationType.sentences)
                            Text("Words").tag(LoremIpsumService.GenerationType.words)
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    
                    Divider()
                    
                    // Count
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Count: \(vm.count)")
                                .font(.subheadline)
                            Spacer()
                        }
                        Stepper("", value: $vm.count, in: 1...100)
                            .labelsHidden()
                    }
                    
                    Divider()
                    
                    // Options
                    Toggle("Start with 'Lorem ipsum...'", isOn: $vm.startWithLorem)
                        .toggleStyle(.switch)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Usage")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("Generate placeholder text for designs, mockups, and layouts.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                .padding(.top, 4)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Generated Text")
                    .font(.headline)
                Spacer()
                
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) chars")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    
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
            .padding()
            
            Divider()
            
            ScrollView {
                if vm.output.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Click Generate to create text")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else {
                    Text(vm.output)
                        .font(.system(.body))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                }
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
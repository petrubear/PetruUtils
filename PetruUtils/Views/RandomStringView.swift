import SwiftUI
import Combine

struct RandomStringView: View {
    @StateObject private var vm = RandomStringViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            outputPane
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text("Random String Generator")
                .font(.headline)
            
            Spacer()
            
            Stepper("Length: \(vm.length)", value: $vm.length, in: 1...1000)
                .frame(width: 140)
            
            Stepper("Count: \(vm.count)", value: $vm.count, in: 1...100)
                .frame(width: 130)
            
            Toggle("a-z", isOn: $vm.includeLowercase)
            Toggle("A-Z", isOn: $vm.includeUppercase)
            Toggle("0-9", isOn: $vm.includeNumbers)
            Toggle("!@#", isOn: $vm.includeSymbols)
            Toggle("Exclude ambiguous", isOn: $vm.excludeAmbiguous)
            
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
                Text("Generated Strings")
                    .font(.subheadline.weight(.medium))
                Spacer()
                
                if !vm.output.isEmpty {
                    Text("\(vm.output.count) string\(vm.output.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(action: {
                        let text = vm.output.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }) {
                        Label("Copy All", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                }
            }
            
            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            ScrollView {
                if vm.output.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.rectangle.stack")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Click Generate to create random strings")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Uses cryptographically secure randomness")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(vm.output.enumerated()), id: \.offset) { index, string in
                            HStack(spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 30, alignment: .trailing)
                                
                                Text(string)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(string, forType: .string)
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding(8)
                }
            }
        }
        .padding()
    }
}

@MainActor
final class RandomStringViewModel: ObservableObject {
    @Published var output: [String] = []
    @Published var errorMessage: String?
    @Published var length: Int = 16
    @Published var count: Int = 5
    @Published var includeLowercase: Bool = true
    @Published var includeUppercase: Bool = true
    @Published var includeNumbers: Bool = true
    @Published var includeSymbols: Bool = false
    @Published var excludeAmbiguous: Bool = true
    
    private let service = RandomStringService()
    
    func generate() {
        errorMessage = nil
        
        var characterSets: [RandomStringService.CharacterSet] = []
        if includeLowercase { characterSets.append(.lowercase) }
        if includeUppercase { characterSets.append(.uppercase) }
        if includeNumbers { characterSets.append(.numbers) }
        if includeSymbols { characterSets.append(.symbols) }
        
        do {
            if count == 1 {
                let string = try service.generate(length: length, characterSets: characterSets, excludeAmbiguous: excludeAmbiguous)
                output = [string]
            } else {
                output = try service.generateMultiple(count: count, length: length, characterSets: characterSets, excludeAmbiguous: excludeAmbiguous)
            }
        } catch {
            errorMessage = error.localizedDescription
            output = []
        }
    }
    
    func clear() {
        output = []
        errorMessage = nil
    }
}

#Preview {
    RandomStringView()
}

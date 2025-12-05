import SwiftUI
import Combine

struct RandomStringView: View {
    @StateObject private var vm = RandomStringViewModel()
    
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
        HStack {
            Text("Random String Generator")
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
                
                // Length & Count
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Length: \(vm.length)")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                        Slider(value: Binding(
                            get: { Double(vm.length) },
                            set: { vm.length = Int($0) }
                        ), in: 1...128, step: 1)
                        
                        HStack {
                            Button("-") { if vm.length > 1 { vm.length -= 1 } }
                            TextField("", value: $vm.length, formatter: NumberFormatter())
                                .frame(width: 50)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.center)
                            Button("+") { if vm.length < 1000 { vm.length += 1 } }
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Count: \(vm.count)")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                        Stepper("", value: $vm.count, in: 1...100)
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Character Sets
                sectionHeader(icon: "textformat", title: "Character Sets", color: .purple)
                
                VStack(spacing: 0) {
                    ToggleRow(title: "Uppercase (A-Z)", isOn: $vm.includeUppercase)
                    Divider().padding(.leading)
                    ToggleRow(title: "Lowercase (a-z)", isOn: $vm.includeLowercase)
                    Divider().padding(.leading)
                    ToggleRow(title: "Numbers (0-9)", isOn: $vm.includeNumbers)
                    Divider().padding(.leading)
                    ToggleRow(title: "Symbols (!@#)", isOn: $vm.includeSymbols)
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // Options
                sectionHeader(icon: "slider.horizontal.3", title: "Options", color: .orange)
                
                VStack(spacing: 0) {
                    ToggleRow(title: "Exclude Ambiguous", subtitle: "Removes I, l, 1, O, 0, etc.", isOn: $vm.excludeAmbiguous)
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Generated Strings")
                    .font(.headline)
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
            .padding()
            
            Divider()
            
            if let error = vm.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
                .padding()
                .background(Color.red.opacity(0.1))
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
                    .padding(.top, 40)
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
                            .padding(.vertical, 6)
                            .padding(.horizontal, 8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding()
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

struct ToggleRow: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal)
        .padding(.vertical, 8)
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
        
        guard !characterSets.isEmpty else {
            errorMessage = "Please select at least one character set."
            return
        }
        
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
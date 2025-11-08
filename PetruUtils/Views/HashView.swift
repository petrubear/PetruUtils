import SwiftUI
import Combine

struct HashView: View {
    @StateObject private var vm = HashViewModel()
    
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
        HStack(spacing: 16) {
            // Algorithm picker
            Picker("Algorithm", selection: $vm.algorithm) {
                ForEach(HashService.HashAlgorithm.allCases) { algo in
                    Text(algo.displayName).tag(algo)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 140)
            
            Divider().frame(height: 20)
            
            // HMAC toggle
            Toggle("HMAC Mode", isOn: $vm.isHMACMode)
                .toggleStyle(.switch)
            
            Spacer()
            
            Button("Generate") {
                vm.generate()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Clear") {
                vm.clear()
            }
            .keyboardShortcut("k", modifiers: [.command])
            
            Button("Copy Output") {
                vm.copyOutput()
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(vm.output.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Input")
                .font(.headline)
            
            FocusableTextEditor(text: $vm.input)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .background(.background)
            
            if vm.isHMACMode {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HMAC Secret Key")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    SecureField("Enter secret key", text: $vm.hmacKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            HStack {
                if !vm.input.isEmpty {
                    Text("\(vm.input.count) characters")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                if let error = vm.errorMessage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .foregroundStyle(.orange)
                            .font(.callout)
                    }
                }
            }
        }
        .padding()
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hash Output")
                    .font(.headline)
                
                Spacer()
                
                if !vm.output.isEmpty {
                    Text("\(vm.selectedAlgorithmInfo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            CodeBlock(text: vm.output)
            
            // All algorithms output
            if vm.showAllAlgorithms && !vm.input.isEmpty && vm.errorMessage == nil {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(HashService.HashAlgorithm.allCases) { algo in
                            if algo != vm.algorithm {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(algo.displayName)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            vm.copyHash(vm.allHashes[algo] ?? "")
                                        }) {
                                            Image(systemName: "doc.on.doc")
                                                .font(.caption)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Text(vm.allHashes[algo] ?? "")
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                        .padding(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
            
            HStack {
                Toggle("Show all algorithms", isOn: $vm.showAllAlgorithms)
                    .font(.caption)
                
                Spacer()
                
                if !vm.output.isEmpty {
                    Button(action: {
                        vm.verifyMode.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: vm.verifyMode ? "checkmark.circle.fill" : "checkmark.circle")
                            Text("Verify")
                        }
                        .font(.caption)
                    }
                }
            }
            
            if vm.verifyMode {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    Text("Verify Hash")
                        .font(.subheadline.weight(.semibold))
                    
                    TextField("Paste hash to verify", text: $vm.verifyHash)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    
                    if let verifyResult = vm.verificationResult {
                        HStack(spacing: 4) {
                            Image(systemName: verifyResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(verifyResult ? .green : .red)
                            Text(verifyResult ? "Hash matches!" : "Hash does not match")
                                .foregroundStyle(verifyResult ? .green : .red)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

// MARK: - ViewModel

@MainActor
final class HashViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var algorithm: HashService.HashAlgorithm = .sha256
    @Published var isHMACMode: Bool = false
    @Published var hmacKey: String = ""
    @Published var errorMessage: String?
    @Published var showAllAlgorithms: Bool = false
    @Published var allHashes: [HashService.HashAlgorithm: String] = [:]
    @Published var verifyMode: Bool = false
    @Published var verifyHash: String = "" {
        didSet {
            if verifyMode && !verifyHash.isEmpty && !output.isEmpty {
                verificationResult = service.verifyHash(
                    text: input,
                    expectedHash: verifyHash,
                    algorithm: algorithm
                )
            } else {
                verificationResult = nil
            }
        }
    }
    @Published var verificationResult: Bool?
    
    private let service = HashService()
    
    var selectedAlgorithmInfo: String {
        "\(algorithm.displayName) (\(algorithm.outputLength) hex chars)"
    }
    
    func generate() {
        errorMessage = nil
        output = ""
        allHashes = [:]
        verificationResult = nil
        
        guard !input.isEmpty else {
            errorMessage = "Input cannot be empty"
            return
        }
        
        do {
            if isHMACMode {
                output = try service.hmacText(input, key: hmacKey, algorithm: algorithm)
            } else {
                output = try service.hashText(input, algorithm: algorithm)
            }
            
            // Generate all hashes if enabled
            if showAllAlgorithms && !isHMACMode {
                generateAllHashes()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func generateAllHashes() {
        for algo in HashService.HashAlgorithm.allCases {
            if let hash = try? service.hashText(input, algorithm: algo) {
                allHashes[algo] = hash
            }
        }
    }
    
    func clear() {
        input = ""
        output = ""
        hmacKey = ""
        errorMessage = nil
        allHashes = [:]
        verifyMode = false
        verifyHash = ""
        verificationResult = nil
    }
    
    func copyOutput() {
        guard !output.isEmpty else { return }
        copyToClipboard(output)
    }
    
    func copyHash(_ hash: String) {
        copyToClipboard(hash)
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Preview

#Preview {
    HashView()
}

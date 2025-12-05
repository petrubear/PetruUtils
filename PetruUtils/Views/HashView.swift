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
            Text("Hash Generator")
                .font(.headline)
            
            Spacer()
            
            Button("Generate") {
                vm.generate()
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
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "text.quote", title: "Input Text", color: .blue)
                
                FocusableTextEditor(text: $vm.input)
                    .frame(minHeight: 150)
                    .padding(4)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                    .font(.system(.body, design: .monospaced))
                
                HStack {
                    if !vm.input.isEmpty {
                        Text("\(vm.input.count) characters")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    Spacer()
                }
                
                Divider()
                
                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Algorithm
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Algorithm")
                            .font(.subheadline.weight(.medium))
                        
                        Picker("", selection: $vm.algorithm) {
                            ForEach(HashService.HashAlgorithm.allCases) { algo in
                                Text(algo.displayName).tag(algo)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    // HMAC
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("HMAC Mode", isOn: $vm.isHMACMode)
                            .toggleStyle(.switch)
                        
                        if vm.isHMACMode {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("HMAC Secret Key")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                SecureField("Enter secret key", text: $vm.hmacKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)

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
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Primary Output
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        sectionHeader(icon: "number.square", title: "Output", color: .green)
                        Spacer()
                        if !vm.output.isEmpty {
                            Text(vm.selectedAlgorithmInfo)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Button(action: { vm.copyOutput() }) {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .keyboardShortcut("c", modifiers: [.command, .shift])
                        }
                    }
                    
                    if !vm.output.isEmpty {
                        Text(vm.output)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                    } else {
                        Text("Enter text to generate hash")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                // All Algorithms
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        sectionHeader(icon: "list.bullet", title: "All Algorithms", color: .orange)
                        Spacer()
                        Toggle("", isOn: $vm.showAllAlgorithms)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    
                    if vm.showAllAlgorithms && !vm.output.isEmpty {
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
                                        
                                        Text(vm.allHashes[algo] ?? "...")
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
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                
                // Verification
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        sectionHeader(icon: "checkmark.shield", title: "Verify Hash", color: .teal)
                        Spacer()
                        Toggle("", isOn: $vm.verifyMode)
                            .toggleStyle(.switch)
                            .labelsHidden()
                    }
                    
                    if vm.verifyMode {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Paste hash to verify against input", text: $vm.verifyHash)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                            
                            if let verifyResult = vm.verificationResult {
                                HStack(spacing: 8) {
                                    Image(systemName: verifyResult ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(verifyResult ? .green : .red)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verifyResult ? "Hash Match" : "Hash Mismatch")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(verifyResult ? .green : .red)
                                        
                                        if !verifyResult {
                                            Text("The provided hash does not match the current input.")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(verifyResult ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
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

// MARK: - ViewModel (Unchanged)

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
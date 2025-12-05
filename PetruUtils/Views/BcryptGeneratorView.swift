import SwiftUI
import Combine

struct BcryptGeneratorView: View {
    @StateObject private var vm = BcryptGeneratorViewModel()

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
            Text("Bcrypt Generator")
                .font(.headline)

            Spacer()

            Picker("Mode", selection: $vm.mode) {
                Text("Generate").tag(BcryptGeneratorViewModel.Mode.generate)
                Text("Verify").tag(BcryptGeneratorViewModel.Mode.verify)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)

            if vm.mode == .generate {
                Button("Generate") { vm.generateHash() }
                    .keyboardShortcut(.return, modifiers: [.command])
            } else {
                Button("Verify") { vm.verifyPassword() }
                    .keyboardShortcut(.return, modifiers: [.command])
            }

            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])

            Button("Copy") { vm.copyResult() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(vm.generatedHash.isEmpty && vm.verificationResult == nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Input")
                    .font(.headline)

                // Password input
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.blue)
                        Text("Password")
                            .font(.subheadline.weight(.semibold))
                    }

                    SecureField("Enter password", text: $vm.password)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    if !vm.password.isEmpty {
                        Text("\(vm.password.count) characters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if vm.mode == .generate {
                    generateModeInputs
                } else {
                    verifyModeInputs
                }

                // Error display
                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .textSelection(.enabled)
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

    @ViewBuilder
    private var generateModeInputs: some View {
        Divider()

        // Cost factor
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundStyle(.orange)
                Text("Cost Factor")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(vm.cost)")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Slider(value: Binding(
                get: { Double(vm.cost) },
                set: { vm.cost = Int($0) }
            ), in: Double(BcryptService.minCost)...Double(min(BcryptService.maxCost, 20)), step: 1)

            HStack {
                Text("Estimated time: \(vm.estimatedTime)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Higher = more secure but slower")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }

        // Cost recommendations
        VStack(alignment: .leading, spacing: 4) {
            Text("Recommended values:")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                costRecommendation(cost: 10, label: "Fast")
                costRecommendation(cost: 12, label: "Balanced")
                costRecommendation(cost: 14, label: "Secure")
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func costRecommendation(cost: Int, label: String) -> some View {
        Button(action: { vm.cost = cost }) {
            VStack(spacing: 2) {
                Text("\(cost)")
                    .font(.system(.caption, design: .monospaced).weight(.semibold))
                Text(label)
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(vm.cost == cost ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var verifyModeInputs: some View {
        Divider()

        // Hash input
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "number.square")
                    .foregroundStyle(.purple)
                Text("Hash to Verify")
                    .font(.subheadline.weight(.semibold))
            }

            TextField("Paste hash here", text: $vm.hashToVerify)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))

            Text("Format: $pbkdf2-sha256$cost$salt$hash")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Result")
                    .font(.headline)

                if vm.mode == .generate {
                    generateOutput
                } else {
                    verifyOutput
                }

                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private var generateOutput: some View {
        if vm.generatedHash.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "lock.rectangle")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Enter a password and click Generate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Press ⌘Return to generate")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Generated hash
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader(icon: "number.square", title: "Generated Hash", color: .blue)

                Text(vm.generatedHash)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)

                Button(action: { vm.copyResult() }) {
                    Label("Copy Hash", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Hash details
            if let hashResult = vm.hashResult {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader(icon: "info.circle", title: "Hash Details", color: .purple)

                    resultRow(label: "Algorithm", value: hashResult.algorithm)
                    resultRow(label: "Cost Factor", value: "\(hashResult.cost)")
                    resultRow(label: "Salt", value: hashResult.salt)
                    resultRow(label: "Derived Key", value: hashResult.derivedKey)
                }
            }

            // Security note
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(.green)
                    Text("Security Note")
                        .font(.caption.weight(.semibold))
                }

                Text("This hash uses PBKDF2-SHA256, a secure key derivation function. The cost factor determines the number of iterations (2^cost), making brute-force attacks more difficult.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private var verifyOutput: some View {
        if let result = vm.verificationResult {
            VStack(spacing: 16) {
                // Verification result
                VStack(spacing: 12) {
                    Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(result ? .green : .red)

                    Text(result ? "Password Matches!" : "Password Does Not Match")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(result ? .green : .red)

                    Text(result
                        ? "The provided password matches the hash."
                        : "The password does not match the stored hash.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()

                // Parsed hash info
                if let parsed = vm.parsedHash {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader(icon: "info.circle", title: "Hash Information", color: .blue)

                        resultRow(label: "Algorithm", value: parsed.algorithm)
                        resultRow(label: "Cost Factor", value: "\(parsed.cost)")
                    }
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Enter password and hash to verify")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Press ⌘Return to verify")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }

    @ViewBuilder
    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .monospaced))
                .textSelection(.enabled)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - ViewModel

@MainActor
final class BcryptGeneratorViewModel: ObservableObject {
    enum Mode {
        case generate
        case verify
    }

    @Published var mode: Mode = .generate
    @Published var password: String = ""
    @Published var cost: Int = BcryptService.defaultCost
    @Published var hashToVerify: String = ""

    @Published var generatedHash: String = ""
    @Published var hashResult: BcryptService.HashResult?
    @Published var verificationResult: Bool?
    @Published var parsedHash: (algorithm: String, cost: Int, salt: String, derivedKey: String)?
    @Published var errorMessage: String?

    private let service = BcryptService()

    var estimatedTime: String {
        service.estimatedTime(for: cost)
    }

    func generateHash() {
        guard !password.isEmpty else {
            errorMessage = "Please enter a password."
            return
        }

        errorMessage = nil

        do {
            let result = try service.generateHash(password: password, cost: cost)
            generatedHash = result.fullHash
            hashResult = result
        } catch {
            errorMessage = error.localizedDescription
            generatedHash = ""
            hashResult = nil
        }
    }

    func verifyPassword() {
        guard !password.isEmpty else {
            errorMessage = "Please enter a password."
            return
        }

        guard !hashToVerify.isEmpty else {
            errorMessage = "Please enter a hash to verify."
            return
        }

        errorMessage = nil

        do {
            verificationResult = try service.verifyPassword(password: password, hash: hashToVerify)
            parsedHash = try? service.parseHash(hashToVerify)
        } catch {
            errorMessage = error.localizedDescription
            verificationResult = nil
            parsedHash = nil
        }
    }

    func clear() {
        password = ""
        hashToVerify = ""
        generatedHash = ""
        hashResult = nil
        verificationResult = nil
        parsedHash = nil
        errorMessage = nil
    }

    func copyResult() {
        let textToCopy: String

        if mode == .generate {
            textToCopy = generatedHash
        } else if let result = verificationResult {
            textToCopy = result ? "Password matches" : "Password does not match"
        } else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
    }
}

// MARK: - Preview

#Preview {
    BcryptGeneratorView()
}

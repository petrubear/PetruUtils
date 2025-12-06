import SwiftUI
import CryptoKit
import Combine

struct JWTView: View {
    @StateObject private var vm = JWTViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            HSplitView {
                leftPane
                rightPane
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Text("JWT Debugger")
                .font(.headline)

            Spacer()

            Button("Decode") { vm.decode() }
                .keyboardShortcut("d", modifiers: [.command])

            Button("Verify") { vm.verify() }
                .keyboardShortcut("v", modifiers: [.command])

            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var leftPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "lock.doc", title: "Encoded Token", color: .blue)

                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.inputToken)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                        .background(.background)

                    HStack {
                        Text("Segments: \(vm.segmentCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let detected = vm.detectedAlgorithm {
                            Text("Detected: \(detected)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        Spacer()
                    }
                }

                Divider()

                sectionHeader(icon: "gearshape", title: "Verification", color: .purple)

                VStack(alignment: .leading, spacing: 16) {
                    // Algorithm
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Algorithm")
                            .font(.subheadline.weight(.medium))

                        Picker("", selection: $vm.algorithm) {
                            ForEach(JWTService.Algorithm.allCases, id: \.self) { alg in
                                Text(alg.rawValue).tag(alg)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }

                    // Secret for HMAC algorithms
                    if vm.algorithm.isSymmetric {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shared Secret (HMAC)")
                                .font(.subheadline.weight(.medium))
                            SecureField("Enter secret to verify signature", text: $vm.hsSecret)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                    }

                    // Public key for RSA/ECDSA algorithms
                    if vm.algorithm.isRSA || vm.algorithm.isECDSA {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Public Key (PEM)")
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text(vm.algorithm.isRSA ? "RSA" : "EC")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            TextEditor(text: $vm.publicKey)
                                .font(.system(size: 11, design: .monospaced))
                                .frame(minHeight: 120)
                                .padding(4)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

                            Text("Paste your public key in PEM format (-----BEGIN PUBLIC KEY-----)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)

                if let err = vm.lastError {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                // Help text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Supported Algorithms")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HMAC: HS256, HS384, HS512")
                        Text("RSA: RS256, RS384, RS512")
                        Text("RSA-PSS: PS256, PS384, PS512")
                        Text("ECDSA: ES256, ES384, ES512")
                    }
                    .font(.system(size: 11, design: .monospaced))
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

    private var rightPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "doc.plaintext", title: "Decoded", color: .green)

                statusView

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Header")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    CodeBlock(text: vm.headerPretty, language: .json)
                        .frame(minHeight: 100, maxHeight: .infinity)
                }

                // Payload
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payload")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    CodeBlock(text: vm.payloadPretty, language: .json)
                        .frame(minHeight: 100, maxHeight: .infinity)
                }

                // Claims Validation
                if !vm.claimValidations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Claims Validation")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 4) {
                            ForEach(vm.claimValidations, id: \.claim) { validation in
                                ClaimValidationRow(validation: validation)
                            }
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                }

                // Signature
                VStack(alignment: .leading, spacing: 8) {
                    Text("Signature")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Text(vm.signatureRaw)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
    }

    @ViewBuilder private var statusView: some View {
        HStack(spacing: 12) {
            Image(systemName: vm.signatureStatus.icon)
                .foregroundStyle(vm.signatureStatus.color)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(vm.signatureStatus.title)
                    .font(.headline)
                    .foregroundStyle(vm.signatureStatus.color)

                Text(vm.signatureStatus.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(vm.signatureStatus.color.opacity(0.1))
        .cornerRadius(8)
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

// MARK: - Claim Validation Row

struct ClaimValidationRow: View {
    let validation: JWTService.ClaimValidation

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: validation.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(validation.isValid ? .green : .red)
                .font(.caption)

            Text(validation.claim)
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, alignment: .leading)

            Text(validation.value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(validation.message)
                .font(.caption2)
                .foregroundStyle(validation.isValid ? .green : .red)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - View Model

@MainActor
final class JWTViewModel: ObservableObject {
    @Published var inputToken: String = ""
    @Published var algorithm: JWTService.Algorithm = .hs256
    @Published var hsSecret: String = ""
    @Published var publicKey: String = ""

    @Published var headerPretty: String = ""
    @Published var payloadPretty: String = ""
    @Published var signatureRaw: String = ""
    @Published var signatureStatus: SignatureStatus = .unknown()
    @Published var claimValidations: [JWTService.ClaimValidation] = []
    @Published var lastError: String?
    @Published var detectedAlgorithm: String?

    private let jwtService = JWTService()
    private var decodedPayload: [String: Any]?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Auto-detect algorithm when token changes
        $inputToken
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] token in
                self?.autoDetectAlgorithm(from: token)
            }
            .store(in: &cancellables)
    }

    var segmentCount: Int { inputToken.split(separator: ".").count }

    private func autoDetectAlgorithm(from token: String) {
        if let detected = jwtService.detectAlgorithm(from: token.trimmingCharacters(in: .whitespacesAndNewlines)) {
            detectedAlgorithm = detected.rawValue
            algorithm = detected
        } else {
            detectedAlgorithm = nil
        }
    }

    func clear() {
        inputToken.removeAll()
        headerPretty.removeAll()
        payloadPretty.removeAll()
        signatureRaw.removeAll()
        signatureStatus = .unknown()
        claimValidations = []
        lastError = nil
        decodedPayload = nil
        detectedAlgorithm = nil
    }

    func decode() {
        lastError = nil
        signatureStatus = .unknown()
        headerPretty = ""
        payloadPretty = ""
        signatureRaw = ""
        decodedPayload = nil
        claimValidations = []

        do {
            let decoded = try jwtService.decode(inputToken.trimmingCharacters(in: .whitespacesAndNewlines))
            headerPretty = decoded.headerJSON
            payloadPretty = decoded.payloadJSON
            signatureRaw = decoded.signature
            decodedPayload = decoded.payload

            // Validate claims
            claimValidations = jwtService.validateClaims(in: decoded.payload)
        } catch {
            lastError = "Decode error: \(error.localizedDescription)"
        }
    }

    func verify() {
        // First decode if not already done
        if decodedPayload == nil {
            decode()
        }

        guard lastError == nil else { return }

        do {
            let isValid = try jwtService.verify(
                token: inputToken.trimmingCharacters(in: .whitespacesAndNewlines),
                algorithm: algorithm,
                secret: algorithm.isSymmetric ? hsSecret : nil,
                publicKey: (algorithm.isRSA || algorithm.isECDSA) ? publicKey : nil
            )
            signatureStatus = isValid ? .valid : .invalid(message: "Signature mismatch.")
        } catch JWTService.JWTError.missingSecret {
            signatureStatus = .invalid(message: "Enter a shared secret to verify HMAC signature.")
        } catch JWTService.JWTError.missingPublicKey {
            signatureStatus = .invalid(message: "Enter a public key to verify \(algorithm.rawValue) signature.")
        } catch JWTService.JWTError.invalidPublicKey {
            signatureStatus = .invalid(message: "Invalid public key format. Use PEM format.")
        } catch JWTService.JWTError.invalidAlgorithm {
            signatureStatus = .invalid(message: "Token algorithm doesn't match selected algorithm.")
        } catch {
            signatureStatus = .invalid(message: error.localizedDescription)
        }
    }
}

// MARK: - Signature Status

enum SignatureStatus {
    case unknown(message: String = "Signature not verified")
    case valid
    case invalid(message: String)

    var title: String {
        switch self {
        case .unknown: return "Unverified"
        case .valid: return "Signature Valid"
        case .invalid: return "Invalid Signature"
        }
    }

    var message: String {
        switch self {
        case .unknown(let m): return m
        case .valid: return "The token signature is valid."
        case .invalid(let m): return m
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .valid: return .green
        case .invalid: return .red
        }
    }

    var icon: String {
        switch self {
        case .unknown: return "questionmark.circle.fill"
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        }
    }
}

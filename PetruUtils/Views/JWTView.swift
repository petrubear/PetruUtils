import SwiftUI
import CryptoKit
import Combine

struct JWTView: View {
    @StateObject private var vm = JWTViewModel()
    @State private var leftWidth: CGFloat = 420 // draggable split

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
                            ForEach(JWTAlgorithm.allCases) { alg in
                                Text(alg.rawValue).tag(alg)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.segmented)
                    }
                    
                    // Secret
                    if vm.algorithm == .hs256 {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shared Secret (HMAC)")
                                .font(.subheadline.weight(.medium))
                            SecureField("Enter secret to verify signature", text: $vm.hsSecret)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
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
                        Text("Example")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    Text("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
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
                    
                    SyntaxHighlightedCodeBlock(text: vm.headerPretty, language: .json)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                }
                
                // Payload
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payload")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    SyntaxHighlightedCodeBlock(text: vm.payloadPretty, language: .json)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
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


@MainActor
final class JWTViewModel: ObservableObject {
    @Published var inputToken: String = ""
    @Published var algorithm: JWTAlgorithm = .hs256
    @Published var hsSecret: String = ""

    @Published var headerPretty: String = ""
    @Published var payloadPretty: String = ""
    @Published var signatureRaw: String = ""
    @Published var signatureStatus: SignatureStatus = .unknown()
    @Published var lastError: String?
    
    private let jwtService = JWTService()
    private var decodedPayload: [String: Any]?

    var segmentCount: Int { inputToken.split(separator: ".").count }

    var quickClaimsSummary: String? {
        guard let payload = decodedPayload else { return nil }
        
        let claims = jwtService.extractStandardClaims(from: payload)
        guard !claims.isEmpty else { return nil }
        
        var parts: [String] = []
        if let iss = claims["iss"] { parts.append("iss: \(iss)") }
        if let sub = claims["sub"] { parts.append("sub: \(sub)") }
        if let aud = claims["aud"] { parts.append("aud: \(aud)") }
        if let exp = claims["exp"] { parts.append("exp: \(exp)") }
        return parts.isEmpty ? nil : parts.joined(separator: "  •  ")
    }

    func clear() {
        inputToken.removeAll()
        headerPretty.removeAll()
        payloadPretty.removeAll()
        signatureRaw.removeAll()
        signatureStatus = .unknown()
        lastError = nil
        decodedPayload = nil
    }

    func decode() {
        lastError = nil
        signatureStatus = .unknown()
        headerPretty = ""
        payloadPretty = ""
        signatureRaw = ""
        decodedPayload = nil

        do {
            let decoded = try jwtService.decode(inputToken.trimmingCharacters(in: .whitespacesAndNewlines))
            headerPretty = decoded.headerJSON
            payloadPretty = decoded.payloadJSON
            signatureRaw = decoded.signature
            decodedPayload = decoded.payload
        } catch {
            lastError = "Decode error: \(error.localizedDescription)"
        }
    }

    func verify() {
        guard algorithm == .hs256 else {
            signatureStatus = .unknown(message: "Only HS256 implemented.")
            return
        }
        
        do {
            let isValid = try jwtService.verifyHS256(
                token: inputToken.trimmingCharacters(in: .whitespacesAndNewlines),
                secret: hsSecret
            )
            signatureStatus = isValid ? .valid : .invalid(message: "Signature mismatch.")
        } catch JWTService.JWTError.missingSecret {
            signatureStatus = .invalid(message: "Enter a shared secret to verify HS256.")
        } catch JWTService.JWTError.invalidAlgorithm {
            signatureStatus = .invalid(message: "Token does not use HS256 algorithm.")
        } catch {
            signatureStatus = .invalid(message: error.localizedDescription)
        }
    }
}

enum JWTAlgorithm: String, CaseIterable, Identifiable {
    case hs256 = "HS256"
    
    var id: String { rawValue }
}

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
        case .valid: return "The token signature matches the secret."
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
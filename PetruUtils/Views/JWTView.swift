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
            GeometryReader { geo in
                HStack(spacing: 0) {
                    leftPane
                        .frame(width: max(320, min(leftWidth, geo.size.width - 320)))

                    // Draggable divider
                    Divider()
                        .frame(width: 1)
                        .background(.quaternary)
                        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                            leftWidth = max(320, min(value.location.x, geo.size.width - 320))
                        })

                    rightPane
                }
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Picker("Alg", selection: $vm.algorithm) {
                ForEach(JWTAlgorithm.allCases) { alg in
                    Text(alg.rawValue).tag(alg)
                }
            }
            .pickerStyle(.menu)

            if vm.algorithm == .hs256 {
                FocusableTextField(text: $vm.hsSecret, placeholder: "Enter shared secret")
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 260, idealHeight: 22)
            }

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
        VStack(alignment: .leading, spacing: 8) {
            Text("JWT").font(.headline)
            FocusableTextEditor(text: $vm.inputToken)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                .background(.background)
            HStack {
                Text("Segments: \(vm.segmentCount)").foregroundStyle(.secondary)
                Spacer()
                if let err = vm.lastError {
                    Text(err).foregroundStyle(.red).font(.callout).textSelection(.enabled)
                }
            }
        }
        .padding()
    }

    private var rightPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusView

                groupBox(title: "Header") {
                    SyntaxHighlightedCodeBlock(text: vm.headerPretty, language: .json)
                }
                groupBox(title: "Payload") {
                    SyntaxHighlightedCodeBlock(text: vm.payloadPretty, language: .json)
                }
                groupBox(title: "Signature (raw, base64url)") {
                    CodeBlock(text: vm.signatureRaw)
                }
            }
            .padding()
        }
        .frame(minWidth: 360)
    }

    @ViewBuilder private var statusView: some View {
        HStack(spacing: 12) {
            Circle().fill(vm.signatureStatus.color).frame(width: 10, height: 10)
            Text(vm.signatureStatus.message).font(.headline)
            Spacer()
            if let claims = vm.quickClaimsSummary {
                Text(claims).foregroundStyle(.secondary).font(.callout)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func groupBox(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
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
    case unknown(message: String = "Signature not checked yet.")
    case valid
    case invalid(message: String)

    var message: String {
        switch self {
        case .unknown(let m): return m
        case .valid: return "Signature valid ✔︎"
        case .invalid(let m): return "Signature invalid ✖︎ — \(m)"
        }
    }
    
    var color: Color {
        switch self {
        case .unknown: return .gray
        case .valid: return .green
        case .invalid: return .red
        }
    }
}


import SwiftUI
import Combine
import AppKit
import UniformTypeIdentifiers

struct CertificateInspectorView: View {
    @StateObject private var viewModel = CertificateInspectorViewModel()

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
            Text("Certificate Inspector (X.509)").font(.headline)
            Spacer()

            Button("Inspect") { viewModel.inspect() }
                .keyboardShortcut(.return, modifiers: [.command])
            Button("Clear") { viewModel.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Certificate (PEM or DER)").font(.headline)

            FocusableTextEditor(text: $viewModel.input)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))

            HStack {
                if !viewModel.input.isEmpty {
                    Text("\(viewModel.input.count) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            // Help text
            VStack(alignment: .leading, spacing: 4) {
                Text("Supported formats:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("• PEM (-----BEGIN CERTIFICATE-----)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("• DER (base64 encoded)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\nExample:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Text("""
                -----BEGIN CERTIFICATE-----
                MIIBkTCB+wIJAKHHCg...
                -----END CERTIFICATE-----
                """)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }

            Spacer()
        }
        .padding()
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Certificate Details").font(.headline)
                Spacer()
                if viewModel.certificateInfo != nil {
                    Button {
                        viewModel.exportJSON()
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.down")
                    }
                    .help("Export certificate details as JSON")

                    Button {
                        viewModel.copyToClipboard()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                    .help("Copy certificate details (⌘⇧C)")
                }
            }

            if let info = viewModel.certificateInfo {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Status section
                        certificateStatusSection(info)

                        Divider()

                        // Subject section
                        certificateSection(title: "Subject", content: info.formattedSubject)

                        // Issuer section
                        certificateSection(title: "Issuer", content: info.formattedIssuer)

                        Divider()

                        // Validity section
                        validitySection(info)

                        Divider()

                        // Public Key section
                        publicKeySection(info)

                        Divider()

                        // Extensions section
                        extensionsSection(info)

                        Divider()

                        // Fingerprints section
                        fingerprintsSection(info)

                        // Additional details
                        detailsSection(info)
                    }
                    .padding(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            } else {
                Text("Paste a certificate and click Inspect")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private func certificateStatusSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if info.isExpired {
                    Label("EXPIRED", systemImage: "xmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.red)
                } else {
                    Label("VALID", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                if info.isCA {
                    Label("CA", systemImage: "building.columns.fill")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                if info.isSelfSigned {
                    Label("Self-Signed", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            if let days = info.daysUntilExpiration {
                Text("Expires in \(days) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func certificateSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }

    private func validitySection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Validity Period")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Text("From:")
                    .foregroundStyle(.secondary)
                Text(info.validFrom, style: .date)
                    .font(.system(.body, design: .monospaced))
                Text(info.validFrom, style: .time)
                    .font(.system(.body, design: .monospaced))
            }

            HStack {
                Text("To:")
                    .foregroundStyle(.secondary)
                Text(info.validTo, style: .date)
                    .font(.system(.body, design: .monospaced))
                Text(info.validTo, style: .time)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private func publicKeySection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Public Key")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Text("Algorithm:")
                    .foregroundStyle(.secondary)
                Text(info.publicKeyAlgorithm)
                    .font(.system(.body, design: .monospaced))
            }

            if let keySize = info.publicKeySize {
                HStack {
                    Text("Key Size:")
                        .foregroundStyle(.secondary)
                    Text("\(keySize) bits")
                        .font(.system(.body, design: .monospaced))
                }
            }

            HStack {
                Text("Signature:")
                    .foregroundStyle(.secondary)
                Text(info.signatureAlgorithm)
                    .font(.system(.body, design: .monospaced))
            }
        }
    }

    private func extensionsSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extensions")
                .font(.subheadline)
                .fontWeight(.semibold)

            if !info.subjectAlternativeNames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subject Alternative Names:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(info.subjectAlternativeNames, id: \.self) { san in
                        Text("• \(san)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }

            if !info.extendedKeyUsage.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extended Key Usage:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(info.extendedKeyUsage, id: \.self) { usage in
                        Text("• \(usage)")
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }

            if info.subjectAlternativeNames.isEmpty && info.extendedKeyUsage.isEmpty {
                Text("No extensions found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func fingerprintsSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Fingerprints")
                .font(.subheadline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 4) {
                Text("SHA-1:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.sha1Fingerprint)
                    .font(.system(size: 10, design: .monospaced))
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("SHA-256:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.sha256Fingerprint)
                    .font(.system(size: 10, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }

    private func detailsSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Details")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Text("Version:")
                    .foregroundStyle(.secondary)
                Text("v\(info.version)")
                    .font(.system(.body, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Serial Number:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(info.serialNumber)
                    .font(.system(size: 11, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
    }
}

@MainActor
final class CertificateInspectorViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var certificateInfo: CertificateInspectorService.CertificateInfo?
    @Published var errorMessage: String?

    private let service = CertificateInspectorService()

    func inspect() {
        errorMessage = nil
        certificateInfo = nil

        guard !input.isEmpty else {
            errorMessage = "Please paste a certificate"
            return
        }

        do {
            certificateInfo = try service.parseCertificate(input)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        input = ""
        certificateInfo = nil
        errorMessage = nil
    }

    func copyToClipboard() {
        guard let info = certificateInfo else { return }

        let text = """
        Certificate Information
        ======================

        Status: \(info.isExpired ? "EXPIRED" : "VALID")\(info.isCA ? " (CA)" : "")\(info.isSelfSigned ? " (Self-Signed)" : "")

        Subject: \(info.formattedSubject)
        Issuer: \(info.formattedIssuer)

        Valid From: \(info.validFrom)
        Valid To: \(info.validTo)

        Public Key: \(info.publicKeyAlgorithm)\(info.publicKeySize.map { " (\($0) bits)" } ?? "")
        Signature Algorithm: \(info.signatureAlgorithm)

        Serial Number: \(info.serialNumber)

        SHA-1 Fingerprint: \(info.sha1Fingerprint)
        SHA-256 Fingerprint: \(info.sha256Fingerprint)
        """

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    func exportJSON() {
        guard let info = certificateInfo else { return }

        do {
            let json = try service.exportAsJSON(info)

            // Show save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "certificate-info.json"
            savePanel.message = "Export certificate information as JSON"

            savePanel.begin { response in
                guard response == .OK, let url = savePanel.url else { return }

                do {
                    try json.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    self.errorMessage = "Failed to export: \(error.localizedDescription)"
                }
            }
        } catch {
            errorMessage = "Failed to generate JSON: \(error.localizedDescription)"
        }
    }
}

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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "doc.text.magnifyingglass", title: "Input", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Certificate (PEM or DER)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    FocusableTextEditor(text: $viewModel.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))

                    HStack {
                        if !viewModel.input.isEmpty {
                            Text("\(viewModel.input.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("Supported Formats")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("• PEM (-----BEGIN CERTIFICATE-----)")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("• DER (base64 encoded)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 4)

                    Text("Example:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    Text("""
                    -----BEGIN CERTIFICATE-----
                    MIIBkTCB+wIJAKHHCg...
                    -----END CERTIFICATE-----
                    """)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            .padding()
        }
    }

    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Output Header
            HStack {
                Text("Certificate Details")
                    .font(.headline)
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
            .padding()
            
            Divider()

            if let info = viewModel.certificateInfo {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Status section
                        certificateStatusSection(info)

                        Divider()

                        // Subject section
                        certificateSection(title: "Subject", content: info.formattedSubject, icon: "person.text.rectangle", color: .blue)

                        // Issuer section
                        certificateSection(title: "Issuer", content: info.formattedIssuer, icon: "building.columns", color: .purple)

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
                    .padding()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Paste a certificate and click Inspect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
        }
    }

    private func certificateStatusSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if info.isExpired {
                    Label("EXPIRED", systemImage: "xmark.circle.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.red)
                } else {
                    Label("VALID", systemImage: "checkmark.circle.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.green)
                }

                if info.isCA {
                    Label("CA", systemImage: "building.columns.fill")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }

                if info.isSelfSigned {
                    Label("Self-Signed", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            if let days = info.daysUntilExpiration {
                Text(days > 0 ? "Expires in \(days) days" : "Expired \(abs(days)) days ago")
                    .font(.caption)
                    .foregroundStyle(days > 0 ? Color.secondary : Color.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(info.isExpired ? Color.red.opacity(0.05) : Color.green.opacity(0.05))
        .cornerRadius(8)
    }

    private func certificateSection(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: icon, title: title, color: color)
            
            Text(content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(6)
        }
    }

    private func validitySection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "calendar", title: "Validity Period", color: .orange)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Not Before")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.validFrom, style: .date)
                        .font(.system(.body, design: .monospaced))
                    Text(info.validFrom, style: .time)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Not After")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.validTo, style: .date)
                        .font(.system(.body, design: .monospaced))
                    Text(info.validTo, style: .time)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
        }
    }

    private func publicKeySection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "key", title: "Public Key Info", color: .green)

            VStack(alignment: .leading, spacing: 8) {
                resultRow(label: "Algorithm", value: info.publicKeyAlgorithm)
                if let keySize = info.publicKeySize {
                    resultRow(label: "Key Size", value: "\(keySize) bits")
                }
                resultRow(label: "Signature Algorithm", value: info.signatureAlgorithm)
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
        }
    }

    private func extensionsSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "puzzlepiece", title: "Extensions", color: .teal)

            if !info.subjectAlternativeNames.isEmpty || !info.extendedKeyUsage.isEmpty {
                if !info.subjectAlternativeNames.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Subject Alternative Names")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(info.subjectAlternativeNames, id: \.self) { san in
                            Text("• \(san)")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    .padding(.bottom, 4)
                }

                if !info.extendedKeyUsage.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Extended Key Usage")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(info.extendedKeyUsage, id: \.self) { usage in
                            Text("• \(usage)")
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            } else {
                Text("No extensions found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func fingerprintsSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "fingerprint", title: "Fingerprints", color: .indigo)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHA-1")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.sha1Fingerprint)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("SHA-256")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.sha256Fingerprint)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
        }
    }

    private func detailsSection(_ info: CertificateInspectorService.CertificateInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "info.circle", title: "Technical Details", color: .gray)

            VStack(alignment: .leading, spacing: 8) {
                resultRow(label: "Version", value: "v\(info.version)")
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Serial Number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.serialNumber)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(6)
        }
    }
    
    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.callout, design: .monospaced))
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
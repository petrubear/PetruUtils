import SwiftUI
import Combine

struct TOTPGeneratorView: View {
    @StateObject private var vm = TOTPGeneratorViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            HSplitView {
                inputPane
                outputPane
            }
        }
        .onAppear {
            vm.startTimer()
        }
        .onDisappear {
            vm.stopTimer()
        }
    }

    private var toolbar: some View {
        HStack {
            Text("TOTP Generator")
                .font(.headline)

            Spacer()

            Button("Generate") { vm.generateCode() }
                .keyboardShortcut(.return, modifiers: [.command])

            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])

            Button("Copy Code") { vm.copyCode() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(vm.currentCode.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Configuration")
                    .font(.headline)

                // Secret key input
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundStyle(.blue)
                        Text("Secret Key (Base32)")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("e.g., JBSWY3DPEHPK3PXP", text: $vm.secret)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .autocorrectionDisabled()

                    HStack {
                        if vm.isValidSecret {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Valid Base32 secret")
                                .foregroundStyle(.green)
                        } else if !vm.secret.isEmpty {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                            Text("Must be Base32 (A-Z, 2-7)")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                }

                Divider()

                // Options
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.purple)
                        Text("Options")
                            .font(.subheadline.weight(.semibold))
                    }

                    // Digits
                    HStack {
                        Text("Digits:")
                            .frame(width: 80, alignment: .leading)

                        Picker("", selection: $vm.digits) {
                            Text("6").tag(6)
                            Text("7").tag(7)
                            Text("8").tag(8)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }

                    // Period
                    HStack {
                        Text("Period:")
                            .frame(width: 80, alignment: .leading)

                        Picker("", selection: $vm.period) {
                            Text("30s").tag(30)
                            Text("60s").tag(60)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }

                    // Algorithm
                    HStack {
                        Text("Algorithm:")
                            .frame(width: 80, alignment: .leading)

                        Picker("", selection: $vm.algorithm) {
                            ForEach(TOTPService.Algorithm.allCases) { algo in
                                Text(algo.displayName).tag(algo)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }

                Divider()

                // Account info (optional)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .foregroundStyle(.orange)
                        Text("Account Info (Optional)")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("Issuer (e.g., Google)", text: $vm.issuer)
                        .textFieldStyle(.roundedBorder)

                    TextField("Account (e.g., user@example.com)", text: $vm.accountName)
                        .textFieldStyle(.roundedBorder)
                }

                // Error display
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
            VStack(spacing: 20) {
                if vm.currentCode.isEmpty {
                    emptyState
                } else {
                    codeDisplay
                    Divider()
                    upcomingCodes
                    Divider()
                    qrCodeSection
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Enter a Base32 secret key")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Press ⌘Return to generate")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var codeDisplay: some View {
        VStack(spacing: 16) {
            // Current code
            VStack(spacing: 8) {
                Text("Current Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(vm.formattedCode)
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundStyle(vm.remainingSeconds <= 5 ? .red : .primary)

                Button(action: { vm.copyCode() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }

            // Progress indicator
            VStack(spacing: 4) {
                ProgressView(value: vm.progress)
                    .progressViewStyle(.linear)
                    .tint(vm.remainingSeconds <= 5 ? .red : .blue)
                    .frame(width: 200)

                Text("\(vm.remainingSeconds)s remaining")
                    .font(.caption)
                    .foregroundStyle(vm.remainingSeconds <= 5 ? .red : .secondary)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }

    private var upcomingCodes: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.blue)
                Text("Upcoming Codes")
                    .font(.subheadline.weight(.semibold))
            }

            ForEach(Array(vm.nextCodes.enumerated()), id: \.offset) { index, codeInfo in
                if index > 0 { // Skip current code
                    HStack {
                        Text(formatCode(codeInfo.code))
                            .font(.system(.body, design: .monospaced))

                        Spacer()

                        Text(formatTimeRange(from: codeInfo.validFrom, to: codeInfo.validUntil))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var qrCodeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "qrcode")
                    .foregroundStyle(.purple)
                Text("QR Code")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button(action: { vm.copyURI() }) {
                    Label("Copy URI", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            if let qrImage = vm.qrCodeImage {
                Image(nsImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .background(Color.white)
                    .cornerRadius(8)
            }

            Text(vm.otpAuthURI)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }

    private func formatCode(_ code: String) -> String {
        // Add space in middle for readability
        let mid = code.count / 2
        let index = code.index(code.startIndex, offsetBy: mid)
        return code[..<index] + " " + code[index...]
    }

    private func formatTimeRange(from: Date, to: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return "\(formatter.string(from: from)) - \(formatter.string(from: to))"
    }
}

// MARK: - ViewModel

@MainActor
final class TOTPGeneratorViewModel: ObservableObject {
    @Published var secret: String = ""
    @Published var digits: Int = 6
    @Published var period: Int = 30
    @Published var algorithm: TOTPService.Algorithm = .sha1
    @Published var issuer: String = ""
    @Published var accountName: String = ""

    @Published var currentCode: String = ""
    @Published var remainingSeconds: Int = 30
    @Published var nextCodes: [(code: String, validFrom: Date, validUntil: Date)] = []
    @Published var otpAuthURI: String = ""
    @Published var qrCodeImage: NSImage?
    @Published var errorMessage: String?

    private let service = TOTPService()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var isValidSecret: Bool {
        !secret.isEmpty && service.isValidBase32Secret(secret)
    }

    var progress: Double {
        Double(remainingSeconds) / Double(period)
    }

    var formattedCode: String {
        // Add space in middle for readability
        guard !currentCode.isEmpty else { return "" }
        let mid = currentCode.count / 2
        let index = currentCode.index(currentCode.startIndex, offsetBy: mid)
        return currentCode[..<index] + " " + currentCode[index...]
    }

    init() {
        // Auto-generate when config changes
        Publishers.CombineLatest4($secret, $digits, $period, $algorithm)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.generateCodeIfValid()
            }
            .store(in: &cancellables)
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCode()
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func generateCode() {
        generateCodeIfValid()
    }

    private func generateCodeIfValid() {
        guard isValidSecret else {
            if !secret.isEmpty {
                errorMessage = "Invalid Base32 secret"
            }
            return
        }

        errorMessage = nil

        let config = TOTPService.TOTPConfig(
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm,
            issuer: issuer.isEmpty ? nil : issuer,
            accountName: accountName.isEmpty ? nil : accountName
        )

        do {
            let result = try service.generateTOTP(config: config)
            currentCode = result.code
            remainingSeconds = result.remainingSeconds

            // Get upcoming codes
            nextCodes = try service.getNextCodes(config: config, count: 4)

            // Generate QR code
            otpAuthURI = try service.generateOTPAuthURI(config: config)
            generateQRCode()
        } catch {
            errorMessage = error.localizedDescription
            currentCode = ""
            nextCodes = []
        }
    }

    private func updateCode() {
        guard isValidSecret else { return }

        let config = TOTPService.TOTPConfig(
            secret: secret,
            digits: digits,
            period: period,
            algorithm: algorithm,
            issuer: issuer.isEmpty ? nil : issuer,
            accountName: accountName.isEmpty ? nil : accountName
        )

        do {
            let result = try service.generateTOTP(config: config)

            // Check if code changed
            if result.code != currentCode {
                currentCode = result.code
                nextCodes = try service.getNextCodes(config: config, count: 4)
            }

            remainingSeconds = result.remainingSeconds
        } catch {
            // Silently fail on timer updates
        }
    }

    private func generateQRCode() {
        guard !otpAuthURI.isEmpty else {
            qrCodeImage = nil
            return
        }

        // Use CoreImage to generate QR code
        guard let data = otpAuthURI.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            qrCodeImage = nil
            return
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else {
            qrCodeImage = nil
            return
        }

        // Scale up for better resolution
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: transform)

        let rep = NSCIImageRep(ciImage: scaledImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        qrCodeImage = nsImage
    }

    func clear() {
        secret = ""
        issuer = ""
        accountName = ""
        currentCode = ""
        remainingSeconds = period
        nextCodes = []
        otpAuthURI = ""
        qrCodeImage = nil
        errorMessage = nil
    }

    func copyCode() {
        guard !currentCode.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(currentCode, forType: .string)
    }

    func copyURI() {
        guard !otpAuthURI.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(otpAuthURI, forType: .string)
    }
}

// MARK: - Preview

#Preview {
    TOTPGeneratorView()
}

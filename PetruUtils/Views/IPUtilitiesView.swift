import SwiftUI
import Combine

struct IPUtilitiesView: View {
    @StateObject private var vm = IPUtilitiesViewModel()

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
            Text("IP Utilities")
                .font(.headline)

            Spacer()

            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])

            Button("Copy All") { vm.copyAll() }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(!vm.hasResult)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Input")
                    .font(.headline)

                // CIDR Input
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundStyle(.blue)
                        Text("CIDR Notation")
                            .font(.subheadline.weight(.semibold))
                    }

                    TextField("e.g., 192.168.1.0/24", text: $vm.cidrInput, onCommit: { vm.calculateFromCIDR() })
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    Text("Enter IP address with prefix length (e.g., 10.0.0.0/8)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // IP + Subnet Mask Input
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "rectangle.split.2x1")
                            .foregroundStyle(.purple)
                        Text("IP + Subnet Mask")
                            .font(.subheadline.weight(.semibold))
                    }

                    HStack(spacing: 8) {
                        TextField("IP Address", text: $vm.ipInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))

                        TextField("Subnet Mask", text: $vm.maskInput, onCommit: { vm.calculateFromIPAndMask() })
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    Text("Enter IP and subnet mask separately")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

                Divider()

                // Common Subnet Reference
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundStyle(.orange)
                        Text("Common Subnets")
                            .font(.subheadline.weight(.semibold))
                    }

                    VStack(spacing: 4) {
                        ForEach(IPUtilitiesService.commonSubnetMasks, id: \.prefix) { item in
                            HStack {
                                Text(item.name)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(width: 120, alignment: .leading)
                                Text(item.mask)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(item.hosts) hosts")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(6)
                }

                Spacer()
            }
            .padding()
        }
    }

    private var outputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Results")
                    .font(.headline)

                if let info = vm.subnetInfo {
                    // Network Information
                    sectionHeader(icon: "network", title: "Network Information", color: .blue)
                    resultRow(label: "Network Address", value: info.network.stringValue)
                    resultRow(label: "Broadcast Address", value: info.broadcast.stringValue)
                    resultRow(label: "Subnet Mask", value: info.subnetMask.stringValue)
                    resultRow(label: "Wildcard Mask", value: info.wildcardMask.stringValue)
                    resultRow(label: "CIDR Notation", value: "/\(info.prefixLength)")

                    Divider()

                    // Host Range
                    sectionHeader(icon: "person.2", title: "Host Range", color: .green)
                    resultRow(label: "First Usable Host", value: info.firstHost.stringValue)
                    resultRow(label: "Last Usable Host", value: info.lastHost.stringValue)
                    resultRow(label: "Total Addresses", value: formatNumber(info.totalHosts))
                    resultRow(label: "Usable Hosts", value: formatNumber(info.usableHosts))

                    Divider()

                    // Classification
                    sectionHeader(icon: "tag", title: "Classification", color: .purple)
                    resultRow(label: "IP Class", value: info.ipClass)
                    resultRow(label: "Address Type", value: info.isPrivate ? "Private" : "Public")

                    Divider()

                    // Binary & Hex Representations
                    sectionHeader(icon: "number.square", title: "Representations", color: .orange)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Network (Binary)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(info.network.binaryString)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subnet Mask (Binary)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(info.subnetMask.binaryString)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Network (Hex)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(info.network.hexString)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }

                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "network")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Enter an IP address or CIDR notation")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Press Return to calculate")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
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
        .padding(.top, 4)
    }

    @ViewBuilder
    private func resultRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()

            HStack(spacing: 4) {
                Text(value)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)

                Button(action: { vm.copyValue(value) }) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .help("Copy value")
            }
        }
        .padding(.vertical, 2)
    }

    private func formatNumber(_ value: UInt32) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

// MARK: - ViewModel

@MainActor
final class IPUtilitiesViewModel: ObservableObject {
    @Published var cidrInput: String = ""
    @Published var ipInput: String = ""
    @Published var maskInput: String = ""

    @Published var subnetInfo: IPUtilitiesService.SubnetInfo?
    @Published var errorMessage: String?

    private let service = IPUtilitiesService()

    var hasResult: Bool {
        subnetInfo != nil
    }

    func calculateFromCIDR() {
        guard !cidrInput.isEmpty else {
            clear()
            return
        }

        errorMessage = nil

        do {
            subnetInfo = try service.calculateSubnetFromCIDR(cidrInput)
            // Update IP and mask fields
            if let info = subnetInfo {
                ipInput = info.network.stringValue
                maskInput = info.subnetMask.stringValue
            }
        } catch {
            errorMessage = error.localizedDescription
            subnetInfo = nil
        }
    }

    func calculateFromIPAndMask() {
        guard !ipInput.isEmpty, !maskInput.isEmpty else {
            if ipInput.isEmpty && maskInput.isEmpty {
                clear()
            }
            return
        }

        errorMessage = nil

        do {
            let ip = try service.parseIPv4(ipInput)
            let mask = try service.parseIPv4(maskInput)
            subnetInfo = try service.calculateSubnetFromMask(ip: ip, mask: mask)

            // Update CIDR field
            if let info = subnetInfo {
                cidrInput = "\(ip.stringValue)/\(info.prefixLength)"
            }
        } catch {
            errorMessage = error.localizedDescription
            subnetInfo = nil
        }
    }

    func clear() {
        cidrInput = ""
        ipInput = ""
        maskInput = ""
        subnetInfo = nil
        errorMessage = nil
    }

    func copyValue(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    func copyAll() {
        guard let info = subnetInfo else { return }

        let output = """
        IP Utilities - Subnet Calculation Results
        ==========================================

        Network Information:
          Network Address:    \(info.network.stringValue)
          Broadcast Address:  \(info.broadcast.stringValue)
          Subnet Mask:        \(info.subnetMask.stringValue)
          Wildcard Mask:      \(info.wildcardMask.stringValue)
          CIDR Notation:      /\(info.prefixLength)

        Host Range:
          First Usable Host:  \(info.firstHost.stringValue)
          Last Usable Host:   \(info.lastHost.stringValue)
          Total Addresses:    \(info.totalHosts)
          Usable Hosts:       \(info.usableHosts)

        Classification:
          IP Class:           \(info.ipClass)
          Address Type:       \(info.isPrivate ? "Private" : "Public")

        Binary Representations:
          Network:            \(info.network.binaryString)
          Subnet Mask:        \(info.subnetMask.binaryString)

        Hex Representations:
          Network:            \(info.network.hexString)
        """

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(output, forType: .string)
    }
}

// MARK: - Preview

#Preview {
    IPUtilitiesView()
}

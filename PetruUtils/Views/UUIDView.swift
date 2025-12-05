import SwiftUI
import Combine

struct UUIDView: View {
    @StateObject private var vm = UUIDViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            
            if vm.showV5Options {
                v5OptionsPanel
                Divider()
            }
            
            ScrollView {
                outputList
            }
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 16) {
            Picker("Version", selection: $vm.version) {
                ForEach(UUIDService.UUIDVersion.allCases) { version in
                    Text(version.rawValue).tag(version)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            .help(vm.version.description)
            
            Divider().frame(height: 20)
            
            Stepper("Count: \(vm.count)", value: $vm.count, in: 1...100)
                .frame(width: 150)
            
            Spacer()
            
            if vm.version == .v5 {
                Button(vm.showV5Options ? "Hide Options" : "Show Options") {
                    vm.showV5Options.toggle()
                }
            }
            
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
    
    private var v5OptionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("UUID v5 Options")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Namespace")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Menu {
                        Button("DNS") { vm.namespace = UUIDService.namespaceDNS }
                        Button("URL") { vm.namespace = UUIDService.namespaceURL }
                        Button("OID") { vm.namespace = UUIDService.namespaceOID }
                        Button("X.500") { vm.namespace = UUIDService.namespaceX500 }
                        Divider()
                        Button("Custom...") { vm.useCustomNamespace = true }
                    } label: {
                        Text(vm.namespaceDisplayName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: 200)
                    
                    if vm.useCustomNamespace {
                        TextField("Custom namespace UUID", text: $vm.namespace)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter name (e.g., example.com)", text: $vm.v5Name)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
    }
    
    private var outputList: some View {
        VStack(spacing: 0) {
            if !vm.generated.isEmpty {
                // Header with format options
                HStack {
                    Text("\(vm.generated.count) generated")
                        .font(.headline)
                    
                    Spacer()
                    
                    Menu("Format") {
                        Button("Lowercase") { vm.applyFormat(.lowercase) }
                        Button("Uppercase") { vm.applyFormat(.uppercase) }
                        Button("With hyphens") { vm.applyFormat(.withHyphens) }
                        Button("Without hyphens") { vm.applyFormat(.withoutHyphens) }
                    }
                    
                    Button("Copy All") {
                        vm.copyAll()
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
                .padding()
                
                Divider()
                
                // UUID List
                LazyVStack(spacing: 0) {
                    ForEach(Array(vm.generated.enumerated()), id: \.offset) { index, uuid in
                        UUIDRow(uuid: uuid, index: index + 1) {
                            vm.copy(uuid)
                        }
                        
                        if index < vm.generated.count - 1 {
                            Divider()
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "number.square")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("Generate UUIDs or ULIDs")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text(vm.version.description)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
                .frame(maxHeight: .infinity)
                .padding()
            }
            
            if let error = vm.errorMessage {
                Divider()
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.orange)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
            }

            // Help text at bottom
            Spacer()
            VStack(alignment: .leading, spacing: 4) {
                Text("Examples:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("UUID v4: 550e8400-e29b-41d4-a716-446655440000")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("ULID: 01ARZ3NDEKTSV4RRFFQ69G5FAV")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

// MARK: - UUID Row

struct UUIDRow: View {
    let uuid: String
    let index: Int
    let onCopy: () -> Void
    
    @State private var showCopied = false
    
    var body: some View {
        HStack {
            Text("\(index).")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            Text(uuid)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: {
                onCopy()
                withAnimation {
                    showCopied = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        showCopied = false
                    }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    if showCopied {
                        Text("Copied")
                            .font(.caption)
                    }
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(showCopied ? .green : .primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - ViewModel

@MainActor
final class UUIDViewModel: ObservableObject {
    @Published var version: UUIDService.UUIDVersion = .v4
    @Published var count: Int = 1
    @Published var generated: [String] = []
    @Published var errorMessage: String?
    @Published var showV5Options: Bool = false
    @Published var namespace: String = UUIDService.namespaceDNS
    @Published var v5Name: String = ""
    @Published var useCustomNamespace: Bool = false
    
    private let service = UUIDService()
    
    var namespaceDisplayName: String {
        switch namespace {
        case UUIDService.namespaceDNS: return "DNS"
        case UUIDService.namespaceURL: return "URL"
        case UUIDService.namespaceOID: return "OID"
        case UUIDService.namespaceX500: return "X.500"
        default: return "Custom"
        }
    }
    
    func generate() {
        errorMessage = nil
        
        do {
            if version == .v5 {
                if count == 1 {
                    let uuid = try service.generateUUID(
                        version: .v5,
                        namespace: namespace,
                        name: v5Name
                    )
                    generated = [uuid]
                } else {
                    generated = try service.generateBulk(
                        count: count,
                        version: .v5,
                        namespace: namespace,
                        namePrefix: v5Name
                    )
                }
            } else {
                generated = try service.generateBulk(count: count, version: version)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clear() {
        generated = []
        errorMessage = nil
    }
    
    func copy(_ uuid: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(uuid, forType: .string)
    }
    
    func copyAll() {
        let combined = generated.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(combined, forType: .string)
    }
    
    func applyFormat(_ format: UUIDService.UUIDFormat) {
        generated = service.formatBulk(generated, as: format)
    }
}

// MARK: - Preview


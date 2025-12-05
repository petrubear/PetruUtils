import SwiftUI
import Combine

struct UUIDView: View {
    @StateObject private var vm = UUIDViewModel()
    
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
            Text("UUID/ULID Generator")
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
                sectionHeader(icon: "gearshape", title: "Configuration", color: .blue)
                
                // Version & Count
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Version")
                            .font(.subheadline.weight(.medium))
                        Picker("", selection: $vm.version) {
                            ForEach(UUIDService.UUIDVersion.allCases) {
                                version in
                                Text(version.rawValue).tag(version)
                            }
                        }
                        .labelsHidden()
                        
                        Text(vm.version.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Count: \(vm.count)")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                        Stepper("", value: $vm.count, in: 1...100)
                            .labelsHidden()
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                
                // v5 Options
                if vm.version == .v5 {
                    sectionHeader(icon: "link", title: "v5 Options", color: .purple)
                    
                    VStack(alignment: .leading, spacing: 12) {
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
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(8)
                }
                
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
        VStack(spacing: 0) {
            HStack {
                Text("Generated UUIDs")
                    .font(.headline)
                
                Spacer()
                
                if !vm.generated.isEmpty {
                    Menu {
                        Button("Lowercase") { vm.applyFormat(.lowercase) }
                        Button("Uppercase") { vm.applyFormat(.uppercase) }
                        Button("With hyphens") { vm.applyFormat(.withHyphens) }
                        Button("Without hyphens") { vm.applyFormat(.withoutHyphens) }
                    } label: {
                        Label("Format", systemImage: "textformat")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    
                    Button(action: { vm.copyAll() }) {
                        Label("Copy All", systemImage: "doc.on.doc")
                    }
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if vm.generated.isEmpty {
                 VStack(spacing: 16) {
                    Image(systemName: "number.square")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("Click Generate to create UUIDs")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Supports v1, v4, v5 UUIDs and ULIDs")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxHeight: .infinity)
            } else {
                // UUID List
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(vm.generated.enumerated()), id: \.offset) {
                            index, uuid in
                            UUIDRow(uuid: uuid, index: index + 1) {
                                vm.copy(uuid)
                            }
                            
                            if index < vm.generated.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(Color.white)
                }
            }
            
            // Footer info
            Divider()
            HStack(spacing: 16) {
                Text("Examples:")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text("v4: 550e8400-e29b...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("ULID: 01ARZ3NDEK...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(8)
            .background(Color.secondary.opacity(0.05))
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

// MARK: - UUID Row (Unchanged logic, slight visual tweak)

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
                .frame(width: 30, alignment: .trailing)
            
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
            .foregroundStyle(showCopied ? .green : .blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(showCopied ? Color.green.opacity(0.05) : Color.clear)
    }
}

// MARK: - ViewModel (Unchanged)

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
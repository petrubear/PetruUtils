import SwiftUI
import Combine

struct URLView: View {
    @StateObject private var vm = URLViewModel()
    
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
        HStack(spacing: 12) {
            Text("URL Encoder")
                .font(.headline)
            
            Spacer()
            
            Button("Process") { vm.process() }
                .keyboardShortcut(.return, modifiers: [.command])
            
            Button("Auto-Detect") { vm.autoDetect(); vm.process() }
                .keyboardShortcut("d", modifiers: [.command])
            
            Button("Clear") { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader(icon: "link", title: "Input", color: .blue)
                
                VStack(alignment: .leading, spacing: 8) {
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200)
                        .padding(4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary))
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: vm.input) { _, _ in
                            vm.process()
                        }
                    
                    HStack {
                        if !vm.input.isEmpty {
                            Text("\(vm.inputCharCount) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                
                Divider()
                
                sectionHeader(icon: "gearshape", title: "Configuration", color: .purple)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Mode")
                            .font(.subheadline)
                        Picker("", selection: $vm.mode) {
                            ForEach(URLViewModel.ProcessMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Component Type")
                            .font(.subheadline)
                        Picker("", selection: $vm.componentType) {
                            Text("Full URL").tag(URLComponentType.fullURL)
                            Text("Query Param").tag(URLComponentType.queryParameter)
                            Text("Path Segment").tag(URLComponentType.pathSegment)
                            Text("Form Data").tag(URLComponentType.formData)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)

                if let error = vm.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()
                if !vm.output.isEmpty {
                    Text("\(vm.outputCharCount) characters")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.trailing, 8)
                    
                    Button(action: vm.copyOutput) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if !vm.output.isEmpty {
                ScrollView {
                    CodeBlock(text: vm.output)
                        .padding(8)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Result will appear here")
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
                .font(.subheadline.weight(.semibold))
        }
    }
}

// MARK: - URL View Model

@MainActor
class URLViewModel: ObservableObject {
    @Published var input: String = ""
    @Published var output: String = ""
    @Published var mode: ProcessMode = .encode
    @Published var componentType: URLComponentType = .queryParameter
    @Published var errorMessage: String?
    @Published var isValid: Bool = false
    
    private let service = URLService()
    
    enum ProcessMode: String, CaseIterable {
        case encode = "Encode"
        case decode = "Decode"
    }
    
    func process() {
        errorMessage = nil
        isValid = false
        
        guard !input.isEmpty else {
            output = ""
            return
        }
        
        do {
            switch mode {
            case .encode:
                output = try service.encode(input, type: componentType)
                isValid = true
            case .decode:
                output = try service.decode(input, type: componentType)
                isValid = true
            }
        } catch {
            errorMessage = error.localizedDescription
            output = ""
        }
    }
    
    func clear() {
        input = ""
        output = ""
        errorMessage = nil
        isValid = false
    }
    
    func copyOutput() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(output, forType: .string)
    }
    
    func autoDetect() {
        if service.isURLEncoded(input) || service.isFormEncoded(input) {
            mode = .decode
        } else {
            mode = .encode
        }
    }
    
    var inputCharCount: Int { input.count }
    var outputCharCount: Int { output.count }
}
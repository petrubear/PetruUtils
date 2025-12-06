import SwiftUI
import UniformTypeIdentifiers

struct GenericTextToolView<VM: TextToolViewModel, ToolbarContent: View, ConfigContent: View, HelpContent: View, InputFooter: View, OutputFooter: View>: View {
    @State private var isDropTargeted: Bool = false
    @ObservedObject var vm: VM
    let title: String
    let inputTitle: String
    let outputTitle: String
    let inputIcon: String
    let outputIcon: String
    
    @ViewBuilder let toolbarContent: () -> ToolbarContent
    @ViewBuilder let configContent: () -> ConfigContent
    @ViewBuilder let helpContent: () -> HelpContent
    @ViewBuilder let inputFooter: () -> InputFooter
    @ViewBuilder let outputFooter: () -> OutputFooter
    
    init(vm: VM,
         title: String,
         inputTitle: String = "Input",
         outputTitle: String = "Output",
         inputIcon: String = "text.alignleft",
         outputIcon: String = "text.alignleft",
         @ViewBuilder toolbarContent: @escaping () -> ToolbarContent,
         @ViewBuilder configContent: @escaping () -> ConfigContent,
         @ViewBuilder helpContent: @escaping () -> HelpContent,
         @ViewBuilder inputFooter: @escaping () -> InputFooter,
         @ViewBuilder outputFooter: @escaping () -> OutputFooter) {
        self.vm = vm
        self.title = title
        self.inputTitle = inputTitle
        self.outputTitle = outputTitle
        self.inputIcon = inputIcon
        self.outputIcon = outputIcon
        self.toolbarContent = toolbarContent
        self.configContent = configContent
        self.helpContent = helpContent
        self.inputFooter = inputFooter
        self.outputFooter = outputFooter
    }
    
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
            vm.loadLastInput()
        }
        .onDisappear {
            vm.saveLastInput()
        }
    }
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            toolbarContent()
            
            Button(String(localized: "common.action.process")) { vm.process() }
                .keyboardShortcut(.return, modifiers: [.command])

            Button(String(localized: "common.action.clear")) { vm.clear() }
                .keyboardShortcut("k", modifiers: [.command])
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var inputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sectionHeader(icon: inputIcon, title: inputTitle, color: .blue)
                    
                    FocusableTextEditor(text: $vm.input)
                        .frame(minHeight: 200, maxHeight: .infinity)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isDropTargeted ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: isDropTargeted ? 2 : 1)
                        )
                        .font(.system(.body, design: .monospaced))
                        .background(.background)
                        .onDrop(of: [.fileURL, .plainText, .utf8PlainText], isTargeted: $isDropTargeted) { providers in
                            handleDrop(providers: providers)
                        }
                    
                    inputFooter()
                    
                    // Configuration Section
                    configContent()

                    // Error Message
                    if let error = vm.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .accessibilityHidden(true)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.callout)
                                .textSelection(.enabled)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(String(localized: "accessibility.label.error"))
                        .accessibilityValue(error)
                    }

                    // Help/Extra Section
                    helpContent()
                }
                .padding()
            }
        }
    }
    
    private var outputPane: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(outputTitle)
                    .font(.headline)
                Spacer()
                outputFooter()
                if !vm.output.isEmpty {
                    Button(String(localized: "common.action.copy")) { vm.copyOutput() }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                }
            }
            .padding()
            
            Divider()
            
            if !vm.output.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                         sectionHeader(icon: outputIcon,
                                      title: String(localized: "common.label.result"),
                                      color: .green)
                        Spacer()
                        if vm.isValid {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .accessibilityHidden(true)
                                Text(String(localized: "common.label.valid"))
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(String(localized: "accessibility.label.validOutput"))
                        }
                    }
                    .padding([.top, .horizontal])
                    .padding(.bottom, 8)
                    
                    CodeBlock(text: vm.output, language: vm.outputLanguage)
                        .frame(maxHeight: .infinity)
                        .padding([.horizontal, .bottom])
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: outputIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(String(localized: "common.label.resultWillAppear"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "accessibility.label.emptyOutput"))
            }
        }
    }
    
    private func sectionHeader(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Drag & Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Try to load file URL first
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                    guard error == nil,
                          let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil) else {
                        return
                    }
                    loadFileContent(from: url)
                }
                return true
            }
        }

        // Try to load plain text
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
                    guard error == nil else { return }
                    if let text = item as? String {
                        DispatchQueue.main.async {
                            vm.input = text
                        }
                    } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            vm.input = text
                        }
                    }
                }
                return true
            }
        }

        return false
    }

    private func loadFileContent(from url: URL) {
        // Supported text file extensions
        let supportedExtensions = ["txt", "json", "xml", "html", "css", "js", "yaml", "yml", "md", "csv", "sql", "sh", "py", "swift", "java", "c", "cpp", "h", "hpp", "ts", "tsx", "jsx", "rb", "go", "rs", "pem", "crt", "cer", "key", "pub", "log", "conf", "cfg", "ini", "env", "toml"]

        let fileExtension = url.pathExtension.lowercased()

        // Check file size (limit to 10MB)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int, fileSize > 10 * 1024 * 1024 {
                return // File too large
            }
        } catch {
            return
        }

        // Read file content
        do {
            // For known text extensions or files without extension, try to read as text
            if supportedExtensions.contains(fileExtension) || fileExtension.isEmpty {
                let content = try String(contentsOf: url, encoding: .utf8)
                DispatchQueue.main.async {
                    vm.input = content
                }
            } else {
                // Try to detect if it's a text file
                let data = try Data(contentsOf: url)
                if let content = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        vm.input = content
                    }
                }
            }
        } catch {
            // Try other encodings
            if let content = try? String(contentsOf: url, encoding: .ascii) {
                DispatchQueue.main.async {
                    vm.input = content
                }
            }
        }
    }
}

// Default Input/Output Footer (Character Count)

extension GenericTextToolView where InputFooter == AnyView, OutputFooter == AnyView {

    init(vm: VM,

         title: String,

         inputTitle: String = "Input",

         outputTitle: String = "Output",

         inputIcon: String = "text.alignleft",

         outputIcon: String = "text.alignleft",

         @ViewBuilder toolbarContent: @escaping () -> ToolbarContent,

         @ViewBuilder configContent: @escaping () -> ConfigContent,

         @ViewBuilder helpContent: @escaping () -> HelpContent) {

        self.init(vm: vm,

                  title: title,

                  inputTitle: inputTitle,

                  outputTitle: outputTitle,

                  inputIcon: inputIcon,

                  outputIcon: outputIcon,

                  toolbarContent: toolbarContent,

                  configContent: configContent,

                  helpContent: helpContent,

                  inputFooter: {

            AnyView(HStack {

                if !vm.input.isEmpty {

                    Text("\(vm.inputCharCount) \(String(localized: "common.label.characters"))")

                        .foregroundStyle(.secondary)

                        .font(.caption)

                }

                Spacer()

            })

        },

                  outputFooter: {

            AnyView(Group {

                if !vm.output.isEmpty {

                    Text("\(vm.outputCharCount) \(String(localized: "common.label.characters"))")

                        .foregroundStyle(.secondary)

                        .font(.caption)

                        .padding(.trailing, 8)

                }

            })

        })

    }

}



// Extension for convenience init when views are empty

extension GenericTextToolView where ToolbarContent == EmptyView, ConfigContent == EmptyView, HelpContent == EmptyView, InputFooter == AnyView, OutputFooter == AnyView {

    init(vm: VM, title: String) {

        self.init(vm: vm, 

                  title: title, 

                  toolbarContent: { EmptyView() }, 

                  configContent: { EmptyView() }, 

                  helpContent: { EmptyView() })

    }

}



extension GenericTextToolView where ToolbarContent == EmptyView, InputFooter == AnyView, OutputFooter == AnyView {

    init(vm: VM, 

         title: String,

         @ViewBuilder configContent: @escaping () -> ConfigContent,

         @ViewBuilder helpContent: @escaping () -> HelpContent) {

        self.init(vm: vm, 

                  title: title, 

                  toolbarContent: { EmptyView() }, 

                  configContent: configContent, 

                  helpContent: helpContent)

    }

}
